# intervals2: the human's answers

Same request as `intervals`, but this human wants three unusual things (marked). Give an answer when the AI asks about a point, and object when the AI states an assumption that contradicts a row. Do not volunteer anything else. If a point is not listed, say "your choice".

| Id | If asked about | Answer |
| --- | --- | --- |
| touching | intervals that share an endpoint, e.g. `[{1, 2}, {2, 3}]` | They merge: `[{1, 3}]`. |
| adjacent | intervals next to each other with no shared point, e.g. `[{1, 2}, {3, 4}]` | **Unusual:** they merge, because no integer lies between them: `[{1, 4}]`. `[{1, 2}, {4, 5}]` stays as it is. |
| order | the order of the result when the input is not sorted, e.g. `[{5, 6}, {1, 2}]` | Sorted by start: `[{1, 2}, {5, 6}]`. |
| reversed | an interval whose start is after its end, e.g. `{3, 1}` | **Unusual:** treat it as `{1, 3}`. Do not raise. |
| empty | an empty list | Return `[]`. |
| point | a zero-length interval, e.g. `{2, 2}` | **Unusual:** drop it before merging: `[{2, 2}]` gives `[]`, and `[{2, 2}, {5, 6}]` gives `[{5, 6}]`. |
