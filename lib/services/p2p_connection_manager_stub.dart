import '../models/webrtc_models.dart';
import '../services/signaling_service.dart';

class P2PConnectionManager {
  P2PConnectionManager._internal();
  static final P2PConnectionManager instance = P2PConnectionManager._internal();

  Future<void> start(
      SignalingService signaling, DiscoveryInfo localInfo) async {}
  Future<void> stop() async {}
  Future<void> connectToPeer(DiscoveryInfo remote) async {}
  Future<void> handleSignalingMessage(SignalingMessage msg) async {}
  Future<void> sendTextMessage(
      {required String chatId,
      required String senderUserId,
      required String plainText,
      required String recipientUserId}) async {}
}

