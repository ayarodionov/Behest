# behest-effects: none
#
# Contract (properties) for Gcd.gcd/2. Needs StreamData.
# Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
defmodule Gcd.PropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "symmetric" do
    check all a <- integer(), b <- integer() do
      assert Gcd.gcd(a, b) == Gcd.gcd(b, a)
    end
  end

  property "divides both numbers" do
    check all a <- integer(), b <- integer() do
      g = Gcd.gcd(a, b)

      if g == 0 do
        assert a == 0 and b == 0
      else
        assert rem(a, g) == 0 and rem(b, g) == 0
      end
    end
  end

  property "no larger common divisor exists" do
    check all a <- positive_integer(), b <- positive_integer() do
      g = Gcd.gcd(a, b)
      refute Enum.any?((g + 1)..min(a, b)//1, fn d -> rem(a, d) == 0 and rem(b, d) == 0 end)
    end
  end

  property "scales with a common factor" do
    check all a <- integer(), b <- integer(), k <- positive_integer() do
      assert Gcd.gcd(a * k, b * k) == k * Gcd.gcd(a, b)
    end
  end
end
