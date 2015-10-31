defmodule Mix.Tasks.Nativegen.Swift.Model do
  use Mix.Task

  import Mix.Nativegen
  import Mix.Generator
  import Mix.Tasks.Nativegen.Swift

  @shortdoc "Generate swift json model"

  @default_types [:string, :text, :uuid, :boolean, :integer, :float, :double, :decimal, :date, :datetime]
  @swift_types ["String", "Bool", "Int", "Float", "Double", "NSDate"]

  @moduledoc """
  Append json model to existing client code.

  ## Example
      mix nativegen.swift.model User username:string first_name:string last_name:string age:integer items:array:Item
  """

  def run(args) do
    {opts, args, _} = OptionParser.parse(args, file: :string)
    [singular | params] = args

    content = generate_json_model(singular, params)

    case opts[:file] do
      nil ->
        show_on_shell content
      file_path ->
        append_file(content, file_path)
    end
  end

  @doc """
  Show json model on shell
  """
  def show_on_shell(content) do
    Mix.shell.info """
    Please add the json model in your iOS project code.

    """ <> content
  end

  @doc """
  Insert json model into your exisiting swift file
  """
  def append_file(content, file) do
    if File.exists?(file) do
      {imports, json_models, repo_def, methods, repo_end} = File.read!(file)
                                                            |> parse_swift
      json_models = json_models
      new_json_models = json_models ++ [content, "\n"]
      body = imports ++ new_json_models ++ repo_def ++ methods ++ repo_end
              |> Enum.join
      File.write! file, body
    else
      Mix.raise "File write error: no such file(#{file})"
    end
  end

  @doc """
  Generate json model from name and params
  """
  def generate_json_model(singular, params) when is_list(params) do
    parsed = parse_params(["id:integer"] ++ params)
    json_params = parsed |> build_json_params
    json_parser = parsed |> build_json_parser
    property    = parsed |> arg_prop
    json_model_template(
    singular: singular,
    json_params: json_params,
    json_parser: json_parser,
    property: property
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

  def json_param(:integer, "id", type), do: "var id: #{type}?"
  def json_param(_atom, variable, type) when type in @swift_types,
  do: "var #{variable}: #{type}"
  def json_param(:array, variable, type),
  do: "var #{variable}: #{type}?"
  def json_param(_atom, variable, type) do
    "var #{variable}Id: Int?\n    " <>
    "var #{variable}: #{type}?"
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

  def json_parser(:integer, "id"), do: "json[\"id\"].int"
  def json_parser(type, variable) when type in [:string, :text, :uuid, :boolean, :integer, :float, :double, :decimal] do
    swift_type = to_swift_type(type)
    "json[\"#{variable}\"].#{json_parse_method(swift_type)}"
  end

  def json_parser(type, "$0") when type in [:string, :text, :uuid, :boolean, :integer, :float, :double, :decimal] do
    swift_type = to_swift_type(type)
    "$0.#{json_parse_method(swift_type)}"
  end

  def json_parser(:date, "$0"), do: "JsonUtil.parseDate(json: $0)"

  def json_parser(:datetime, "$0"), do: "JsonUtil.parseDate(json: $0)"

  def json_parser(type, "$0") when is_bitstring(type),
  do: "#{type}(json: $0)"

  def json_parser(type, variable) when type in [:datetime, :date],
  do: "JsonUtil.parseDate(json[\"#{variable}\"])"

  def json_parser(type, var) when is_atom(type) do
    class_name = type |> Atom.to_string |> to_upper_camel_case
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
          if json["<%= @var %>_id"].error == nil {
              <%= @camel_var %>Id = json["<%= @var %>_id"].int
          }
          if json["<%= @var %>"].error == nil {
              <%= @camel_var %> = <%= @type %>(json: json["<%= @var %>"])
          }
  """

  embed_template :array_json_parser, """
          if json["<%= @var %>"].error == nil {
              <%= @camel_var %> = json["<%= @var %>"].arrayValue.map { <%= @type_parser %> }
          }
  """

  embed_template :json_model, """
  public class <%= @singular %> : NSObject, JsonModel {
  <%= @json_params %>
      public required init(json: JSON) {
  <%= @json_parser %>
      }

      public func prop() -> [String : AnyObject] {
          return <%= @property %>
      }
  }
  """

end
