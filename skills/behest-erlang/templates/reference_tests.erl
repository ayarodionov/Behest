%% behest-effects: none
%%
%% Contract for uniq:uniq/1, built around a REFERENCE MODEL: a slow, obviously
%% correct version that the human can read in one glance. The main property is
%% "the implementation agrees with the reference on every input".
%% Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
-module(uniq_reference_tests).
-export([cases/0]).
-include_lib("eunit/include/eunit.hrl").
%% eunit.hrl and proper.hrl both define ?LET; keep PropEr's.
-undef(LET).
-include_lib("proper/include/proper.hrl").

%% --- reference model (part of the contract) ----------------------------
%% Keep the first occurrence of each element, in the original order.
%% Quadratic on purpose: clarity matters here, speed does not.

reference([]) -> [];
reference([X | Rest]) -> [X | reference([Y || Y <- Rest, Y =/= X])].

%% --- examples ---------------------------------------------------------
%% Still needed: they are the answers to the open questions, in plain sight.

keeps_first_occurrence_test() ->
    ?assertEqual([b, a, c], uniq:uniq([b, a, b, c, a])).

empty_list_test() ->
    ?assertEqual([], uniq:uniq([])).

%% Answer to an open question: 1 and 1.0 are different elements (=:=, not ==).
integer_and_float_differ_test() ->
    ?assertEqual([1, 1.0], uniq:uniq([1, 1.0, 1])).

%% --- properties -------------------------------------------------------

agrees_with_reference_test_() ->
    prop_test(prop_agrees_with_reference()).

prop_agrees_with_reference() ->
    ?FORALL(Xs, input(), uniq:uniq(Xs) =:= reference(Xs)).

%% Few distinct values, so duplicates are likely; 1 and 1.0 are both present.
input() ->
    list(element()).

element() ->
    oneof([range(-2, 2), a, b, 1.0]).

%% --- concrete cases for the human --------------------------------------
%% Run before asking for approval and paste the output into the question:
%%
%%     erl -noshell -pa <ebin dirs> -eval "uniq_reference_tests:cases(), halt()."
%%
%% Each line is one input and the answer the contract demands for it. The human
%% approves these cases, not the generator code. Needs no implementation.

cases() ->
    lists:foreach(
      fun(Length) ->
              {ok, Xs} = proper_gen:pick(vector(Length, element())),
              io:format("uniq(~p) -> ~p~n", [Xs, reference(Xs)])
      end,
      [0, 1, 2, 4, 6, 8, 10]).

%% --- helpers ----------------------------------------------------------

prop_test(Prop) ->
    {timeout, 60,
     fun() ->
             ?assert(proper:quickcheck(Prop, [{numtests, 300}, {to_file, user}]))
     end}.
