# behest-effects: none
#
# Contract for Median.median/1, with properties run by PropEr
# (https://github.com/proper-testing/proper) called directly from Elixir.
# Use this variant when the project already uses PropEr, or wants PropEr's
# shrinking and stateful testing without a wrapper. In mix.exs:
#
#     {:proper, "~> 1.5", only: :test}
#
# PropCheck (https://github.com/alfert/propcheck) wraps the same engine in Elixir
# macros (`forall xs <- list(integer()) do ... end`); see the skill for that form.
# Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
defmodule Median.ContractTest do
  use ExUnit.Case, async: true

  # PropEr's generators, with short local names.
  import :proper_types, only: [list: 1, non_empty: 1, integer: 0, float: 0]

  describe "examples" do
    test "odd length: the middle value" do
      assert Median.median([3.0, 1.0, 2.0]) == {:ok, 2.0}
    end

    test "even length: mean of the two middle values" do
      assert Median.median([4.0, 1.0, 3.0, 2.0]) == {:ok, 2.5}
    end

    test "odd length of five: still the middle value" do
      assert Median.median([5.0, 1.0, 4.0, 2.0, 3.0]) == {:ok, 3.0}
    end

    test "empty list is an error" do
      assert Median.median([]) == {:error, :empty}
    end
  end

  describe "properties" do
    test "order does not matter" do
      check(list(float()), fn xs -> Median.median(xs) == Median.median(Enum.reverse(xs)) end)
    end

    test "lies between the minimum and the maximum" do
      check(non_empty(list(integer())), fn xs ->
        {:ok, m} = Median.median(xs)
        Enum.min(xs) <= m and m <= Enum.max(xs)
      end)
    end

    # Pins the position: without this, any fixed position (the first third, say)
    # would pass the two properties above.
    test "at least half the values are at or below it, and at least half at or above" do
      check(non_empty(list(integer())), fn xs ->
        {:ok, m} = Median.median(xs)
        n = length(xs)
        2 * Enum.count(xs, &(&1 <= m)) >= n and 2 * Enum.count(xs, &(&1 >= m)) >= n
      end)
    end
  end

  # Runs one property with PropEr: `:proper.forall/2` is what ?FORALL expands to
  # in Erlang. On failure PropEr shrinks the input, and the test fails with the
  # shrunk counterexample. PropEr's own output goes to the test log.
  defp check(type, property, runs \\ 500) do
    prop = :proper.forall(type, fn x -> property.(x) == true end)

    unless :proper.quickcheck(prop, [{:numtests, runs}, {:to_file, :user}]) == true do
      flunk("property fails; shrunk counterexample: #{inspect(:proper.counterexample())}")
    end
  end
end
