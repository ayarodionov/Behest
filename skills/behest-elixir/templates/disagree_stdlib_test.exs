# Disagreement check, using only the standard library (no StreamData).
# Throwaway: keep it in .behest-scratch/ and do not commit.
#
#     mix test .behest-scratch/disagree_stdlib_test.exs
#
# Median is the real implementation; Alt below is a deliberately different
# implementation (other algorithm, or the other plausible reading of the
# request) that ALSO passes the approved contract. Where they disagree, the
# contract is missing an example: show both answers to the human.
defmodule Scratch.DisagreeTest do
  use ExUnit.Case

  defmodule Alt do
    # Reading B: for even lengths take the lower of the two middle values.
    def median([]), do: {:error, :empty}
    def median(xs), do: {:ok, xs |> Enum.sort() |> Enum.at(div(length(xs) - 1, 2))}
  end

  test "the two implementations agree (1000 seeded inputs)" do
    :rand.seed(:exsss, {2026, 1, 1})
    differ? = fn xs -> Median.median(xs) != Alt.median(xs) end

    for _ <- 1..1000 do
      # Small integers hit ties, zeros and negatives, where meaning differs.
      xs = for _ <- 1..:rand.uniform(8), do: :rand.uniform(11) - 6

      if differ?.(xs) do
        small = shrink(xs, differ?)

        flunk("""
        the implementations disagree on #{inspect(small)}
          Median: #{inspect(Median.median(small))}
          Alt:    #{inspect(Alt.median(small))}
        """)
      end
    end
  end

  # Smaller lists that still differ. Removing two neighbours keeps the length
  # odd or even (removing one flips it and can hide the disagreement); then
  # single elements; then each element moved towards zero.
  defp shrink(xs, still_differs) do
    n = length(xs)

    candidates =
      for(i <- 0..(n - 2)//1, n > 2, do: xs |> List.delete_at(i) |> List.delete_at(i)) ++
        for(i <- 0..(n - 1)//1, n > 1, do: List.delete_at(xs, i)) ++
        for(i <- 0..(n - 1)//1, Enum.at(xs, i) != 0, do: List.replace_at(xs, i, div(Enum.at(xs, i), 2)))

    case Enum.find(candidates, still_differs) do
      nil -> xs
      smaller -> shrink(smaller, still_differs)
    end
  end
end
