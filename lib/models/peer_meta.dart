// To parse this JSON data, do
//
//     final peerMeta = peerMetaFromJson(jsonString);

import 'dart:convert';

PeerMeta peerMetaFromJson(String str) => PeerMeta.fromJson(json.decode(str));

String peerMetaToJson(PeerMeta data) => json.encode(data.toJson());

class PeerMeta {
  PeerMeta({
    this.metadataName,
    this.metadataDescription,
    this.metadataUrl,
    this.metadataIcons,
    this.projectId,
    this.relayHost,
  });

  String? metadataName;
  String? metadataDescription;
  String? metadataUrl;
  List<String>? metadataIcons;
  String? projectId;
  String? relayHost;

  factory PeerMeta.fromJson(Map<String, dynamic> json) => PeerMeta(
        metadataName: json["metadataName"],
        metadataDescription: json["metadataDescription"],
        metadataUrl: json["metadataUrl"],
        metadataIcons: json["metadataIcons"] == null
            ? null
            : List<String>.from(json["metadataIcons"].map((x) => x)),
        projectId: json["projectId"],
        relayHost: json["relayHost"],
      );

  Map<String, dynamic> toJson() => {
        "metadataName": metadataName,
        "metadataDescription": metadataDescription,
        "metadataUrl": metadataUrl,
        "metadataIcons": metadataIcons == null
            ? null
            : List<dynamic>.from(metadataIcons!.map((x) => x)),
        "projectId": projectId,
        "relayHost": relayHost,
      };
}
