defmodule Mix.Tasks.Nativegen.Swift.Model do
  use Mix.Task

  import Mix.Nativegen
  import Mix.Generator
  import Mix.Tasks.Nativegen.Swift

  @shortdoc "Generate swift json class"

  @default_types [:string, :text, :uuid, :boolean, :integer, :float, :double, :decimal, :date, :datetime]
  @swift_types ["String", "Bool", "Int", "Float", "Double", "NSDate"]

  @moduledoc """
  Append json model to existing client code.

  ## Example
      mix nativegen.swift.model User username:string first_name:string last_name:string age:integer items:array:Item
  """

  def run(args) do
    [singular | params] = args

    content = generate_json_model(singular, params)

    show_on_shell content
  end

  def show_on_shell(content) do
    Mix.shell.info """
    Please add the json model in your iOS project code.
    """ <> content
  end

  def generate_json_model(singular, params) when is_list(params) do
    parsed = parse_params(params)
    json_params = parsed |> build_json_params
    json_parser = parsed |> build_json_parser
    json_model_template(
    singular: singular,
    json_params: json_params,
    json_parser: json_parser
    )
  end

  def build_json_params(params) when is_list(params) do
    params
    |> Enum.map(fn {atom, var, type} ->
        swift_type = to_swift_type(atom, type)
        camel_case = to_camel_case(var)
        "    " <> json_param(atom, camel_case, swift_type)
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
        "        #{to_camel_case(variable)} = " <> json_parser(atom, variable)
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

  def json_parser(type, var) when is_atom(type) do
    class_name = type |> Atom.to_string |> String.capitalize
    camel_var = to_camel_case(var)
    contents = custom_json_parser_template(var: var, camel_var: camel_var, type: class_name)
    String.slice(contents, 0, String.length(contents)-1)
  end

  def json_parser(type, var) when is_bitstring(type) do
    class_name = type |> String.capitalize
    camel_var = to_camel_case(var)
    contents = custom_json_parser_template(var: var, camel_var: camel_var, type: class_name)
    String.slice(contents, 0, String.length(contents)-1)
  end

  def json_parser(:array, var, type) do
    type_parser = json_parser(type, "$0")
    camel_var = to_camel_case(var)
    contents = array_json_parser_template(var: var, camel_var: camel_var, type_parser: type_parser)
    String.slice(contents, 0, String.length(contents)-1)
  end

  def json_parse_method(type), do: String.downcase(type) <> "Value"

  embed_template :custom_json_parser, """
          if let <%= @camel_var %>IdJson = json["<%= @var %>_id"] {
              <%= @camel_var %>Id = <%= @camel_var %>IdJson.intValue
          }
          if let <%= @camel_var %>Json = json["<%= @var %>"] {
              <%= @camel_var %> = <%= @type %>(json: <%= @camel_var %>Json)
          }
  """

  embed_template :array_json_parser, """
          if let <%= @camel_var %>Json = json["<%= @var %>"] {
              <%= @camel_var %> = <%= @camel_var %>Json.arrayValue.map { <%= @type_parser %> }
          }
  """

  embed_template :json_model, """
  public class <%= @singular %> : JsonModel {
  <%= @json_params %>
      public required init(json: JSON) {
  <%= @json_parser %>
      }
  }
  """

end
