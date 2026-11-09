%% behest-effects: none
%%
%% Contract for median:median/1.
%% Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
-module(median_contract_tests).
-include_lib("eunit/include/eunit.hrl").
%% eunit.hrl and proper.hrl both define ?LET; keep PropEr's.
-undef(LET).
-include_lib("proper/include/proper.hrl").

odd_length_test() ->
    ?assertEqual({ok, 2.0}, median:median([3.0, 1.0, 2.0])).

empty_list_test() ->
    ?assertEqual({error, empty}, median:median([])).

integers_give_a_float_test() ->
    ?assertEqual({ok, 2.0}, median:median([1, 2, 3])).

even_length_is_the_mean_test() ->
    ?assertEqual({ok, 1.5}, median:median([1, 2])).

order_does_not_matter_test_() ->
    prop_test(prop_order()).

between_min_and_max_test_() ->
    prop_test(prop_bounds()).

result_is_always_a_float_test_() ->
    prop_test(prop_float()).

prop_order() ->
    ?FORALL(Xs, list(float()),
            median:median(Xs) =:= median:median(shuffle(Xs))).

prop_bounds() ->
    ?FORALL(Xs, non_empty(list(integer())),
            begin
                {ok, M} = median:median(Xs),
                lists:min(Xs) =< M andalso M =< lists:max(Xs)
            end).

prop_float() ->
    ?FORALL(Xs, non_empty(list(integer())),
            begin
                {ok, M} = median:median(Xs),
                is_float(M)
            end).

prop_test(Prop) ->
    {timeout, 60,
     fun() ->
             ?assert(proper:quickcheck(Prop, [{numtests, 100}, {to_file, user}]))
     end}.

shuffle(L) ->
    [X || {_, X} <- lists:sort([{rand:uniform(), E} || E <- L])].
