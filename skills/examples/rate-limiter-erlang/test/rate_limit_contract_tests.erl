%% behest-effects: none
%%
%% Contract for rate_limit:check/5, a fixed-window limiter.
%% Pure: the current time is an argument, so every example is deterministic.
%% Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
-module(rate_limit_contract_tests).
-include_lib("eunit/include/eunit.hrl").
%% eunit.hrl and proper.hrl both define ?LET; keep PropEr's.
-undef(LET).
-include_lib("proper/include/proper.hrl").

%% limit 3 per 1000 ms window; each call is {ClientId, TimeMs}

fourth_call_in_a_window_is_rejected_test() ->
    ?assertEqual([ok, ok, ok, rate_limited],
                 replay([{a, 0}, {a, 0}, {a, 0}, {a, 10}], 3, 1000)).

clients_are_independent_test() ->
    ?assertEqual([ok, ok, ok, ok],
                 replay([{a, 0}, {a, 0}, {a, 0}, {b, 10}], 3, 1000)).

a_new_window_resets_the_count_test() ->
    ?assertEqual([ok, ok, ok, ok],
                 replay([{a, 0}, {a, 0}, {a, 0}, {a, 1000}], 3, 1000)).

rejected_calls_do_not_count_test() ->
    %% 3 accepted, 2 rejected in window 0; the next window starts fresh at 1000
    ?assertEqual([ok, ok, ok, rate_limited, rate_limited, ok],
                 replay([{a, 0}, {a, 1}, {a, 2}, {a, 3}, {a, 4}, {a, 1000}], 3, 1000)).

never_more_than_limit_per_window_test_() ->
    prop_test(prop_limit()).

prop_limit() ->
    ?FORALL(Steps, list({oneof([a, b, c]), pos_integer()}),
            begin
                Calls = with_times(Steps),
                Results = replay(Calls, 3, 100),
                Accepted = lists:foldl(
                             fun({{Id, T}, ok}, Acc) ->
                                     maps:update_with({Id, T div 100}, fun(N) -> N + 1 end, 1, Acc);
                                (_, Acc) -> Acc
                             end, #{}, lists:zip(Calls, Results)),
                lists:all(fun(N) -> N =< 3 end, maps:values(Accepted))
            end).

%% --- helpers ----------------------------------------------------------

replay(Calls, Limit, WindowMs) ->
    {Results, _} =
        lists:mapfoldl(fun({Id, T}, Counts) ->
                               rate_limit:check(Counts, Id, T, Limit, WindowMs)
                       end, #{}, Calls),
    Results.

with_times(Steps) ->
    {Calls, _} =
        lists:mapfoldl(fun({Id, Dt}, T) ->
                               T1 = T + Dt - 1,
                               {{Id, T1}, T1}
                       end, 0, Steps),
    Calls.

prop_test(Prop) ->
    {timeout, 60,
     fun() ->
             ?assert(proper:quickcheck(Prop, [{numtests, 100}, {to_file, user}]))
     end}.
