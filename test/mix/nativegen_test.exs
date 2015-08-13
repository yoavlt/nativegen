defmodule Nativegen.NativegenTest do
  use ExUnit.Case

  import Mix.Nativegen

  test "to camel case" do
    assert to_camel_case("hoge_fuga_piyo") == "hogeFugaPiyo"
    assert to_camel_case("hoge") == "hoge"
  end

end
