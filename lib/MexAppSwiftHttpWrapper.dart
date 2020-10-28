import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class MexAppSwiftHttpWrapper {
  static const MethodChannel _channel =
      const MethodChannel('MexAppSwiftHttpWrapper');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<Object> request(NetworkRequest request) async {
    print('request - ' + jsonEncode(request.toJson()));
    final Object response = await _channel.invokeMethod(
      'request',
      jsonEncode(request),
    );
    print('response - ' + response.toString());
    return response;
  }
}

class NetworkRequest {
  String apiHost;
  String endpoint;
  String method;
  Map<String, String> headers;
  Map<String, dynamic> params;

  NetworkRequest fromJson(Map<String, dynamic> json) => NetworkRequest()
    ..apiHost = json['apiHost'] as String
    ..endpoint = json['endpoint'] as String
    ..method = json['method'] as String
    ..headers = json['headers'] as Map<String, String>
    ..params = json['params'] as Map<String, dynamic>;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'apiHost': apiHost,
        'endpoint': endpoint,
        'method': method,
        'headers': headers,
        'params': params,
      };
}

class SwiftHttpError {
  int networkErrorCode;
  String invalidArgumentMessage;
  String unknownErrorMessage;

  SwiftHttpError();

  factory SwiftHttpError.fromJson(Map<String, dynamic> json) => SwiftHttpError()
    ..networkErrorCode = json['networkErrorCode'] as int
    ..invalidArgumentMessage = json['invalidArgumentMessage'] as String
    ..unknownErrorMessage = json['unknownErrorMessage'] as String;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'networkErrorCode': networkErrorCode,
        'invalidArgumentMessage': invalidArgumentMessage,
        'unknownErrorMessage': unknownErrorMessage,
      };
}
