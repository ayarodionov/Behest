# slug2: the human's answers

Same request as `slug`, but this human wants four unusual things (marked). Give an answer when the AI asks about a point, and object when the AI states an assumption that contradicts a row. Do not volunteer anything else. If a point is not listed, say "your choice".

| Id | If asked about | Answer |
| --- | --- | --- |
| accents | accented Latin letters, e.g. "Crème Brûlée" | Keep the base letter: `"creme-brulee"`. |
| collapse | several spaces or punctuation marks in a row, e.g. "a  --  b" | One hyphen for the whole run: `"a-b"`. |
| edges | punctuation or spaces at the start or end, e.g. "  Hello!  " | No leading or trailing hyphen: `"hello"`. |
| underscore | underscores, e.g. "snake_case name" | **Unusual:** keep them: `"snake_case-name"`. |
| empty | nothing usable left, e.g. "!!!" or "" | **Unusual:** return `"untitled"`. |
| digits | digits, e.g. "Top 10 Tips" | Keep them: `"top-10-tips"`. |
| nonlatin | non-Latin letters, e.g. "Привет world" | Drop them: `"world"`. |
| apostrophe | apostrophes, e.g. "Don't stop" | Remove them, they are not separators: `"dont-stop"`. |
| ampersand | the `&` sign, e.g. "rock & roll" | **Unusual:** it becomes the word "and": `"rock-and-roll"`; `"R&D"` gives `"r-and-d"`. |
| maxlen | a length limit | **Unusual:** at most 30 characters. Cut after 30; if the cut leaves a hyphen at the end, remove it. |
