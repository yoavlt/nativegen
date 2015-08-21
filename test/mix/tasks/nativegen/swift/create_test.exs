defmodule Nativegen.Swift.CreateTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift.Create

  @valid_params ["id:integer", "username:string", "age:integer", "battle_num:integer", "group:Group", "items:array:Item"]

  test "build create args" do
    args = build_create_args(@valid_params)
    assert args == ["username:string", "age:integer", "battle_num:integer", "group:Group"]
  end

  test "run" do
    if File.exists?("test_generate_directory") do
      File.rm_rf("test_generate_directory")
    end
    run(["test_generate_directory/test", "User", "users"] ++ @valid_params)
    assert File.exists?("test_generate_directory/test/UserRepository.swift")
    File.rm_rf("test_generate_directory")
  end

  test "run with group" do
    if File.exists?("test_generate_directory") do
      File.rm_rf("test_generate_directory")
    end
    run(["test_generate_directory/test", "User", "users"] ++ @valid_params ++ ["--group", "v1"])
    assert File.exists?("test_generate_directory/test/UserRepository.swift")
    assert File.read!("test_generate_directory/test/UserRepository.swift") =~ "v1"
    File.rm_rf("test_generate_directory")
  end

  test "generate default methods by swift" do
    params = ["username:string"]
    default_methods = default_methods(:swift, "users", "api", params, ["id:integer"] ++ params)
    assert default_methods == """
        public func create(username: String) -> Future<User, NSError> {
            return requestData(.POST, routes: "/api/users", param: ["username": username])
        }

        public func show(id: Int) -> Future<User, NSError> {
            return requestData(.GET, routes: "/api/users/\\(id)", param: nil)
        }

        public func update(id: Int, username: String) -> Future<User, NSError> {
            return requestData(.PATCH, routes: "/api/users/\\(id)", param: ["username": username])
        }

        public func delete(id: Int) -> Future<Bool, NSError> {
            return requestSuccess(.DELETE, routes: "/api/users/\\(id)", param: nil)
        }
    """
  end

  test "generate default methods by objc" do
    params = ["username:string"]
    default_methods = default_methods(:objc_comp, "users", "api", params, ["id:integer"] ++ params)
    assert default_methods == """
        public func create(username: String, onSuccess: (User) -> (), onError: (NSError) -> ()) {
            requestData(.POST, routes: "/api/users", param: ["username": username])
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error) }
        }

        public func show(id: Int, onSuccess: (User) -> (), onError: (NSError) -> ()) {
            requestData(.GET, routes: "/api/users/\\(id)", param: nil)
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error) }
        }

        public func update(id: Int, username: String, onSuccess: (User) -> (), onError: (NSError) -> ()) {
            requestData(.PATCH, routes: "/api/users/\\(id)", param: ["username": username])
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error) }
        }

        public func delete(id: Int, onSuccess: (Bool) -> (), onError: (NSError) -> ()) {
            requestSuccess(.DELETE, routes: "/api/users/\\(id)", param: nil)
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error) }
        }
    """
  end

end
