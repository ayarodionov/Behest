defmodule Gcd do
  @moduledoc "Greatest common divisor (Euclid)."

  @spec gcd(integer(), integer()) :: non_neg_integer()
  def gcd(a, 0), do: abs(a)
  def gcd(a, b), do: gcd(b, rem(a, b))
end
