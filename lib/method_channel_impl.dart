import 'dart:convert';

import 'package:flutter/services.dart';

class MethodChannelImpl {
  static final MethodChannelImpl _intance = MethodChannelImpl._internal();

  MethodChannelImpl._internal();

  factory MethodChannelImpl() {
    return _intance;
  }

  MethodChannel platform = const MethodChannel('wallet_connect_2');
  EventChannel eventStreamDelegate = const EventChannel('streamDelegate');
  EventChannel eventStreamPair = const EventChannel('streamPair');
  EventChannel eventStreamDisconnect = const EventChannel('streamDisconnect');
  EventChannel eventStreamApprove = const EventChannel('streamApprove');
  EventChannel eventStreamReject = const EventChannel('streamReject');
  EventChannel eventStreamRespondRequest =
      const EventChannel('streamRespondRequest');
  EventChannel eventStreamRejectRequest =
      const EventChannel('streamRejectRequest');
  EventChannel eventStreamSessionUpdate =
      const EventChannel('streamSessionUpdate');
  EventChannel eventStreamSessionUpgrade =
      const EventChannel('streamSessionUpgrade');
  EventChannel eventStreamSessionPing = const EventChannel('streamSessionPing');

  Future pair(String uri, Function onSuccess, Function onError) async {
    try {
      platform.invokeMethod('pair', <String, dynamic>{'uri': uri});

      streamPair().listen((event) {
        print(
          'listen pair ' + event.toString(),
        );

        var dec = json.decode(event.toString());
        if (dec['T'] == 'onSuccess') {
          onSuccess;
        }
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future disconnect(Function onSuccess, Function onError) async {
    try {
      platform.invokeMethod('disconnect');
      streamDisconnect().listen((event) {
        print(
          'listen disconnect ' + event.toString(),
        );

        var dec = json.decode(event.toString());
        if (dec['T'] == 'onSuccess') {
          onSuccess;
        }
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future delegate() async {
    try {
      await platform.invokeMethod('delegate');
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future approve(
      List<String> accounts, Function onSuccess, Function onError) async {
    try {
      platform.invokeMethod('approve', <String, dynamic>{'accounts': accounts});

      streamApprove().listen((event) {
        print(
          'listen approve ' + event.toString(),
        );

        var dec = json.decode(event.toString());
        if (dec['T'] == 'onSuccess') {
          onSuccess;
        }
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future reject(Function onSuccess, Function onError) async {
    try {
      platform.invokeMethod('reject');

      streamReject().listen((event) {
        print(
          'listen reject ' + event.toString(),
        );

        var dec = json.decode(event.toString());
        if (dec['T'] == 'onSuccess') {
          onSuccess;
        }
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future respondRequest(
      String sign, Function onSuccess, Function onError) async {
    try {
      platform.invokeMethod('respondRequest', <String, dynamic>{'sign': sign});

      streamRespondRequest().listen((event) {
        print(
          'listen respond request ' + event.toString(),
        );
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future rejectRequest(Function onSuccess, Function onError) async {
    try {
      await platform.invokeMethod('rejectRequest');

      streamRejectRequest().listen((event) {
        print(
          'listen reject request ' + event.toString(),
        );
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future sessionUpdate(
      List<String> accounts, Function onSuccess, Function onError) async {
    try {
      platform.invokeMethod(
          'sessionUpdate', <String, dynamic>{'accounts': accounts});

      streamSessionUpdate().listen((event) {
        print(
          'listen session update ' + event.toString(),
        );

        var dec = json.decode(event.toString());
        if (dec['T'] == 'onSuccess') {
          onSuccess;
        }
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future sessionUpgrade(List<String> chains, List<String> jsonrpc,
      Function onSuccess, Function onError) async {
    try {
      platform.invokeMethod('sessionUpgrade', <String, dynamic>{
        'chains': chains,
        'jsonrpc': jsonrpc,
      });

      streamSessionUpgrade().listen((event) {
        print(
          'listen session upgrade ' + event.toString(),
        );

        var dec = json.decode(event.toString());
        if (dec['T'] == 'onSuccess') {
          onSuccess;
        }
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future sessionPing(Function onSuccess, Function onError) async {
    try {
      platform.invokeMethod('sessionPing');

      streamSessionPing().listen((event) {
        print(
          'listen session ping ' + event.toString(),
        );

        var dec = json.decode(event.toString());
        if (dec['T'] == 'onSuccess') {
          onSuccess;
        }
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  Stream streamDelegate() {
    return eventStreamDelegate.receiveBroadcastStream().asBroadcastStream();
  }

  Stream streamPair() {
    return eventStreamPair.receiveBroadcastStream().asBroadcastStream();
  }

  Stream streamDisconnect() {
    return eventStreamDisconnect.receiveBroadcastStream().asBroadcastStream();
  }

  Stream streamApprove() {
    return eventStreamApprove.receiveBroadcastStream().asBroadcastStream();
  }

  Stream streamReject() {
    return eventStreamReject.receiveBroadcastStream().asBroadcastStream();
  }

  Stream streamRespondRequest() {
    return eventStreamRespondRequest
        .receiveBroadcastStream()
        .asBroadcastStream();
  }

  Stream streamRejectRequest() {
    return eventStreamRejectRequest
        .receiveBroadcastStream()
        .asBroadcastStream();
  }

  Stream streamSessionUpdate() {
    return eventStreamSessionUpdate
        .receiveBroadcastStream()
        .asBroadcastStream();
  }

  Stream streamSessionUpgrade() {
    return eventStreamSessionUpgrade
        .receiveBroadcastStream()
        .asBroadcastStream();
  }

  Stream streamSessionPing() {
    return eventStreamSessionPing.receiveBroadcastStream().asBroadcastStream();
  }
}
