-module(median).
-export([median/1]).

median([]) ->
    {error, empty};
median(Xs) ->
    S = lists:sort(Xs),
    N = length(S),
    Mid = N div 2,
    case N rem 2 of
        1 -> {ok, float(lists:nth(Mid + 1, S))};
        0 -> {ok, (lists:nth(Mid, S) + lists:nth(Mid + 1, S)) / 2}
    end.
