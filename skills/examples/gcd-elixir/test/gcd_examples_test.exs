# behest-effects: none
#
# Contract (examples) for Gcd.gcd/2. Plain ExUnit, no dependencies.
# Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
defmodule Gcd.ExamplesTest do
  use ExUnit.Case, async: true

  test "common case" do
    assert Gcd.gcd(12, 18) == 6
  end

  test "coprime numbers give 1" do
    assert Gcd.gcd(17, 5) == 1
  end

  test "zero and n give |n|, in either order" do
    assert Gcd.gcd(0, 7) == 7
    assert Gcd.gcd(7, 0) == 7
  end

  test "gcd(0, 0) is 0" do
    assert Gcd.gcd(0, 0) == 0
  end

  test "signs are ignored: the result is never negative" do
    assert Gcd.gcd(-12, 18) == 6
    assert Gcd.gcd(12, -18) == 6
    assert Gcd.gcd(-12, -18) == 6
  end
end
