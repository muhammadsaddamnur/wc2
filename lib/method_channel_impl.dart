import 'package:flutter/services.dart';

class MethodChannelImpl {
  static const platform = MethodChannel('wallet_connect_2');
  static const eventChannel = EventChannel('streamDelegate');

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
      // String result = await platform.invokeMethod('delegate');

      // switch (result) {
      //   case 'onSessionProposal':
      //     print('onSessionProposal');
      //     break;
      //   case 'onSessionRequest':
      //     print('onSessionRequest');
      //     break;
      //   case 'onSessionDelete':
      //     print('onSessionDelete');
      //     break;
      //   case 'onSessionNotification':
      //     print('onSessionNotification');
      //     break;
      // }
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
}
