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
    {opts, args, _} = OptionParser.parse(args, file: :string, objc: :boolean, multipart: :boolean, group: :string)

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
    if opts[:group] do
      route = "/#{opts[:group]}#{route}"
    end

    objc = opts[:objc]

    case {opts[:multipart], opts[:upload_file], opts[:upload_stream]} do
      {true, _, _} ->
        generate_multipart(objc, route, method_name, response_type)
      {_, true, _} ->
        generate_upload_file(objc, route, method_name, response_type)
      {_, _, true} ->
        generate_upload_stream(objc, route, method_name, response_type)
      _ ->
        generate_normal(objc, http_method, route, method_name, response_type, params)
    end
  end

  def generate_normal(objc, http_method, route, method_name, response_type, params) do
    if objc do
      generate_objc_method(
      http_method, route, method_name, response_type, params
      )
    else
      generate_swift_method(http_method, route, method_name, response_type, params)
    end
  end

  def generate_multipart(objc, route, method_name, response_type) do
    objc_switch(objc, route, method_name, response_type,
                &generate_multipart_objc_method/3,
                &generate_multipart_method/3)
  end

  def generate_upload_file(objc, route, method_name, response_type) do
    objc_switch(objc, route, method_name, response_type,
                &generate_upload_objc_method/3,
                &generate_upload_method/3)
  end

  def generate_upload_stream(objc, route, method_name, response_type) do
    objc_switch(objc, route, method_name, response_type,
                &generate_upload_stream_objc_method/3,
                &generate_upload_stream_method/3)
  end

  def objc_switch(objc, route, method_name, response_type, on_objc, on_swift) do
    if objc do
      on_objc.(route, method_name, response_type)
    else
      on_swift.(route, method_name, response_type)
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

  def generate_objc_method(http_method, route, method_name, response_type, params, opts \\ [])

  def generate_objc_method(http_method, route, method_name, response_type, params, opts) when is_list(params) do
    method = request_method(Keyword.get(opts, :method) || response_type)
    generate_objc_method(method, http_method, route, method_name, response_type, params, opts)
  end

  def generate_objc_method(request_method, http_method, route, method_name, response_type, params, opts) when is_list(params) do
    http_method = http_method |> String.to_atom |> to_swift_method
    param = arg_param(params, route, opts)
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

  def generate_swift_method(http_method, route, method_name, response_type, params, opts \\ [])
  def generate_swift_method(http_method, route, method_name, response_type, params, opts) when is_list(params) do
    method = request_method(Keyword.get(opts, :method) || response_type)
    generate_swift_method(method, http_method, route, method_name, response_type, params, opts)
  end

  def generate_swift_method(request_method, http_method, route, method_name, response_type, params, opts) when is_list(params) do
    http_method = http_method |> String.to_atom |> to_swift_method
    param = arg_param(params, route, opts)
    arg = params |> parse_params |> default_args

    method_template(
      method_name: method_name,
      param: param,
      arg: arg,
      response_type: response_type,
      request_method: request_method,
      http_method: http_method,
      route: replace_param(route)
    )
  end

  @doc """
  Generate multipart form data method which is callable from swift
  """
  def generate_multipart_method(route, method_name, response_type) do
    arg = extract_params(route) |> Enum.map(fn par ->
      par <> ": Int, "
    end)
    multipart_template(
      method_name: method_name,
      arg: arg,
      response_type: response_type,
      request_method: multipart_request_method(response_type),
      route: replace_param(route)
    )
  end

  @doc """
  Generate multipart form data method which is callable from swift and Objective-C
  """
  def generate_multipart_objc_method(route, method_name, response_type) do
    arg = extract_params(route) |> Enum.map(fn par ->
      par <> ": Int, "
    end)
    objc_multipart_template(
      method_name: method_name,
      arg: arg,
      response_type: response_type,
      request_method: multipart_request_method(response_type),
      route: replace_param(route)
    )
  end

  def generate_upload_method(route, method_name, response_type) do
    upload_file_template(
      method_name: method_name,
      request_method: upload_request_method(response_type),
      response_type: response_type,
      route: route
    )
  end

  @doc """
  Generate upload file method which is callable from swift and Objective-C
  """
  def generate_upload_objc_method(route, method_name, response_type) do
    objc_upload_file_template(
      method_name: method_name,
      request_method: upload_request_method(response_type),
      response_type: response_type,
      route: route
    )
  end

  def generate_upload_stream_method(route, method_name, response_type) do
    upload_stream_template(
      method_name: method_name,
      request_method: upload_stream_method(response_type),
      response_type: response_type,
      route: route
    )
  end

  def generate_upload_stream_objc_method(route, method_name, response_type) do
    objc_upload_stream_template(
      method_name: method_name,
      request_method: upload_stream_method(response_type),
      response_type: response_type,
      route: route
    )
  end

  @doc """
  Replace parameters of route with swift syntax
  Example:
  iex> replace_param("/users/:id/hoge")
  "/users/\\(id)/hoge"
  """
  def replace_param(method_name) do
    case extract_param(method_name) do
      nil -> method_name
      %{"param" => param} ->
        next = String.replace(method_name, ":" <> param, "\\(#{to_camel_case(param)})")
        replace_param(next)
    end
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

  def multipart_request_method("Bool"), do: "multipartFormDataSuccess"
  def multipart_request_method(response_type) do
    if response_type =~ ~r/\[.+\]/ do
      "multipartFormArray"
    else
      "multipartFormData"
    end
  end

  def upload_request_method("Bool"), do: "uploadFileSuccess"
  def upload_request_method(_), do: "uploadFile"

  def upload_stream_method("Bool"), do: "uploadStreamFileSuccess"
  def upload_stream_method(_), do: "uploadStreamFile"

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

  embed_template :multipart, """
      public func <%= @method_name %>(<%= @arg %>multipart: (Alamofire.MultipartFormData) -> ()) -> Future<<%= @response_type %>, NSError> {
          return <%= @request_method %>("<%= @route %>", multipart: multipart)
      }
  """

  embed_template :objc_multipart, """
      public func <%= @method_name %>(data: [String : AnyObject], <%= @arg %>onSuccess: (<%= @response_type %>) -> (), onError: (NSError) -> ()) {
          <%= @request_method %>("<%= @route %>") { multipart in
              for (fileName, appendable) in data {
                  self.parseMultipartForm(appendable, fileName: fileName, multipart: multipart)
              }
          }.onSuccess { data in onSuccess(data) }
           .onFailure { err in onError(err) }
      }
  """

  embed_template :upload_stream, """
    public func <%= @method_name %>(stream: NSInputStream, progress: (Double) -> Void) -> Future<<%= @response_type %>, NSError> {
        return <%= @request_method %>(stream, routes: "<%= @route %>", f: progress)
    }
  """

  embed_template :objc_upload_stream, """
      public func <%= @method_name %>(stream: NSInputStream, progress: (Double) -> Void, onSuccess: (<%= @response_type %>) -> (), onError: (NSError) -> ()) {
          <%= @request_method %>(stream, routes: "<%= @route %>", f: progress)
              .onSuccess { data in onSuccess(data) }
              .onFailure { err in onError(err) }
      }
  """

  embed_template :upload_file, """
    public func <%= @method_name %>(url: NSURL, progress: (Double) -> Void) -> Future<<%= @response_type %>, NSError> {
        return <%= @request_method %>(url, routes: "<%= @route %>", f: progress)
    }
  """

  embed_template :objc_upload_file, """
      public func <%= @method_name %>(url: NSURL, progress: (Double) -> Void, onSuccess: (<%= @response_type %>) -> (), onError: (NSError) -> ()) {
          <%= @request_method %>(url, routes: "<%= @route %>", f: progress)
              .onSuccess { data in onSuccess(data) }
              .onFailure { err in onError(err) }
      }
  """

end
