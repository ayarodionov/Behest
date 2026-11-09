%% Thin wrapper: the only place that reads the clock.
-module(rate_limit_clock).
-export([check/4]).

check(Counts, Id, Limit, WindowMs) ->
    rate_limit:check(Counts, Id, erlang:monotonic_time(millisecond), Limit, WindowMs).
