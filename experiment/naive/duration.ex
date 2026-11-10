# A plausible first guess, written without asking anything: it adds up every
# number-unit pair it finds and ignores the rest of the string.
defmodule Duration do
  @units %{"h" => 3600, "m" => 60, "s" => 1}

  def parse(string) do
    case Regex.scan(~r/(\d+)([hms])/, string) do
      [] -> :error
      parts -> {:ok, parts |> Enum.map(fn [_, n, u] -> String.to_integer(n) * @units[u] end) |> Enum.sum()}
    end
  end
end
