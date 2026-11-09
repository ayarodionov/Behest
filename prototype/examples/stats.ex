defmodule Behest.Examples.Stats do
  use Behest

  defspec median(xs) do
    examples do
      median([3.0, 1.0, 2.0]) == {:ok, 2.0}
      median([4.0, 1.0, 3.0, 2.0]) == {:ok, 2.5}
      median([]) == {:error, :empty}
    end

    property "order does not matter", xs: list_of(float()) do
      median(xs) == median(Enum.shuffle(xs))
    end

    property "lies between min and max", xs: nonempty_list_of(integer()) do
      {:ok, m} = median(xs)
      Enum.min(xs) <= m and m <= Enum.max(xs)
    end

    implementation do
      sorted = Enum.sort(xs)
      n = length(sorted)
      mid = div(n, 2)

      cond do
        n == 0 -> {:error, :empty}
        rem(n, 2) == 1 -> {:ok, Enum.at(sorted, mid)}
        true -> {:ok, (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2}
      end
    end
  end
end
