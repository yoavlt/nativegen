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
    [http_method, route, method_name, response_type | params] = args

    content = generate_method(
      http_method,
      route,
      method_name,
      response_type,
      params
    )

    show_on_shell content
  end

  def show_on_shell(content) do
    Mix.shell.info """

    Please add the method in your iOS project code.

    """ <> content
  end

  def generate_method(http_method, route, method_name, response_type, params) when is_list(params) do
    http_method = http_method |> String.to_atom |> to_swift_method
    param = params |> parse_params |> generate_params |> wrap_array
    arg = params |> parse_params |> default_args

    content = method_template(
    method_name: method_name,
    param: param,
    arg: arg,
    response_type: response_type,
    http_method: http_method,
    route: route
    )
  end

  embed_template :method, """
      public func <%= @method_name %>(<%= @arg %>) -> Future<<%= @response_type %>, NSError> {
          return request(<%= @http_method %>, routes: "<%= @route %>", param: <%= @param %>)
      }
  """

end
