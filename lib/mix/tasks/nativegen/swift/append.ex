defmodule Mix.Tasks.Nativegen.Swift.Append do
  use Mix.Task

  import Mix.Generator
  import Mix.Tasks.Nativegen.Swift

  @shortdoc "Append request method to existing client code"

  @moduledoc """
  Append request method to existing client code.

  ## Example
      mix nativegen.swift.append /path/to/your/client/path.swift responseMessage Post /api/chat/response thread_id:integer message:string

  The first argument is the path to your client file.
  """

  def run(args) do
    [file_path, method_name, response_type, route | params] = args
    unless Path.extname(file_path) == ".swift" do
      Mix.raise "Please specify *.swift file path"
    end

    method = method_name |> String.to_atom |> to_swift_method

  end

  embed_template :method, """
  public <%= @method_name %>(<%= @param %>) -> Future<<%= @post %>, NSError> {
      return requestData(<%= @method %>, routes: "<%= @route %>", param: ["<%= @param_key %>": [<%= @param %>]])
  }
  """

end
