import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';

class MethodChannelIOS {
  MethodChannel platform = const MethodChannel('wallet_connect_2');
  EventChannel eventChannel = const EventChannel('stream1');

  Future test() async {
    final String res = await platform.invokeMethod('getDeviceModel',
        {"flutterAppVersion": "0.0.1", "developerName": "XYZ"});
    print(res);
  }

  void initialize() {
    Map<String, dynamic> params = {
      "metadataName": "Example Wallet",
      "metadataDescription": "wallet description",
      "metadataUrl": "example.wallet",
      "metadataIcons": [
        "https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"
      ],
      "projectId": "4af2e046c7a7cbff0a96dc0f594b7e13",
      "relayHost": "relay.walletconnect.com"
    };

    platform.invokeMethod('initialize', params);
  }

  Future pair(String uri, Function onSuccess, Function onError) async {
    try {
      String result =
          await platform.invokeMethod('pair', <String, dynamic>{'uri': uri});
      print(result);
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future approve(String account) async {
    try {
      platform.invokeMethod('approve', <String, dynamic>{'account': account});
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future reject() async {
    try {
      platform.invokeMethod('reject');
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future disconnect(String topic) async {
    try {
      platform.invokeMethod('disconnect', <String, dynamic>{'topic': topic});
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future respondRequest(String sign) async {
    try {
      String result = await platform
          .invokeMethod('respondRequest', <String, dynamic>{'sign': sign});
      print(result);
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future rejectRequest() async {
    try {
      String result = await platform.invokeMethod('rejectRequest');
      print(result);
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future reloadActiveSessions() async {
    try {
      String result = await platform.invokeMethod('reloadSessions');
      log(json.decode(result).toString());
      return json.decode(result);
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future update(String topic, String account, List<String> chains) async {
    try {
      platform.invokeMethod('update', <String, dynamic>{
        'account': account,
        'topic': topic,
        'chains': chains
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future upgrade(String topic, List<String> chains, List<String> methods,
      {List<String> notifications = const []}) async {
    try {
      String a = await platform.invokeMethod('upgrade', <String, dynamic>{
        'topic': topic,
        'chains': chains,
        'methods': methods,
        'notifications': notifications
      });
      print(a);
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future ping(String topic) async {
    try {
      String a = await platform.invokeMethod('ping', <String, dynamic>{
        'topic': topic,
      });
      print(a);
    } on PlatformException catch (e) {
      return e;
    }
  }
}
