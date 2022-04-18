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
        gasLimit: json["gasLimit"] == null
            ? null
            : (json["gasLimit"] is String == true
                ? json["gasLimit"]
                : json["gasLimit"].toString()),
        value: json["value"] == null
            ? null
            : (json["value"] is String == true
                ? json["value"]
                : json["value"].toString()),
        gasPrice: json["gasPrice"] == null
            ? null
            : (json["gasPrice"] is String == true
                ? json["gasPrice"]
                : json["gasPrice"].toString()),
        to: json["to"],
        nonce: json["nonce"] == null
            ? null
            : (json["nonce"] is String == true
                ? json["nonce"]
                : json["nonce"].toString()),
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
