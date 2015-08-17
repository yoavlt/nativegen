defmodule Nativegen.SwiftTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift
  @valid_params ["id:integer", "username:string", "age:integer", "battle_num:integer", "group:Group", "items:array:Item"]

  test "parse params to variable and Swift type" do
    params = swift_var_type(["username:string", "age:integer", "group:Group", "items:array:Item"])
    assert Enum.fetch!(params, 0) == {"username", "String"}
    assert Enum.fetch!(params, 1) == {"age", "Int"}
    assert Enum.fetch!(params, 2) == {"group", "Group"}
    assert Enum.fetch!(params, 3) == {"items", "[Item]"}
  end

  test "generate params" do
    params = Mix.Nativegen.parse_params(@valid_params)
    params = generate_params(params)
    assert params == "\"username\": username, \"age\": age, \"battle_num\": battleNum, \"group_id\": groupId"
  end

  test "default args" do
    params = Mix.Nativegen.parse_params(@valid_params)
    args = default_args(params)
    assert args == "id: Int, username: String, age: Int, battleNum: Int, groupId: Int, items: [Item]"
  end

end
