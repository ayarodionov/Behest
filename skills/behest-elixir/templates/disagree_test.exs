# Disagreement check. Throwaway: keep in .behest-scratch/ and do not commit.
#
#     mix test .behest-scratch/disagree_test.exs
#
# Median is the real implementation; Alt below is a deliberately different
# implementation (other algorithm, or the other plausible reading of the
# request) that ALSO passes the approved contract. Where they disagree, the
# contract is missing an example: show both answers to the human.
defmodule Scratch.DisagreeTest do
  use ExUnit.Case
  use ExUnitProperties

  defmodule Alt do
    # Reading B: for even lengths take the lower of the two middle values.
    def median([]), do: {:error, :empty}
    def median(xs), do: {:ok, xs |> Enum.sort() |> Enum.at(div(length(xs) - 1, 2))}
  end

  # The input is built from pairs plus at most one extra element. A plain
  # list_of(integer()) shrinks one element at a time, and removing one element
  # flips odd/even length and hides a disagreement, so the shrunk case stays
  # large. Shrinking pairs keeps the length parity, so it reaches e.g. [0, 1].
  # Adapt the generator to the shape of your own function's input.
  property "the two implementations agree" do
    check all pairs <- list_of({integer(), integer()}),
              extra <- one_of([constant(nil), integer()]),
              max_runs: 1000 do
      xs = Enum.flat_map(pairs, fn {a, b} -> [a, b] end) ++ if(extra == nil, do: [], else: [extra])
      assert Median.median(xs) == Alt.median(xs)
    end
  end
end
