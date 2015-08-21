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
            return request(.POST, routes: "/users/create", param: ["username": username, "age": age])
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

  test "generate a method with datetime parameter" do
    assert generate_method(
    "post",
    "/users/register",
    "registerUser",
    "Bool",
    ["username:string", "registered_at:datetime", "join_date:date"]
    ) == """
        public func registerUser(username: String, registeredAt: NSDate, joinDate: NSDate) -> Future<Bool, NSError> {
            return requestSuccess(.POST, routes: "/users/register", param: ["username": username, "registered_at": toDateTimeObj(registeredAt), "join_date": toDateObj(joinDate)])
        }
    """
  end

  test "generate a objective-c comatible method" do
    assert generate_method(
    :objc,
    "post",
    "/users/register",
    "registerUser",
    "Bool",
    ["username:string", "registered_at:datetime", "join_date:date"]
    ) == """
        public func registerUser(username: String, registeredAt: NSDate, joinDate: NSDate, onSuccess: (Bool) -> (), onError: (NSError) -> ()) {
            requestSuccess(.POST, routes: "/users/register", param: ["username": username, "registered_at": toDateTimeObj(registeredAt), "join_date": toDateObj(joinDate)])
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error) }
        }
    """
  end

  test "generate a objective-c comatible data method" do
    assert generate_method(
    :objc_data,
    "post",
    "/users/show/:id",
    "registerUser",
    "Bool",
    ["username:string", "registered_at:datetime", "join_date:date"]
    ) == """
        public func registerUser(username: String, registeredAt: NSDate, joinDate: NSDate, onSuccess: (Bool) -> (), onError: (NSError) -> ()) {
            requestData(.POST, routes: "/users/show/\\(id)", param: ["username": username, "registered_at": toDateTimeObj(registeredAt), "join_date": toDateObj(joinDate)])
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error) }
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
    
    public class User : NSObject, JsonModel {
        let username: String
        var items: [Item]
        public required init(json: JSON) {
            username = json["username"].stringValue
            if let itemsJson = json["items"] {
                items = itemsJson.arrayValue.map { Item(json: $0) }
            }
        }
    }
    
    public class UserRepository : NSObject, Repository {
    
        public func create(username: String) -> Future<User, NSError> {
            return requestData(.POST, routes: "/api/users", param: ["username": username])
        }
    
        public func show(id: Int) -> Future<User, NSError> {
            return requestData(.GET, routes: "/api/users/\\(id)", param: nil)
        }
    
        public func update(id: Int, username: String, items: [Item]) -> Future<User, NSError> {
            return requestData(.PATCH, routes: "/api/users/\\(id)", param: ["username": username])
        }
    
        public func delete(id: Int) -> Future<Bool, NSError> {
            return requestSuccess(.DELETE, routes: "/api/users/\\(id)", param: nil)
        }
    
        public func buyItem(itemId: Int) -> Future<Bool, NSError> {
            return requestSuccess(.POST, routes: "/users/buy", param: ["item_id": itemId])
        }
    
    }
    """
    File.rm_rf "test_generate_directory"
  end

  test "extract parameter" do
    assert extract_param("/users/:id/show") == %{"param" => "id"}
    assert extract_param("/users/:id") == %{"param" => "id"}
  end

  test "replace parmeter in router" do
    method_name = "/users/:id/show/:hoge"
    assert replace_param(method_name) == "/users/\\(id)/show/\\(hoge)"
  end

  test "generate content" do
    content = generate_content(["post", "/users/:id/postMessage", "postMessage", "Bool", "message:string", "user:users"], [objc: true])
    refute content =~ "Future"
    content = generate_content(["post", "/users/:id/postMessage", "postMessage", "Bool", "message:string", "user:users"], nil)
    assert content =~ "Future"
  end

end
