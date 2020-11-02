import Flutter
import UIKit
import Alamofire

public class SwiftMexAppSwiftHttpWrapperPlugin: NSObject, FlutterPlugin {
    
    var sessionManager : SessionManager = SessionManager()
    let defaultTimeout : Double = 2.0
    let defaultRetryCount : Int = 3
    var retryCount : Int?

    public override init() {
        super.init()
        self.initSessionManager(defaultTimeout)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "SwiftHttpWrapper", binaryMessenger: registrar.messenger())
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
        case "setTimeout":
            guard let timeout : Double = call.arguments as? Double else {
                result(argumentMissingError("timeout"))
                return
            }
            initSessionManager(timeout)
            result(true)
            return
        case "setRetryCount":
            guard let retryCount : Int = call.arguments as? Int else {
                result(argumentMissingError("retryCount"))
                return
            }
            self.retryCount = retryCount
            result(true)
            return
        default:
            result(argumentNotSupportedError("method", call.method))
            return
        }
        
    }
    
    func initSessionManager(_ timeout: Double) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        sessionManager = SessionManager(configuration: configuration)
    }
    
    func handleRequest(_ request: NetworkRequest, _ result: @escaping FlutterResult) {
        
        print(request.endpoint)
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
        
        sessionManager.retrier = RetryHandler(retryCount ?? defaultRetryCount) {
            result(self.timeoutError())
        }
        
        sessionManager.request(
            request.apiHost + "/" + request.endpoint,
            method: httpMethod,
            parameters: request.params,
            encoding: httpMethod == .get ? URLEncoding.default : JSONEncoding.default,
            headers: request.headers
        ).response { response in
            let responseDataAsString : String = String(decoding: response.data!, as: UTF8.self)
            //print(response)
            print("response data as string - " + responseDataAsString)
            //print(response.response?.statusCode)
            
            if let status = response.response?.statusCode {
                switch(status) {
                case 200:
                    // return to Flutter response data as string
                    result(responseDataAsString)
                default:
                    // return to Flutter error status code and data
                    result(self.networkError(status, responseDataAsString))
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
    
    func networkError(_ statusCode: Int, _ data: String?) -> [String: Any?] {
        return SwiftHttpError(
            networkErrorCode: statusCode,
            networkErrorData: data
        ).toDictionary()
    }
    
    func timeoutError() -> [String: Any?] {
        return SwiftHttpError(timeout: true).toDictionary()
    }
    
    func unknownError(_ error: Error) -> [String: Any?] {
        return SwiftHttpError(unknownErrorMessage: error.localizedDescription).toDictionary()
    }
}

class RetryHandler: RequestRetrier {
    
    let retryCount: Int
    let onTimeout: () -> ()
    
    init(_ retryCount: Int, _ onTimeout: @escaping () -> ()) {
        self.retryCount = retryCount
        self.onTimeout = onTimeout
    }
    
    public func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: RequestRetryCompletion) {
        print("should")
        
        if let code = (error as? URLError)?.code {
            switch code {
            case .timedOut:
                print("timeoutException")
                if (request.retryCount <= retryCount) {
                    completion(true, 0.0)
                } else {
                    onTimeout()
                }
                return
            default:
                completion(false, 0.0)
                return
            }
        }
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
    var networkErrorData: String?
    var invalidArgumentMessage: String?
    var unknownErrorMessage: String?
    var timeout: Bool
    
    init (networkErrorCode: Int? = nil,
          networkErrorData: String? = nil,
          invalidArgumentMessage: String? = nil,
          unknownErrorMessage: String? = nil,
          timeout: Bool = false) {
        self.networkErrorCode = networkErrorCode
        self.networkErrorData = networkErrorData
        self.invalidArgumentMessage = invalidArgumentMessage
        self.unknownErrorMessage = unknownErrorMessage
        self.timeout = timeout
    }
    
    func toDictionary() -> [String: Any?] {
        return [
            "swiftHttpError": [
                "networkErrorCode": networkErrorCode as Any,
                "networkErrorData": networkErrorData as Any,
                "invalidArgumentMessage": invalidArgumentMessage as Any,
                "unknownErrorMessage": unknownErrorMessage as Any,
                "timeout": timeout as Any,
            ],
        ]
    }
}
