defmodule Mix.Nativegen do

  @moduledoc false

  @doc """
  target path
  """
  def target_path(specified_path, file_name) do
    specified_path
    |> Path.expand
    |> Path.join(file_name)
  end

  @doc """
  Transform to handle types and variables easily
  """
  def parse_params(params) when is_list(params) do
    params
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.map(fn
      [variable, "array", type] ->
        {:array, variable, type}
      [variable, type] ->
        {String.to_atom(type), variable, type}
    end)
  end

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

  def to_swift_type(type, sub_type) when is_bitstring(type) do
    String.capitalize(type)
  end

  def to_camel_case(word) do
    [head | tail] = word |> String.split("_")
    capitalized = tail
                  |> Enum.map(&String.capitalize/1)
                  |> Enum.join("")
    head <> capitalized
  end

end
