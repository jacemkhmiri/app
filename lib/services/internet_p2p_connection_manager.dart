import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/database_service.dart';
import '../models/database_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

class InternetP2PConnectionManager {
  InternetP2PConnectionManager._internal();
  static final InternetP2PConnectionManager instance = InternetP2PConnectionManager._internal();

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  WebSocketChannel? _signalingChannel;
  String? _currentUserId;
  String? _signalingServerUrl;

  // Public STUN/TURN servers for internet connectivity
  static const List<Map<String, String>> _iceServers = [
    {
      'urls': 'stun:stun.l.google.com:19302',
    },
    {
      'urls': 'stun:stun1.l.google.com:19302',
    },
    {
      'urls': 'stun:stun2.l.google.com:19302',
    },
    {
      'urls': 'stun:stun3.l.google.com:19302',
    },
    {
      'urls': 'stun:stun4.l.google.com:19302',
    },
    // Add TURN servers for better connectivity (you can use free ones or paid services)
    {
      'urls': 'turn:openrelay.metered.ca:80',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
    {
      'urls': 'turn:openrelay.metered.ca:443',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
  ];

  Future<void> start(String userId, {String signalingServerUrl = 'wss://signaling-server.herokuapp.com'}) async {
    _currentUserId = userId;
    _signalingServerUrl = signalingServerUrl;
    
    try {
      // Connect to signaling server
      await _connectToSignalingServer();
      print('✅ Connected to signaling server');
    } catch (e) {
      print('❌ Failed to connect to signaling server: $e');
      // Fallback to local signaling (for development)
      await _startLocalSignaling();
    }
  }

  Future<void> _connectToSignalingServer() async {
    try {
      _signalingChannel = IOWebSocketChannel.connect(_signalingServerUrl!);
      
      _signalingChannel!.stream.listen(
        (message) async {
          await _handleSignalingMessage(message);
        },
        onError: (error) {
          print('Signaling server error: $error');
        },
        onDone: () {
          print('Signaling server disconnected');
        },
      );

      // Send user registration
      _sendSignalingMessage({
        'type': 'register',
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to connect to signaling server: $e');
    }
  }

  Future<void> _startLocalSignaling() async {
    // For development - create a simple local signaling mechanism
    print('🔄 Using local signaling fallback');
  }

  Future<void> _handleSignalingMessage(dynamic message) async {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String;

      switch (type) {
        case 'offer':
          await _handleOffer(data);
          break;
        case 'answer':
          await _handleAnswer(data);
          break;
        case 'ice-candidate':
          await _handleIceCandidate(data);
          break;
        case 'user-online':
          await _handleUserOnline(data);
          break;
        case 'user-offline':
          await _handleUserOffline(data);
          break;
        case 'typing':
          // TODO: Notify UI that user is typing
          break;
        case 'stop-typing':
          // TODO: Notify UI that user stopped typing
          break;
        case 'message-seen':
          // TODO: Update local message status to 'read'
          break;
      }
    } catch (e) {
      print('Error handling signaling message: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    final fromUserId = data['fromUserId'] as String;
    final offer = data['offer'] as Map<String, dynamic>;

    try {
      final pc = await _createPeerConnection(fromUserId);
      await pc.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      _sendSignalingMessage({
        'type': 'answer',
        'toUserId': fromUserId,
        'fromUserId': _currentUserId,
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
      });
    } catch (e) {
      print('Error handling offer: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    final fromUserId = data['fromUserId'] as String;
    final answer = data['answer'] as Map<String, dynamic>;

    try {
      final pc = _peerConnections[fromUserId];
      if (pc != null) {
        await pc.setRemoteDescription(
          RTCSessionDescription(answer['sdp'], answer['type']),
        );
      }
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    final fromUserId = data['fromUserId'] as String;
    final candidate = data['candidate'] as Map<String, dynamic>;

    try {
      final pc = _peerConnections[fromUserId];
      if (pc != null) {
        await pc.addCandidate(
          RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          ),
        );
      }
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }

  Future<void> _handleUserOnline(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    print('User online: $userId');
    // Update user status in your app
  }

  Future<void> _handleUserOffline(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    print('User offline: $userId');
    // Update user status in your app
  }

  Future<void> connectToUser(String targetUserId) async {
    if (_peerConnections.containsKey(targetUserId)) {
      print('Already connected to $targetUserId');
      return;
    }

    try {
      final pc = await _createPeerConnection(targetUserId);
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      _sendSignalingMessage({
        'type': 'offer',
        'toUserId': targetUserId,
        'fromUserId': _currentUserId,
        'offer': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
      });
    } catch (e) {
      print('Error connecting to user: $e');
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String remoteUserId) async {
    final config = {
      'iceServers': _iceServers,
      'iceCandidatePoolSize': 10,
    };

    final pc = await createPeerConnection(config);
    _peerConnections[remoteUserId] = pc;

    // Handle ICE candidates
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _sendSignalingMessage({
          'type': 'ice-candidate',
          'toUserId': remoteUserId,
          'fromUserId': _currentUserId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    // Handle data channels
    pc.onDataChannel = (channel) {
      _setupDataChannel(remoteUserId, channel);
    };

    // Create data channel for this connection
    final dataChannel = await pc.createDataChannel('messages', RTCDataChannelInit());
    _setupDataChannel(remoteUserId, dataChannel);

    return pc;
  }

  void _setupDataChannel(String remoteUserId, RTCDataChannel channel) {
    _dataChannels[remoteUserId] = channel;
    
    channel.onMessage = (message) async {
      try {
        final data = jsonDecode(message.text);
        await _handleDataChannelMessage(data);
      } catch (e) {
        print('Error handling data channel message: $e');
      }
    };
  }

  Future<void> _handleDataChannelMessage(Map<String, dynamic> data) async {
    try {
      final chatId = data['chatId'] as String;
      final senderId = data['senderId'] as String;
      final content = data['content'] as String;
      // final timestamp = DateTime.parse(data['timestamp'] as String);

      // Save message to local database
      final message = MessageModel.textMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
        encryptionKey: 'temp_key', // In production, handle encryption properly
      );
      await DatabaseService.saveMessage(message);
    } catch (e) {
      print('Error handling data channel message: $e');
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String recipientUserId,
    required String content,
  }) async {
    final channel = _dataChannels[recipientUserId];
    if (channel == null) {
      print('No data channel for user: $recipientUserId');
      return;
    }

    try {
      final message = {
        'chatId': chatId,
        'senderId': _currentUserId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      };

      channel.send(RTCDataChannelMessage(jsonEncode(message)));

      // Optionally emit a delivery hint to recipient via signaling
      _sendSignalingMessage({
        'type': 'delivery-hint',
        'toUserId': recipientUserId,
        'fromUserId': _currentUserId,
        'chatId': chatId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> sendTyping({required String toUserId, required bool isTyping}) async {
    _sendSignalingMessage({
      'type': isTyping ? 'typing' : 'stop-typing',
      'toUserId': toUserId,
      'fromUserId': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> sendSeen({required String toUserId, required String chatId, required String messageId}) async {
    _sendSignalingMessage({
      'type': 'message-seen',
      'toUserId': toUserId,
      'fromUserId': _currentUserId,
      'chatId': chatId,
      'messageId': messageId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _sendSignalingMessage(Map<String, dynamic> message) {
    if (_signalingChannel != null) {
      _signalingChannel!.sink.add(jsonEncode(message));
    }
  }

  Future<void> stop() async {
    // Close all peer connections
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();

    // Close all data channels
    for (final channel in _dataChannels.values) {
      await channel.close();
    }
    _dataChannels.clear();

    // Close signaling connection
    await _signalingChannel?.sink.close();
    _signalingChannel = null;
  }

  // Get list of online users (this would come from your backend)
  Future<List<String>> getOnlineUsers() async {
    // In a real implementation, this would query your backend
    return ['user_alice', 'user_bob', 'user_charlie'];
  }
}
