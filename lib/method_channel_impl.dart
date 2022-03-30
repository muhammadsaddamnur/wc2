import 'package:flutter/services.dart';

class MethodChannelImpl {
  static final MethodChannelImpl _intance = MethodChannelImpl._internal();

  MethodChannelImpl._internal();

  factory MethodChannelImpl() {
    return _intance;
  }

  MethodChannel platform = const MethodChannel('wallet_connect_2');
  EventChannel eventChannel = const EventChannel('streamDelegate');

  Future pair(String uri, Function onSuccess, Function onError) async {
    try {
      String result =
          await platform.invokeMethod('pair', <String, dynamic>{'uri': uri});

      if (result == "onSuccess") {
        print('success');
        onSuccess;
      } else {
        print('error');
        onError;
      }
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

  Stream streamDelegate() {
    return eventChannel.receiveBroadcastStream().asBroadcastStream();
  }

  Future approve(Function onSuccess, Function onError) async {
    try {
      String result = await platform.invokeMethod('approve');

      if (result == "onSuccess") {
        print('success');
        onSuccess;
      } else {
        print('error');
        onError;
      }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future reject(Function onSuccess, Function onError) async {
    try {
      String result = await platform.invokeMethod('reject');

      if (result == "onSuccess") {
        print('success');
        onSuccess;
      } else {
        print('error');
        onError;
      }
    } on PlatformException catch (e) {
      return e;
    }
  }
}
