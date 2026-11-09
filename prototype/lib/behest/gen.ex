defmodule Behest.Gen do
  @moduledoc """
  Minimal random generators for properties. A generator is a function of a
  size hint that returns a value. Imported automatically inside `property`.

  No shrinking yet: a counterexample is reported as found.
  """

  def integer, do: fn size -> :rand.uniform(2 * size + 1) - size - 1 end
  def positive_integer, do: fn size -> :rand.uniform(size + 1) end
  def float, do: fn size -> (:rand.uniform() * 2 - 1) * size end
  def boolean, do: fn _ -> :rand.uniform(2) == 1 end
  def atom, do: member_of([:a, :b, :c, :d, :e])
  def binary, do: fn size -> :rand.bytes(:rand.uniform(size + 1) - 1) end
  def constant(value), do: fn _ -> value end

  def member_of([_ | _] = values), do: fn _ -> Enum.at(values, :rand.uniform(length(values)) - 1) end

  def one_of([_ | _] = gens), do: fn size -> Enum.at(gens, :rand.uniform(length(gens)) - 1).(size) end

  def list_of(gen), do: fn size -> for _ <- 1..(:rand.uniform(size + 1) - 1)//1, do: gen.(size) end

  def nonempty_list_of(gen), do: fn size -> for _ <- 1..:rand.uniform(size + 1)//1, do: gen.(size) end

  def tuple(gens) when is_tuple(gens),
    do: fn size -> gens |> Tuple.to_list() |> Enum.map(& &1.(size)) |> List.to_tuple() end
end
