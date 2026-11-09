# Disagreement check. Throwaway: keep in test/scratch/ and do not commit.
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

  property "the two implementations agree" do
    check all xs <- list_of(integer()), max_runs: 1000 do
      assert Median.median(xs) == Alt.median(xs)
    end
  end
end
