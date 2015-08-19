defmodule Mix.Tasks.Nativegen.Swift.Method do
  use Mix.Task

  import Mix.Nativegen
  import Mix.Generator
  import Mix.Tasks.Nativegen.Swift

  @shortdoc "Show swift method, please copy and paste to your code"

  @moduledoc """
  Append request method to existing client code.

  ## Example
      mix nativegen.swift.method post /api/chat/response responseMessage Chat thread_id:integer message:string
  """

  def run(args) do
    {opts, args, _} = OptionParser.parse(args, file: :string)
    [http_method, route, method_name, response_type | params] = args

    content = generate_method(
      http_method,
      route,
      method_name,
      response_type,
      params
    )

    case opts[:file] do
      nil ->
        show_on_shell content
      file_path ->
        append_file(content, file_path)
    end
  end

  def show_on_shell(content) do
    Mix.shell.info """

    Please add the method in your iOS project code.

    """ <> content
  end

  def append_file(content, path) do
    if File.exists?(path) do
      {imports, json_models, repo_def, methods, repo_end} = File.read!(path)
      |> parse_swift
      methods = methods ++ [content, "\n"]
      new_body = imports ++ json_models ++ repo_def ++ methods ++ repo_end
                  |> Enum.join
      File.write! path, new_body
    else
      Mix.raise "File write error: no such file(#{path})"
    end
  end

  def generate_method(:data, http_method, route, method_name, response_type, params) when is_list(params) do
    generate_method(request_method("Data"), http_method, route, method_name, response_type, params)
  end

  def generate_method(http_method, route, method_name, response_type, params) when is_list(params) do
    generate_method(request_method(response_type), http_method, route, method_name, response_type, params)
  end

  def generate_method(request_method, http_method, route, method_name, response_type, params) when is_list(params) do
    http_method = http_method |> String.to_atom |> to_swift_method
    param = params |> parse_params |> generate_params |> wrap_array
    arg = params |> parse_params |> default_args

    content = method_template(
    method_name: method_name,
    param: param,
    arg: arg,
    response_type: response_type,
    request_method: request_method,
    http_method: http_method,
    route: route
    )
  end

  def request_method("Bool"), do: "requestSuccess"
  def request_method("Data"), do: "requestData"
  def request_method(_), do: "request"

  embed_template :method, """
      public func <%= @method_name %>(<%= @arg %>) -> Future<<%= @response_type %>, NSError> {
          return <%= @request_method %>(<%= @http_method %>, routes: "<%= @route %>", param: <%= @param %>)
      }
  """

end
