defmodule Nativegen.Swift.ModelTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift.Model

  @valid_params ["id:integer", "username:string", "age:integer", "battle_num:integer", "group:Group", "items:array:Item"]

  test "build json params" do
    params = Mix.Nativegen.parse_params(@valid_params)
    assert build_json_params(params) <> "\n" == ~S"""
        var id: Int?
        let username: String
        let age: Int
        let battleNum: Int
        var groupId: Int?
        var group: Group?
        var items: [Item]?
    """
  end

  test "build json parser" do
    params = Mix.Nativegen.parse_params(@valid_params)
    parser = build_json_parser(params)
    assert parser <> "\n" == ~S"""
            id = json["id"].int
            username = json["username"].stringValue
            age = json["age"].intValue
            battleNum = json["battle_num"].intValue
            if json["group_id"].error == nil {
                groupId = json["group_id"].int
            }
            if json["group"].error == nil {
                group = Group(json: json["group"])
            }
            if json["items"].error == nil {
                items = json["items"].arrayValue.map { Item(json: $0) }
            }
    """
  end

  test "generate json model" do
    assert generate_json_model(
    "User",
    ["username:string", "age:integer", "first_name:string", "last_name:string"]) === """
    public class User : NSObject, JsonModel {
        var id: Int?
        let username: String
        let age: Int
        let firstName: String
        let lastName: String
        public required init(json: JSON) {
            id = json["id"].int
            username = json["username"].stringValue
            age = json["age"].intValue
            firstName = json["first_name"].stringValue
            lastName = json["last_name"].stringValue
        }
    }
    """
  end

  test "append model content" do
    alias Mix.Tasks.Nativegen.Swift.Create
    Create.run(["test_generate_directory/test", "User", "users", "username:string"])
    content = generate_json_model("Item", ["name:string", "strength:float"])
    file_name = "test_generate_directory/test/UserRepository.swift"
    append_file(content, file_name)
    body = File.read! file_name
    assert body == """
    import Foundation
    import BrightFutures
    import Alamofire
    import SwiftyJSON
    
    public class User : NSObject, JsonModel {
        var id: Int?
        let username: String
        public required init(json: JSON) {
            id = json["id"].int
            username = json["username"].stringValue
        }
    }
    
    public class Item : NSObject, JsonModel {
        var id: Int?
        let name: String
        let strength: Float
        public required init(json: JSON) {
            id = json["id"].int
            name = json["name"].stringValue
            strength = json["strength"].floatValue
        }
    }
    
    public class UserRepository : Repository {
    
        public func create(username: String) -> Future<User, NSError> {
            return requestData(.POST, routes: "/api/users", param: ["user": ["username": username]])
        }
    
        public func show(id: Int) -> Future<User, NSError> {
            return requestData(.GET, routes: "/api/users/\\(id)", param: nil)
        }
    
        public func update(id: Int, username: String) -> Future<User, NSError> {
            return requestData(.PATCH, routes: "/api/users/\\(id)", param: ["user": ["username": username]])
        }
    
        public func delete(id: Int) -> Future<Bool, NSError> {
            return requestSuccess(.DELETE, routes: "/api/users/\\(id)", param: nil)
        }
    
    }
    """
    File.rm_rf "test_generate_directory"
  end

end
