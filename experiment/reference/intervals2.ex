defmodule Intervals do
  def merge(intervals) when is_list(intervals) do
    intervals
    |> Enum.map(fn {a, b} when is_integer(a) and is_integer(b) -> {min(a, b), max(a, b)} end)
    |> Enum.reject(fn {from, to} -> from == to end)
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
