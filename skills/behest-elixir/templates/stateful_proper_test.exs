# behest-effects: send, spawn
#
# Contract for TtlCache, a GenServer, with PropEr's stateful testing
# (proper_statem, https://github.com/proper-testing/proper) called directly from
# Elixir. Random command sequences run against the real process and against a
# small model; every reply must match the model's, and a failure is shrunk to
# the shortest failing sequence. In mix.exs:
#
#     {:proper, "~> 1.5", only: :test}
#
# Time is not an effect here. The clock is a function given to start_link/1, so
# the contract moves time itself and nothing ever sleeps. The effects line allows
# messages and processes only: an implementation that reads the real clock, or
# starts a timer, fails the effect scan.
# Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
defmodule TtlCache.StatefulProperTest do
  use ExUnit.Case, async: false

  import :proper_types, only: [oneof: 1, frequency: 1, integer: 2]

  @cache :ttl_cache_under_test

  # --- the model (part of the contract) --------------------------------------
  # State: the current time and, for each key, its value and the time it expires.
  # An entry is visible while now < expires.

  def model({:put, _k, _v, ttl}, s) when not is_integer(ttl) or ttl < 1, do: {{:error, :bad_ttl}, s}
  def model({:put, k, v, ttl}, s), do: {:ok, put_in(s.entries[k], {v, s.now + ttl})}

  def model({:get, k}, s) do
    case s.entries do
      %{^k => {v, expires}} when s.now < expires -> {{:ok, v}, s}
      _ -> {:not_found, s}
    end
  end

  def model({:delete, k}, s), do: {:ok, %{s | entries: Map.delete(s.entries, k)}}
  def model(:size, s), do: {Enum.count(s.entries, fn {_, {_, expires}} -> s.now < expires end), s}
  def model({:advance, ms}, s), do: {:ok, %{s | now: s.now + ms}}

  # --- examples: each is a script, in order -----------------------------------
  # Written as {command, expected_reply}. They are the answers to the open
  # questions, in plain sight; each is also checked against the model.

  test "put then get" do
    script([{{:put, :a, 1, 10}, :ok}, {{:get, :a}, {:ok, 1}}, {{:get, :b}, :not_found}])
  end

  # Answer: an entry with TTL 10 put at time 0 is still there at 9 and gone at 10.
  test "expires exactly at its ttl" do
    script([
      {{:put, :a, 1, 10}, :ok},
      {{:advance, 9}, :ok},
      {{:get, :a}, {:ok, 1}},
      {{:advance, 1}, :ok},
      {{:get, :a}, :not_found}
    ])
  end

  # Answer: putting an existing key replaces the value and restarts its TTL.
  test "put again restarts the ttl" do
    script([
      {{:put, :a, 1, 10}, :ok},
      {{:advance, 8}, :ok},
      {{:put, :a, 2, 10}, :ok},
      {{:advance, 8}, :ok},
      {{:get, :a}, {:ok, 2}}
    ])
  end

  # Answer: a TTL below 1 is refused, and nothing is stored.
  test "bad ttl is refused" do
    script([{{:put, :a, 1, 0}, {:error, :bad_ttl}}, {{:get, :a}, :not_found}, {:size, 0}])
  end

  # --- the property: proper_statem ----------------------------------------------

  test "replies always match the model (300 random command sequences)" do
    prop =
      :proper.forall(:proper_statem.commands(__MODULE__), fn cmds ->
        {history, _state, result} = with_cache(fn -> :proper_statem.run_commands(__MODULE__, cmds) end)

        # Both arguments are functions: that is what ?WHENFAIL expands to in Erlang.
        :proper.whenfail(
          fn -> IO.puts("commands: #{inspect(cmds)}\nhistory: #{inspect(history)}\nresult: #{inspect(result)}") end,
          fn -> result == :ok end
        )
      end)

    unless :proper.quickcheck(prop, [{:numtests, 300}, {:to_file, :user}]) == true do
      [cmds] = :proper.counterexample()
      flunk("the cache and the model disagree; shortest failing sequence: #{inspect(Enum.map(cmds, &step/1))}")
    end
  end

  # proper_statem callbacks. The model state is the same map model/2 uses.

  def initial_state, do: %{now: 0, entries: %{}}

  # Few keys and short TTLs, so entries collide and expire often.
  def command(_s) do
    key = oneof([:a, :b, :c])
    ttl = frequency([{8, integer(1, 6)}, {1, oneof([0, -1])}])

    frequency([
      {4, {:call, TtlCache, :put, [@cache, key, integer(1, 9), ttl]}},
      {4, {:call, TtlCache, :get, [@cache, key]}},
      {1, {:call, TtlCache, :delete, [@cache, key]}},
      {2, {:call, TtlCache, :size, [@cache]}},
      {3, {:call, __MODULE__, :advance, [integer(1, 4)]}}
    ])
  end

  def precondition(_s, _call), do: true

  def next_state(s, _reply, call) do
    {_expected, s1} = model(to_model(call), s)
    s1
  end

  def postcondition(s, call, reply) do
    {expected, _} = model(to_model(call), s)
    reply == expected
  end

  defp to_model({:call, TtlCache, :put, [_, k, v, ttl]}), do: {:put, k, v, ttl}
  defp to_model({:call, TtlCache, :get, [_, k]}), do: {:get, k}
  defp to_model({:call, TtlCache, :delete, [_, k]}), do: {:delete, k}
  defp to_model({:call, TtlCache, :size, [_]}), do: :size
  defp to_model({:call, __MODULE__, :advance, [ms]}), do: {:advance, ms}

  defp step({:set, _var, call}), do: to_model(call)

  # --- concrete cases for the human --------------------------------------------
  # Run before asking for approval and paste the output into the question:
  #
  #     mix test --only cases
  #
  # (put `ExUnit.configure(exclude: [:cases])` in test/test_helper.exs). Random
  # sequences are mostly dull, so 200 are generated and the three in which the
  # most happens are shown. Needs no implementation.

  @tag :cases
  test "print concrete cases" do
    for _ <- 1..200 do
      {:ok, cmds} = :proper_gen.pick(:proper_statem.commands(__MODULE__), 14)

      {steps, _} =
        Enum.map_reduce(cmds, initial_state(), fn c, s ->
          st = step(c)
          {expected, s1} = model(st, s)
          {{s.now, st, expected}, s1}
        end)

      {interest(steps), steps}
    end
    |> Enum.sort_by(fn {score, _} -> -score end)
    |> Enum.take(3)
    |> Enum.each(fn {_, steps} ->
      IO.puts("--- sequence")
      for {now, st, expected} <- steps, do: IO.puts("  t=#{now}  #{inspect(st)} -> #{inspect(expected)}")
    end)
  end

  # Hits, a miss on a key that was put earlier (an expiry or a delete), refusals.
  defp interest(steps) do
    put = for {_, {:put, k, _, _}, :ok} <- steps, do: k

    Enum.count(steps, &match?({_, {:get, _}, {:ok, _}}, &1)) +
      2 * Enum.count(steps, fn s -> match?({_, {:get, _}, :not_found}, s) and elem(elem(s, 1), 1) in put end) +
      Enum.count(steps, &match?({_, _, {:error, _}}, &1))
  end

  # --- helpers: a controllable clock and a fresh cache per run ------------------

  # Time lives in a counter the test owns; the cache gets a function that reads it.
  def advance(ms) do
    :counters.add(:persistent_term.get({__MODULE__, :clock}), 1, ms)
    :ok
  end

  defp with_cache(fun) do
    clock = :counters.new(1, [])
    :persistent_term.put({__MODULE__, :clock}, clock)
    {:ok, pid} = TtlCache.start_link(clock: fn -> :counters.get(clock, 1) end, name: @cache)

    try do
      fun.()
    after
      Process.unlink(pid)
      GenServer.stop(pid)
    end
  end

  defp script(steps) do
    with_cache(fn ->
      Enum.reduce(steps, initial_state(), fn {st, expected}, s ->
        {from_model, s1} = model(st, s)
        assert {st, from_model} == {st, expected}
        assert {st, run(st)} == {st, expected}
        s1
      end)
    end)
  end

  defp run({:put, k, v, ttl}), do: TtlCache.put(@cache, k, v, ttl)
  defp run({:get, k}), do: TtlCache.get(@cache, k)
  defp run({:delete, k}), do: TtlCache.delete(@cache, k)
  defp run(:size), do: TtlCache.size(@cache)
  defp run({:advance, ms}), do: advance(ms)
end
