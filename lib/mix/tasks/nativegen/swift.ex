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
        |> to_upper_camel_case
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
    |> Enum.map(&transform_prop/1)
    |> Enum.join(", ")
  end

  def generate_prop(params) do
    params
    |> Enum.reject(fn
      {:array, _, _} -> true
      _ -> false
    end)
    |> Enum.map(&transform_prop/1)
    |> Enum.join(", ")
  end

  def transform_prop({atom, var, _} = prop) do
    if var == "id" or not atom in @default_types do
      translate_prop(prop) <> " ?? NSNull()"
    else
      translate_prop(prop)
    end
  end

  def translate_prop({:date, var, _}) do
    "\"#{var}\": JsonUtil.toDateObj(#{to_camel_case(var)})"
  end

  def translate_prop({:datetime, var, _}) do
    "\"#{var}\": JsonUtil.toDateTimeObj(#{to_camel_case(var)})"
  end

  def translate_prop({atom, var, _}) when atom in @default_types do
    "\"#{var}\": #{to_camel_case(var)}"
  end

  def translate_prop({_, var, _}) do
    "\"#{var}_id\": #{to_camel_case(var)}Id"
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
  def arg(atom, variable, type), do: "#{variable}Id: Int?"

  def wrap_dict(param_str, nil) do
    case param_str do
      ""  -> "nil"
      par -> "[#{par}]"
    end
  end

  def wrap_dict(param_str, key) do
    case param_str do
      ""  -> "nil"
      par -> "[\"#{key}\": #{wrap_dict(par, nil)}]"
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
    {methods, lines}  = while_methods(lines)
    repo_end = lines |> drop_last_break
    {imports, json_models, repo_def, methods, repo_end}
  end

  def while_imports(lines) do
    Enum.split_while(lines, fn line ->
      not (line =~ ", JsonModel")
    end)
  end

  def while_json_models(lines) do
    {jsons, lines} = Enum.split_while(lines, fn line ->
      not (line =~ ": Repository")
    end)
    json_models = drop_last_break(jsons)
    {json_models, lines}
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

  @doc """
  Return arguments parameter of request method
  Example:
  iex> arg_param(["id:integer", "username:string"], "/users/:id/register", [])
  "[\"username\": username]"
  """
  def arg_param(params, route, opts) do
    route_params = extract_params(route)
    params
    |> parse_params
    |> Enum.reject(&(is_include?(&1, route_params)))
    |> generate_params
    |> wrap_dict(Keyword.get(opts, :key))
  end

  @doc """
  Return prop method dictionary of JsonModel
  Example:
  iex> arg_prop(["id:integer", "username:string"])
  "[\"id\": id, \"username\": username]"
  """
  def arg_prop(params, opts \\ []) do
    params
    |> generate_prop
    |> wrap_dict(Keyword.get(opts, :key))
  end

  @doc """
  Extract parameters from route
  Example:
  iex> extract_params("/users/:id/register")
       ["id"]
  """
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

  def is_include?({_, var, _}, params), do: var in params

end
