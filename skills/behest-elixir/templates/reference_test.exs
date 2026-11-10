# behest-effects: none
#
# Contract for Uniq.uniq/1, built around a REFERENCE MODEL: a slow, obviously
# correct version that the human can read in one glance. The main property is
# "the implementation agrees with the reference on every input".
# Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
#
# Not run where it was written (StreamData was not reachable); the Erlang
# version of this template (behest-erlang/templates/reference_tests.erl) was.
defmodule Uniq.ReferenceTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  # --- reference model (part of the contract) -------------------------------
  # Keep the first occurrence of each element, in the original order.
  # Quadratic on purpose: clarity matters here, speed does not.

  def reference([]), do: []
  def reference([x | rest]), do: [x | reference(Enum.reject(rest, &(&1 === x)))]

  # --- examples ---------------------------------------------------------------
  # Still needed: they are the answers to the open questions, in plain sight.

  test "keeps the first occurrence" do
    assert Uniq.uniq([:b, :a, :b, :c, :a]) === [:b, :a, :c]
  end

  test "empty list" do
    assert Uniq.uniq([]) === []
  end

  # Answer to an open question: 1 and 1.0 are different elements (===, not ==).
  test "integer and float differ" do
    assert Uniq.uniq([1, 1.0, 1]) === [1, 1.0]
  end

  # --- properties -------------------------------------------------------------

  # Few distinct values, so duplicates are likely; 1 and 1.0 are both present.
  defp element, do: one_of([integer(-2..2), constant(:a), constant(:b), constant(1.0)])

  property "agrees with the reference" do
    check all xs <- list_of(element()), max_runs: 300 do
      assert Uniq.uniq(xs) === reference(xs)
    end
  end

  # --- concrete cases for the human -------------------------------------------
  # Run before asking for approval and paste the output into the question:
  #
  #     mix test --only cases
  #
  # (put `ExUnit.configure(exclude: [:cases])` in test/test_helper.exs so normal
  # runs skip it). Each line is one input and the answer the contract demands for
  # it. The human approves these cases, not the generator code. Needs no
  # implementation.

  @tag :cases
  test "print concrete cases" do
    for length <- [0, 1, 2, 4, 6, 8, 10] do
      [xs] = list_of(element(), length: length) |> Enum.take(1)
      IO.puts("uniq(#{inspect(xs)}) -> #{inspect(reference(xs))}")
    end
  end
end
