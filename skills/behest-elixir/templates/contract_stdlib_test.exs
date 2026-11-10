# behest-effects: none
#
# Contract for Median.median/1, using only the standard library (no StreamData).
# Use this variant when StreamData cannot be installed; otherwise prefer
# contract_test.exs, whose generators and shrinking are better.
# Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
defmodule Median.ContractTest do
  use ExUnit.Case, async: true

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
      check(&numbers/0, fn xs -> Median.median(xs) == Median.median(Enum.reverse(xs)) end)
    end

    test "lies between the minimum and the maximum" do
      check(&numbers/0, fn xs ->
        {:ok, m} = Median.median(xs)
        Enum.min(xs) <= m and m <= Enum.max(xs)
      end)
    end

    # Pins the position: without this, any fixed position (the first third, say)
    # would pass the two properties above.
    test "at least half the values are at or below it, and at least half at or above" do
      check(&numbers/0, fn xs ->
        {:ok, m} = Median.median(xs)
        n = length(xs)
        2 * Enum.count(xs, &(&1 <= m)) >= n and 2 * Enum.count(xs, &(&1 >= m)) >= n
      end)
    end
  end

  # --- a small property runner: seeded inputs, and shrinking on failure ---------

  # A non-empty list of small integers: ties, zeros and negatives are common.
  defp numbers, do: for(_ <- 1..:rand.uniform(9), do: :rand.uniform(11) - 6)

  # Runs `property` (a function returning true or false) on `runs` generated
  # inputs. The seed is fixed, so a failure repeats; change it to explore.
  defp check(generator, runs \\ 500, property) do
    :rand.seed(:exsss, {2026, 1, 1})

    for _ <- 1..runs do
      input = generator.()

      if fails?(property, input) do
        small = shrink(input, &fails?(property, &1))
        flunk("property fails for #{inspect(small)} (first found with #{inspect(input)})")
      end
    end
  end

  # A crash counts as a failure, so a shrunk input cannot hide one.
  defp fails?(property, input) do
    property.(input) != true
  rescue
    _ -> true
  end

  # Smaller lists that still fail. Removing two neighbours keeps the length odd
  # or even (removing one flips it and can hide the failure); then single
  # elements; then each element moved towards zero.
  defp shrink(xs, still_fails) do
    n = length(xs)

    candidates =
      for(i <- 0..(n - 2)//1, n > 2, do: xs |> List.delete_at(i) |> List.delete_at(i)) ++
        for(i <- 0..(n - 1)//1, n > 1, do: List.delete_at(xs, i)) ++
        for(i <- 0..(n - 1)//1, Enum.at(xs, i) != 0, do: List.replace_at(xs, i, div(Enum.at(xs, i), 2)))

    case Enum.find(candidates, still_fails) do
      nil -> xs
      smaller -> shrink(smaller, still_fails)
    end
  end
end
