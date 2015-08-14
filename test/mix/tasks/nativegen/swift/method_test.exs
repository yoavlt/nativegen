defmodule Nativegen.Swift.MethodTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift.Method

  test "generate method test" do
    assert generate_method(
    "post",
    "/users/create",
    "createUser",
    "User",
    ["username:string", "age:integer"]
    ) == """
        public func createUser(username: String, age: Int) -> Future<User, NSError> {
            return request(.POST, routes: "/users/create", param: [username: username, age: age])
        }
    """
  end

  test "generate requestSuccess method" do
    assert generate_method(
    "delete",
    "/users/delete",
    "deleteUser",
    "Bool",
    ["id:integer"]
    ) == """
        public func deleteUser(id: Int) -> Future<Bool, NSError> {
            return requestSuccess(.DELETE, routes: "/users/delete", param: nil)
        }
    """
  end

  test "append method content" do
    alias Mix.Tasks.Nativegen.Swift.Create
    Create.run(["test_generate_directory/test", "User", "users", "username:string", "items:array:Item"])
    content = generate_method("post", "/users/buy", "buyItem", "Bool", ["item_id:integer"])
    file_name = "test_generate_directory/test/UserRepository.swift"
    append_file(content, file_name)

    assert File.read!(file_name) == """
    import Foundation
    import BrightFutures
    import Alamofire
    import SwiftyJSON
    
    public class User : JsonModel {
        let username: String
        var items: [Item]
        public required init(json: JSON) {
            username = json["username"].stringValue
            if let itemsJson = json["items"] {
                items = itemsJson.arrayValue.map { Item(json: $0) }
            }
        }
    }
    
    public class UserRepository : Repository {
    
        public func create(username: String) -> Future<User, NSError> {
            return requestData(.POST, routes: "/api/users", param: ["user": [username: username]])
        }
    
        public func show(id: Int) -> Future<User, NSError> {
            return requestData(.GET, routes: "/api/users/(id)", param: nil)
        }
    
        public func update(id: Int, username: String, items: [Item]) -> Future<User, NSError> {
            return requestData(.PATCH, routes: "/api/users/(id)", param: ["user": [username: username]])
        }
    
        public func delete(id: Int) -> Future<Bool, NSError> {
            return requestSuccess(.DELETE, routes: "/api/users/(id)", param: nil)
        }
    
        public func buyItem(itemId: Int) -> Future<Bool, NSError> {
            return requestSuccess(.POST, routes: "/users/buy", param: [item_id: itemId])
        }
    
    }
    """
    File.rm_rf "test_generate_directory"
  end

end
