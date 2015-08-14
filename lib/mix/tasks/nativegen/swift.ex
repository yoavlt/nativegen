defmodule Mix.Tasks.Nativegen.Swift do

  @moduledoc """
  Handle swift code utilities
  """

  import Mix.Nativegen

  @default_types [:string, :text, :uuid, :boolean, :integer, :float, :double, :decimal, :date, :datetime]
  @swift_types ["String", "Bool", "Int", "Float", "Double", "NSDate"]

  @doc """
  Parse parameter to variable and Swift's type
  """
  def swift_var_type(params) when is_list(params) do
    parse_params(params)
    |> Enum.map(fn
      {atom, var, type} ->
        {var, to_swift_type(atom, type)}
    end)
  end

  @doc """
  Parse parameter to Swift's type
  """
  def to_swift_type(type, sub_type \\ "")
  def to_swift_type(type, _sub_type) when is_bitstring(type),
  do: String.capitalize(type)
  def to_swift_type(type, sub_type) when is_atom(type) do
    case type do
      :string   -> "String"
      :text     -> "String"
      :uuid     -> "String"
      :boolean  -> "Bool"
      :integer  -> "Int"
      :float    -> "Float"
      :double   -> "Double"
      :decimal  -> "Double"
      :date     -> "NSDate"
      :datetime -> "NSDate"
      :array    -> "[#{to_swift_type(sub_type)}]"
      custom    ->
        custom
        |> Atom.to_string
        |> String.capitalize
    end
  end

  @doc """
  Swift HTTP method type
  """
  def to_swift_method(:get),    do: ".GET"
  def to_swift_method(:post),   do: ".POST"
  def to_swift_method(:put),    do: ".PUT"
  def to_swift_method(:patch),  do: ".PATCH"
  def to_swift_method(:delete), do: ".DELETE"

  def generate_params(params) do
    params
    |> Enum.reject(fn
      {_, "id", _}   -> true
      {:array, _, _} -> true
      {_, _, _}      -> false
    end)
    |> Enum.map(fn
      {atom, var, _} when atom in @default_types -> "#{var}: #{to_camel_case(var)}"
      {_, var, _} -> "#{var}_id: #{to_camel_case(var)}Id"
    end)
    |> Enum.join(", ")
  end

  def default_args(params) when is_list(params) do
    params
    |> Enum.map(fn {atom, var, type} ->
      swift_type = to_swift_type(atom, type)
      camel_case = to_camel_case(var)
      arg(atom, camel_case, swift_type)
    end)
    |> Enum.join(", ")
  end

  def arg(_atom, variable, type) when type in @swift_types,
  do: "#{variable}: #{type}"
  def arg(:array, variable, type), do: "#{variable}: #{type}"
  def arg(atom, variable, type), do: "#{variable}Id: Int"

  def wrap_array(param_str) do
    case param_str do
      ""  -> "nil"
      par -> "[#{par}]"
    end
  end

  @doc """
  Parse swift repository code to {imports, jsom_models, repo_def, methods, repo_end}
  """
  def parse_swift(body) do
    lines = body |> String.split("\n") |> Enum.map(&(&1 <> "\n"))
    {imports, lines}     = while_imports(lines)
    {json_models, lines} = while_json_models(lines)
    {repo_def, lines}    = while_repo_def(lines)
    {methods, repo_end}  = while_methods(lines)
    {imports, json_models, repo_def, methods, repo_end}
  end

  def while_imports(lines) do
    Enum.split_while(lines, fn line ->
      not (line =~ ": JsonModel")
    end)
  end

  def while_json_models(lines) do
    Enum.split_while(lines, fn line ->
      not (line =~ ": Repository")
    end)
  end

  def while_repo_def(lines) do
    Enum.split_while(lines, fn line ->
      not (line =~ "public func")
    end)
  end

  def while_methods(lines) do
    Enum.split_while(lines, fn line ->
      not (line == "}\n")
    end)
  end

end
