defmodule Mix.Tasks.Nativegen.Swift.Create do
  use Mix.Task
  import Mix.Generator
  import Mix.Nativegen
  import Mix.Tasks.Nativegen.Swift
  import Mix.Tasks.Nativegen.Swift.Model

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
    [path, singular, plural | params] = args

    params = ["id:integer"] ++ params
              |> List.flatten
              |> Enum.uniq
    parsed = parse_params(params)
    swift_params = swift_var_type(params)

    group = "api" # TODO: customizable

    file_path = target_path(path, singular <> "Repository.swift")
    contents = concrete_repository_template(
      singular: singular,
      plural: plural,
      json_model: generate_json_model(singular, parsed),
      create_args: build_create_args(parsed),
      update_args: build_update_args(parsed),
      param: generate_params(parsed),
      param_key: String.downcase(singular),
      group: group
    )

    create_file(file_path, contents)
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

  public class <%= @singular %>Repository : Repository {

      public func create(<%= @create_args %>) -> Future<<%= @singular %>, NSError> {
          return requestData(.POST, routes: "/<%= @group %>/<%= @plural %>", param: ["<%= @param_key %>": [<%= @param %>]])
      }

      public func show(id: Int) -> Future<<%= @singular %>, NSError> {
          return requestData(.GET, routes: "/<%= @group %>/<%= @plural %>/\(id)", param: nil)
      }

      public func update(<%= @update_args %>) -> Future<<%= @singular %>, NSError> {
          return requestData(.PATCH, routes: "/<%= @group %>/<%= @plural %>/\(id)", param: ["<%= @param_key %>": [<%= @param %>]])
      }

      public func delete(id: Int) -> Future<Bool, NSError> {
          return requestSuccess(.DELETE, routes: "/<%= @group %>/<%= @plural %>/\(id)", param: nil)
      }

  }
  """
end
