-module(lua_test).

-include_lib("eunit/include/eunit.hrl").

small_integer_test() -> push_to_helper(1, pushinteger, tointeger).
zero_integer_test() -> push_to_helper(0, pushinteger, tointeger).
small_negative_integer_test() -> push_to_helper(-2, pushinteger, tointeger).
small_number_test() -> push_to_helper(2, pushnumber, tonumber).
small_negative_number_test() -> push_to_helper(-2, pushnumber, tonumber).
zero_number_test() -> push_to_helper(0, pushnumber, tonumber).
big_number_test() -> push_to_helper(5000000000, pushnumber, tonumber).
big_float_number_test() -> push_to_helper(5000000000.234, pushnumber, tonumber).
big_neg_number_test() -> push_to_helper(-5000000000, pushnumber, tonumber).
big_neg_float_test() -> push_to_helper(-5000000000.234, pushnumber, tonumber).
string_test() -> push_to_helper("testing", pushstring, tolstring).
bool_test() -> push_to_helper(false, pushboolean, toboolean).

nil_type_test() -> type_test_helper(pushnil, nil).
boolean_type_test() -> type_test_helper(true, pushboolean, boolean).
num_type_test() -> type_test_helper(1, pushinteger, number).
string_type_test() -> type_test_helper("labas", pushstring, string).

call_test() ->
    {ok, L} = lua:new_state(),
    ?assertEqual(ok, lua:getfield(L, global, "type")),
    ?assertEqual(function, lua:type(L, 1)),
    ?assertEqual(ok, lua:pushnumber(L, 1)),
    ?assertEqual(ok, lua:call(L, 1, 1)),
    ?assertEqual({ok, "number"}, lua:tolstring(L, 1)),
    lua:close(L).
    
set_get_global_test() ->
    {ok, L} = lua:new_state(),
    ?assertMatch(ok, lua:pushnumber(L, 23)),
    ?assertMatch(ok, lua:setfield(L, global, "foo")),
    ?assertMatch(ok, lua:getfield(L, global, "foo")),
    ?assertMatch({ok, 23}, lua:tonumber(L, 1)),
    lua:close(L).

%% =============================================================================
%% Helpers
%% =============================================================================

push_to_helper(Val, Push, To) ->
    {ok, L} = lua:new_state(),
    ?assertMatch(ok, lua:Push(L, Val)),
    ?assertMatch({ok, Val}, lua:To(L, 1)),
    lua:close(L).

type_test_helper(PushFun, Type) ->
    {ok, L} = lua:new_state(),
    ?assertEqual(ok, lua:PushFun(L)),
    ?assertEqual(Type, lua:type(L, 1)),
    lua:close(L).

type_test_helper(Value, PushFun, Type) ->
    {ok, L} = lua:new_state(),
    ?assertEqual(ok, lua:PushFun(L, Value)),
    ?assertEqual(Type, lua:type(L, 1)),
    lua:close(L).
