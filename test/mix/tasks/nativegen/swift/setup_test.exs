defmodule Nativegen.Swift.SetupTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift.Setup

  @test_host "http://yoavlt.com"

  test "contains host in compiled repository file" do
    contents = compile_repository(@test_host)
    assert String.contains?(contents, "let host = \"#{@test_host}\"")
  end

  test "raises when given invalid number of arguments" do
    assert_raise Mix.Error, fn -> run ["1st"] end
    assert_raise Mix.Error, fn -> run ["1st", "2nd", "3rd"] end
  end

  test "created directory specified 1st argument and generated swift file" do
    Mix.shell(Mix.Shell.Process)
    test_directory = Path.join(".", "test_generate_directory/repo")
    if File.exists?(test_directory) do
      File.rm_rf(test_directory)
    end
    refute File.exists?(test_directory)
    run [test_directory, @test_host]
    assert File.exists?(test_directory)
    assert File.exists?(Path.join(test_directory, "repository.swift"))
    File.rm_rf(Path.join(".", "test_generate_directory"))
  end

end
