// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cryptography/cryptography.dart';

void main() {
  runApp(MyApp());
}

/// Replace with your deployed signaling server URL
/// After deploying to Render.com, update this with your URL:
/// Example: const SIGNALING_SERVER = 'https://your-p2p-server.onrender.com';
const SIGNALING_SERVER = 'https://p2p-signaling-server-1.onrender.com';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class SignedPost {
  final String author; // base64 pubkey
  final int seq;
  final int timestamp;
  final String text;
  final String sig; // base64 signature
  final bool verified;
  final bool local;
  SignedPost({
    required this.author,
    required this.seq,
    required this.timestamp,
    required this.text,
    required this.sig,
    required this.verified,
    required this.local,
  });
}

class _MyAppState extends State<MyApp> {
  // WebRTC
  RTCPeerConnection? pc;
  RTCDataChannel? dataChannel;
  final Map<String, dynamic> rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // Add TURN here if needed
    ]
  };

  // Signaling
  IO.Socket? socket;
  String roomId = '';
  bool isInitiator = false;

  // Crypto (Ed25519)
  final algorithm = Ed25519();
  SimpleKeyPair? keyPair;
  SimplePublicKey? publicKey;
  int seq = 0;

  // UI state
  String myPubBase64 = '';
  List<SignedPost> feed = [];
  final TextEditingController postController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController serverController =
      TextEditingController(text: SIGNALING_SERVER);

  @override
  void dispose() {
    dataChannel?.close();
    pc?.close();
    socket?.disconnect();
    postController.dispose();
    roomController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // no-op
  }

  Future<void> generateKeys() async {
    final kp = await algorithm.newKeyPair();
    final pub = await kp.extractPublicKey();
    setState(() {
      keyPair = kp;
      publicKey = pub;
      myPubBase64 = base64Encode(pub.bytes);
    });
  }

  // canonical stable stringify for payload (simple)
  String stableStringify(Map<String, dynamic> obj) {
    final keys = obj.keys.toList()..sort();
    final map = <String, dynamic>{};
    for (final k in keys) map[k] = obj[k];
    return jsonEncode(map);
  }

  Future<String> signPayload(Map<String, dynamic> payload) async {
    if (keyPair == null) throw Exception('No keypair generated');
    final msg = utf8.encode(stableStringify(payload));
    final signature = await algorithm.sign(
      msg,
      keyPair: keyPair!,
    );
    return base64Encode(signature.bytes);
  }

  Future<bool> verifyPayload(
      Map<String, dynamic> payload, String base64Sig, String base64Pub) async {
    try {
      final pubBytes = base64Decode(base64Pub);
      final pubKey = SimplePublicKey(pubBytes, type: KeyPairType.ed25519);
      final sigBytes = base64Decode(base64Sig);
      final msg = utf8.encode(stableStringify(payload));
      return await algorithm.verify(msg, signature: Signature(sigBytes, publicKey: pubKey));
    } catch (e) {
      return false;
    }
  }

  Future<void> _createPeerConnection({required bool initiator}) async {
    pc = await createPeerConnection(rtcConfig);

    pc!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        final data = {
          'type': 'ice',
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex
          }
        };
        socket?.emit('signal', {'room': roomId, 'data': data});
      }
    };

    pc!.onSignalingState = (state) {
      print('Signaling state: $state');
    };

    pc!.onIceConnectionState = (state) {
      print('ICE connection state: $state');
    };

    // Data channel for posts
    if (initiator) {
      dataChannel = await pc!.createDataChannel('p2p-feed', RTCDataChannelInit());
      _setupDataChannel();
    } else {
      pc!.onDataChannel = (RTCDataChannel dc) {
        dataChannel = dc;
        _setupDataChannel();
      };
    }
  }

  void _setupDataChannel() {
    if (dataChannel == null) return;
    dataChannel!.onMessage = (RTCDataChannelMessage message) async {
      try {
        final txt = message.text;
        final obj = jsonDecode(txt) as Map<String, dynamic>;
        // Extract fields
        final author = obj['author'] as String;
        final seq = obj['seq'] as int;
        final timestamp = obj['timestamp'] as int;
        final content = obj['content']?['text'] as String? ?? '';
        final sig = obj['sig'] as String;
        final payload = {
          'author': author,
          'seq': seq,
          'timestamp': timestamp,
          'content': {'text': content}
        };
        final ok = await verifyPayload(payload, sig, author.replaceFirst('did:local:', ''));
        setState(() {
          feed.insert(
              0,
              SignedPost(
                  author: author,
                  seq: seq,
                  timestamp: timestamp,
                  text: content,
                  sig: sig,
                  verified: ok,
                  local: false));
        });
      } catch (e) {
        print('Bad incoming data: $e');
      }
    };

    dataChannel!.onDataChannelState = (state) {
      print('DC state: $state');
    };
  }

  Future<void> startSignaling() async {
    final serverUrl = serverController.text.trim();
    if (serverUrl.isEmpty) return;
    // Connect to signaling server
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
    });

    socket!.on('connect', (_) {
      print('connected to signaling server ${socket!.id}');
      socket!.emit('join', roomId);
    });

    socket!.on('peer-joined', (data) {
      print('peer joined: $data');
    });

    socket!.on('signal', (data) async {
      // data: could be {type:'offer'/'answer'/'ice', sdp/candidate}
      print('got signal: $data');
      final Map d = Map.from(data);
      final type = d['type'];
      if (type == 'offer') {
        // remote offer -> setRemote -> create answer
        final sdp = d['sdp'];
        await pc?.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
        final answer = await pc!.createAnswer();
        await pc!.setLocalDescription(answer);
        socket?.emit('signal', {'room': roomId, 'data': {'type': 'answer', 'sdp': answer.sdp}});
      } else if (type == 'answer') {
        final sdp = d['sdp'];
        await pc?.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
      } else if (type == 'ice') {
        final c = d['candidate'];
        await pc?.addCandidate(RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
      }
    });

    socket!.on('disconnect', (_) {
      print('signaling disconnected');
    });

    socket!.connect();
  }

  Future<void> createOfferAndSend() async {
    if (pc == null) {
      await _createPeerConnection(initiator: true);
    }
    final offer = await pc!.createOffer({'offerToReceiveAudio': false, 'offerToReceiveVideo': false});
    await pc!.setLocalDescription(offer);
    socket?.emit('signal', {'room': roomId, 'data': {'type': 'offer', 'sdp': offer.sdp}});
  }

  Future<void> createAnswerFlow() async {
    if (pc == null) {
      await _createPeerConnection(initiator: false);
    }
    // Wait for remote offer via signaling; code in socket.on('signal') will handle it
  }

  Future<void> sendSignedPost(String text) async {
    if (dataChannel == null || dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('DataChannel not open')));
      return;
    }
    final author = 'did:local:${myPubBase64}';
    seq += 1;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'author': author,
      'seq': seq,
      'timestamp': timestamp,
      'content': {'text': text}
    };
    final sig = await signPayload(payload);
    final msg = {...payload, 'sig': sig};
    final jsonMsg = jsonEncode(msg);
    dataChannel!.send(RTCDataChannelMessage(jsonMsg));
    setState(() {
      feed.insert(
          0,
          SignedPost(
              author: author, seq: seq, timestamp: timestamp, text: text, sig: sig, verified: true, local: true));
    });
  }

  Widget buildFeedItem(SignedPost p) {
    return ListTile(
      title: Text(p.text),
      subtitle: Text('${p.author} • seq ${p.seq} • ${DateTime.fromMillisecondsSinceEpoch(p.timestamp).toLocal()}'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(p.local ? 'local' : 'remote', style: TextStyle(fontSize: 12)),
          Text('verified: ${p.verified}', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P2P Text Feed (Flutter)',
      home: Scaffold(
        appBar: AppBar(title: Text('P2P Text Feed — Flutter')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            Row(children: [
              ElevatedButton(onPressed: generateKeys, child: Text('Generate Keys')),
              SizedBox(width: 8),
              Expanded(child: SelectableText(myPubBase64.isEmpty ? 'Public key not generated' : myPubBase64))
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: serverController,
                  decoration: InputDecoration(labelText: 'Signaling server (http(s)://host:port)'),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                  onPressed: () async {
                    // set room id and start socket
                    if (roomController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter room id first')));
                      return;
                    }
                    roomId = roomController.text.trim();
                    await startSignaling();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected to signaling')));
                  },
                  child: Text('Connect'))
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: roomController,
                decoration: InputDecoration(labelText: 'Room ID (share with peer)'),
              )),
              SizedBox(width: 8),
              ElevatedButton(
                  onPressed: () async {
                    // create offer (initiator)
                    isInitiator = true;
                    await _createPeerConnection(initiator: true);
                    await createOfferAndSend();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Offer created & sent')));
                  },
                  child: Text('Create Offer')),
              SizedBox(width: 8),
              ElevatedButton(
                  onPressed: () async {
                    // answer flow (non-initiator)
                    isInitiator = false;
                    await _createPeerConnection(initiator: false);
                    // Wait for incoming offer via signaling; answer will be produced automatically when offer arrives
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Waiting for offer...')));
                  },
                  child: Text('Be Answerer'))
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: postController,
                decoration: InputDecoration(labelText: 'Write a text-only post'),
              )),
              SizedBox(width: 8),
              ElevatedButton(
                  onPressed: () async {
                    final txt = postController.text.trim();
                    if (txt.isEmpty) return;
                    await sendSignedPost(txt);
                    postController.clear();
                  },
                  child: Text('Send'))
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: feed.length,
                itemBuilder: (context, i) => buildFeedItem(feed[i]),
              ),
            )
          ]),
        ),
      ),
    );
  }
}