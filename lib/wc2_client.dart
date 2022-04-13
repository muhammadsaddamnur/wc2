import 'dart:convert';
import 'dart:developer';

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
    eventChannel.receiveBroadcastStream().listen(_onEvent);
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

  void _onEvent(event) {
    if (event != null) {
      debugPrint(event);
      dynamic dec = json.decode(event.toString().trim());
      switch (dec["T"]) {
        case "sessionProposal":
          onSessionProposal(SessionProposal.fromJson(dec));
          break;
        case "delete":
          if (onDelete != null) onDelete!(Delete.fromJson(dec));
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
                onEthSignTransaction!(
                    int.parse(val.value!.chainId!.split(":").last),
                    WCEthereumTransaction.fromJson(
                        val.value!.request!.params!.first));
              }
              break;
            case 'personal_sign':
              if (onPersonalSign != null) {
                onPersonalSign!(val.value!.request!.params!.first ?? '');
              }
              break;
            case 'eth_sign':
              if (onEthSign != null) {
                onEthSign!(val.value!.request!.params!.last ?? '');
              }
              break;
            case 'eth_signTypedData':
              if (onEthSignTypedData != null) {
                onEthSignTypedData!(val.value!.request!.params!.last ?? '');
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

  initialize({required PeerMeta peerMeta}) {
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
