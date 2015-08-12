defmodule Swiftgen.SwiftgenTest do
  use ExUnit.Case

  import Mix.Swiftgen

  @valid_args ["username:string", "age:integer", "group:Group", "items:array:Item"]

  test "parse params to variable and Swift type" do
    params = swift_var_type(["username:string", "age:integer", "group:Group", "items:array:Item"])
    assert Enum.fetch!(params, 0) == {"username", "String"}
    assert Enum.fetch!(params, 1) == {"age", "Int"}
    assert Enum.fetch!(params, 2) == {"group", "Group"}
    assert Enum.fetch!(params, 3) == {"items", "[Item]"}
  end

end
