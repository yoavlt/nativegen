defmodule Nativegen.NativegenTest do
  use ExUnit.Case

  import Mix.Nativegen

  test "to camel case" do
    assert to_camel_case("hoge_fuga_piyo") == "hogeFugaPiyo"
    assert to_camel_case("hoge") == "hoge"
    assert to_camel_case("HogeFuga") == "HogeFuga"
  end

  test "drop last empty" do
    assert drop_last_empty(["hoge", "fuga", ""]) == ["hoge", "fuga"]
    assert drop_last_empty(["hoge", "fuga", ""]) == ["hoge", "fuga"]
  end

  test "drop last break" do
    assert drop_last_break(["hoge", "fuga", "\n", "\n"]) == ["hoge", "fuga", "\n"]
  end

end
