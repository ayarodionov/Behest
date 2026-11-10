# behest-effects: none
#
# Contract for Median.median/1.
# Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
defmodule Median.ContractTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

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
    property "order does not matter" do
      check all xs <- list_of(float()) do
        assert Median.median(xs) == Median.median(Enum.shuffle(xs))
      end
    end

    property "lies between the minimum and the maximum" do
      check all xs <- list_of(integer(), min_length: 1) do
        {:ok, m} = Median.median(xs)
        assert Enum.min(xs) <= m and m <= Enum.max(xs)
      end
    end

    # Pins the position: without this, any fixed position (the first third, say)
    # would pass the two properties above.
    property "at least half the values are at or below it, and at least half at or above" do
      check all xs <- list_of(integer(), min_length: 1) do
        {:ok, m} = Median.median(xs)
        n = length(xs)
        assert 2 * Enum.count(xs, &(&1 <= m)) >= n
        assert 2 * Enum.count(xs, &(&1 >= m)) >= n
      end
    end
  end
end
