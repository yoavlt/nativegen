defmodule Nativegen.SwiftTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift

  test "parse params to variable and Swift type" do
    params = swift_var_type(["username:string", "age:integer", "group:Group", "items:array:Item"])
    assert Enum.fetch!(params, 0) == {"username", "String"}
    assert Enum.fetch!(params, 1) == {"age", "Int"}
    assert Enum.fetch!(params, 2) == {"group", "Group"}
    assert Enum.fetch!(params, 3) == {"items", "[Item]"}
  end

end
