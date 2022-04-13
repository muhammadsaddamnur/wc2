import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:wallet_connect_v2_flutter/models/peer_meta.dart';

class MethodChannelIOS {
  MethodChannel platform = const MethodChannel('wallet_connect_2');

  void initialize(PeerMeta peerMeta) {
    platform.invokeMethod('initialize', peerMeta.toJson());
  }

  Future pair(String uri) async {
    try {
      await platform.invokeMethod('pair', <String, dynamic>{'uri': uri});
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

  Future sessionStore() async {
    try {
      String result = await platform.invokeMethod('sessionStore');
      log(json.decode(result).toString());
      return json.decode(result);
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future update({
    required String topic,
    required String account,
    required List<String> chains,
  }) async {
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

  Future upgrade({
    required String topic,
    required List<String> chains,
    required List<String> methods,
    List<String> notifications = const [],
  }) async {
    try {
      await platform.invokeMethod('upgrade', <String, dynamic>{
        'topic': topic,
        'chains': chains,
        'methods': methods,
        'notifications': notifications
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future ping(String topic) async {
    try {
      await platform.invokeMethod('ping', <String, dynamic>{
        'topic': topic,
      });
    } on PlatformException catch (e) {
      return e;
    }
  }
}
