defmodule Mix.Tasks.Swiftgen.Setup do
  use Mix.Task
  import Mix.Generator
  import Mix.Swiftgen

  @shortdoc "Setup swift code base"

  @moduledoc """
  Generates swift code base into your iOS project.

  The generated code depends on the below libraries
  - Alamofire
  - SwiftyJSON
  - BrightFutures

  ## Example
      mix swiftgen.setup /path/to/your/swift/directory http://your_base_url.com

  The first argument is the directory which you want to generate code base in your iOS project,
  and second argument is your host URL.
  """
  def run(args) do
    case args do
      [path, host] ->
        unless File.exists?(path) do
          create_directory(path)
        end

        file_path = target_path(path, "repository.swift")
        contents = compile_repository(host)

        create_file(file_path, contents)
      _ -> Mix.raise """
      expected swiftgen.setup receive two arguments.
      """
    end
  end

  @doc """
  Compile content of repository.swift file.
  """
  def compile_repository(host) do
    repository_template(host: host)
  end

  embed_template :repository, """
  import Foundation
  import BrightFutures
  import Alamofire
  import SwiftyJSON

  protocol JsonModel {
      init(json: JSON)
  }

  public class Repository {
      let host = "<%= @host %>"
      public init() {

      }

      func urlStr(routes: String) -> String {
          return host + routes
      }

      func url(routes: String) -> NSURL {
          return NSURL(string:urlStr(routes))!
      }

      func request<T : JsonModel>(method: Alamofire.Method, routes: String, param: [String:AnyObject]?) -> Future<T, NSError> {
          let p = Promise<T, NSError>()
          Alamofire.request(method, urlStr(routes), parameters: param)
              .responseJSON { (req, res, json, err) in
                  if let nserror = err {
                      p.failure(nserror)
                  } else {
                      if let errors = JSON(rawValue:json!)["errors"] {
                          p.failure(NSError(domain: "server error", code: 101, userInfo: nil))
                          return
                      }
                      let arrayModel = JSON(rawValue: json!).map { T(json: $0) }
                      if arrayModel != nil {
                          p.success(arrayModel!)
                      } else {
                          p.failure(NSError(domain: "Repository Error", code: 100, userInfo: nil))
                      }
                  }
          }
          return p.future
      }

      func requestArray<T : JsonModel>(method: Alamofire.Method, routes: String, param: [String:AnyObject]?) -> Future<[T], NSError> {
          let p = Promise<[T], NSError>()
          Alamofire.request(method, urlStr(routes), parameters: param)
              .responseJSON { (req, res, json, err) in
                  if let nserror = err {
                      p.failure(nserror)
                  } else {
                      if let errors = JSON(rawValue:json!)["errors"] {
                          p.failure(NSError(domain: "server error", code: 101, userInfo: nil))
                          return
                      }
                      let arrayModel = JSON(json!).array?.map { T(json: $0) }
                      if arrayModel != nil {
                          p.success(arrayModel!)
                      } else {
                          p.success([])
                      }
                  }
          }
          return p.future
      }

      func requestSuccess(method: Alamofire.Method, routes: String, param: [String: AnyObject]?) -> Future<Bool, NSError> {
          let p = Promise<Bool, NSError>()
          Alamofire.request(.POST, urlStr(routes), parameters: param)
              .responseJSON { (req, res, json, err) in
                  if let nserror = err {
                      p.failure(nserror)
                  } else {
                      if let errors = JSON(rawValue:json!)["errors"] {
                          p.failure(NSError(domain: "server error", code: 101, userInfo: nil))
                          return
                      }
                      if let success = JSON(json!)["success"].bool {
                          p.success(success)
                      } else {
                          p.failure(AError(message: "error", errorCode: 0))
                      }
                  }
          }
          return p.future
      }

      func requestData<T : JsonModel>(method: Alamofire.Method, routes: String, param: [String: AnyObject]?) -> Future<T, NSError> {
          let p = Promise<T, NSError>()
          Alamofire.request(method, urlStr(routes), parameters: param)
              .responseJSON { (req, res, json, err) in
                  if let nserror = err {
                      p.failure(nserror)
                  } else {
                      if let errors = JSON(rawValue:json!)["errors"] {
                          p.failure(NSError(domain: "server error", code: 101, userInfo: nil))
                          return
                      }
                      let arrayModel = JSON(rawValue: json!).map { T(json: $0) }
                      if arrayModel != nil {
                          p.success(arrayModel!)
                      } else {
                          p.failure(NSError(domain: "Repository Error", code: 100, userInfo: nil))
                      }
                  }
          }
          return p.future
      }

      func parseDate(year:Int, month:Int, day:Int) -> NSDate {
          var c = NSDateComponents()
          c.year = year
          c.month = month
          c.day = day

          var gregorian = NSCalendar(identifier:NSGregorianCalendar)
          var date = gregorian.dateFromComponents(c)
          return date
      }

  }
  """

end
