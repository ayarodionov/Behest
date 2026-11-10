# duration2: the human's answers

Same request as `duration`, but this human wants four unusual things (marked). Give an answer when the AI asks about a point, and object when the AI states an assumption that contradicts a row. Do not volunteer anything else. If a point is not listed, say "your choice".

| Id | If asked about | Answer |
| --- | --- | --- |
| bare | a number without a unit, e.g. "90" | **Unusual:** it means minutes: `"90"` is `{:ok, 5400}`, `"15"` is `{:ok, 900}`. |
| units | which units exist, e.g. "1d", "1w", "500ms" | **Unusual:** `d` (a day, 86400 seconds) exists and comes before `h`: `"1d"` is `{:ok, 86400}`, `"1d2h"` is `{:ok, 93600}`. `w` and `ms` do not: `:error`. |
| order | units out of order, e.g. "30m1h" | `:error`. The order is d, h, m, s. |
| repeat | the same unit twice, e.g. "1h1h" | `:error`. |
| large | values above 59, e.g. "90m" or "100s" | Allowed: `{:ok, 5400}` and `{:ok, 100}`. |
| spaces | spaces, e.g. " 1h30m " or "1h 30m" | Allowed around the string and between the parts: both are `{:ok, 5400}`. |
| case | upper case, e.g. "1H30M" | Accepted: `{:ok, 5400}`. |
| empty | the empty string | **Unusual:** `""` is `{:ok, 0}`, not an error. `"0s"` is `{:ok, 0}` too. |
| fraction | fractions, e.g. "1.5h" | **Unusual:** accepted when the result is a whole number of seconds: `"1.5h"` is `{:ok, 5400}`, `"0.5m"` is `{:ok, 30}`. |
| sign | signs, e.g. "-1h" | `:error`. |
