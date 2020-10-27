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
        print("handle " + call.method)
        
        switch call.method {
        case "get":
            guard let url = call.arguments as? String else {
                result(
                    FlutterError(
                        code: "invalidArgs",
                        message: "Missing URL argument",
                        details: "Expected 1 String argument"
                    )
                )
                return
            }
            handleGet(url, result)
        default:
            result("iOS " + UIDevice.current.systemVersion)
        }
        
    }
    
    public func handleGet(_ url: String, _ result: @escaping FlutterResult) {
        Alamofire.request(url).responseJSON{(response) in
            print(response)

            if let status = response.response?.statusCode {
                switch(status){
                case 200:
                    print("Success")
                default:
                    print("Error, status: \(status)")
                }
            }
            
            //to get JSON return value
            if let requestResult = response.result.value {
                //let data = requestResult as! NSDictionary
                print(requestResult)
                result(requestResult)
            }
        }
    }
    
}
