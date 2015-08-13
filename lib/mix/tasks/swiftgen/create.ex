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

  @swift_types ["String", "Bool", "Int", "Float", "Double", "NSDate"]
  @default_types [:string, :text, :uuid, :boolean, :integer, :float, :double, :decimal, :date, :datetime]

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
      json_params: build_json_params(parsed),
      create_args: build_create_args(parsed),
      update_args: build_update_args(parsed),
      json_parser: build_json_parser(parsed),
      param: generate_params(parsed),
      param_key: String.downcase(singular),
      group: group
    )

    create_file(file_path, contents)
  end

  def generate_params(params) do
    params
    |> Enum.reject(fn
      {_, "id", _}   -> true
      {:array, _, _} -> true
      {_, _, _}      -> false
    end)
    |> Enum.map(fn
      {atom, var, _} when atom in @default_types -> "#{var}: #{var}"
      {_, var, _} -> "#{var}_id: #{var}Id"
    end)
    |> Enum.join(", ")
  end

  def build_json_params(params) when is_list(params) do
    params
    |> Enum.map(fn {atom, var, type} ->
        swift_type = to_swift_type(atom, type)
        "    " <> json_param(atom, var, swift_type)
    end)
    |> Enum.join("\n")
  end

  def json_param(_atom, variable, type) when type in @swift_types,
  do: "let #{variable}: #{type}"
  def json_param(:array, variable, type),
  do: "var #{variable}: #{type}"
  def json_param(_atom, variable, type) do
    "var #{variable}Id: Int\n    " <>
    "var #{variable}: #{type}"
  end

  def build_json_parser(params) when is_list(params) do
    params
    |> Enum.map(fn
      {:array, variable, type} ->
        json_parser(:array, variable, type)
      {atom, variable, _} when atom in @default_types ->
        "        #{variable} = " <> json_parser(atom, variable)
      {atom, variable, _} ->
        json_parser(atom, variable)
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

  def json_parser(type, "$0") when type in [:datetime, :date],
  do: "Repository.parseDate(json: $0)"

  def json_parser(type, "$0") when is_bitstring(type),
  do: "#{type}(json: $0)"

  def json_parser(type, variable) when type in [:datetime, :date],
  do: "Repository.parseDate(json[\"#{variable}\"]!)"

  def json_parser(type, variable) when is_atom(type) do
    class_name = type |> Atom.to_string |> String.capitalize
    contents = custom_json_parser_template(var: variable, type: class_name)
    String.slice(contents, 0, String.length(contents)-1)
  end

  def json_parser(type, variable) when is_bitstring(type) do
    class_name = type |> String.capitalize
    contents = custom_json_parser_template(var: variable, type: class_name)
    String.slice(contents, 0, String.length(contents)-1)
  end

  def json_parser(:array, variable, type) do
    type_parser = json_parser(type, "$0")
    contents = array_json_parser_template(var: variable, type_parser: type_parser)
    String.slice(contents, 0, String.length(contents)-1)
  end

  def json_parse_method(type), do: String.downcase(type) <> "Value"

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

  def default_args(params) when is_list(params) do
    params
    |> Enum.map(fn {atom, var, type} ->
      swift_type = to_swift_type(atom, type)
      arg(atom, var, swift_type)
    end)
    |> Enum.join(", ")
  end

  def arg(_atom, variable, type) when type in @swift_types,
  do: "#{variable}: #{type}"
  def arg(:array, variable, type), do: "#{variable}: #{type}"
  def arg(atom, variable, type), do: "#{variable}Id: Int"

  embed_template :custom_json_parser, """
          if let <%= @var %>IdJson = json["<%= @var %>_id"] {
              <%= @var %>_id = json["<%= @var %>_id"].intValue
          }
          if let <%= @var %>Json = json["<%= @var %>"] {
              <%= @var %> = <%= @type %>(json: <%= @var %>Json)
          }
  """

  embed_template :array_json_parser, """
          if let <%= @var %>Json = json["<%= @var %>"] {
              <%= @var %> = <%= @var %>Json.arrayValue.map { <%= @type_parser %> }
          }
  """

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
