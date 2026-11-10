%% A key-value cache whose entries expire. The clock is passed in at start, so the
%% server never reads the time itself and its behaviour can be tested exactly.
-module(ttl_cache).
-behaviour(gen_server).

-export([start_link/2, stop/1, put/4, get/2, delete/2, size/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

%% Clock is a fun() -> integer milliseconds.
start_link(Name, Clock) when is_atom(Name), is_function(Clock, 0) ->
    gen_server:start_link({local, Name}, ?MODULE, Clock, []).

stop(Cache) -> gen_server:stop(Cache).

put(Cache, Key, Value, TtlMs) -> gen_server:call(Cache, {put, Key, Value, TtlMs}).
get(Cache, Key) -> gen_server:call(Cache, {get, Key}).
delete(Cache, Key) -> gen_server:call(Cache, {delete, Key}).
size(Cache) -> gen_server:call(Cache, size).

%% --- callbacks ---------------------------------------------------------

init(Clock) -> {ok, #{clock => Clock, entries => #{}}}.

handle_call({put, Key, Value, Ttl}, _From, State = #{clock := Clock, entries := Entries})
  when is_integer(Ttl), Ttl >= 1 ->
    Expires = Clock() + Ttl,
    {reply, ok, State#{entries := Entries#{Key => {Value, Expires}}}};
handle_call({put, _Key, _Value, _Ttl}, _From, State) ->
    {reply, {error, bad_ttl}, State};
handle_call({get, Key}, _From, State) ->
    Live = live(State),
    Reply = case Live of
                #{Key := {Value, _}} -> {ok, Value};
                _ -> not_found
            end,
    {reply, Reply, State#{entries := Live}};
handle_call({delete, Key}, _From, State = #{entries := Entries}) ->
    {reply, ok, State#{entries := maps:remove(Key, Entries)}};
handle_call(size, _From, State) ->
    Live = live(State),
    {reply, maps:size(Live), State#{entries := Live}}.

handle_cast(_Msg, State) -> {noreply, State}.

%% Stray messages are ignored; the cache keeps its entries.
handle_info(_Msg, State) -> {noreply, State}.

%% Entries that have not expired at the current time.
live(#{clock := Clock, entries := Entries}) ->
    Now = Clock(),
    maps:filter(fun(_Key, {_Value, Expires}) -> Now < Expires end, Entries).
