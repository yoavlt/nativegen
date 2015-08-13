defmodule Nativegen.Swift.CreateTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift.Create

  @valid_params ["id:integer", "username:string", "age:integer", "battle_num:integer", "group:Group", "items:array:Item"]

  test "build update args" do
    params = Mix.Nativegen.parse_params(@valid_params)
    args = build_update_args(params)
    assert args == "id: Int, username: String, age: Int, battleNum: Int, groupId: Int, items: [Item]"
  end

  test "build create args" do
    params = Mix.Nativegen.parse_params(@valid_params)
    args = build_create_args(params)
    assert args == "username: String, age: Int, battleNum: Int, groupId: Int"
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

end
