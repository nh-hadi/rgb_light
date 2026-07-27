import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

enum EspConnectionState { disconnected, connecting, connected }

class EspUdpService {
  static final EspUdpService _instance = EspUdpService._internal();
  factory EspUdpService() => _instance;
  EspUdpService._internal();

  RawDatagramSocket? _socket;
  Timer? _heartbeatTimer;
  DateTime _lastResponseTime = DateTime.now().subtract(const Duration(seconds: 10));

  final ValueNotifier<EspConnectionState> connectionState =
      ValueNotifier<EspConnectionState>(EspConnectionState.disconnected);

  final ValueNotifier<Map<String, dynamic>?> espStateNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  static const String _espIp = '192.168.4.1';
  static const int _espPort = 8888;

  void init() async {
    if (_socket != null) return;
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = true; // Mengizinkan broadcast sinyal UDP

      _socket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data).trim();
            if (message.startsWith('STATE:')) {
              _handleStateResponse(message);
            }
          }
        }
      });

      // Mulai Heartbeat & Query Status Otomatis setiap 2 detik
      _startHeartbeat();
    } catch (e) {
      debugPrint('UDP Bind Error: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    queryState();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      queryState();

      // Jika ada respons dari ESP dalam 5 detik terakhir, set terhubung
      final now = DateTime.now();
      if (now.difference(_lastResponseTime).inMilliseconds > 5000) {
        connectionState.value = EspConnectionState.disconnected;
      }
    });
  }

  void queryState() {
    _send('Q');
  }

  void _handleStateResponse(String message) {
    try {
      final parts = message.substring(6).split(',');
      if (parts.length >= 6) {
        final r = int.parse(parts[0]);
        final g = int.parse(parts[1]);
        final b = int.parse(parts[2]);
        final brightness = int.parse(parts[3]);
        final modeId = int.parse(parts[4]);
        final speedMs = int.parse(parts[5]);

        _lastResponseTime = DateTime.now();
        connectionState.value = EspConnectionState.connected;

        espStateNotifier.value = {
          'color': Color.fromARGB(255, r, g, b),
          'brightness': brightness.toDouble(),
          'modeId': modeId,
          'speedMs': speedMs.toDouble(),
        };
      }
    } catch (e) {
      debugPrint('Error Parse State UDP: $e');
    }
  }

  void _send(String message) {
    if (_socket == null) {
      init();
    }
    try {
      final data = message.codeUnits;
      // Kirim ke IP spesifik 192.168.4.1
      _socket?.send(data, InternetAddress(_espIp), _espPort);
      // Kirim juga ke Broadcast Address 255.255.255.255 untuk jaminan penerimaan 100%
      _socket?.send(data, InternetAddress('255.255.255.255'), _espPort);
    } catch (e) {
      debugPrint('UDP Send Error: $e');
    }
  }

  // Pengiriman Warna Real-Time via UDP
  void sendColor(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    _send('C:$r,$g,$b');
  }

  void sendColorDirect(Color color) => sendColor(color);

  // Pengiriman Kecerahan Real-Time via UDP
  void sendBrightness(int brightness) {
    final val = brightness.clamp(0, 255);
    _send('B:$val');
  }

  void sendBrightnessDirect(int brightness) => sendBrightness(brightness);

  // Pengiriman Kecepatan Real-Time via UDP
  void sendSpeed(int speedMs) {
    final val = speedMs.clamp(100, 3000);
    _send('S:$val');
  }

  void sendSpeedDirect(int speedMs) => sendSpeed(speedMs);

  // Pengiriman Mode Efek Real-Time via UDP
  void sendMode(int modeId) {
    _send('M:$modeId');
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _socket?.close();
    _socket = null;
  }
}
