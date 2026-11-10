# slug: the human's answers

Give an answer only when the AI asks about that point. Do not volunteer anything.
If the AI asks something that is not listed, say "your choice".

| Id | If asked about | Answer |
| --- | --- | --- |
| accents | accented Latin letters, e.g. "Crème Brûlée" | Keep the base letter: `"creme-brulee"`. |
| collapse | several spaces or punctuation marks in a row, e.g. "rock & roll" | One hyphen for the whole run: `"rock-roll"`. |
| edges | punctuation or spaces at the start or end, e.g. "  Hello!  " | No leading or trailing hyphen: `"hello"`. |
| underscore | underscores, e.g. "snake_case name" | A separator like a space: `"snake-case-name"`. |
| empty | nothing usable left, e.g. "!!!" or "" | Return `""`. Not an error. |
| digits | digits, e.g. "Top 10 Tips" | Keep them: `"top-10-tips"`. |
| nonlatin | non-Latin letters, e.g. "Привет world" | Drop them (ASCII output only): `"world"`. |
| apostrophe | apostrophes, e.g. "Don't stop" | Remove them, they are not separators: `"dont-stop"`. |
