
import 'dart:async';

import 'package:flutter/services.dart';

class MexAppSwiftHttpWrapper {
  static const MethodChannel _channel =
      const MethodChannel('MexAppSwiftHttpWrapper');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future get(String url) async {
    final response = await _channel.invokeMethod('get', url);
    return response;
  }
}
