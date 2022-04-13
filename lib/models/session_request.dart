// To parse this JSON data, do
//
//     final sessionRequest = sessionRequestFromJson(jsonString);

import 'dart:convert';

SessionRequest sessionRequestFromJson(String str) =>
    SessionRequest.fromJson(json.decode(str));

String sessionRequestToJson(SessionRequest data) => json.encode(data.toJson());

class SessionRequest {
  SessionRequest({
    this.t,
    this.value,
  });

  String? t;
  Value? value;

  factory SessionRequest.fromJson(Map<String, dynamic> json) => SessionRequest(
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
    this.chainId,
    this.topic,
    this.request,
  });

  String? chainId;
  String? topic;
  Request? request;

  factory Value.fromJson(Map<String, dynamic> json) => Value(
        chainId: json["chainId"],
        topic: json["topic"],
        request:
            json["request"] == null ? null : Request.fromJson(json["request"]),
      );

  Map<String, dynamic> toJson() => {
        "chainId": chainId,
        "topic": topic,
        "request": request == null ? null : request!.toJson(),
      };
}

class Request {
  Request({
    this.method,
    this.id,
    this.params,
  });

  String? method;
  int? id;
  List<dynamic>? params;

  factory Request.fromJson(Map<String, dynamic> json) => Request(
        method: json["method"],
        id: json["id"],
        params: json["params"] == null
            ? null
            : List<dynamic>.from(json["params"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "method": method,
        "id": id,
        "params":
            params == null ? null : List<dynamic>.from(params!.map((x) => x)),
      };
}
