%% Fixed-window rate limiter, pure core: time comes in as an argument.
-module(rate_limit).
-export([check/5]).

%% check(Counts, Id, NowMs, Limit, WindowMs) -> {ok | rate_limited, NewCounts}
check(Counts, _Id, _NowMs, Limit, _WindowMs) when Limit =< 0 ->
    {rate_limited, Counts};
check(Counts, Id, NowMs, Limit, WindowMs) ->
    Start = NowMs - (NowMs rem WindowMs),
    case maps:get(Id, Counts, undefined) of
        {Start, N} when N >= Limit -> {rate_limited, Counts};
        {Start, N} -> {ok, Counts#{Id => {Start, N + 1}}};
        _ -> {ok, Counts#{Id => {Start, 1}}}
    end.
