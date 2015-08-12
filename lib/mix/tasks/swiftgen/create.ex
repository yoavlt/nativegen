defmodule Mix.Tasks.Swiftgen.Create do
  use Mix.Task
  import Mix.Generator
  import Mix.Swiftgen

  @shortdoc "Create specified swift repository code"

  @moduledoc """
  Create scaffold repository code.

  The generated code depends on the below libraries
  - Alamofire
  - SwiftyJSON
  - BrightFutures

  ## Example
    mix swiftgen.create /path/to/your/directory User users username:string group:Group items:array:Item
  """

  def run(args) do
    [path, singular, plural | params] = args
  end

  def generate_params(params) do
  end

  def build_json_params(params) when is_list(params) do

  end

  def json_param(variable, type) do
    "let #{variable}: #{type}"
  end

  def build_json_parser(params) when is_list(params) do
    parse_params(params)
    |> Enum.map(fn [variable, type] ->
      json_param(variable, type)
    end)
    |> Enum.join("\n")
  end

  def build_create_args(params) when is_list(params) do
  end

  def build_update_args(params) when is_list(params) do
  end

  embed_template :concrete_repository, """
  import Foundation
  import BrightFutures
  import Alamofire
  import SwiftyJSON

  public class <%= @singular %> : JsonModel {
      <%= @json_params %>
      public required init(json: JSON) {
          <%= @json_parser %>
      }
  }

  public class <%= @singular %>Repository : Repository {

      public func create(<%= @create_args %>) -> Future<<%= @singular %>, NSError> {
          return requestData(.POST, routes: "/<%= @group %>/<%= @plural %>", param: [<%= @param %>])
      }

      public func show(id: Int) -> Future<<%= @singular %>, NSError> {
          return requestData(.GET, routes: "/<%= @group %>/<%= @plural %>/\(id)", param: nil)
      }

      public func update(<%= @update_args %>) -> Future<<%= @singular %>, NSError> {
          return requestData(.PATCH, routes: "/<%= @group %>/<%= @plural %>/\(id)", param: [<%= @param %>])
      }

      public func delete(id: Int) -> Future<Bool, NSError> {
          return requestSuccess(.DELETE, routes: "/<%= @group %>/<%= @plural %>/\(id)", param: nil)
      }

  }
  """
end
