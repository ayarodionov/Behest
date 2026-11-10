# duration: the human's answers

Give an answer only when the AI asks about that point. Do not volunteer anything.
If the AI asks something that is not listed, say "your choice".

| Id | If asked about | Answer |
| --- | --- | --- |
| bare | a number without a unit, e.g. "90" | `:error`. A unit is required. |
| units | which units exist, e.g. "1d" or "500ms" | Only `h`, `m` and `s`. Anything else is `:error`. |
| order | units out of order, e.g. "30m1h" | `:error`. The order is h, then m, then s. |
| repeat | the same unit twice, e.g. "1h1h" | `:error`. |
| large | values above 59, e.g. "90m" or "100s" | Allowed: `{:ok, 5400}` and `{:ok, 100}`. |
| spaces | spaces, e.g. " 1h30m " or "1h 30m" | Allowed around the string and between the parts: both are `{:ok, 5400}`. |
| case | upper case, e.g. "1H30M" | Accepted: `{:ok, 5400}`. |
| empty | the empty string, and zero, e.g. "" and "0s" | `""` is `:error`; `"0s"` is `{:ok, 0}`. |
| sign | signs and fractions, e.g. "-1h" or "1.5h" | `:error` for both. |
