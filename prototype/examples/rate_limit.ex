defmodule Behest.Examples.RateLimit do
  @moduledoc """
  Fixed-window rate limiter. `check/5` is pure (time is passed in), so its
  examples and properties are deterministic. `check_now/4` reads the clock and
  must therefore declare the `:time` effect.
  """
  use Behest

  defspec check(counts, id, now_ms, limit, window_ms) do
    examples do
      replay([{:a, 0}, {:a, 0}, {:a, 0}, {:a, 10}], 3, 1000) == [:ok, :ok, :ok, :rate_limited]
      replay([{:a, 0}, {:a, 0}, {:a, 0}, {:b, 10}], 3, 1000) == [:ok, :ok, :ok, :ok]
      replay([{:a, 0}, {:a, 0}, {:a, 0}, {:a, 1000}], 3, 1000) == [:ok, :ok, :ok, :ok]
    end

    property "never more than limit per client per window",
      steps: list_of(tuple({member_of([:a, :b, :c]), positive_integer()})) do
      calls = with_times(steps)
      results = replay(calls, 3, 100)

      Enum.zip(calls, results)
      |> Enum.filter(fn {_, r} -> r == :ok end)
      |> Enum.frequencies_by(fn {{id, t}, _} -> {id, div(t, 100)} end)
      |> Enum.all?(fn {_, n} -> n <= 3 end)
    end

    implementation do
      start = now_ms - rem(now_ms, window_ms)

      case Map.get(counts, id) do
        {^start, n} when n >= limit -> {:rate_limited, counts}
        {^start, n} -> {:ok, Map.put(counts, id, {start, n + 1})}
        _ -> {:ok, Map.put(counts, id, {start, 1})}
      end
    end
  end

  defspec now_ms() do
    effects [:time]

    implementation do
      System.monotonic_time(:millisecond)
    end
  end

  defspec check_now(counts, id, limit, window_ms) do
    effects [:time]

    implementation do
      check(counts, id, now_ms(), limit, window_ms)
    end
  end

  # helpers used by examples and properties

  defp replay(calls, limit, window_ms) do
    {results, _} =
      Enum.map_reduce(calls, %{}, fn {id, t}, counts ->
        {result, counts} = check(counts, id, t, limit, window_ms)
        {result, counts}
      end)

    results
  end

  defp with_times(steps) do
    {calls, _} = Enum.map_reduce(steps, 0, fn {id, dt}, t -> {{id, t + dt - 1}, t + dt - 1} end)
    calls
  end
end
