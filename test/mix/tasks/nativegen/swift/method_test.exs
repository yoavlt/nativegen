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

end
