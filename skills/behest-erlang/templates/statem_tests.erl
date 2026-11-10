%% behest-effects: send, spawn
%%
%% Contract for ttl_cache, a gen_server. A STATEFUL contract: the property runs
%% random sequences of commands against the real process and against a small
%% model, and every reply must match the model's.
%%
%% Time is not an effect here. The clock is a fun given to start_link/2, so the
%% contract moves time itself and nothing ever sleeps. The effects line allows
%% messages and processes only: an implementation that reads the real clock, or
%% starts a timer, fails the effect scan.
%% Human-approved. Do not edit once approved; if it seems wrong, stop and ask.
%%
%% Template: this is the contract of skills/examples/ttl-cache-erlang, which runs.
%% Replace ttl_cache, the model and the commands with your own.
-module(statem_tests).   %% rename to <module>_contract_tests
-export([cases/0]).
%% proper_statem callbacks and the command the model uses to move time
-export([initial_state/0, command/1, precondition/2, postcondition/3, next_state/3, advance/1]).
-include_lib("eunit/include/eunit.hrl").
%% eunit.hrl and proper.hrl both define ?LET; keep PropEr's.
-undef(LET).
-include_lib("proper/include/proper.hrl").

-define(CACHE, ttl_cache_under_test).

%% --- the model (part of the contract) -----------------------------------
%% State: the current time and, for each key, its value and the time it expires.
%% An entry is visible while Now < Expires.

model({put, _K, _V, Ttl}, S) when not is_integer(Ttl); Ttl < 1 ->
    {{error, bad_ttl}, S};
