import 'dart:async';
import '../models/webrtc_models.dart';

typedef SignalingMessageHandler = Future<void> Function(SignalingMessage msg);

class SignalingService {
  final String serviceName;
  final DiscoveryInfo localInfo;
  final SignalingMessageHandler onMessage;
  final int udpPort;

  SignalingService({
    required this.serviceName,
    required this.localInfo,
    required this.onMessage,
    this.udpPort = 53535,
  });

  Future<void> start() async {}
  Future<void> stop() async {}
  Future<List<DiscoveryInfo>> discover(
          {Duration timeout = const Duration(seconds: 2)}) async =>
      <DiscoveryInfo>[];
  Future<void> send(
      SignalingMessage message, dynamic address, int port) async {}
}

