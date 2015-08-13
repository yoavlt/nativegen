defmodule Mix.Tasks.Nativegen.Swift do

  @moduledoc """
  Handle swift code utilities
  """

  import Mix.Nativegen

  @default_types [:string, :text, :uuid, :boolean, :integer, :float, :double, :decimal, :date, :datetime]

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

end
