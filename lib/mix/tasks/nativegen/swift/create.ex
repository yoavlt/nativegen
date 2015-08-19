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
    {opts, args, _} = OptionParser.parse(args, [group: :string])
    [path, singular, plural | params] = args

    id_params = ["id:integer"] ++ params
              |> Enum.uniq
    parsed = parse_params(id_params)

    group = opts[:group] || "api"

    file_path = target_path(path, singular <> "Repository.swift")
    contents = concrete_repository_template(
      singular: singular,
      plural: plural,
      json_model: Model.generate_json_model(singular, params),
      create_args: build_create_args(parsed),
      update_args: build_update_args(parsed),
      param: generate_params(parsed),
      param_key: String.downcase(singular),
      group: group
    )

    create_file(file_path, contents)
  end

  def default_methods(:swift, plural, params, id_params) do
    alias Mix.Tasks.Nativegen.Swift.Method
    IO.inspect params
    create_method = Method.generate_method(:data, "post", "/api/#{plural}", "create", "User", params)
    show_method   = Method.generate_method(:data, "get", "/api/#{plural}/\\(id)", "show", "User", ["id:integer"])
    update_method = Method.generate_method(:data, "patch", "/api/#{plural}/\\(id)", "update", "User", params)
    delete_method = Method.generate_method("delete", "/api/#{plural}/\\(id)", "delete", "Bool", ["id:integer"])
    [create_method, show_method, update_method, delete_method] |> Enum.join("\n")
  end

  def default_methods(:objc_comp, param) do

  end

  def build_create_args(params) when is_list(params) do
    params
    |> Enum.reject(fn
      {_, "id", _}   -> true
      {:array, _, _} -> true
      {_, _, _}      -> false
    end)
    |> default_args
  end

  def build_update_args(params) when is_list(params) do
    default_args(params)
  end

  embed_template :concrete_repository, """
  import Foundation
  import BrightFutures
  import Alamofire
  import SwiftyJSON

  <%= @json_model %>

  public class <%= @singular %>Repository : NSObject, Repository {

      public func create(<%= @create_args %>) -> Future<<%= @singular %>, NSError> {
          return requestData(.POST, routes: "/<%= @group %>/<%= @plural %>", param: ["<%= @param_key %>": [<%= @param %>]])
      }

      public func show(id: Int) -> Future<<%= @singular %>, NSError> {
          return requestData(.GET, routes: "/<%= @group %>/<%= @plural %>/\\(id)", param: nil)
      }

      public func update(<%= @update_args %>) -> Future<<%= @singular %>, NSError> {
          return requestData(.PATCH, routes: "/<%= @group %>/<%= @plural %>/\\(id)", param: ["<%= @param_key %>": [<%= @param %>]])
      }

      public func delete(id: Int) -> Future<Bool, NSError> {
          return requestSuccess(.DELETE, routes: "/<%= @group %>/<%= @plural %>/\\(id)", param: nil)
      }

  }
  """
end
