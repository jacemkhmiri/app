import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/webrtc_models.dart';

typedef SignalingMessageHandler = Future<void> Function(SignalingMessage msg);

class SignalingService {
  final String serviceName;
  final DiscoveryInfo localInfo;
  final SignalingMessageHandler onMessage;
  final int udpPort;

  RawDatagramSocket? _udpSocket;
  MDnsClient? _mdns;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _started = false;

  SignalingService({
    required this.serviceName,
    required this.localInfo,
    required this.onMessage,
    this.udpPort = 53535,
  });

  Future<void> start() async {
    if (_started) return;
    _started = true;

    await _bindUdp();
    await _startMdns();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) async {
      await stop();
      await start();
    });
  }

  Future<void> stop() async {
    _started = false;
    _mdns?.stop();
    _mdns = null;
    _udpSocket?.close();
    _udpSocket = null;
    await _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> _bindUdp() async {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
    _udpSocket!.readEventsEnabled = true;
    _udpSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _udpSocket!.receive();
        if (dg == null) return;
        try {
          final jsonStr = utf8.decode(dg.data);
          final msg = SignalingMessage.decode(jsonStr);
          if (msg.toDeviceId == localInfo.deviceId) {
            onMessage(msg);
          }
        } catch (_) {}
      }
    });
  }

  Future<void> _startMdns() async {
    _mdns = MDnsClient(rawDatagramSocketFactory: (host, int port,
        {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) {
      return RawDatagramSocket.bind(InternetAddress.anyIPv4, port,
          reuseAddress: reuseAddress, reusePort: reusePort, ttl: ttl);
    });
    await _mdns!.start();

    // Note: multicast_dns v0.3.2 does not support service registration
    // Only service discovery is supported via lookup()
  }

  Future<List<DiscoveryInfo>> discover(
      {Duration timeout = const Duration(seconds: 2)}) async {
    final results = <DiscoveryInfo>[];
    final fullname = '_$serviceName._udp.local';
    final completer = Completer<void>();

    _mdns
        ?.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(fullname))
        .listen((ptr) async {
      await for (final txt in _mdns!.lookup<TxtResourceRecord>(
          ResourceRecordQuery.text(ptr.domainName))) {
        try {
          final info = DiscoveryInfo.decode(txt.text);
          if (info.deviceId != localInfo.deviceId) {
            results.add(info);
          }
        } catch (_) {}
      }
    }, onDone: () => completer.complete());

    await completer.future.timeout(timeout, onTimeout: () {});
    return results;
  }

  Future<void> send(
      SignalingMessage message, InternetAddress address, int port) async {
    final socket = _udpSocket;
    if (socket == null) return;
    final data = utf8.encode(message.encode());
    socket.send(data, address, port);
  }
}
