defmodule Mix.Swiftgen do

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
      {:array, variable, type} ->
        {variable, "[#{to_swift_type(type)}]"}
      {type, variable, _} ->
        {variable, to_swift_type(type)}
    end)
  end

  @doc """
  Parse parameter to Swift's type
  """
  def to_swift_type(type) when is_atom(type) do
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
      custom    ->
        custom
        |> Atom.to_string
        |> String.capitalize
    end
  end

  def to_swift_type(type) when is_bitstring(type) do
    String.capitalize(type)
  end

end

