// To parse this JSON data, do
//
//     final WCEthereumTransaction = WCEthereumTransactionFromJson(jsonString);

import 'dart:convert';

// ignore: non_constant_identifier_names
WCEthereumTransaction WCEthereumTransactionFromJson(String str) =>
    WCEthereumTransaction.fromJson(json.decode(str));

// ignore: non_constant_identifier_names
String WCEthereumTransactionToJson(WCEthereumTransaction data) =>
    json.encode(data.toJson());

class WCEthereumTransaction {
  WCEthereumTransaction({
    required this.from,
    required this.data,
    this.gasLimit,
    this.value,
    this.gasPrice,
    required this.to,
    this.nonce,
  });

  String from;
  String data;
  String? gasLimit;
  String? value;
  String? gasPrice;
  String to;
  String? nonce;

  factory WCEthereumTransaction.fromJson(Map<String, dynamic> json) =>
      WCEthereumTransaction(
        from: json["from"],
        data: json["data"],
        gasLimit: json["gasLimit"],
        value: json["value"],
        gasPrice: json["gasPrice"],
        to: json["to"],
        nonce: json["nonce"],
      );

  Map<String, dynamic> toJson() => {
        "from": from,
        "data": data,
        "gasLimit": gasLimit,
        "value": value,
        "gasPrice": gasPrice,
        "to": to,
        "nonce": nonce,
      };
}
