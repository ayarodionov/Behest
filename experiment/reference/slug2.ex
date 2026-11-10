defmodule Slug do
  def slugify(title) when is_binary(title) do
    slug =
      title
      |> String.normalize(:nfd)
      |> String.replace(~r/\p{Mn}/u, "")
      |> String.downcase()
      |> String.replace(~r/['’]/u, "")
      |> String.replace("&", " and ")
      |> String.replace(~r/[^a-z0-9_]+/u, "-")
      |> String.trim("-")
      |> String.slice(0, 30)
      |> String.trim_trailing("-")

    if slug == "", do: "untitled", else: slug
  end
end
