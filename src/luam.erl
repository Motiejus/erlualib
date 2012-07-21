%%% @doc LuaM, extended function calling
%%%
%%% This module is responsible for high-level function invocations in Lua.
%%%
%%% ## Erlang->Lua type conversion table
%%%     >-------->------>
%%% +------------+----------------+
%%% | Erlang     |      Lua       |
%%% +------------+----------------+
%%% | 'nil'      | nil
%%% | boolean    | boolean        |
%%% | binary     | string         |
%%% | atom       | string         |
%%% | string     | string         |
%%% | number     | number         |
%%% | proplist   | tagged table   |
%%% | tuple      | indexed table  |
%%% +------------+----------------+
%%%
%%% Whereas >--------->----->
%%% +-----------------+------------+
%%% |       Lua       |   Erlang   |
%%% +-----------------+------------+
%%% | nil             | nil        |
%%% | boolean         | boolean    |
%%% | light_user_data | --NA--     |
%%% | number          | float      |
%%% | string          | binary     |
%%% | table           | proplist   |
%%% | function        | --NA--     |
%%% | user_data       | --NA--     |
%%% | thread.         | --NA--     |
%%% +-----------------+------------+
%%%
%%% ## Table to proplist conversion rules
%%% Table key conversion rules are same like for any other data type.
%%%
%%% ## Function return value handling
%%% When function returns with one value, give it plain.
%%% When function returns more values, wrap them to tuple.

-module(luam).

-export([call/3, push_arg/2]).
-export([foreach/4]).

-type arg() :: binary() | % string
               atom()   | % string
               number() | % number
               list()   | % table
               tuple().   % table

-type ret() :: nil       |
               boolean() |
               float()   |
               binary()  |
               list({ret(), ret()}).

-spec call(lua:lua(), list(arg()), non_neg_integer()) -> tuple(ret()).
call(L, Args, N) ->
    [push_arg(L, Arg) || Arg <- Args],
    Len = length(Args),
    lua:call(L, Len, N),
    pop_results(L, N).

-spec push_arg(lua:lua(), arg()) -> ok.
push_arg(L, nil) ->
    lua:pushnil(L);
push_arg(L, Arg) when is_boolean(Arg) ->
    lua:pushboolean(L, Arg);
push_arg(L, Arg) when is_binary(Arg) ->
    lua:pushlstring(L, Arg);
push_arg(L, Arg) when is_number(Arg) ->
    lua:pushnumber(L, Arg);
push_arg(L, Args) when is_tuple(Args) ->
    lua:createtable(L, size(Args), 0),
    TPos = lua:gettop(L), % table position we have just created
    Fun = fun({I, Arg}) ->
            lua:pushnumber(L, I),
            push_arg(L, Arg),
            lua:settable(L, TPos)
    end,
    lists:foreach(Fun, lists:zip(
            lists:seq(1, size(Args)),
            tuple_to_list(Args))
    );
push_arg(L, Args) when is_list(Args) ->
    throw(not_implemented).

%% @doc Pops N results from the stack and returns result tuple
-spec pop_results(lua:lua(), pos_integer()) -> tuple().
pop_results(L, N) ->
    MapFun = fun(_) -> R = toterm(L, -1), lua:remove(L, -1), R end,
    list_to_tuple(lists:map(MapFun, lists:seq(1, N))).

%% @doc Returns Nth element on the stack (does not pop)
-spec toterm(lua:lua(), lua:index()) -> ret().
toterm(L, N) ->
    case lua:type(L, N) of
        nil -> nil;
        boolean -> lua:toboolean(L, N);
        number -> lua:tonumber(L, N);
        string -> lua:tolstring(L, N);
        table ->
            F = fun(K, V, Acc) -> [{K, V}|Acc] end,
            lists:reverse(foreach(L, N, F, []))
    end.

%% @doc Call Fun over table on index N
-spec foreach(lua:lua(), N :: lua:index(), Fun, Acc0) -> Acc1 when
      Fun :: fun((ret(), ret(), AccIn) -> AccOut),
      Acc0 :: term(),
      Acc1 :: term(),
      AccIn :: term(),
      AccOut :: term().
foreach(L, N, Fun, Acc0) ->
    lua:pushnil(L),
    foreach(L, N, Fun, Acc0, lua:next(L, N)).

foreach(_L, _N, _Fun, Acc, 0) -> Acc;
foreach( L,  N,  Fun, Acc, _) ->
    V = toterm(L, -1), lua:remove(L, -1),
    K = toterm(L, -1),
    Acc2 = Fun(K, V, Acc),
    foreach(L, N, Fun, Acc2, lua:next(L, N)).
