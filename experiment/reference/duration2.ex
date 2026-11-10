defmodule Duration do
  @num "\\d+(?:\\.\\d+)?"
  @pattern Regex.compile!(
             "^(?:(?<d>#{@num})d)?\\s*(?:(?<h>#{@num})h)?\\s*(?:(?<m>#{@num})m)?\\s*(?:(?<s>#{@num})s)?$"
           )

  def parse(string) when is_binary(string) do
    trimmed = string |> String.trim() |> String.downcase()

    cond do
      trimmed == "" -> {:ok, 0}
      Regex.match?(~r/^\d+$/, trimmed) -> {:ok, String.to_integer(trimmed) * 60}
      true -> parse_parts(Regex.named_captures(@pattern, trimmed))
    end
  end

  defp parse_parts(nil), do: :error

  defp parse_parts(%{"d" => d, "h" => h, "m" => m, "s" => s}) do
    total = num(d) * 86_400 + num(h) * 3600 + num(m) * 60 + num(s)
    if total == Float.round(total), do: {:ok, round(total)}, else: :error
  end

  defp num(""), do: 0.0

  defp num(text) do
    {value, ""} = Float.parse(text)
    value
  end
end
