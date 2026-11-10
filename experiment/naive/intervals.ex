# A plausible first guess, written without asking anything: it swaps reversed
# intervals and also merges neighbours such as {1, 2} and {3, 4}.
defmodule Intervals do
  def merge(intervals) do
    intervals
    |> Enum.map(fn {a, b} -> {min(a, b), max(a, b)} end)
    |> Enum.sort()
    |> Enum.reduce([], fn
      {from, to}, [{cur_from, cur_to} | rest] when from <= cur_to + 1 ->
        [{cur_from, max(cur_to, to)} | rest]

      interval, acc ->
        [interval | acc]
    end)
    |> Enum.reverse()
  end
end
