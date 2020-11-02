import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class MexAppSwiftHttpWrapper {
  static const MethodChannel _channel = const MethodChannel('SwiftHttpWrapper');

  /// Make a network request with the given [request] object
  /// Returns server response as [String] or [SwiftHttpError] object in case
  /// of some error
  static Future<Object> request(NetworkRequest request) async {
    final Object response = await _channel.invokeMethod(
      'request',
      jsonEncode(request),
    );

    if (response is Map && response['swiftHttpError'] != null) {
      return SwiftHttpError.fromJson(response['swiftHttpError']);
    }

    return response;
  }

  /// Set timeout value (double). Default value is 2.0
  static Future setTimeout(double timeoutSeconds) async {
    return _channel.invokeMethod('setTimeout', timeoutSeconds);
  }

  /// Set retry count value (int). Default value is 3 times
  static Future<Object> setRetryCount(int retryCount) async {
    return _channel.invokeMethod('setRetryCount', retryCount);
  }
}

/// Object for sending the network request
class NetworkRequest {
  /// Host, for example "https://main3-cn.duedex.com:12343"
  /// Include protocol and port
  String apiHost;

  /// Endpoint path, for example "v1/user"
  /// Can be without "/" at start
  String endpoint;

  /// Http method. Allowed get/, post, delete, patch, put \
  /// Returns an error if use not supported method
  String method;

  /// Headers as a map
  Map<String, String> headers;

  /// Params as a map
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

/// Error object which SwiftHttpWrapper returns in case of any error
class SwiftHttpError {
  /// Network code like 500, 401, 400
  /// Returns of we have an error while doing network request
  /// That mean all parameters was OK and we actually DID the network
  /// request, and actually GET answer from server, but it has an error
  int networkErrorCode;

  /// If the server returns us an error and some data, we put data here
  String networkErrorData;

  /// Some argument is wrong. We did NOT perform the network requests yet.
  /// Just returns an error because some argument was wrong
  String invalidArgumentMessage;

  /// Some unknown error happens in any place
  String unknownErrorMessage;

  /// We faced timeout exception for some reason
  /// Implementation have default values: timeout = 2 seconds, retry count = 3
  /// you can set your own values by [setTimeout] and [setRetryCount]
  /// wrapper tried to perform request with that timeout and retry count
  /// and if fails - return timeout error
  bool timeout;

  SwiftHttpError();

  factory SwiftHttpError.fromJson(Map json) => SwiftHttpError()
    ..networkErrorCode = json['networkErrorCode'] as int
    ..networkErrorData = json['networkErrorData']
    ..invalidArgumentMessage = json['invalidArgumentMessage'] as String
    ..unknownErrorMessage = json['unknownErrorMessage'] as String
    ..timeout = json['timeout'] as bool;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'networkErrorCode': networkErrorCode,
        'networkErrorData': networkErrorData,
        'invalidArgumentMessage': invalidArgumentMessage,
        'unknownErrorMessage': unknownErrorMessage,
        'timeout': timeout,
      };
}
