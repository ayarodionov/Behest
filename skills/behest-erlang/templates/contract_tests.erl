%% behest-effects: none
%%
%% Contract for median:median/1.
%% Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
-module(median_contract_tests).
-include_lib("eunit/include/eunit.hrl").
%% eunit.hrl and proper.hrl both define ?LET; keep PropEr's.
-undef(LET).
-include_lib("proper/include/proper.hrl").

%% --- examples ---------------------------------------------------------

odd_length_test() ->
    ?assertEqual({ok, 2.0}, median:median([3.0, 1.0, 2.0])).

even_length_test() ->
    ?assertEqual({ok, 2.5}, median:median([4.0, 1.0, 3.0, 2.0])).

empty_list_test() ->
    ?assertEqual({error, empty}, median:median([])).

%% --- properties -------------------------------------------------------

order_does_not_matter_test_() ->
    prop_test(prop_order()).

between_min_and_max_test_() ->
    prop_test(prop_bounds()).

prop_order() ->
    ?FORALL(Xs, list(float()),
            median:median(Xs) =:= median:median(shuffle(Xs))).

prop_bounds() ->
    ?FORALL(Xs, non_empty(list(integer())),
            begin
                {ok, M} = median:median(Xs),
                lists:min(Xs) =< M andalso M =< lists:max(Xs)
            end).

%% --- helpers ----------------------------------------------------------

prop_test(Prop) ->
    {timeout, 60,
     fun() ->
             ?assert(proper:quickcheck(Prop, [{numtests, 100}, {to_file, user}]))
     end}.

shuffle(L) ->
    [X || {_, X} <- lists:sort([{rand:uniform(), E} || E <- L])].
