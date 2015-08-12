defmodule Swiftgen.SwiftgenTest do
  use ExUnit.Case

  import Mix.Swiftgen

  test "parse params to variable and Swift type" do
    params = parse_params(["username:string", "age:integer", "group:Group", "items:array:Item"])
    assert params |> Enum.fetch!(0) == {"username", "String"}
    assert params |> Enum.fetch!(1) == {"age", "Int"}
    assert params |> Enum.fetch!(2) == {"group", "Group"}
    assert params |> Enum.fetch!(3) == {"items", "[Item]"}
  end

end
