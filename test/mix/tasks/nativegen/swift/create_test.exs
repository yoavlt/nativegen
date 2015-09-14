defmodule Nativegen.Swift.CreateTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift.Create

  @valid_params ["id:integer", "username:string", "age:integer", "battle_num:integer", "group:Group", "items:array:Item"]

  test "build create args" do
    args = build_create_args(@valid_params)
    assert args == ["username:string", "age:integer", "battle_num:integer", "group:Group"]
  end

  test "run" do
    Mix.shell(Mix.Shell.Process)
    if File.exists?("test_generate_directory") do
      File.rm_rf("test_generate_directory")
    end
    run(["test_generate_directory/test", "User", "users"] ++ @valid_params)
    assert File.exists?("test_generate_directory/test/UserRepository.swift")
    File.rm_rf("test_generate_directory")
  end

  test "run with group" do
    Mix.shell(Mix.Shell.Process)
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
    default_methods = default_methods(:swift, "User", "users", "api", params, ["id:integer"] ++ params)
    assert default_methods == """
        public func create(username: String) -> Future<User, RepositoryError> {
            return requestData(.POST, routes: "/api/users", param: ["user": ["username": username]])
        }

        public func show(id: Int) -> Future<User, RepositoryError> {
            return requestData(.GET, routes: "/api/users/\\(id)", param: nil)
        }

        public func update(id: Int, username: String) -> Future<User, RepositoryError> {
            return requestData(.PATCH, routes: "/api/users/\\(id)", param: ["user": ["username": username]])
        }

        public func delete(id: Int) -> Future<Bool, RepositoryError> {
            return requestSuccess(.DELETE, routes: "/api/users/\\(id)", param: nil)
        }
    """
  end

  test "generate default methods by objc" do
    params = ["username:string"]
    default_methods = default_methods(:objc_comp, "User", "users", "api", params, ["id:integer"] ++ params)
    assert default_methods == """
        public func create(username: String, onSuccess: (User) -> (), onError: (RepositoryError) -> ()) {
            requestData(.POST, routes: "/api/users", param: ["user": ["username": username]])
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error.toError()) }
        }

        public func show(id: Int, onSuccess: (User) -> (), onError: (RepositoryError) -> ()) {
            requestData(.GET, routes: "/api/users/\\(id)", param: nil)
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error.toError()) }
        }

        public func update(id: Int, username: String, onSuccess: (User) -> (), onError: (RepositoryError) -> ()) {
            requestData(.PATCH, routes: "/api/users/\\(id)", param: ["user": ["username": username]])
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error.toError()) }
        }

        public func delete(id: Int, onSuccess: (Bool) -> (), onError: (RepositoryError) -> ()) {
            requestSuccess(.DELETE, routes: "/api/users/\\(id)", param: nil)
                .onSuccess { data in onSuccess(data) }
                .onFailure { error in onError(error.toError()) }
        }
    """
  end

end