model({put, K, V, Ttl}, S = #{now := Now, entries := E}) ->
    {ok, S#{entries := E#{K => {V, Now + Ttl}}}};
model({get, K}, S = #{now := Now, entries := E}) ->
    case E of
        #{K := {V, Expires}} when Now < Expires -> {{ok, V}, S};
        _ -> {not_found, S}
    end;
model({delete, K}, S = #{entries := E}) ->
    {ok, S#{entries := maps:remove(K, E)}};
model(size, S = #{now := Now, entries := E}) ->
    {maps:size(maps:filter(fun(_, {_, Expires}) -> Now < Expires end, E)), S};
model({advance, Ms}, S = #{now := Now}) ->
    {ok, S#{now := Now + Ms}}.

%% --- examples: each is a script, in order --------------------------------
%% Written as {Command, ExpectedReply}. They are the answers to the open
%% questions, in plain sight.

put_then_get_test() ->
    script([{{put, a, 1, 10}, ok}, {{get, a}, {ok, 1}}, {{get, b}, not_found}]).

%% Answer: an entry with TTL 10 put at time 0 is still there at 9 and gone at 10.
expires_exactly_at_its_ttl_test() ->
    script([{{put, a, 1, 10}, ok},
            {{advance, 9}, ok}, {{get, a}, {ok, 1}},
            {{advance, 1}, ok}, {{get, a}, not_found}]).

%% Answer: putting an existing key replaces the value and restarts its TTL.
put_again_restarts_the_ttl_test() ->
    script([{{put, a, 1, 10}, ok}, {{advance, 8}, ok},
            {{put, a, 2, 10}, ok}, {{advance, 8}, ok},
            {{get, a}, {ok, 2}}]).

%% Answer: reading does not extend the life of an entry.
get_does_not_extend_the_ttl_test() ->
    script([{{put, a, 1, 10}, ok}, {{advance, 5}, ok}, {{get, a}, {ok, 1}},
            {{advance, 5}, ok}, {{get, a}, not_found}]).

%% Answer: size counts only entries that have not expired.
size_counts_live_entries_only_test() ->
    script([{{put, a, 1, 5}, ok}, {{put, b, 2, 10}, ok}, {size, 2},
            {{advance, 5}, ok}, {size, 1},
            {{advance, 5}, ok}, {size, 0}]).

%% Answer: deleting a key that is not there is fine.
delete_test() ->
    script([{{put, a, 1, 10}, ok}, {{delete, a}, ok}, {{get, a}, not_found},
            {{delete, a}, ok}]).

%% Answer: a TTL below 1 is refused, and nothing is stored.
bad_ttl_is_refused_test() ->
    script([{{put, a, 1, 0}, {error, bad_ttl}}, {{put, a, 1, -3}, {error, bad_ttl}},
            {{get, a}, not_found}, {size, 0}]).

%% Answer: a stray message does not crash the cache or lose entries.
stray_messages_are_ignored_test() ->
    with_cache(fun() ->
        ok = ttl_cache:put(?CACHE, a, 1, 10),
        whereis(?CACHE) ! {some, garbage},
        ?assertEqual({ok, 1}, ttl_cache:get(?CACHE, a))
    end).

%% --- the property --------------------------------------------------------

replies_always_match_the_model_test_() ->
    {timeout, 120,
     fun() ->
             ?assert(proper:quickcheck(prop_matches_model(), [{numtests, 300}, {to_file, user}]))
     end}.

prop_matches_model() ->
    ?FORALL(Cmds, commands(?MODULE),
            begin
                Outcome = with_cache(fun() -> run_commands(?MODULE, Cmds) end),
                {History, _State, Result} = Outcome,
                ?WHENFAIL(io:format("commands: ~p~nhistory: ~p~nresult: ~p~n",
                                    [Cmds, History, Result]),
                          Result =:= ok)
            end).

%% proper_statem callbacks. The model state is the same map model/2 uses.

initial_state() -> #{now => 0, entries => #{}}.

%% Few keys and short TTLs, so entries collide and expire often.
command(_S) ->
    frequency([{4, {call, ttl_cache, put, [?CACHE, key(), value(), ttl()]}},
               {4, {call, ttl_cache, get, [?CACHE, key()]}},
               {1, {call, ttl_cache, delete, [?CACHE, key()]}},
               {2, {call, ttl_cache, size, [?CACHE]}},
               {3, {call, ?MODULE, advance, [range(1, 4)]}}]).

key() -> oneof([a, b, c]).
value() -> range(1, 9).
ttl() -> frequency([{8, range(1, 6)}, {1, oneof([0, -1])}]).

precondition(_S, _Call) -> true.

next_state(S, _Reply, Call) ->
    {_Expected, S1} = model(to_model(Call), S),
    S1.

postcondition(S, Call, Reply) ->
    {Expected, _} = model(to_model(Call), S),
    Reply =:= Expected.

to_model({call, ttl_cache, put, [_, K, V, Ttl]}) -> {put, K, V, Ttl};
to_model({call, ttl_cache, get, [_, K]}) -> {get, K};
to_model({call, ttl_cache, delete, [_, K]}) -> {delete, K};
to_model({call, ttl_cache, size, [_]}) -> size;
to_model({call, ?MODULE, advance, [Ms]}) -> {advance, Ms}.

%% --- concrete cases for the human ----------------------------------------
%% Run before asking for approval and paste the output into the question:
%%
%%     erl -noshell -pa <ebin dirs> -eval "statem_tests:cases(), halt()."
%%
%% Each block is one generated command sequence with the reply the model demands
%% for every step. Needs no implementation.

cases() ->
    %% Random sequences are mostly dull, so generate many and show the three in
    %% which the most happens (hits, expiries, refusals).
    Scored = [begin
                  {ok, Cmds} = proper_gen:pick(commands(?MODULE), 14),
                  Steps = replay_on_model(Cmds),
                  {interest(Steps), Steps}
              end || _ <- lists:seq(1, 200)],
    Best = lists:sublist(lists:reverse(lists:keysort(1, Scored)), 3),
    lists:foreach(
      fun({_Score, Steps}) ->
              io:format("--- sequence~n"),
              [io:format("  t=~p  ~p -> ~p~n", [Now, Step, Expected])
               || {Now, Step, Expected} <- Steps]
      end, Best).

replay_on_model(Cmds) ->
    {Steps, _} =
        lists:mapfoldl(
          fun({set, _Var, Call}, S) ->
                  Step = to_model(Call),
                  {Expected, S1} = model(Step, S),
                  {{maps:get(now, S), Step, Expected}, S1}
          end, initial_state(), Cmds),
    Steps.

%% Hits, a miss on a key that was put earlier (an expiry or a delete), refusals.
interest(Steps) ->
    Put = [K || {_, {put, K, _, _}, ok} <- Steps],
    length([hit || {_, {get, _}, {ok, _}} <- Steps])
        + 2 * length([gone || {_, {get, K}, not_found} <- Steps, lists:member(K, Put)])
        + length([refused || {_, _, {error, _}} <- Steps])
        + length([n || {_, size, N} <- Steps, N > 0]).

%% --- helpers: a controllable clock and a fresh cache per run ---------------

%% Time lives in a counter the test owns; the cache gets a fun that reads it.
advance(Ms) ->
    counters:add(persistent_term:get({?MODULE, clock}), 1, Ms),
    ok.

with_cache(Fun) ->
    Clock = counters:new(1, []),
    persistent_term:put({?MODULE, clock}, Clock),
    {ok, Pid} = ttl_cache:start_link(?CACHE, fun() -> counters:get(Clock, 1) end),
    try Fun()
    after
        unlink(Pid),
        ttl_cache:stop(Pid)
    end.

%% Runs a list of {Command, ExpectedReply} against a fresh cache, and checks each
%% expected reply against the model too, so an example cannot contradict it.
script(Steps) ->
    with_cache(fun() ->
        lists:foldl(
          fun({Step, Expected}, S) ->
                  {FromModel, S1} = model(Step, S),
                  ?assertEqual({Step, Expected}, {Step, FromModel}),
                  ?assertEqual({Step, Expected}, {Step, do(Step)}),
                  S1
          end, initial_state(), Steps)
    end).

do({put, K, V, Ttl}) -> ttl_cache:put(?CACHE, K, V, Ttl);
do({get, K}) -> ttl_cache:get(?CACHE, K);
do({delete, K}) -> ttl_cache:delete(?CACHE, K);
do(size) -> ttl_cache:size(?CACHE);
do({advance, Ms}) -> advance(Ms).
