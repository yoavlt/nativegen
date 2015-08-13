defmodule Mix.Tasks.Nativegen.Swift.Append do
  use Mix.Task

  import Mix.Generator
  import Mix.Tasks.Nativegen.Swift

  @shortdoc "Append request method to existing client code"

  @moduledoc """
  Append request method to existing client code.

  ## Example
      mix nativegen.swift.append /path/to/your/client/path.swift responseMessage post Chat /api/chat/response thread_id:integer message:string

  The first argument is the path to your client file.
  """

  def run(args) do
  end

end
