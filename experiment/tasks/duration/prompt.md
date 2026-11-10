Write an Elixir module `Duration` with a function `parse/1` that parses strings like `"1h30m"` into a number of seconds. It returns `{:ok, seconds}`, or `:error` when the string is not a valid duration.

For example, `Duration.parse("1h30m")` returns `{:ok, 5400}`.
