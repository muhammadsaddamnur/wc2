// To parse this JSON data, do
//
//     final sessionProposal = sessionProposalFromJson(jsonString);

import 'dart:convert';

SessionProposal sessionProposalFromJson(String str) =>
    SessionProposal.fromJson(json.decode(str));

String sessionProposalToJson(SessionProposal data) =>
    json.encode(data.toJson());

class SessionProposal {
  SessionProposal({
    this.t,
    this.value,
  });

  String? t;
  Value? value;

  factory SessionProposal.fromJson(Map<String, dynamic> json) =>
      SessionProposal(
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
    this.accounts,
    this.chains,
    this.description,
    this.icons,
    this.isController,
    this.methods,
    this.name,
    this.proposerPublicKey,
    this.relayProtocol,
    this.topic,
    this.ttl,
    this.url,
  });

  List<dynamic>? accounts;
  List<dynamic>? chains;
  String? description;
  List<dynamic>? icons;
  String? isController;
  List<dynamic>? methods;
  String? name;
  String? proposerPublicKey;
  String? relayProtocol;
  String? topic;
  String? ttl;
  String? url;

  factory Value.fromJson(Map<String, dynamic> json) => Value(
        accounts: json["accounts"] == null
            ? null
            : List<dynamic>.from(json["accounts"].map((x) => x)),
        chains: json["chains"] == null
            ? null
            : List<dynamic>.from(json["chains"].map((x) => x)),
        description: json["description"],
        icons: json["icons"] == null
            ? null
            : List<dynamic>.from(json["icons"].map((x) => x)),
        isController: json["isController"],
        methods: json["methods"] == null
            ? null
            : List<dynamic>.from(json["methods"].map((x) => x)),
        name: json["name"],
        proposerPublicKey: json["proposerPublicKey"],
        relayProtocol: json["relayProtocol"],
        topic: json["topic"],
        ttl: json["ttl"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "accounts": accounts == null
            ? null
            : List<dynamic>.from(accounts!.map((x) => x)),
        "chains":
            chains == null ? null : List<dynamic>.from(chains!.map((x) => x)),
        "description": description,
        "icons":
            icons == null ? null : List<dynamic>.from(icons!.map((x) => x)),
        "isController": isController,
        "methods":
            methods == null ? null : List<dynamic>.from(methods!.map((x) => x)),
        "name": name,
        "proposerPublicKey": proposerPublicKey,
        "relayProtocol": relayProtocol,
        "topic": topic,
        "ttl": ttl,
        "url": url,
      };
}
