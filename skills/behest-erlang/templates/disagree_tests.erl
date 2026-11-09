%% Disagreement check. Throwaway: do not commit.
%%
%% median is the real implementation; alt_median is a deliberately different
%% one (other algorithm, or the other plausible reading of the request) that
%% ALSO passes the approved contract. Where they disagree, the contract is
%% missing an example: show both answers to the human.
%%
%% Note: PropEr shrinks to the SIMPLEST disagreeing input, which may point at a
%% different gap than the one you expected. For example [0,0] can show that one
%% implementation returns 0.0 and the other 0 (=:= tells them apart), a
%% result-type question, not an algorithm question. That is a missing example too.
-module(disagree_tests).
-include_lib("eunit/include/eunit.hrl").
%% eunit.hrl and proper.hrl both define ?LET; keep PropEr's.
-undef(LET).
-include_lib("proper/include/proper.hrl").

agree_test_() ->
    {timeout, 120,
     fun() ->
             ?assert(proper:quickcheck(prop_agree(),
                                       [{numtests, 1000}, {to_file, user}]))
     end}.

prop_agree() ->
    ?FORALL(Xs, list(integer()),
            median:median(Xs) =:= alt_median:median(Xs)).
