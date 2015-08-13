defmodule Nativegen.CreateTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Create

  @valid_params ["id:integer", "username:string", "age:integer", "battle_num:integer", "group:Group", "items:array:Item"]

  test "build json params" do
    params = Mix.Nativegen.parse_params(@valid_params)
    assert build_json_params(params) <> "\n" == ~S"""
        let id: Int
        let username: String
        let age: Int
        let battleNum: Int
        var groupId: Int
        var group: Group
        var items: [Item]
    """
  end

  test "default args" do
    params = Mix.Nativegen.parse_params(@valid_params)
    args = default_args(params)
    assert args == "id: Int, username: String, age: Int, battleNum: Int, groupId: Int, items: [Item]"
  end

  test "build create args" do
    params = Mix.Nativegen.parse_params(@valid_params)
    args = build_create_args(params)
    assert args == "username: String, age: Int, battleNum: Int, groupId: Int"
  end

  test "build update args" do
    params = Mix.Nativegen.parse_params(@valid_params)
    args = build_update_args(params)
    assert args == "id: Int, username: String, age: Int, battleNum: Int, groupId: Int, items: [Item]"
  end

  test "build json parser" do
    params = Mix.Nativegen.parse_params(@valid_params)
    parser = build_json_parser(params)
    assert parser <> "\n" == ~S"""
            id = json["id"].intValue
            username = json["username"].stringValue
            age = json["age"].intValue
            battleNum = json["battle_num"].intValue
            if let groupIdJson = json["group_id"] {
                groupId = groupIdJson.intValue
            }
            if let groupJson = json["group"] {
                group = Group(json: groupJson)
            }
            if let itemsJson = json["items"] {
                items = itemsJson.arrayValue.map { Item(json: $0) }
            }
    """
  end

  test "generate params" do
    params = Mix.Nativegen.parse_params(@valid_params)
    params = generate_params(params)
    assert params == "username: username, age: age, battle_num: battleNum, group_id: groupId"
  end

  test "run" do
    if File.exists?("test_generate_directory") do
      File.rm_rf("test_generate_directory")
    end
    run(["test_generate_directory/test", "User", "users", @valid_params])
    assert File.exists?("test_generate_directory/test/UserRepository.swift")
    File.rm_rf("test_generate_directory")
  end

end
