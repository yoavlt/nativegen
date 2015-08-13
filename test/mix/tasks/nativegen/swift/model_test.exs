defmodule Nativegen.Swift.ModelTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift.Model

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

  test "generate json model" do
    assert generate_json_model(
    "User",
    ["username:string", "age:integer", "first_name:string", "last_name:string"]) === """
    public class User : JsonModel {
        let username: String
        let age: Int
        let firstName: String
        let lastName: String
        public required init(json: JSON) {
            username = json["username"].stringValue
            age = json["age"].intValue
            firstName = json["first_name"].stringValue
            lastName = json["last_name"].stringValue
        }
    }
    """
  end


end
