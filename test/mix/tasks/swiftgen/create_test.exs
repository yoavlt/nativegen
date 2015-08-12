defmodule Swiftgen.CreateTest do
  use ExUnit.Case

  import Mix.Tasks.Swiftgen.Create

  @valid_params ["id:integer", "username:string", "age:integer", "group:Group", "items:array:Item"]

  test "build json params" do
    params = Mix.Swiftgen.parse_params(@valid_params)
    assert build_json_params(params) <> "\n" == ~S"""
        let id: Int
        let username: String
        let age: Int
        var groupId: Int
        var group: Group
        var items: [Item]
    """
  end

  test "default args" do
    params = Mix.Swiftgen.parse_params(@valid_params)
    args = default_args(params)
    assert args == "id: Int, username: String, age: Int, groupId: Int, items: [Item]"
  end

  test "build create args" do
    params = Mix.Swiftgen.parse_params(@valid_params)
    args = build_create_args(params)
    assert args == "username: String, age: Int, groupId: Int"
  end

  test "build update args" do
    params = Mix.Swiftgen.parse_params(@valid_params)
    args = build_update_args(params)
    assert args == "id: Int, username: String, age: Int, groupId: Int, items: [Item]"
  end

  test "build json parser" do
    params = Mix.Swiftgen.parse_params(@valid_params)
    parser = build_json_parser(params)
    assert parser <> "\n" == ~S"""
            id = json["id"].intValue
            username = json["username"].stringValue
            age = json["age"].intValue
            if let groupIdJson = json["group_id"] {
                group_id = json["group_id"].intValue
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
    params = Mix.Swiftgen.parse_params(@valid_params)
    params = generate_params(params)
    assert params == "username: username, age: age, group_id: groupId"
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
