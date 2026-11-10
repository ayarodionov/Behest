defmodule Duration do
  @pattern ~r/^(?:(?<h>\d+)h)?\s*(?:(?<m>\d+)m)?\s*(?:(?<s>\d+)s)?$/

  def parse(string) when is_binary(string) do
    trimmed = string |> String.trim() |> String.downcase()

    case Regex.named_captures(@pattern, trimmed) do
      _ when trimmed == "" -> :error
      nil -> :error
      %{"h" => h, "m" => m, "s" => s} -> {:ok, to_int(h) * 3600 + to_int(m) * 60 + to_int(s)}
    end
  end

  defp to_int(""), do: 0
  defp to_int(digits), do: String.to_integer(digits)
end
