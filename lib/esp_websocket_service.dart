import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

enum EspConnectionState { disconnected, connecting, connected }

class EspWebSocketService {
  static final EspWebSocketService _instance = EspWebSocketService._internal();
  factory EspWebSocketService() => _instance;
  EspWebSocketService._internal();

  WebSocket? _socket;
  Timer? _reconnectTimer;
  DateTime _lastSendTime = DateTime.now();

  final ValueNotifier<EspConnectionState> connectionState =
      ValueNotifier<EspConnectionState>(EspConnectionState.disconnected);

  static const String _wsUrl = 'ws://192.168.4.1:81';

  void connect() async {
    if (connectionState.value == EspConnectionState.connected ||
        connectionState.value == EspConnectionState.connecting) {
      return;
    }

    connectionState.value = EspConnectionState.connecting;

    try {
      final ioSocket = await WebSocket.connect(_wsUrl).timeout(
        const Duration(seconds: 4),
      );
      _socket = ioSocket;
      connectionState.value = EspConnectionState.connected;

      ioSocket.listen(
        (data) {},
        onDone: () => _handleDisconnect(),
        onError: (error) => _handleDisconnect(),
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void forceReconnect() {
    _reconnectTimer?.cancel();
    try {
      _socket?.close();
    } catch (e) {}
    _socket = null;
    connectionState.value = EspConnectionState.disconnected;
    connect();
  }

  void _handleDisconnect() {
    connectionState.value = EspConnectionState.disconnected;
    _socket = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (connectionState.value == EspConnectionState.disconnected) {
        connect();
      }
    });
  }

  // Fungsi pembatas laju pengiriman paket (Throttling 50 ms Universal untuk semua perintah)
  bool _shouldThrottle() {
    final now = DateTime.now();
    if (now.difference(_lastSendTime).inMilliseconds < 50) {
      return true; // Abaikan jika kurang dari 50 ms
    }
    _lastSendTime = now;
    return false;
  }

  // Pengiriman Warna Throttled (Max 1 paket per 30 ms)
  void sendColor(Color color) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    if (_shouldThrottle()) return;

    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();

    _send('C:$r,$g,$b');
  }

  // Pengiriman Kecerahan Throttled (Format "B:Val")
  void sendBrightness(int brightness) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    if (_shouldThrottle()) return;

    final val = brightness.clamp(0, 255);
    _send('B:$val');
  }

  // Pengiriman Kecepatan Animasi Throttled (Format "S:SpeedVal")
  void sendSpeed(int speedMs) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    if (_shouldThrottle()) return;

    final val = speedMs.clamp(10, 65535);
    _send('S:$val');
  }

  // Pengiriman Mode Efek (Format "M:ModeID")
  void sendMode(int modeId) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    _send('M:$modeId');
  }

  void _send(String message) {
    try {
      _socket?.add(message);
    } catch (e) {
      _handleDisconnect();
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    try {
      _socket?.close();
    } catch (e) {}
  }
}
