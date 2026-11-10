# behest-effects: send, spawn
#
# Contract for TtlCache, a GenServer. A STATEFUL contract: the property runs random
# sequences of commands against the real process and against a small model, and
# every reply must match the model's.
#
# Time is not an effect here. The clock is a function given to start_link/1, so the
# contract moves time itself and nothing ever sleeps. The effects line allows
# messages and processes only: an implementation that reads the real clock, or
# starts a timer, fails the effect scan.
#
# Standard library only (no StreamData): commands come from a seeded :rand
# generator, and a failing sequence is shrunk by removing commands.
# Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
defmodule TtlCache.StatefulContractTest do
  use ExUnit.Case, async: false

  # --- the model (part of the contract) --------------------------------------
  # State: the current time and, for each key, its value and the time it expires.
  # An entry is visible while now < expires.

  def initial, do: %{now: 0, entries: %{}}

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
  # questions, in plain sight.

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

  # Answer: size counts only entries that have not expired.
  test "size counts live entries only" do
    script([
      {{:put, :a, 1, 5}, :ok},
      {{:put, :b, 2, 10}, :ok},
      {:size, 2},
      {{:advance, 5}, :ok},
      {:size, 1}
    ])
  end

  # Answer: a TTL below 1 is refused, and nothing is stored.
  test "bad ttl is refused" do
    script([{{:put, :a, 1, 0}, {:error, :bad_ttl}}, {{:get, :a}, :not_found}, {:size, 0}])
  end

  # Answer: a stray message does not crash the cache or lose entries.
  test "stray messages are ignored" do
    {cache, _clock} = start()
    :ok = TtlCache.put(cache, :a, 1, 10)
    send(cache, {:some, :garbage})
    assert TtlCache.get(cache, :a) == {:ok, 1}
    GenServer.stop(cache)
  end

  # --- the property -------------------------------------------------------------

  test "replies always match the model (300 random command sequences)" do
    :rand.seed(:exsss, {2026, 11, 10})

    for _ <- 1..300 do
      commands = for _ <- 1..:rand.uniform(15), do: command()

      if mismatch(commands) do
        small = shrink(commands)
        {step, expected, got} = mismatch(small)

        flunk("""
        the cache and the model disagree.
        shortest failing sequence: #{inspect(small)}
        at #{inspect(step)}: the model says #{inspect(expected)}, the cache said #{inspect(got)}
        """)
      end
    end
  end

  # Few keys and short TTLs, so entries collide and expire often.
  defp command do
    key = Enum.random([:a, :b, :c])

    case :rand.uniform(14) do
      n when n <= 4 -> {:put, key, :rand.uniform(9), Enum.random([1, 2, 3, 4, 5, 6, 0, -1])}
      n when n <= 8 -> {:get, key}
      9 -> {:delete, key}
      n when n <= 11 -> :size
      _ -> {:advance, :rand.uniform(4)}
    end
  end

  # nil when every reply matches the model, else {step, expected, got} for the first that does not.
  defp mismatch(commands) do
    {cache, clock} = start()

    result =
      Enum.reduce_while(commands, initial(), fn step, s ->
        {expected, s1} = model(step, s)
        got = run(cache, clock, step)
        if got == expected, do: {:cont, s1}, else: {:halt, {step, expected, got}}
      end)

    GenServer.stop(cache)
    if is_map(result), do: nil, else: result
  end

  # Remove one command at a time for as long as the sequence still fails.
  defp shrink(commands) do
    smaller =
      Enum.find_value(0..(length(commands) - 1), fn i ->
        candidate = List.delete_at(commands, i)
        if candidate != [] and mismatch(candidate), do: candidate
      end)

    if smaller, do: shrink(smaller), else: commands
  end

  # --- concrete cases for the human --------------------------------------------
  # Run before asking for approval and paste the output into the question:
  #
  #     mix test --only cases
  #
  # (put `ExUnit.configure(exclude: [:cases])` in test/test_helper.exs). Each block
  # is one generated command sequence with the reply the model demands for every
  # step. Needs no implementation. Random sequences are mostly dull, so many are
  # generated and the three in which the most happens are shown.

  @tag :cases
  test "print concrete cases" do
    :rand.seed(:exsss, {1, 2, 3})

    for _ <- 1..200 do
      commands = for _ <- 1..14, do: command()

      {steps, _} =
        Enum.map_reduce(commands, initial(), fn step, s ->
          {expected, s1} = model(step, s)
          {{s.now, step, expected}, s1}
        end)

      {interest(steps), steps}
    end
    |> Enum.sort_by(fn {score, _} -> -score end)
    |> Enum.take(3)
    |> Enum.each(fn {_, steps} ->
      IO.puts("--- sequence")
      for {now, step, expected} <- steps, do: IO.puts("  t=#{now}  #{inspect(step)} -> #{inspect(expected)}")
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
  defp start do
    clock = :counters.new(1, [])
    {:ok, cache} = TtlCache.start_link(clock: fn -> :counters.get(clock, 1) end)
    {cache, clock}
  end

  defp run(cache, _clock, {:put, k, v, ttl}), do: TtlCache.put(cache, k, v, ttl)
  defp run(cache, _clock, {:get, k}), do: TtlCache.get(cache, k)
  defp run(cache, _clock, {:delete, k}), do: TtlCache.delete(cache, k)
  defp run(cache, _clock, :size), do: TtlCache.size(cache)
  defp run(_cache, clock, {:advance, ms}), do: :counters.add(clock, 1, ms)

  # Runs {command, expected_reply} pairs against a fresh cache, and checks each
  # expected reply against the model too, so an example cannot contradict it.
  defp script(steps) do
    {cache, clock} = start()

    Enum.reduce(steps, initial(), fn {step, expected}, s ->
      {from_model, s1} = model(step, s)
      assert {step, from_model} == {step, expected}
      assert {step, run(cache, clock, step)} == {step, expected}
      s1
    end)

    GenServer.stop(cache)
  end
end
