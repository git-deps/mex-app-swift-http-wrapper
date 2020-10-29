import Flutter
import UIKit
import Alamofire

public class SwiftMexAppSwiftHttpWrapperPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "MexAppSwiftHttpWrapper", binaryMessenger: registrar.messenger())
        let instance = SwiftMexAppSwiftHttpWrapperPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("handle - method: \(call.method)")
        
        switch call.method {
        case "request":
            guard let requestString : String = call.arguments as? String else {
                result(argumentMissingError("request"))
                return
            }
            do {
                let request = try NetworkRequest(requestString)
                handleRequest(request, result)
            } catch {
                print("Unexpected error: \(error).")
                result(unknownError(error))
                return
            }
            return
        default:
            result(argumentNotSupportedError("method", call.method))
            return
        }
        
    }
    
    func handleRequest(_ request: NetworkRequest, _ result: @escaping FlutterResult) {
        
        var httpMethod : HTTPMethod = .get
        
        switch request.method.lowercased() {
        case "get":
            httpMethod = .get
        case "post":
            httpMethod = .post
        case "delete":
            httpMethod = .delete
        case "patch":
            httpMethod = .patch
        case "put":
            httpMethod = .put
        default:
            result(argumentNotSupportedError("method", request.method))
            return
        }
        
        Alamofire.request(
            request.apiHost + "/" + request.endpoint,
            method: httpMethod,
            parameters: request.params,
            encoding: httpMethod == .get ? URLEncoding.default : JSONEncoding.default,
            headers: request.headers
        ).responseJSON{(response) in
            print("Actual server return data - " + String(decoding: response.data!, as: UTF8.self))
            
            if let status = response.response?.statusCode {
                switch(status) {
                case 200:
                    // return to Flutter exact the same data we received from API
                    if let requestResult = response.result.value {
                        print(requestResult)
                        result(String(decoding: response.data!, as: UTF8.self))
                    }
                default:
                    // return to Flutter error status code and data, maybe
                    result(self.networkError(status, response.result.value))
                    return
                }
            }
        }
    }
    
    func argumentMissingError(_ parameterName: String) -> [String: Any?] {
        return SwiftHttpError(invalidArgumentMessage: "Missing '\(parameterName)' argument").toDictionary()
    }
    
    func argumentNotSupportedError(_ parameterName: String, _ parameterValue: String) -> [String: Any?] {
        return SwiftHttpError(invalidArgumentMessage: "'\(parameterName)' argument can not take value of '\(parameterValue)'").toDictionary()
    }
    
    func networkError(_ statusCode: Int, _ data: Any?) -> [String: Any?] {
        return SwiftHttpError(
            networkErrorCode: statusCode,
            networkErrorData: data
        ).toDictionary()
    }
    
    func unknownError(_ error: Error) -> [String: Any?] {
        return SwiftHttpError(unknownErrorMessage: error.localizedDescription).toDictionary()
    }
}

struct NetworkRequest {
    var apiHost: String
    var endpoint: String
    var method: String
    var headers: [String: String]?
    var params: [String: Any]?
    
    init (_ json: String) throws {
                        
        // make sure this JSON is in the format we expect
        guard let json = try JSONSerialization.jsonObject(with: Data(json.utf8), options: []) as? [String: Any] else {
            throw NSError()
        }
        
        apiHost = json["apiHost"] as! String
        endpoint = json["endpoint"] as! String
        method = json["method"] as! String
        headers = json["headers"] as? [String: String]
        params = json["params"] as? [String: Any]
    }
}

struct SwiftHttpError {
    var networkErrorCode: Int?
    var networkErrorData: Any?
    var invalidArgumentMessage: String?
    var unknownErrorMessage: String?
    
    init (networkErrorCode: Int? = nil,
          networkErrorData: Any? = nil,
          invalidArgumentMessage: String? = nil,
          unknownErrorMessage: String? = nil) {
        self.networkErrorCode = networkErrorCode
        self.networkErrorData = networkErrorData
        self.invalidArgumentMessage = invalidArgumentMessage
        self.unknownErrorMessage = unknownErrorMessage
    }
    
    func toDictionary() -> [String: Any?] {
        return [
            "swiftHttpError": [
                "networkErrorCode": networkErrorCode as Any,
                "networkErrorData": networkErrorData as Any,
                "invalidArgumentMessage": invalidArgumentMessage as Any,
                "unknownErrorMessage": unknownErrorMessage as Any,
            ],
        ]
    }
}
