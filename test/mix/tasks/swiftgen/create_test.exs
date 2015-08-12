defmodule Swiftgen.CreateTest do
  use ExUnit.Case

  import Mix.Tasks.Swiftgen.Create

  @valid_params ["id:integer", "username:string", "age:integer", "group:Group", "items:array:Item"]

  test "build json params" do
    params = Mix.Swiftgen.swift_var_type(@valid_params)
    assert build_json_params(params) <> "\n" == ~S"""
    let id: Int
    let username: String
    let age: Int
    let group: Group
    let items: [Item]
    """
  end

  test "default args" do
    params = Mix.Swiftgen.swift_var_type(@valid_params)
    args = default_args(params)
    assert args == "id: Int, username: String, age: Int, group: Group, items: [Item]"
  end

  test "build create args" do
    params = Mix.Swiftgen.swift_var_type(@valid_params)
    args = build_create_args(params)
    assert args == "username: String, age: Int, group: Group, items: [Item]"
  end

  test "build update args" do
    params = Mix.Swiftgen.swift_var_type(@valid_params)
    args = build_update_args(params)
    assert args == "id: Int, username: String, age: Int, group: Group, items: [Item]"
  end

  test "build json parser" do
    params = Mix.Swiftgen.parse_params(@valid_params)
    parser = build_json_parser(params)
    assert parser <> "\n" == ~S"""
    id = json["id"].intValue
    username = json["username"].stringValue
    age = json["age"].intValue
    group = Group(json: json["group"]!)
    items = json["items"].arrayValue.map { Item(json: $0) }
    """
  end

end
