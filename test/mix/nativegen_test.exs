defmodule Nativegen.NativegenTest do
  use ExUnit.Case

  import Mix.Nativegen

  @valid_args ["username:string", "age:integer", "group:Group", "items:array:Item"]

  test "parse params to variable and Swift type" do
    params = swift_var_type(["username:string", "age:integer", "group:Group", "items:array:Item"])
    assert Enum.fetch!(params, 0) == {"username", "String"}
    assert Enum.fetch!(params, 1) == {"age", "Int"}
    assert Enum.fetch!(params, 2) == {"group", "Group"}
    assert Enum.fetch!(params, 3) == {"items", "[Item]"}
  end

  test "to camel case" do
    assert to_camel_case("hoge_fuga_piyo") == "hogeFugaPiyo"
    assert to_camel_case("hoge") == "hoge"
  end

end
