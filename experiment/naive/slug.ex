# A plausible first guess, written without asking anything.
defmodule Slug do
  def slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/[^a-z0-9_-]/, "")
  end
end
