%% behest-effects: time
%%
%% Contract for rate_limit_clock:check/4, the thin wrapper that reads the clock.
%% It may read the time and nothing else; all the logic lives in rate_limit,
%% whose contract declares no effects.
%% Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
-module(rate_limit_clock_contract_tests).
-include_lib("eunit/include/eunit.hrl").

first_call_is_accepted_test() ->
    ?assertMatch({ok, _}, rate_limit_clock:check(#{}, a, 3, 1000)).

limit_zero_rejects_everything_test() ->
    %% A real clock cannot be pinned to a value, but a limit of 0 must reject
    %% regardless of what time it is.
    ?assertMatch({rate_limited, _}, rate_limit_clock:check(#{}, a, 0, 1000)).
