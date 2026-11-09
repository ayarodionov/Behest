defmodule Behest.Examples.Gcd do
  @moduledoc """
  Greatest common divisor (Euclid). A good contract example: the examples pin
  down the edge cases (zeros, negatives), and the properties say what "greatest
  common divisor" means without saying how to compute it.
  """
  use Behest

  defspec gcd(a, b) do
    examples do
      gcd(12, 18) == 6
      gcd(17, 5) == 1
      gcd(0, 7) == 7
      gcd(7, 0) == 7
      gcd(0, 0) == 0
      gcd(-12, 18) == 6
      gcd(12, -18) == 6
      gcd(-12, -18) == 6
    end

    property "divides both numbers", a: integer(), b: integer() do
      g = gcd(a, b)

      if g == 0 do
        a == 0 and b == 0
      else
        rem(a, g) == 0 and rem(b, g) == 0
      end
    end

    property "no larger common divisor exists", a: positive_integer(), b: positive_integer() do
      g = gcd(a, b)
      not Enum.any?((g + 1)..min(a, b)//1, fn d -> rem(a, d) == 0 and rem(b, d) == 0 end)
    end

    property "symmetric", a: integer(), b: integer() do
      gcd(a, b) == gcd(b, a)
    end

    property "never negative", a: integer(), b: integer() do
      gcd(a, b) >= 0
    end

    property "scales with a common factor", a: integer(), b: integer(), k: positive_integer() do
      gcd(a * k, b * k) == k * gcd(a, b)
    end

    property "agrees with Integer.gcd/2", a: integer(), b: integer() do
      gcd(a, b) == Integer.gcd(a, b)
    end

    implementation do
      if b == 0, do: abs(a), else: gcd(b, rem(a, b))
    end
  end
end
