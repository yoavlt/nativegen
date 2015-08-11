defmodule Mix.Tasks.Swiftgen.Append do
  use Mix.Task

  @shortdoc "Append request method to existing client code"

  @moduledoc """
  Append request method to existing client code.

  ## Example
      mix swiftgen.append /path/to/your/client/path responseMessage post /api/chat/response thread_id:integer message:string

  The first argument is the path to your client file.
  """

  def run(args) do
  end

end
