import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_connect_v2_flutter/models/delete.dart';
import 'package:wallet_connect_v2_flutter/models/session_request.dart';
import 'package:wallet_connect_v2_flutter/models/sign/WCEthereumTransaction.dart';

import 'models/peer_meta.dart';
import 'models/session_proposal.dart';

class WC2Client {
  WC2Client({
    required this.onSessionProposal,
    required this.onFailure,
    this.onDelete,
    this.onSessionRequest,
    this.onEthSendTransaction,
    this.onEthSignTransaction,
    this.onPersonalSign,
    this.onEthSign,
    this.onEthSignTypedData,
  }) {
    if (!Platform.isAndroid) {
      eventChannel.receiveBroadcastStream().listen(_onEvent);
    } else {
      // streamPair().listen((event) {
      //   _onEvent(event);
      // });
      // streamDelegate().listen((event) {
      //   _onEvent(event);
      // });
      // streamApprove().listen((event) {
      //   _onEvent(event);
      // });
      // streamDisconnect().listen((event) {
      //   _onEvent(event);
      // });
      // streamReject().listen((event) {
      //   _onEvent(event);
      // });
      // streamRejectRequest().listen((event) {
      //   _onEvent(event);
      // });
      // streamRespondRequest().listen((event) {
      //   _onEvent(event);
      // });
      // streamSessionPing().listen((event) {
      //   _onEvent(event);
      // });
      // streamSessionUpdate().listen((event) {
      //   _onEvent(event);
      // });
      // streamSessionUpgrade().listen((event) {
      //   _onEvent(event);
      // });
      streamAndroid();
    }
  }

  streamAndroid() {
    eventChannelAndroid = StreamGroup.merge([
      streamDelegate(),
      streamPair(),
      streamDisconnect(),
      streamRespondRequest(),
      streamRejectRequest(),
      streamApprove(),
      streamReject(),
      streamSessionPing(),
      streamSessionUpdate(),
      streamSessionUpgrade()
    ]);
    eventChannelAndroid.listen((event) {
      _onEvent(event);
    });
  }

  final Function(SessionProposal) onSessionProposal;
  final Function(SessionRequest)? onSessionRequest;
  final Function(Delete)? onDelete;

  final Function(dynamic)? onEthSendTransaction;
  final Function(int, WCEthereumTransaction)? onEthSignTransaction;
  final Function(String)? onPersonalSign;
  final Function(String)? onEthSign;
  final Function(String)? onEthSignTypedData;
  final Function(dynamic) onFailure;

  /// event channel ==============================================================
  EventChannel eventChannel = const EventChannel('stream_wallet_connect_2');

  late Stream<dynamic> eventChannelAndroid;

  /// android
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

  void _onEvent(event) {
    if (event != null) {
      log(event);
      dynamic dec = json.decode(event.toString().trim());
      switch (dec["T"]) {
        case "sessionProposal":
          onSessionProposal(SessionProposal.fromJson(dec));
          break;
        case "delete":
          print(dec['value'] is String);
          if (onDelete != null) onDelete!(Delete.fromJson((dec)));
          break;
        case "sessionRequest":
          SessionRequest val = SessionRequest.fromJson(dec);
          if (onSessionRequest != null) onSessionRequest!(val);
          switch (val.value!.request!.method) {
            case 'eth_sendTransaction':
              if (onEthSendTransaction != null) onEthSendTransaction!(val);
              break;
            case 'eth_signTransaction':
              if (onEthSignTransaction != null) {
                // log(val.value!.toString());
                onEthSignTransaction!(
                    int.parse(val.value!.chainId!.split(":").last),
                    WCEthereumTransaction.fromJson(
                        val.value!.request!.params!.first));
              }
              break;
            case 'personal_sign':
              if (onPersonalSign != null) {
                var param = val.value!.request!.params!.first ?? '';
                onPersonalSign!(
                  (param ?? '') is Map ? json.encode(param) : param,
                );
              }
              break;
            case 'eth_sign':
              if (onEthSign != null) {
                var param = val.value!.request!.params!.last ?? '';
                onEthSign!(
                  (param) is Map ? json.encode(param) : param,
                );
              }
              break;
            case 'eth_signTypedData':
              if (onEthSignTypedData != null) {
                var param = val.value!.request!.params!.last ?? '';
                onEthSignTypedData!(
                  param is Map ? json.encode(param) : param,
                );
              }
              break;
            default:
          }
          break;
        default:
          onFailure(event);
      }
    } else {
      onFailure('Error');
    }
  }

  /// method channel ==============================================================
  MethodChannel platform = const MethodChannel('wallet_connect_2');

  initialize({required PeerMeta peerMeta}) async {
    platform.invokeMethod('initialize', peerMeta.toJson());
    if (Platform.isAndroid) {
      delegate();
    }
    // print(a);
  }

  Future pair(String uri) async {
    try {
      String a =
          await platform.invokeMethod('pair', <String, dynamic>{'uri': uri});
      print(a);

      // if (Platform.isAndroid) {
      //   print("wkwokwko");
      //   streamPair().listen((event) {
      //     print('evvvent' + event.toString());
      //     _onEvent(event);
      //   });
      // }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future delegate() async {
    try {
      platform.invokeMethod('delegate');

      // if (Platform.isAndroid) {
      //   streamDelegate().listen((event) {
      //     _onEvent(event);
      //   });
      // }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future approve(String account) async {
    try {
      platform.invokeMethod('approve', <String, dynamic>{'account': account});
      // if (Platform.isAndroid) {
      //   streamApprove().listen((event) {
      //     _onEvent(event);
      //   });
      // }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future reject() async {
    try {
      platform.invokeMethod('reject');
      // if (Platform.isAndroid) {
      //   streamReject().listen((event) {
      //     _onEvent(event);
      //   });
      // }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future disconnect(String topic) async {
    try {
      platform.invokeMethod('disconnect', <String, dynamic>{'topic': topic});
      // if (Platform.isAndroid) {
      //   streamDisconnect().listen((event) {
      //     _onEvent(event);
      //   });
      // }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future respondRequest(String sign) async {
    try {
      // String result = await platform
      //     .invokeMethod('respondRequest', <String, dynamic>{'sign': sign});
      // print(result);
      platform.invokeMethod('respondRequest', <String, dynamic>{'sign': sign});
      // if (Platform.isAndroid) {
      //   streamRespondRequest().listen((event) {
      //     _onEvent(event);
      //   });
      // }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future rejectRequest() async {
    try {
      // String result = await platform.invokeMethod('rejectRequest');
      // print(result);
      platform.invokeMethod('rejectRequest');
      // if (Platform.isAndroid) {
      //   streamRejectRequest().listen((event) {
      //     _onEvent(event);
      //   });
      // }
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
      // if (Platform.isAndroid) {
      //   streamSessionUpdate().listen((event) {
      //     _onEvent(event);
      //   });
      // }
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
      // if (Platform.isAndroid) {
      //   streamSessionUpgrade().listen((event) {
      //     _onEvent(event);
      //   });
      // }
    } on PlatformException catch (e) {
      return e;
    }
  }

  Future ping(String topic) async {
    try {
      await platform.invokeMethod('ping', <String, dynamic>{
        'topic': topic,
      });
      // if (Platform.isAndroid) {
      //   streamSessionPing().listen((event) {
      //     _onEvent(event);
      //   });
      // }
    } on PlatformException catch (e) {
      return e;
    }
  }

  /// android
  ///
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
