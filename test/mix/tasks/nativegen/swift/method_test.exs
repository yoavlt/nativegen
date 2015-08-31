defmodule Nativegen.Swift.MethodTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift.Method

  test "generate method test" do
    assert generate_swift_method(
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
    assert generate_swift_method(
    "post",
    "/users/:user_id/show",
    "showUser",
    "User",
    ["user_id:integer"]
    ) == """
        public func showUser(userId: Int) -> Future<User, NSError> {
            return request(.POST, routes: "/users/\\(userId)/show", param: nil)
        }
    """
    assert generate_swift_method(
    "post",
    "/users/:user_id/messages",
    "fetchMessages",
    "[Message]",
    ["user_id:integer"]
    ) == """
        public func fetchMessages(userId: Int) -> Future<[Message], NSError> {
            return requestArray(.POST, routes: "/users/\\(userId)/messages", param: nil)
        }
    """
  end

  test "generate requestSuccess method" do
    assert generate_swift_method(
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
    assert generate_swift_method(
    "post",
    "/users/register",
    "registerUser",
    "Bool",
    ["username:string", "registered_at:datetime", "join_date:date"]
    ) == """
        public func registerUser(username: String, registeredAt: NSDate, joinDate: NSDate) -> Future<Bool, NSError> {
            return requestSuccess(.POST, routes: "/users/register", param: ["username": username, "registered_at": JsonUtil.toDateTimeObj(registeredAt), "join_date": JsonUtil.toDateObj(joinDate)])
        }
    """
  end

  test "generate a objective-c comatible method" do
    assert generate_objc_method(
    "post",
    "/users/register",
    "registerUser",
    "Bool",
    ["username:string", "registered_at:datetime", "join_date:date"]
    ) == """
        public func registerUser(username: String, registeredAt: NSDate, joinDate: NSDate, onSuccess: (Bool) -> (), onError: (NSError) -> ()) {
            requestSuccess(.POST, routes: "/users/register", param: ["username": username, "registered_at": JsonUtil.toDateTimeObj(registeredAt), "join_date": JsonUtil.toDateObj(joinDate)])
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error) }
        }
    """
  end

  test "generate a objective-c comatible data method" do
    assert generate_objc_method(
    "post",
    "/users/show/:id",
    "registerUser",
    "Bool",
    ["username:string", "registered_at:datetime", "join_date:date"]
    ) == """
        public func registerUser(username: String, registeredAt: NSDate, joinDate: NSDate, onSuccess: (Bool) -> (), onError: (NSError) -> ()) {
            requestSuccess(.POST, routes: "/users/show/\\(id)", param: ["username": username, "registered_at": JsonUtil.toDateTimeObj(registeredAt), "join_date": JsonUtil.toDateObj(joinDate)])
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error) }
        }
    """
  end

  test "append method content" do
    alias Mix.Tasks.Nativegen.Swift.Create
    Create.run(["test_generate_directory/test", "User", "users", "username:string", "items:array:Item"])
    content = generate_swift_method("post", "/users/buy", "buyItem", "Bool", ["item_id:integer"])
    file_name = "test_generate_directory/test/UserRepository.swift"
    append_file(content, file_name)

    assert File.read!(file_name) == """
    import Foundation
    import BrightFutures
    import Alamofire
    import SwiftyJSON
    
    public class User : NSObject, JsonModel {
        var id: Int?
        var username: String
        var items: [Item]?
        public required init(json: JSON) {
            id = json["id"].int
            username = json["username"].stringValue
            if json["items"].error == nil {
                items = json["items"].arrayValue.map { Item(json: $0) }
            }
        }

        public func prop() -> [String : AnyObject?] {
            return ["id": id, "username": username]
        }
    }
    
    public class UserRepository : Repository {
    
        public func create(username: String) -> Future<User, NSError> {
            return requestData(.POST, routes: "/api/users", param: ["user": ["username": username]])
        }
    
        public func show(id: Int) -> Future<User, NSError> {
            return requestData(.GET, routes: "/api/users/\\(id)", param: nil)
        }
    
        public func update(id: Int, username: String, items: [Item]) -> Future<User, NSError> {
            return requestData(.PATCH, routes: "/api/users/\\(id)", param: ["user": ["username": username]])
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

    assert_raise Mix.Error, fn -> append_file(content, file_name) end
  end

  test "replace parmeter in router" do
    method_name = "/users/:id/show/:hoge"
    assert replace_param(method_name) == "/users/\\(id)/show/\\(hoge)"
    method_name = "/users/:user_id/show"
    assert replace_param(method_name) == "/users/\\(userId)/show"
  end

  test "generate content" do
    content = generate_content(["post", "/users/:id/postMessage", "postMessage", "Bool", "message:string", "user:users"], [objc: true])
    refute content =~ "Future"
    content = generate_content(["post", "/users/:id/postMessage", "postMessage", "Bool", "message:string", "user:users"], nil)
    assert content =~ "Future"

    content = generate_content(["post", "/users/:id/postMessage", "postMessage", "Bool", "message:string", "user:users"], [group: :api])
    assert content =~ "/api/users/"
  end

  test "request method" do
    assert request_method("Bool") == "requestSuccess"
    assert request_method("Data") == "requestData"
    assert request_method("[Array]") == "requestArray"
  end

  test "multipart request methods" do
    assert multipart_request_method("Bool") == "multipartFormDataSuccess"
    assert multipart_request_method("Data") == "multipartFormData"
    assert multipart_request_method("[User]") == "multipartFormArray"
    assert multipart_request_method("User") == "multipartFormData"
  end

  test "generate multipart method" do
    assert generate_multipart_method("/users/:id/register", "registerUser", "Bool") == """
        public func registerUser(id: Int, multipart: (Alamofire.MultipartFormData) -> ()) -> Future<Bool, NSError> {
            return multipartFormDataSuccess(\"/users/\\(id)/register\", multipart: multipart)
        }
    """
    assert generate_multipart_method("/users/:id/register", "registerUser", "User") == """
        public func registerUser(id: Int, multipart: (Alamofire.MultipartFormData) -> ()) -> Future<User, NSError> {
            return multipartFormData(\"/users/\\(id)/register\", multipart: multipart)
        }
    """
  end

  test "generate multipart method which is Objective-C compatible" do
    assert generate_multipart_objc_method("/users/:id/register", "userRegister", "Bool") == """
        public func userRegister(data: [String : AnyObject], id: Int, onSuccess: (Bool) -> (), onError: (NSError) -> ()) {
            multipartFormDataSuccess(\"/users/\\(id)/register\") { multipart in
                for (fileName, appendable) in data {
                    self.parseMultipartForm(appendable, fileName: fileName, multipart: multipart)
                }
            }.onSuccess { data in onSuccess(data) }
             .onFailure { err in onError(err) }
        }
    """
  end

  test "run command" do
    Mix.shell(Mix.Shell.Process)
    run(["post", "/users/:id/register", "registerUser", "User", "id:integer", "--objc", "--group", "v2"])
    assert_receive {:mix_shell, :info, [method]}
    assert method =~ "Please add"
    assert method =~ "request"
    assert method =~ "registerUser"

    run(["post", "/users/:id/register", "registerUser", "Bool", "id:integer", "--multipart", "--group", "v2"])
    assert_receive {:mix_shell, :info, [method]}
    assert method =~ "multipartFormData"

    run(["post", "/users/:id/register", "registerUser", "Bool", "id:integer", "--multipart", "--objc", "--group", "v2"])
    assert_receive {:mix_shell, :info, [method]}
    refute method =~ "Future"
  end

end
