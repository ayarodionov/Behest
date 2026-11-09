defmodule Behest.Effects do
  @moduledoc """
  Static effect check. Scans an implementation for calls with side effects
  and compares them with the `effects [...]` the spec declares. Calls to other
  `defspec` functions in the same module bring their effects along.

  Known effects: :send, :spawn, :ets, :io, :time, :random.
  The scan is syntactic and covers common calls; it is not a proof.
  """

  @erlang %{
    ets: :ets,
    file: :io,
    io: :io,
    rand: :random,
    random: :random,
    timer: :time,
    gen_server: :send
  }

  @erlang_fun %{
    {:erlang, :send} => :send,
    {:erlang, :spawn} => :spawn,
    {:erlang, :spawn_link} => :spawn,
    {:erlang, :monotonic_time} => :time,
    {:erlang, :system_time} => :time,
    {:erlang, :send_after} => :time,
    {:erlang, :start_timer} => :time,
    {:os, :system_time} => :time
  }

  @elixir %{
    IO: :io,
    File: :io,
    Port: :io,
    Task: :spawn
  }

  @elixir_fun %{
    {:Process, :send} => :send,
    {:Process, :send_after} => :time,
    {:Process, :sleep} => :time,
    {:Process, :spawn} => :spawn,
    {:GenServer, :call} => :send,
    {:GenServer, :cast} => :send,
    {:GenServer, :reply} => :send,
    {:GenServer, :start} => :spawn,
    {:GenServer, :start_link} => :spawn,
    {:Agent, :start} => :spawn,
    {:Agent, :start_link} => :spawn,
    {:Agent, :get} => :send,
    {:Agent, :update} => :send,
    {:System, :monotonic_time} => :time,
    {:System, :system_time} => :time,
    {:System, :os_time} => :time,
    {:System, :cmd} => :io,
    {:DateTime, :utc_now} => :time,
    {:NaiveDateTime, :utc_now} => :time,
    {:Date, :utc_today} => :time,
    {:Time, :utc_now} => :time,
    {:Enum, :random} => :random,
    {:Enum, :shuffle} => :random,
    {:Enum, :take_random} => :random
  }

  @kernel %{send: :send, spawn: :spawn, spawn_link: :spawn, spawn_monitor: :spawn}

  @doc "Returns `[{effect, call_description}]` found directly in `ast`."
  def scan(ast) do
    {_, found} = Macro.prewalk(ast, [], fn node, acc -> {node, classify(node) ++ acc} end)
    found |> Enum.reverse() |> Enum.uniq()
  end

  defp classify({{:., _, [mod, fun]}, _, args}) when is_atom(mod) and is_list(args) do
    case Map.get(@erlang_fun, {mod, fun}) || Map.get(@erlang, mod) do
      nil -> []
      eff -> [{eff, ":#{mod}.#{fun}"}]
    end
  end

  defp classify({{:., _, [{:__aliases__, _, [mod]}, fun]}, _, args}) when is_list(args) do
    case Map.get(@elixir_fun, {mod, fun}) || Map.get(@elixir, mod) do
      nil -> []
      eff -> [{eff, "#{mod}.#{fun}"}]
    end
  end

  defp classify({fun, _, args}) when is_atom(fun) and is_list(args) do
    case Map.get(@kernel, fun) do
      nil -> []
      eff -> [{eff, "#{fun}/#{length(args)}"}]
    end
  end

  defp classify(_), do: []

  @doc "Returns local calls `{name, arity}` in `ast` (candidates for other specs)."
  def local_calls(ast) do
    {_, calls} =
      Macro.prewalk(ast, [], fn
        {name, _, args} = node, acc when is_atom(name) and is_list(args) -> {node, [{name, length(args)} | acc]}
        node, acc -> {node, acc}
      end)

    Enum.uniq(calls)
  end

  @doc false
  def check!(specs, env) do
    by_key = Map.new(specs, &{{&1.name, &1.arity}, &1})

    for spec <- specs do
      used = spec.direct ++ inherited(spec, by_key)

      case Enum.reject(used, fn {eff, _} -> eff in spec.declared end) do
        [] ->
          :ok

        missing ->
          lines =
            missing
            |> Enum.uniq_by(&elem(&1, 0))
            |> Enum.map_join("\n", fn {eff, via} -> "  #{inspect(eff)} (from #{via})" end)

          raise CompileError,
            file: env.file,
            line: spec.line,
            description:
              "#{spec.name}/#{spec.arity} uses effects it does not declare:\n#{lines}\n" <>
                "declared: #{inspect(spec.declared)}"
      end
    end

    :ok
  end

  # A call to another spec brings that spec's declared effects. Each spec is
  # checked against its own declaration, so declarations compose.
  defp inherited(spec, by_key) do
    for {n, a} = callee <- spec.local_calls,
        callee != {spec.name, spec.arity},
        Map.has_key?(by_key, callee),
        eff <- Map.fetch!(by_key, callee).declared,
        do: {eff, "#{n}/#{a}"}
  end
end
