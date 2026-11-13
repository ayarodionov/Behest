# Disagreement check with PropEr (https://github.com/proper-testing/proper),
# called directly from Elixir. Throwaway: keep it in .behest-scratch/ and do not
# commit.
#
#     mix test .behest-scratch/disagree_proper_test.exs
#
# Median is the real implementation; Alt below is a deliberately different
# implementation (other algorithm, or the other plausible reading of the
# request) that ALSO passes the approved contract. Where they disagree, the
# contract is missing an example: show both answers to the human.
defmodule Scratch.DisagreeProperTest do
  use ExUnit.Case

  defmodule Alt do
    # Reading B: for even lengths take the lower of the two middle values.
    def median([]), do: {:error, :empty}
    def median(xs), do: {:ok, xs |> Enum.sort() |> Enum.at(div(length(xs) - 1, 2))}
  end

  # The input is built from pairs plus at most one extra element. PropEr shrinks a
  # list by removing one element at a time, which flips odd/even length and can
  # hide a disagreement; shrinking pairs keeps the parity, so it reaches e.g.
  # [0, 1]. `:proper_types.bind/3` is what ?LET expands to in Erlang.
  defp inputs do
    pairs = :proper_types.list({:proper_types.integer(-5, 5), :proper_types.integer(-5, 5)})
    extra = :proper_types.oneof([[], [:proper_types.integer(-5, 5)]])

    :proper_types.bind({pairs, extra}, fn {ps, ex} -> Enum.flat_map(ps, &Tuple.to_list/1) ++ ex end, false)
  end

  test "the two implementations agree" do
    prop = :proper.forall(inputs(), fn xs -> Median.median(xs) == Alt.median(xs) end)

    unless :proper.quickcheck(prop, [{:numtests, 1000}, {:to_file, :user}]) == true do
      [small] = :proper.counterexample()

      flunk("""
      the implementations disagree on #{inspect(small)}
        Median: #{inspect(Median.median(small))}
        Alt:    #{inspect(Alt.median(small))}
      """)
    end
  end
end
