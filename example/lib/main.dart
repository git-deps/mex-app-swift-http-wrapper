import 'package:flutter/material.dart';
import 'package:MexAppSwiftHttpWrapper/MexAppSwiftHttpWrapper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _response;
  SwiftHttpError? _error;

  @override
  void initState() {
    super.initState();
    _getMarkets();
  }

  _getMarkets() async {
    await MexAppSwiftHttpWrapper.setTimeout(5);
    await MexAppSwiftHttpWrapper.setRetryCount(0);
    final response = await MexAppSwiftHttpWrapper.request(NetworkRequest(
      apiHost: 'https://app-api-int.jfrex.com',
      endpoint: '/v1/instrument',
      method: 'get'
    ));

    if (response is SwiftHttpError) {
      setState(() => _error = response);
    } else {
      setState(() => _response = response as String?);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black54,
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(10.0),
          child: Column(
            children: [
              _text('Result of get request:'),
              if (_response == null && _error == null)
                Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              if (_response != null)
                _text('Success response: ' + _response!) ,
              if (_error != null)
                _text('Error: ' + _error!.toJson().toString())
            ],
          ),
        ),
      ),
    );
  }

  Widget _text(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontFamily: "Courier",
        height: 1.2,
      ),
    );
  }
}
