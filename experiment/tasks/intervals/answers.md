# intervals: the human's answers

Give an answer only when the AI asks about that point. Do not volunteer anything.
If the AI asks something that is not listed, say "your choice".

| Id | If asked about | Answer |
| --- | --- | --- |
| touching | intervals that share an endpoint, e.g. `[{1, 2}, {2, 3}]` | They merge: `[{1, 3}]`. |
| adjacent | intervals that are next to each other but share no point, e.g. `[{1, 2}, {3, 4}]` | They do not merge: `[{1, 2}, {3, 4}]`. |
| order | the order of the result when the input is not sorted, e.g. `[{5, 6}, {1, 2}]` | Sorted by start: `[{1, 2}, {5, 6}]`. |
| reversed | an interval whose start is after its end, e.g. `{3, 1}` | Raise `ArgumentError`. Do not swap or drop it. |
| empty | an empty list | Return `[]`. |
| point | a zero-length interval, e.g. `{2, 2}` | Valid. `[{2, 2}]` stays `[{2, 2}]`; inside `{1, 3}` it is absorbed. |
