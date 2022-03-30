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

  Future disconnect(Function onSuccess, Function onError) async {
    try {
      String result = await platform.invokeMethod('disconnect');

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

  Future approve(
      List<String> accounts, Function onSuccess, Function onError) async {
    try {
      String result = await platform
          .invokeMethod('approve', <String, dynamic>{'accounts': accounts});

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

  Future respondRequest(
      String sign, Function onSuccess, Function onError) async {
    try {
      String result = await platform
          .invokeMethod('respondRequest', <String, dynamic>{'sign': sign});

      if (result == "onError") {
        print('error');
        onError;
      } else {
        print('success');
        onSuccess;
      }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future rejectRequest(Function onSuccess, Function onError) async {
    try {
      String result = await platform.invokeMethod('rejectRequest');

      if (result == "onError") {
        print('error');
        onError;
      } else {
        print('success');
        onSuccess;
      }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future sessionUpdate(
      List<String> accounts, Function onSuccess, Function onError) async {
    try {
      String result = await platform.invokeMethod(
          'sessionUpdate', <String, dynamic>{'accounts': accounts});

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

  Future sessionUpgrade(List<String> chains, List<String> jsonrpc,
      Function onSuccess, Function onError) async {
    try {
      String result =
          await platform.invokeMethod('sessionUpgrade', <String, dynamic>{
        'chains': chains,
        'jsonrpc': jsonrpc,
      });

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

  Future sessionPing(Function onSuccess, Function onError) async {
    try {
      String result = await platform.invokeMethod('sessionPing');

      if (result == "onSuccess") {
        print('success');
        onSuccess;
      } else {
        print('error : $result');
        onError;
      }
    } on PlatformException catch (e) {
      return e;
    }
  }
}
