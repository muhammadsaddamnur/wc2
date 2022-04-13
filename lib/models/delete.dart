// To parse this JSON data, do
//
//     final delete = deleteFromJson(jsonString);

import 'dart:convert';

Delete deleteFromJson(String str) => Delete.fromJson(json.decode(str));

String deleteToJson(Delete data) => json.encode(data.toJson());

class Delete {
  Delete({
    this.t,
    this.value,
  });

  String? t;
  Value? value;

  factory Delete.fromJson(Map<String, dynamic> json) => Delete(
        t: json["T"],
        value: json["value"] == null ? null : Value.fromJson(json["value"]),
      );

  Map<String, dynamic> toJson() => {
        "T": t,
        "value": value == null ? null : value!.toJson(),
      };
}

class Value {
  Value({
    this.topic,
    this.reason,
  });

  String? topic;
  Reason? reason;

  factory Value.fromJson(Map<String, dynamic> json) => Value(
        topic: json["topic"],
        reason: json["reason"] == null ? null : Reason.fromJson(json["reason"]),
      );

  Map<String, dynamic> toJson() => {
        "topic": topic,
        "reason": reason == null ? null : reason!.toJson(),
      };
}

class Reason {
  Reason({
    this.code,
    this.message,
  });

  String? code;
  String? message;

  factory Reason.fromJson(Map<String, dynamic> json) => Reason(
        code: json["code"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "message": message,
      };
}
