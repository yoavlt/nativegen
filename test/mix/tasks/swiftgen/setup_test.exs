defmodule Swiftgen.SetupTest do
  use ExUnit.Case

  import Mix.Tasks.Swiftgen.Setup

  @test_host "http://yoavlt.com"

  test "contains host in compiled repository file" do
    contents = compile_repository(@test_host)
    assert String.contains?(contents, "let host = \"" <> @test_host)
  end
end
