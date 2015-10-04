defmodule Mix.Tasks.Nativegen.Swift.Create do
  use Mix.Task
  import Mix.Generator
  import Mix.Nativegen
  import Mix.Tasks.Nativegen.Swift
  alias Mix.Tasks.Nativegen.Swift.Model

  @shortdoc "Create specified swift repository code"

  @moduledoc """
  Create repository code that contains CRUD methods.

  The generated code depends on the below libraries
  - Alamofire
  - SwiftyJSON
  - BrightFutures

  ## Example
    mix nativegen.swift.create /path/to/your/directory User users username:string group:Group items:array:Item
  """

  def run(args) do
    {opts, args, _} = OptionParser.parse(args, group: :string, objc: :boolean)
    [path, singular, plural | params] = args

    id_params = ["id:integer"] ++ params
                |> Enum.uniq
    parsed = parse_params(id_params)

    group = opts[:group] || "api"

    file_path = target_path(path, singular <> "Repository.swift")
    methods = if opts[:objc] do
      default_methods(:objc_comp, singular, plural, group, params, id_params)
    else
      default_methods(:swift, singular, plural, group, params, id_params)
    end

    contents = concrete_repository_template(
      singular: singular,
      plural: plural,
      json_model: Model.generate_json_model(singular, params),
      methods: methods,
      param: generate_params(parsed),
      param_key: String.downcase(singular),
      group: group
    )

    create_file(file_path, contents)
  end

  def default_methods(:swift, singular, plural, group, params, id_params) do
    alias Mix.Tasks.Nativegen.Swift.Method
    opts = [method: "Data", key: String.downcase(singular)] 
    create_method = Method.generate_swift_method("post", "/#{group}/#{plural}", "create", singular, build_create_args(params), opts)
    show_method   = Method.generate_swift_method("get", "/#{group}/#{plural}/\\(id)", "show", singular, ["id:integer"], opts)
    update_method = Method.generate_swift_method("patch", "/#{group}/#{plural}/\\(id)", "update", singular, id_params, opts)
    delete_method = Method.generate_swift_method("delete", "/#{group}/#{plural}/\\(id)", "delete", "Bool", ["id:integer"])
    [create_method, show_method, update_method, delete_method] |> Enum.join("\n")
  end

  def default_methods(:objc_comp, singular, plural, group, params, id_params) do
    alias Mix.Tasks.Nativegen.Swift.Method
    opts = [method: "Data", key: String.downcase(singular)] 
    create_method = Method.generate_objc_method("post", "/#{group}/#{plural}", "create", singular, build_create_args(params), opts)
    show_method   = Method.generate_objc_method("get", "/#{group}/#{plural}/\\(id)", "show", singular, ["id:integer"], opts)
    update_method = Method.generate_objc_method("patch", "/#{group}/#{plural}/\\(id)", "update", singular, id_params, opts)
    delete_method = Method.generate_objc_method("delete", "/#{group}/#{plural}/\\(id)", "delete", "Bool", ["id:integer"])
    [create_method, show_method, update_method, delete_method] |> Enum.join("\n")
  end

  def build_create_args(params) when is_list(params) do
    params
    |> Enum.reject(fn param ->
      case parse_param(param) do
        {_, "id", _}   -> true
        {:array, _, _} -> true
        {_, _, _}      -> false
      end
    end)
  end

  embed_template :concrete_repository, """
  import Foundation
  import BrightFutures
  import Alamofire
  import SwiftyJSON

  <%= @json_model %>

  public class <%= @singular %>Repository : Repository {

  <%= @methods %>
  }
  """
end
