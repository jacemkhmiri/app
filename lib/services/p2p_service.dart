import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

class P2PService extends ChangeNotifier {
  // Singleton pattern
  static final P2PService _instance = P2PService._internal();
  factory P2PService() => _instance;
  P2PService._internal();

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  String? _currentUserId;
  String? _currentUsername;
  String? _signalingServerUrl;

  // WebRTC
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ]
  };

  // Socket.io for signaling
  IO.Socket? _socket;
  
  // Crypto
  final _algorithm = Ed25519();
  SimpleKeyPair? _keyPair;
  SimplePublicKey? _publicKey;
  String _myPubBase64 = '';
  
  // Active rooms/chats
  final Map<String, String> _activeRooms = {}; // chatId -> roomId
  final Map<String, List<Map<String, dynamic>>> _pendingMessages = {};
  
  // Callbacks for UI updates
  Function(String chatId, Map<String, dynamic> message)? onMessageReceived;
  Function(String userId, bool isOnline)? onUserStatusChanged;
  Function(String chatId, bool isTyping)? onTypingStatusChanged;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;
  String? get currentUserId => _currentUserId;
  String? get currentUsername => _currentUsername;
  String get publicKey => _myPubBase64;

  Future<void> initialize({
    required String userId,
    required String username,
    required String signalingServerUrl,
  }) async {
    if (_isConnecting || _isConnected) {
      print('P2P Service already initialized or connecting');
      return;
    }

    _isConnecting = true;
    _connectionStatus = 'Connecting...';
    notifyListeners();

    try {
      _currentUserId = userId;
      _currentUsername = username;
      _signalingServerUrl = signalingServerUrl;

      // Generate crypto keys
      await _generateKeys();

      // Connect to signaling server
      await _connectToSignalingServer();

      _isConnected = true;
      _isConnecting = false;
      _connectionStatus = 'Connected';
      notifyListeners();

      print('✅ P2P Service initialized successfully');
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Failed to connect';
      notifyListeners();
      throw Exception('Failed to initialize P2P: $e');
    }
  }

  Future<void> _generateKeys() async {
    _keyPair = await _algorithm.newKeyPair();
    _publicKey = await _keyPair!.extractPublicKey();
    _myPubBase64 = base64Encode(_publicKey!.bytes);
    print('🔑 Generated Ed25519 key pair');
  }

  Future<void> _connectToSignalingServer() async {
    _socket = IO.io(_signalingServerUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 5,
    });

    _socket!.on('connect', (_) {
      print('✅ Connected to signaling server: ${_socket!.id}');
      _connectionStatus = 'Connected';
      notifyListeners();
      
      // Register user
      _socket!.emit('register', {
        'userId': _currentUserId,
        'username': _currentUsername,
        'publicKey': _myPubBase64,
      });
    });

    _socket!.on('user-registered', (data) {
      print('✅ User registered: $data');
    });

    _socket!.on('user-online', (data) {
      final userId = data['userId'];
      onUserStatusChanged?.call(userId, true);
    });

    _socket!.on('user-offline', (data) {
      final userId = data['userId'];
      onUserStatusChanged?.call(userId, false);
    });

    _socket!.on('room-created', (data) {
      print('Room created: $data');
    });

    _socket!.on('peer-joined', (data) {
      print('Peer joined room: $data');
      final roomId = data['roomId'];
      final peerId = data['peerId'];
      _handlePeerJoined(roomId, peerId);
    });

    _socket!.on('signal', (data) async {
      await _handleSignal(data);
    });

    _socket!.on('message', (data) {
      _handleMessage(data);
    });

    _socket!.on('typing', (data) {
      final chatId = data['chatId'];
      final isTyping = data['isTyping'];
      onTypingStatusChanged?.call(chatId, isTyping);
    });

    _socket!.on('disconnect', (_) {
      print('❌ Disconnected from signaling server');
      _connectionStatus = 'Disconnected';
      _isConnected = false;
      notifyListeners();
    });

    _socket!.on('error', (error) {
      print('❌ Socket error: $error');
      _connectionStatus = 'Error';
      notifyListeners();
    });

    _socket!.connect();
    
    // Wait for connection
    await Future.delayed(const Duration(seconds: 2));
    if (!_socket!.connected) {
      throw Exception('Failed to connect to signaling server');
    }
  }

  Future<String> startChat(String chatId, String recipientUserId) async {
    // Generate or get room ID for this chat
    String roomId = _activeRooms[chatId] ?? const Uuid().v4();
    _activeRooms[chatId] = roomId;

    // Join or create room
    _socket?.emit('join-room', {
      'roomId': roomId,
      'chatId': chatId,
      'userId': _currentUserId,
      'recipientUserId': recipientUserId,
    });

    // Create peer connection if needed
    if (!_peerConnections.containsKey(recipientUserId)) {
      await _createPeerConnection(recipientUserId, isInitiator: true);
    }

    return roomId;
  }

  Future<void> _handlePeerJoined(String roomId, String peerId) async {
    if (peerId == _currentUserId) return;

    // Create peer connection for the new peer
    if (!_peerConnections.containsKey(peerId)) {
      await _createPeerConnection(peerId, isInitiator: false);
    }
  }

  Future<void> _createPeerConnection(String peerId, {required bool isInitiator}) async {
    final pc = await createPeerConnection(_rtcConfig);
    _peerConnections[peerId] = pc;

    // Handle ICE candidates
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _socket?.emit('signal', {
          'to': peerId,
          'from': _currentUserId,
          'type': 'ice',
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    // Handle connection state changes
    pc.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state with $peerId: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        _connectionStatus = 'Peer connected';
        notifyListeners();
      }
    };

    // Create or handle data channel
    if (isInitiator) {
      final dc = await pc.createDataChannel('chat', RTCDataChannelInit());
      _setupDataChannel(dc, peerId);
      
      // Create and send offer
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      
      _socket?.emit('signal', {
        'to': peerId,
        'from': _currentUserId,
        'type': 'offer',
        'sdp': offer.sdp,
      });
    } else {
      pc.onDataChannel = (RTCDataChannel dc) {
        _setupDataChannel(dc, peerId);
      };
    }
  }

  void _setupDataChannel(RTCDataChannel dc, String peerId) {
    _dataChannels[peerId] = dc;

    dc.onMessage = (RTCDataChannelMessage message) {
      final data = jsonDecode(message.text);
      _handleDataChannelMessage(peerId, data);
    };

    dc.onDataChannelState = (RTCDataChannelState state) {
      print('Data channel state with $peerId: $state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        // Send any pending messages
        _sendPendingMessages(peerId);
      }
    };
  }

  Future<void> _handleSignal(Map<String, dynamic> data) async {
    final from = data['from'];
    final type = data['type'];
    
    if (from == _currentUserId) return;

    final pc = _peerConnections[from];
    if (pc == null && type != 'offer') return;

    switch (type) {
      case 'offer':
        if (pc == null) {
          await _createPeerConnection(from, isInitiator: false);
        }
        final sdp = data['sdp'];
        await _peerConnections[from]!.setRemoteDescription(
          RTCSessionDescription(sdp, 'offer'),
        );
        final answer = await _peerConnections[from]!.createAnswer();
        await _peerConnections[from]!.setLocalDescription(answer);
        
        _socket?.emit('signal', {
          'to': from,
          'from': _currentUserId,
          'type': 'answer',
          'sdp': answer.sdp,
        });
        break;

      case 'answer':
        final sdp = data['sdp'];
        await pc!.setRemoteDescription(
          RTCSessionDescription(sdp, 'answer'),
        );
        break;

      case 'ice':
        final candidate = data['candidate'];
        await pc!.addCandidate(
          RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          ),
        );
        break;
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final message = data['message'];
    onMessageReceived?.call(chatId, message);
  }

  void _handleDataChannelMessage(String peerId, Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'message':
        final chatId = data['chatId'];
        final message = data['message'];
        onMessageReceived?.call(chatId, message);
        break;
      case 'typing':
        final chatId = data['chatId'];
        final isTyping = data['isTyping'];
        onTypingStatusChanged?.call(chatId, isTyping);
        break;
      case 'seen':
        // Handle message seen status
        break;
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String recipientUserId,
    required String content,
    String? messageId,
  }) async {
    final message = {
      'type': 'message',
      'chatId': chatId,
      'message': {
        'id': messageId ?? const Uuid().v4(),
        'senderId': _currentUserId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    // Try to send via data channel first
    final dc = _dataChannels[recipientUserId];
    if (dc != null && dc.state == RTCDataChannelState.RTCDataChannelOpen) {
      dc.send(RTCDataChannelMessage(jsonEncode(message)));
    } else {
      // Fallback to signaling server or queue message
      _socket?.emit('message', {
        'to': recipientUserId,
        'from': _currentUserId,
        ...message,
      });
      
      // Queue message for later
      _pendingMessages[recipientUserId] ??= [];
      _pendingMessages[recipientUserId]!.add(message);
    }
  }

  void sendTypingStatus(String chatId, String recipientUserId, bool isTyping) {
    final data = {
      'type': 'typing',
      'chatId': chatId,
      'isTyping': isTyping,
    };

    final dc = _dataChannels[recipientUserId];
    if (dc != null && dc.state == RTCDataChannelState.RTCDataChannelOpen) {
      dc.send(RTCDataChannelMessage(jsonEncode(data)));
    } else {
      _socket?.emit('typing', {
        'to': recipientUserId,
        'from': _currentUserId,
        ...data,
      });
    }
  }

  void _sendPendingMessages(String peerId) {
    final pending = _pendingMessages[peerId];
    if (pending == null || pending.isEmpty) return;

    final dc = _dataChannels[peerId];
    if (dc == null || dc.state != RTCDataChannelState.RTCDataChannelOpen) return;

    for (final message in pending) {
      dc.send(RTCDataChannelMessage(jsonEncode(message)));
    }
    
    _pendingMessages[peerId]!.clear();
  }

  Future<void> disconnect() async {
    // Close all peer connections
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();

    // Close all data channels
    for (final dc in _dataChannels.values) {
      await dc.close();
    }
    _dataChannels.clear();

    // Disconnect from signaling server
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _isConnected = false;
    _connectionStatus = 'Disconnected';
    _activeRooms.clear();
    _pendingMessages.clear();
    
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
