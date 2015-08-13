defmodule Nativegen.Swift.AppendTest do
  use ExUnit.Case

  import Mix.Tasks.Nativegen.Swift.Append

  @valid_attr ["test_generate_directory/test/UserRepository.swift", "responseMessage", "Post", "/api/chat/response", "thread_id:integer", "message:string"]

end
