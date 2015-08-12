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

  def parse_params(params) when is_list(params) do
    params
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.map(fn args ->
      case args do
        [variable, "array", type] ->
          {variable, "[#{parse_type(type)}]"}
        [variable, type] ->
          {variable, parse_type(type)}
      end
    end)
  end

  def parse_type(type) do
    case type do
      "string"   -> "String"
      "integer"  -> "Int"
      "float"    -> "Float"
      "double"   -> "Double"
      "decimal"  -> "Double"
      "date"     -> "NSDate"
      "datetime" -> "NSDate"
      custom     -> custom
    end
  end

end

