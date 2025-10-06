import 'dart:convert';

enum PeerConnectionState { connecting, connected, disconnected, failed }

enum SignalingMessageType { discovery, offer, answer, ice }

class DiscoveryInfo {
  final String deviceId;
  final String userId;
  final String username;
  final String publicKey;
  final String ip;
  final int port;

  DiscoveryInfo({
    required this.deviceId,
    required this.userId,
    required this.username,
    required this.publicKey,
    required this.ip,
    required this.port,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'userId': userId,
        'username': username,
        'publicKey': publicKey,
        'ip': ip,
        'port': port,
      };

  static DiscoveryInfo fromJson(Map<String, dynamic> json) => DiscoveryInfo(
        deviceId: json['deviceId'] as String,
        userId: json['userId'] as String,
        username: json['username'] as String,
        publicKey: json['publicKey'] as String,
        ip: json['ip'] as String,
        port: (json['port'] as num).toInt(),
      );

  String encode() => jsonEncode(toJson());
  static DiscoveryInfo decode(String s) => fromJson(jsonDecode(s));
}

class SignalingMessage {
  final SignalingMessageType type;
  final String fromDeviceId;
  final String toDeviceId;
  final Map<String, dynamic> payload;

  SignalingMessage({
    required this.type,
    required this.fromDeviceId,
    required this.toDeviceId,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'fromDeviceId': fromDeviceId,
        'toDeviceId': toDeviceId,
        'payload': payload,
      };

  static SignalingMessage fromJson(Map<String, dynamic> json) =>
      SignalingMessage(
        type: SignalingMessageType.values
            .firstWhere((e) => e.name == json['type'] as String),
        fromDeviceId: json['fromDeviceId'] as String,
        toDeviceId: json['toDeviceId'] as String,
        payload: (json['payload'] as Map).cast<String, dynamic>(),
      );

  String encode() => jsonEncode(toJson());
  static SignalingMessage decode(String s) => fromJson(jsonDecode(s));
}

class DataChannelMessage {
  final String chatId;
  final String senderUserId;
  final String cipherText;
  final String symmetricKeyCipher;
  final DateTime timestamp;

  DataChannelMessage({
    required this.chatId,
    required this.senderUserId,
    required this.cipherText,
    required this.symmetricKeyCipher,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'chatId': chatId,
        'senderUserId': senderUserId,
        'cipherText': cipherText,
        'symmetricKeyCipher': symmetricKeyCipher,
        'timestamp': timestamp.toIso8601String(),
      };

  static DataChannelMessage fromJson(Map<String, dynamic> json) =>
      DataChannelMessage(
        chatId: json['chatId'] as String,
        senderUserId: json['senderUserId'] as String,
        cipherText: json['cipherText'] as String,
        symmetricKeyCipher: json['symmetricKeyCipher'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  String encode() => jsonEncode(toJson());
  static DataChannelMessage decode(String s) => fromJson(jsonDecode(s));
}
