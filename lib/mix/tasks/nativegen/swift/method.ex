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
    {opts, args, _} = OptionParser.parse(args, file: :string, objc: :boolean)
    # [http_method, route, method_name, response_type | params] = args

    content = generate_content(args, opts)
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

  def generate_content([http_method, route, method_name, response_type | params], opts) do
    if opts[:objc] do
      generate_method(
        :objc,
        http_method, route, method_name, response_type, params
      )
    else
      generate_method(http_method, route, method_name, response_type, params)
    end
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

  def generate_method(:objc_data, http_method, route, method_name, response_type, params) when is_list(params) do
    generate_method(:objc, request_method("Data"), http_method, route, method_name, response_type, params)
  end

  def generate_method(:objc, http_method, route, method_name, response_type, params) when is_list(params) do
    generate_method(:objc, request_method(response_type), http_method, route, method_name, response_type, params)
  end

  def generate_method(:objc, request_method, http_method, route, method_name, response_type, params) when is_list(params) do
    http_method = http_method |> String.to_atom |> to_swift_method
    route_params = extract_params(route)
    param = params
            |> parse_params
            |> Enum.reject(&(is_include?(&1, route_params)))
            |> generate_params
            |> wrap_array
    arg = params |> parse_params |> default_args

    objc_method_template(
    method_name: method_name,
    param: param,
    arg: arg,
    response_type: response_type,
    request_method: request_method,
    http_method: http_method,
    route: replace_param(route)
    )
  end

  def generate_method(http_method, route, method_name, response_type, params) when is_list(params) do
    generate_method(request_method(response_type), http_method, route, method_name, response_type, params)
  end

  def generate_method(request_method, http_method, route, method_name, response_type, params) when is_list(params) do
    http_method = http_method |> String.to_atom |> to_swift_method
    route_params = extract_params(route)
    param = params
            |> parse_params
            |> Enum.reject(&(is_include?(&1, route_params)))
            |> generate_params
            |> wrap_array
    arg = params |> parse_params |> default_args

    content = method_template(
    method_name: method_name,
    param: param,
    arg: arg,
    response_type: response_type,
    request_method: request_method,
    http_method: http_method,
    route: replace_param(route)
    )
  end

  def is_include?({_, var, _}, params), do: var in params

  def replace_param(method_name) do
    case extract_param(method_name) do
      nil -> method_name
      %{"param" => param} ->
        next = String.replace(method_name, ":" <> param, "\\(#{to_camel_case(param)})")
        replace_param(next)
    end
  end

  def extract_params(method_name, params \\ []) do
    case extract_param(method_name) do
      nil -> params
      %{"param" => param} ->
        next = String.replace(method_name, ":" <> param, "\\(#{to_camel_case(param)})")
        extract_params(next, [param | params])
    end
  end

  @doc ~S"""
  extract parameters from route.

  Example:
  iex> extract_param("/users/:id/show")
  %{"param" => "id"}
  """
  def extract_param(method_name) do
    Regex.named_captures(~r/:(?<param>.+?)(\/|$)/, method_name)
  end

  def request_method("Bool"), do: "requestSuccess"
  def request_method("Data"), do: "requestData"
  def request_method(response_type) do
    if response_type =~ ~r/\[.+\]/ do
      "requestArray"
    else
      "request"
    end
  end

  embed_template :method, """
      public func <%= @method_name %>(<%= @arg %>) -> Future<<%= @response_type %>, NSError> {
          return <%= @request_method %>(<%= @http_method %>, routes: "<%= @route %>", param: <%= @param %>)
      }
  """

  embed_template :objc_method, """
      public func <%= @method_name %>(<%= @arg %>, onSuccess: (<%= @response_type %>) -> (), onError: (NSError) -> ()) {
          <%= @request_method %>(<%= @http_method %>, routes: "<%= @route %>", param: <%= @param %>)
              .onSuccess { data in onSuccess(data) }
              .onFailure { error in onError(error) }
      }
  """

end
