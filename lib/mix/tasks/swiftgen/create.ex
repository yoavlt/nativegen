defmodule Mix.Tasks.Swiftgen.Create do
  use Mix.Task
  import Mix.Generator
  import Mix.Swiftgen

  @shortdoc "Create specified swift repository code"

  @moduledoc """
  Create scaffold repository code.

  The generated code depends on the below libraries
  - Alamofire
  - SwiftyJSON
  - BrightFutures

  ## Example
    mix swiftgen.create /path/to/your/directory User users username:string group:Group items:array:Item
  """

  def run(args) do
    [path, singular, plural | params] = args

    params = ["id:integer"] ++ params
              |> List.flatten
              |> Enum.uniq
    parsed = parse_params(params)
    swift_params = swift_var_type(params)

    json_params = build_json_params(swift_params)
    create_args = build_create_args(swift_params)
    update_args = build_update_args(swift_params)
    json_parser = build_json_parser(parsed)
    param = generate_params(swift_params)
    group = "api" # TODO: customizable

    file_path = target_path(path, singular <> "Repository.swift")
    contents = concrete_repository_template(
      singular: singular,
      plural: plural,
      json_params: json_params,
      create_args: create_args,
      update_args: update_args,
      json_parser: json_parser,
      param: param,
      group: group
    )

    create_file(file_path, contents)
  end

  def generate_params(params) do
    params
    |> Enum.reject(fn
      {"id", _}   -> true
      {_, _} -> false
    end)
    |> Enum.map(fn {var, _} -> "#{var}: #{var}" end)
    |> Enum.join(", ")
  end

  def build_json_params(params) when is_list(params) do
    params
    |> Enum.map(fn {variable, type} ->
      "    " <> json_param(variable, type)
    end)
    |> Enum.join("\n")
  end

  def json_param(variable, type) do
    "let #{variable}: #{type}"
  end

  def build_json_parser(params) when is_list(params) do
    params
    |> Enum.map(fn
      {:array, variable, type} ->
        "        #{variable} = " <> json_parser(:array, variable, type)
      {atom, variable, _} ->
        "        #{variable} = " <> json_parser(atom, variable)
    end)
    |> Enum.join("\n")
  end

  def json_parser(type, variable) when type in [:string, :text, :uuid, :boolean, :integer, :float, :double, :decimal] do
    swift_type = to_swift_type(type)
    "json[\"#{variable}\"].#{json_parse_method(swift_type)}"
  end

  def json_parser(type, "$0") when type in [:string, :text, :uuid, :boolean, :integer, :float, :double, :decimal] do
    swift_type = to_swift_type(type)
    "$0.#{json_parse_method(swift_type)}"
  end

  def json_parser(type, "$0") when type in [:datetime, :date] do
    "Repository.parseDate(json: $0)"
  end

  def json_parser(type, "$0") when is_bitstring(type) do
    "#{type}(json: $0)"
  end

  def json_parser(type, variable) when type in [:datetime, :date] do
    "Repository.parseDate(json[\"#{variable}\"]!)"
  end

  def json_parser(type, variable) when is_atom(type) do
    class_name = type |> Atom.to_string |> String.capitalize
    "#{class_name}(json: json[\"#{variable}\"]!)"
  end

  def json_parser(type, variable) when is_bitstring(type) do
    class_name = type |> String.capitalize
    "#{class_name}(json: json[\"#{variable}\"]!)"
  end

  def json_parser(:array, variable, type) do
    swift_type = to_swift_type(type)
    type_parser = json_parser(type, "$0")
    "json[\"#{variable}\"].arrayValue.map { #{type_parser} }"
  end

  def json_parse_method(type) do
    String.downcase(type) <> "Value"
  end

  def build_create_args(params) when is_list(params) do
    params
    |> Enum.reject(fn
      {"id", _} -> true
      {_, _}    -> false
    end)
    |> build_update_args
  end

  def build_update_args(params) when is_list(params) do
    default_args(params)
  end

  def default_args(params) when is_list(params) do
    params
    |> Enum.map(fn {variable, type} ->
      arg(variable, type)
    end)
    |> Enum.join(", ")
  end

  def arg(variable, type) do
    "#{variable}: #{type}"
  end

  embed_template :concrete_repository, """
  import Foundation
  import BrightFutures
  import Alamofire
  import SwiftyJSON

  public class <%= @singular %> : JsonModel {
  <%= @json_params %>
      public required init(json: JSON) {
  <%= @json_parser %>
      }
  }

  public class <%= @singular %>Repository : Repository {

      public func create(<%= @create_args %>) -> Future<<%= @singular %>, NSError> {
          return requestData(.POST, routes: "/<%= @group %>/<%= @plural %>", param: [<%= @param %>])
      }

      public func show(id: Int) -> Future<<%= @singular %>, NSError> {
          return requestData(.GET, routes: "/<%= @group %>/<%= @plural %>/\(id)", param: nil)
      }

      public func update(<%= @update_args %>) -> Future<<%= @singular %>, NSError> {
          return requestData(.PATCH, routes: "/<%= @group %>/<%= @plural %>/\(id)", param: [<%= @param %>])
      }

      public func delete(id: Int) -> Future<Bool, NSError> {
          return requestSuccess(.DELETE, routes: "/<%= @group %>/<%= @plural %>/\(id)", param: nil)
      }

  }
  """
end
