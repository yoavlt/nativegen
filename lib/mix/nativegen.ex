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
  Transform variable or method to lower camel case.
  """
  def to_camel_case(word) do
    [head | tail] = word |> String.split("_")
    capitalized = tail
                  |> Enum.map(&String.capitalize/1)
                  |> Enum.join("")
    head <> capitalized
  end

  @doc """
  Split last \n line
  """
  def drop_last_empty(content) when is_bitstring(content) do
    content
    |> String.split("\n")
    |> Enum.map(&(&1 <> "\n"))
    |> drop_last_empty
  end

  def drop_last_empty(content) when is_list(content) do
    drop_last_if(content, &(&1 == ""))
  end

  def drop_last_break(content) when is_list(content) do
    drop_last_if(content, &(&1 == "\n"))
  end

  def drop_last_if(content, f) when is_list(content) do
    last = content |> List.last
    if f.(last) do
      content |> Enum.drop(-1)
    else
      content
    end
  end

end
