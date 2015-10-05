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

  public protocol JsonModel {
      init(json: JSON)
      func prop() -> [String : AnyObject]
  }

  public enum RepositoryError : ErrorType {
      case RemoteServerError(String)
      case AlamofireError(ErrorType)

    func toError() -> NSError {
        switch self {
        case .RemoteServerError(let message):
            return NSError(domain: message, code: 101, userInfo: nil)
        case .AlamofireError(_):
            return NSError(domain: "Network Error", code: 101, userInfo: nil)
        }
    }
  }

  extension JSON {
      var hasKey: Bool {
          get {
              return self.error == nil
          }
      }
  }

  public class Repository : NSObject {
      let host = "<%= @host %>"

      func urlStr(routes: String) -> String {
          return host + routes
      }

      func url(routes: String) -> NSURL {
          return NSURL(string:urlStr(routes))!
      }

      func beforeRequest(route: String) {
          // write your code here
      }

      func afterRequest(route: String) {
          // write your code here
      }

      func responseJson<T: JsonModel>(p: Promise<T, RepositoryError>, req: NSURLRequest?, res: NSHTTPURLResponse?, result: Result<AnyObject>) {
          switch result {
          case .Success(let msg) where msg is String:
              p.tryFailure(.RemoteServerError("\(msg)"))
          case .Success(let obj):
              let json = JSON(obj)
              let jsonError = json["errors"]
              if jsonError.hasKey {
                  p.tryFailure(.RemoteServerError("\(jsonError.object)"))
                  return
              }
              let model = T(json: json)
              p.trySuccess(model)
          case .Failure(_, let error):
              p.tryFailure(.AlamofireError(error))
          }
      }

      func responseJsonData<T: JsonModel>(p: Promise<T, RepositoryError>, req: NSURLRequest?, res: NSHTTPURLResponse?, result: Result<AnyObject>) {
          switch result {
          case .Success(let msg) where msg is String:
              p.tryFailure(.RemoteServerError("\(msg)"))
          case .Success(let obj):
              let json = JSON(obj)
              let jsonError = json["errors"]
              if jsonError.hasKey {
                  p.tryFailure(.RemoteServerError("\(jsonError.object)"))
                  return
              }
              let model = T(json: json["data"])
              p.trySuccess(model)
          case .Failure(_, let error):
              p.tryFailure(.AlamofireError(error))
          }
      }

      func responseJsonArray<T : JsonModel>(p: Promise<[T], RepositoryError>, req: NSURLRequest?, res: NSHTTPURLResponse?, result: Result<AnyObject>) {
          switch result {
          case .Success(let msg) where msg is String:
              p.tryFailure(.RemoteServerError("\(msg)"))
          case .Success(let obj):
              let json = JSON(obj)
              let jsonError = json["errors"]
              if jsonError.hasKey {
                  p.tryFailure(.RemoteServerError("\(jsonError.object)"))
                  return
              }
              let arrayModel = json.array?.map { T(json: $0) }
              p.trySuccess(arrayModel!)
          case .Failure(_, let error):
              p.tryFailure(.AlamofireError(error))
          }
      }

      func responseSuccess(p: Promise<Bool, RepositoryError>, req: NSURLRequest?, res: NSHTTPURLResponse?, result: Result<AnyObject>) {
          if let statusCode = res?.statusCode {
              if statusCode == 201 || statusCode == 202 || statusCode == 204 {
                  p.trySuccess(true)
                  return
              }
          }
          switch result {
          case .Success(let msg) where msg is String:
              p.tryFailure(.RemoteServerError("\(msg)"))
          case .Success(let obj):
              let json = JSON(obj)
              let jsonError = json["errors"]
              if jsonError.hasKey {
                  p.tryFailure(.RemoteServerError("\(jsonError.object)"))
                  return
              }
              p.trySuccess(true)
          case .Failure(_, let error):
              p.tryFailure(.AlamofireError(error))
          }
      }

      func request<T : JsonModel>(method: Alamofire.Method, routes: String, param: [String:AnyObject]?) -> Future<T, RepositoryError> {
          let p = Promise<T, RepositoryError>()
          beforeRequest(routes)
          Alamofire.request(method, urlStr(routes), parameters: param)
              .responseJSON { (req, res, result) in
                  self.afterRequest(routes)
                  self.responseJson(p, req: req, res: res, result: result)
          }
          return p.future
      }

      func requestArray<T : JsonModel>(method: Alamofire.Method, routes: String, param: [String:AnyObject]?) -> Future<[T], RepositoryError> {
          let p = Promise<[T], RepositoryError>()
          beforeRequest(routes)
          Alamofire.request(method, urlStr(routes), parameters: param)
              .responseJSON { (req, res, result) in
                  self.afterRequest(routes)
                  self.responseJsonArray(p, req: req, res: res, result: result)
          }
          return p.future
      }

      func requestSuccess(method: Alamofire.Method, routes: String, param: [String: AnyObject]?) -> Future<Bool, RepositoryError> {
          let p = Promise<Bool, RepositoryError>()
          beforeRequest(routes)
          Alamofire.request(method, urlStr(routes), parameters: param)
              .responseJSON { (req, res, result) in
                  self.afterRequest(routes)
                  self.responseSuccess(p, req: req, res: res, result: result)
          }
          return p.future
      }

      func uploadStreamFileSuccess(stream: NSInputStream, routes: String, f: (Double) -> Void) -> Future<Bool, RepositoryError> {
          let p = Promise<Bool, RepositoryError>()
          beforeRequest(routes)
          Alamofire.upload(.POST, urlStr(routes), stream: stream)
              .progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                  let ratio: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                  f(ratio)
              }
              .responseJSON { req, res, result in
                  self.afterRequest(routes)
                  self.responseSuccess(p, req: req, res: res, result: result)
              }
          return p.future
      }

      func uploadStreamFile<T : JsonModel>(stream: NSInputStream, routes: String, f: (Double) -> Void) -> Future<T, RepositoryError> {
          let p = Promise<T, RepositoryError>()
          beforeRequest(routes)
          Alamofire.upload(.POST, urlStr(routes), stream: stream)
              .progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                  let ratio: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                  f(ratio)
              }
              .responseJSON { req, res, result in
                  self.afterRequest(routes)
                  self.responseJson(p, req: req, res: res, result: result)
              }
          return p.future
      }

      func uploadFileSuccess(url: NSURL, routes: String, f: (Double) -> Void) -> Future<Bool, RepositoryError> {
          let p = Promise<Bool, RepositoryError>()
          beforeRequest(routes)
          Alamofire.upload(.POST, urlStr(routes), file: url)
              .progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                  let ratio: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                  f(ratio)
              }
              .responseJSON { req, res, result in
                  self.afterRequest(routes)
                  self.responseSuccess(p, req: req, res: res, result: result)
              }

          return p.future
      }

      func uploadFile<T : JsonModel>(url: NSURL, routes: String, f: (Double) -> Void) -> Future<T, RepositoryError> {
          let p = Promise<T, RepositoryError>()
          beforeRequest(routes)
          Alamofire.upload(.POST, urlStr(routes), file: url)
              .progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                  let ratio: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                  f(ratio)
              }
              .responseJSON { req, res, result in
                  self.afterRequest(routes)
                  self.responseJson(p, req: req, res: res, result: result)
              }

          return p.future
      }

      func requestData<T : JsonModel>(method: Alamofire.Method, routes: String, param: [String: AnyObject]?) -> Future<T, RepositoryError> {
          let p = Promise<T, RepositoryError>()
          beforeRequest(routes)
          Alamofire.request(method, urlStr(routes), parameters: param)
              .responseJSON { req, res, result in
                  self.afterRequest(routes)
                  self.responseJsonData(p, req: req, res: res, result: result)
              }
          return p.future
      }

      func multipartFormData<T : JsonModel>(routes: String, progress: (Double) -> (), multipart: Alamofire.MultipartFormData -> ()) -> Future<T, RepositoryError> {
          let p = Promise<T, RepositoryError>()

          beforeRequest(routes)
          Alamofire.upload(.POST, urlStr(routes), multipartFormData: multipart,
              encodingCompletion: { encodingResult in
                  switch encodingResult {
                  case .Success(let upload, _, _):
                      upload.progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                          let ratio: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                          progress(ratio)
                      }
                      upload.responseJSON { (req, res, result) in
                          self.afterRequest(routes)
                          self.responseJson(p, req: req, res: res, result: result)
                      }
                  case .Failure(let encodingError):
                      p.tryFailure(.AlamofireError(encodingError))
                  }
          })

          return p.future
      }

      func multipartFormArray<T : JsonModel>(routes: String, progress: (Double) -> (), multipart: Alamofire.MultipartFormData -> ()) -> Future<[T], RepositoryError> {
          let p = Promise<[T], RepositoryError>()

          beforeRequest(routes)
          Alamofire.upload(.POST, urlStr(routes), multipartFormData: multipart,
              encodingCompletion: { encodingResult in
                  switch encodingResult {
                  case .Success(let upload, _, _):
                      upload.progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                          let ratio: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                          progress(ratio)
                      }
                      upload.responseJSON { req, res, result in
                          self.afterRequest(routes)
                          self.responseJsonArray(p, req: req, res: res, result: result)
                      }
                  case .Failure(let encodingError):
                      p.tryFailure(.AlamofireError(encodingError))
                  }
          })

          return p.future
      }

      func multipartFormDataSuccess(routes: String, progress: (Double) -> (), multipart: Alamofire.MultipartFormData -> ()) -> Future<Bool, RepositoryError> {
          let p = Promise<Bool, RepositoryError>()

          beforeRequest(routes)
          Alamofire.upload(.POST, urlStr(routes), multipartFormData: multipart,
              encodingCompletion: { encodingResult in
                  switch encodingResult {
                  case .Success(let upload, _, _):
                      upload.progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                          let ratio: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                          progress(ratio)
                      }
                      upload.responseJSON { req, res, result in
                          self.afterRequest(routes)
                          self.responseSuccess(p, req: req, res: res, result: result)
                      }
                  case .Failure(let encodingError):
                      p.tryFailure(.AlamofireError(encodingError))
                  }
          })

          return p.future
      }

      func parseMultipartForm(appendable: AnyObject, fileName: String, multipart: Alamofire.MultipartFormData, mimeType: String = "image/jpg") {
          if let data = appendable as? NSData {
              let ext = JsonUtil.mimeToExt(mimeType)
              let file = "\(fileName).\(ext)"
              multipart.appendBodyPart(data: data, name: fileName, fileName: file, mimeType: mimeType)
          }
          if let url = appendable as? NSURL {
              multipart.appendBodyPart(fileURL: url, name: fileName)
          }
      }

  }

  class JsonUtil {

      static func parseDate(year:Int, month:Int, day:Int) -> NSDate {
          let c = NSDateComponents()
          c.year = year
          c.month = month
          c.day = day

          let gregorian = NSCalendar(identifier:NSCalendarIdentifierGregorian)
          let date = gregorian!.dateFromComponents(c)
          return date!
      }

      static func parseDateTime(year:Int, month:Int, day:Int, hour:Int, min:Int, sec:Int) -> NSDate {
          let c = NSDateComponents()
          c.year = year
          c.month = month
          c.day = day
          c.hour = hour
          c.minute = min
          c.second = sec

          let gregorian = NSCalendar(identifier:NSCalendarIdentifierGregorian)
          let date = gregorian!.dateFromComponents(c)
          return date!
      }

      static func parseDate(json: JSON) -> NSDate {
          let year = json["year"].intValue
          let month = json["month"].intValue
          let day = json["day"].intValue
          return parseDate(year, month: month, day: day)
      }

      static func parseDateTime(json: JSON) -> NSDate {
          let year = json["year"].intValue
          let month = json["month"].intValue
          let day = json["day"].intValue
          let hour = json["hour"].intValue
          let min = json["min"].intValue
          let sec = json["sec"].intValue
          return parseDateTime(year, month: month, day: day, hour: hour, min: min, sec: sec)
      }

      static func dateComponent(date: NSDate, component : NSCalendarUnit) -> Int {
          let calendar = NSCalendar.currentCalendar()
          let components = calendar.components(component, fromDate: date)

          return components.valueForComponent(component)
      }

      static func toDateObj(date: NSDate) -> [String: Int] {
          return [
              "year": dateComponent(date, component: .Year),
              "month": dateComponent(date, component: .Month),
              "day": dateComponent(date, component: .Day)
          ]
      }

      static func toDateTimeObj(date: NSDate) -> [String: Int] {
          var dateObj = toDateObj(date)
          dateObj.updateValue(dateComponent(date, component: .Hour), forKey: "hour")
          dateObj.updateValue(dateComponent(date, component: .Minute), forKey: "min")
          dateObj.updateValue(dateComponent(date, component: .Second), forKey: "sec")
          return dateObj
      }

      static func mimeToExt(mime: String) -> String {
          return mime.componentsSeparatedByString("/")[1]
      }

  }
  """

end
