defmodule Intervals do
  def merge(intervals) when is_list(intervals) do
    Enum.each(intervals, fn
      {from, to} when is_integer(from) and is_integer(to) and from <= to -> :ok
      other -> raise ArgumentError, "invalid interval: #{inspect(other)}"
    end)

    intervals
    |> Enum.sort()
    |> Enum.reduce([], fn
      {from, to}, [{cur_from, cur_to} | rest] when from <= cur_to ->
        [{cur_from, max(cur_to, to)} | rest]

      interval, acc ->
        [interval | acc]
    end)
    |> Enum.reverse()
  end
end
