defmodule Mix.Tasks.Swiftgen do

  @moduledoc """
  Handle swift code utilities
  """

  import Mix.Nativegen

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

end
