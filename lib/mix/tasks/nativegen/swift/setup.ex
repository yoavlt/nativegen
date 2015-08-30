defmodule Mix.Tasks.Nativegen.Swift.Setup do
  use Mix.Task
  import Mix.Generator
  import Mix.Nativegen

  @shortdoc "Setup swift code base"

  @moduledoc """
  Generates swift code base into your iOS project.

  The generated code depends on the below libraries
  - Alamofire
  - SwiftyJSON
  - BrightFutures

  ## Example
      mix nativegen.setup /path/to/your/swift/directory http://your_base_url.com

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
      expected nativegen.setup receive two arguments.
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

  public class Repository : NSObject {
      let host = "<%= @host %>"

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
                      if let errors = JSON(rawValue:json!)?["errors"] {
                          p.failure(NSError(domain: "server error", code: 101, userInfo: nil))
                          return
                      }
                      if let resJson = JSON(rawValue: json!) {
                          let model = T(json: resJson)
                          p.success(model)
                      } else {
                          p.failure(NSError(domain: "No data property", code: 100, userInfo: nil))
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
                      if let errors = JSON(rawValue:json!)?["errors"] {
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
          Alamofire.request(method, urlStr(routes), parameters: param)
              .responseJSON { (req, res, json, err) in
                  if let statusCode = res?.statusCode {
                      if statusCode == 201 || statusCode == 202 || statusCode == 204 {
                          p.success(true)
                          return
                      }
                  }
                  if let nserror = err {
                      p.failure(nserror)
                  } else {
                      if let errors = JSON(rawValue:json!)?["errors"] {
                          p.failure(NSError(domain: "server error", code: 101, userInfo: nil))
                          return
                      }
                      if let success = JSON(json!)["success"].bool {
                          p.success(success)
                      } else {
                          p.failure(NSError(domain: "request success error", code: 0, userInfo: nil))
                      }
                  }
          }
          return p.future
      }

      func uploadStreamFile(stream: NSInputStream, routes: String, f: (Double) -> Void) -> Future<Bool, NSError> {
          let p = Promise<Bool, NSError>()
          Alamofire.upload(.POST, urlStr(routes), stream: stream)
              .progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                  let ratio: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                  f(ratio)
              }
              .responseJSON { _, res, json, error in
                  if let statusCode = res?.statusCode {
                      if statusCode == 204 {
                          p.success(true)
                          return
                      }
                  }
                  if let nserror = error {
                      p.failure(nserror)
                  } else {
                      if let success = JSON(json!)["success"].bool {
                          p.success(success)
                      } else {
                          p.failure(NSError(domain: "request success error", code: 0, userInfo: nil))
                      }
                  }
              }
          return p.future
      }

      func uploadFile(url: NSURL, routes: String, f: (Double) -> Void) -> Future<Bool, NSError> {
          let p = Promise<Bool, NSError>()
          Alamofire.upload(.POST, urlStr(routes), file: url)
              .progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                  let ratio: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                  f(ratio)
              }
              .responseJSON { _, res, json, error in
                  if let statusCode = res?.statusCode {
                      if statusCode == 204 {
                          p.success(true)
                          return
                      }
                  }
                  if let nserror = error {
                      p.failure(nserror)
                  } else {
                      if let success = JSON(json!)["success"].bool {
                          p.success(success)
                      } else {
                          p.failure(NSError(domain: "request success error", code: 0, userInfo: nil))
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
                      if let errorJson = JSON(rawValue:json!)?["errors"] {
                          if errorJson.error == nil {
                              p.failure(NSError(domain: errorJson.description, code: 101, userInfo: nil))
                              return
                          }
                      }
                      if let dataJson = JSON(rawValue: json!)?["data"] {
                          let model = T(json: dataJson)
                          p.success(model)
                      } else {
                          p.failure(NSError(domain: "No data property", code: 100, userInfo: nil))
                      }
                  }
          }
          return p.future
      }

      func multipartFormData<T : JsonModel>(routes: String, multipart: Alamofire.MultipartFormData -> ()) -> Future<T, NSError> {
          let p = Promise<T, NSError>()

          Alamofire.upload(.POST, URLString: urlStr(routes), multipartFormData: multipart,
              encodingCompletion: { encodingResult in
                  switch encodingResult {
                  case .Success(let upload, _, _):
                      upload.responseJSON { (req, res, json, err) in
                          if let nserror = err {
                              p.failure(nserror)
                          } else {
                              if let errors = JSON(rawValue:json!)?["errors"] {
                                  p.failure(NSError(domain: "server error", code: 101, userInfo: nil))
                                  return
                              }
                              if let resJson = JSON(rawValue: json!) {
                                  let model = T(json: resJson)
                                  p.success(model)
                              } else {
                                  p.failure(NSError(domain: "No data property", code: 100, userInfo: nil))
                              }
                          }
                      }
                  case .Failure(let encodingError):
                      p.failure(encodingError)
                  }
          })

          return p.future
      }

      func multipartFormArray<[T] : JsonModel>(routes: String, multipart: Alamofire.MultipartFormData -> ()) -> Future<[T], NSError> {
          let p = Promise<T, NSError>()

          Alamofire.upload(.POST, URLString: urlStr(routes), multipartFormData: multipart,
              encodingCompletion: { encodingResult in
                  switch encodingResult {
                  case .Success(let upload, _, _):
                      upload.responseJSON { (req, res, json, err) in
                      if let nserror = err {
                          p.failure(nserror)
                      } else {
                          if let errors = JSON(rawValue:json!)?["errors"] {
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
                  case .Failure(let encodingError):
                      p.failure(encodingError)
                  }
          })

          return p.future
      }

      func multipartFormDataSuccess(routes: String, multipart: Alamofire.MultipartFormData -> ()) -> Future<Bool, NSError> {
          let p = Promise<Bool, NSError>()

          Alamofire.upload(.POST, URLString: urlStr(routes), multipartFormData: multipart,
              encodingCompletion: { encodingResult in
                  switch encodingResult {
                  case .Success(let upload, _, _):
                      upload.responseJSON { (req, res, json, err) in
                          if let statusCode = res?.statusCode {
                              if statusCode == 204 {
                                  p.success(true)
                                  return
                              }
                          }
                          if let nserror = err {
                              p.failure(nserror)
                          } else {
                              if let errors = JSON(rawValue:json!)?["errors"] {
                                  p.failure(NSError(domain: "server error", code: 101, userInfo: nil))
                                  return
                              }
                              if let success = JSON(json!)["success"].bool {
                                  p.success(success)
                              } else {
                                  p.failure(NSError(domain: "request success error", code: 0, userInfo: nil))
                              }
                          }
                      }
                  case .Failure(let encodingError):
                      p.failure(encodingError)
                  }
          })

          return p.future
      }

      func parseMultipartForm(appendable: NSObject, fileName: String, multipart: Alamofire.MultipartFormData) {
          if let data = appendable as? NSData {
              multipart.appendBodyPart(data: data, name: fileName)
          }
          if let url = appendable as? NSURL {
              multipart.appendBodyPart(fileURL: url, name: fileName)
          }
      }

      static func parseDate(year:Int, month:Int, day:Int) -> NSDate {
          var c = NSDateComponents()
          c.year = year
          c.month = month
          c.day = day

          var gregorian = NSCalendar(identifier:NSCalendarIdentifierGregorian)
          var date = gregorian!.dateFromComponents(c)
          return date!
      }

      static func parseDate(json: JSON) -> NSDate {
          let year = json["year"].intValue
          let month = json["month"].intValue
          let day = json["day"].intValue
          return parseDate(year, month: month, day: day)
      }

      public func dateComponent(date: NSDate, component : NSCalendarUnit) -> Int {
          let calendar = NSCalendar.currentCalendar()
          let components = calendar.components(component, fromDate: date)

          return components.valueForComponent(component)
      }

      func toDateObj(date: NSDate) -> [String: Int] {
          return [
              "year": dateComponent(date, component: .CalendarUnitYear),
              "month": dateComponent(date, component: .CalendarUnitMonth),
              "day": dateComponent(date, component: .CalendarUnitDay)
          ]
      }

      func toDateTimeObj(date: NSDate) -> [String: Int] {
          var dateObj = toDateObj(date)
          dateObj.updateValue(dateComponent(date, component: .CalendarUnitHour), forKey: "hour")
          dateObj.updateValue(dateComponent(date, component: .CalendarUnitMinute), forKey: "minute")
          dateObj.updateValue(dateComponent(date, component: .CalendarUnitSecond), forKey: "second")
          return dateObj
      }

  }
  """

end
