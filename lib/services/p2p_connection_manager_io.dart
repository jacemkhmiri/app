import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/webrtc_models.dart';
import '../services/signaling_service.dart';
import '../services/encryption_service.dart';
import '../services/database_service.dart';
import '../models/database_models.dart';

class P2PConnectionManager {
  P2PConnectionManager._internal();
  static final P2PConnectionManager instance = P2PConnectionManager._internal();

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  SignalingService? _signaling;
  DiscoveryInfo? _localInfo;

  Future<void> start(
      SignalingService signaling, DiscoveryInfo localInfo) async {
    _signaling = signaling;
    _localInfo = localInfo;
    await _signaling!.start();
  }

  Future<void> stop() async {
    await _signaling?.stop();
    _signaling = null;
    _localInfo = null;
    for (final dc in _dataChannels.values) {
      await dc.close();
    }
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _dataChannels.clear();
    _peerConnections.clear();
  }

  Future<void> connectToPeer(DiscoveryInfo remote) async {
    if (_peerConnections.containsKey(remote.deviceId)) return;
    final pc = await _createPeer(remote.deviceId);
    final dcInit = RTCDataChannelInit()..ordered = true;
    final dc = await pc.createDataChannel('data', dcInit);
    _setupDataChannel(remote.deviceId, dc);

    final offer = await pc.createOffer(
        {'offerToReceiveAudio': false, 'offerToReceiveVideo': false});
    await pc.setLocalDescription(offer);
    await _sendSignaling(remote, 'offer', {
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  Future<void> handleSignalingMessage(SignalingMessage msg) async {
    final remoteId = msg.fromDeviceId;
    if (msg.type == SignalingMessageType.offer) {
      final pc = await _createPeer(remoteId);
      await pc.setRemoteDescription(
          RTCSessionDescription(msg.payload['sdp'], msg.payload['type']));
      final answer = await pc.createAnswer(
          {'offerToReceiveAudio': false, 'offerToReceiveVideo': false});
      await pc.setLocalDescription(answer);
      final discovery = await _getDiscoveryByDeviceId(remoteId);
      if (discovery != null) {
        await _sendSignaling(discovery, 'answer', {
          'sdp': answer.sdp,
          'type': answer.type,
        });
      }
    } else if (msg.type == SignalingMessageType.answer) {
      final pc = _peerConnections[remoteId];
      if (pc != null) {
        await pc.setRemoteDescription(
            RTCSessionDescription(msg.payload['sdp'], msg.payload['type']));
      }
    } else if (msg.type == SignalingMessageType.ice) {
      final pc = _peerConnections[remoteId];
      if (pc != null) {
        final cand = RTCIceCandidate(msg.payload['candidate'],
            msg.payload['sdpMid'], msg.payload['sdpMLineIndex']);
        await pc.addCandidate(cand);
      }
    }
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String senderUserId,
    required String plainText,
    required String recipientUserId,
  }) async {
    final discovery = DatabaseService.discoveryBox.get(recipientUserId);
    if (discovery == null) return;
    final remoteDeviceId = discovery.deviceId;
    var dc = _dataChannels[remoteDeviceId];
    if (dc == null) {
      await connectToPeer(DiscoveryInfo(
        deviceId: discovery.deviceId,
        userId: discovery.userId,
        username: '',
        publicKey: discovery.publicKey,
        ip: discovery.ipAddress,
        port: 53535,
      ));
      dc = _dataChannels[remoteDeviceId];
    }
    if (dc == null) return;

    String symmetricKey = EncryptionService.generateSymmetricKey();
    final cipherText =
        EncryptionService.symmetricEncrypt(plainText, symmetricKey);
    final symmetricKeyCipher =
        EncryptionService.encryptMessage(symmetricKey, discovery.publicKey);
    final payload = DataChannelMessage(
      chatId: chatId,
      senderUserId: senderUserId,
      cipherText: cipherText,
      symmetricKeyCipher: symmetricKeyCipher,
      timestamp: DateTime.now(),
    );
    dc.send(RTCDataChannelMessage(payload.encode()));
  }

  Future<RTCPeerConnection> _createPeer(String remoteDeviceId) async {
    final config = {
      'iceServers': [
        {
          'urls': ['stun:stun.l.google.com:19302']
        },
      ]
    };
    final pc = await createPeerConnection(config);
    _peerConnections[remoteDeviceId] = pc;
    pc.onIceCandidate = (c) async {
      final discovery = await _getDiscoveryByDeviceId(remoteDeviceId);
      if (discovery != null && c.candidate != null) {
        await _sendSignaling(discovery, 'ice', {
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        });
      }
    };
    pc.onDataChannel = (channel) {
      _setupDataChannel(remoteDeviceId, channel);
    };
    return pc;
  }

  void _setupDataChannel(String remoteDeviceId, RTCDataChannel channel) {
    _dataChannels[remoteDeviceId] = channel;
    channel.onMessage = (msg) async {
      try {
        final decoded = DataChannelMessage.decode(msg.text);
        final currentUser = DatabaseService.getCurrentUser();
        if (currentUser == null) return;
        final symmetricKey = EncryptionService.decryptMessage(
            decoded.symmetricKeyCipher, currentUser.privateKey);
        final plain = EncryptionService.symmetricDecrypt(
            decoded.cipherText, symmetricKey);
        final message = MessageModel.textMessage(
          chatId: decoded.chatId,
          senderId: decoded.senderUserId,
          content: plain,
          encryptionKey: symmetricKey,
        );
        await DatabaseService.saveMessage(message);
      } catch (_) {}
    };
  }

  Future<void> _sendSignaling(
      DiscoveryInfo remote, String type, Map<String, dynamic> payload) async {
    final signaling = _signaling;
    final local = _localInfo;
    if (signaling == null || local == null) return;
    final msg = SignalingMessage(
      type: SignalingMessageType.values.firstWhere((e) => e.name == type,
          orElse: () => SignalingMessageType.offer),
      fromDeviceId: local.deviceId,
      toDeviceId: remote.deviceId,
      payload: payload,
    );
    await signaling.send(msg, InternetAddress(remote.ip), remote.port);
  }

  Future<DiscoveryInfo?> _getDiscoveryByDeviceId(String deviceId) async {
    final list = DatabaseService.discoveryBox.values.toList();
    for (final d in list) {
      if (d.deviceId == deviceId) {
        return DiscoveryInfo(
          deviceId: d.deviceId,
          userId: d.userId,
          username: '',
          publicKey: d.publicKey,
          ip: d.ipAddress,
          port: 53535,
        );
      }
    }
    return null;
  }
}

