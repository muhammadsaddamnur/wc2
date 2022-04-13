import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_connect_v2_flutter/models/delete.dart';
import 'package:wallet_connect_v2_flutter/models/session_request.dart';
import 'package:wallet_connect_v2_flutter/models/sign/WCEthereumTransaction.dart';

import 'models/session_proposal.dart';

class EventChannelIOS {
  EventChannel eventChannel = const EventChannel('stream_wallet_connect_2');
  final Function(SessionProposal) onSessionProposal;
  final Function(SessionRequest)? onSessionRequest;
  final Function(Delete)? onDelete;

  final Function(dynamic)? onEthSendTransaction;
  final Function(int, WCEthereumTransaction)? onEthSignTransaction;
  final Function(String)? onPersonalSign;
  final Function(String)? onEthSign;
  final Function(String)? onEthSignTypedData;
  final Function(dynamic) onFailure;

  EventChannelIOS({
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

  void _onEvent(event) {
    if (event != null) {
      debugPrint(event);
      dynamic dec;
      dec = json.decode(event.toString().trim());
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
}
