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

  // Throttling 150ms saat menggeser perlahan agar memori interrupt ESP8266 tidak sesak
  bool _shouldThrottle() {
    final now = DateTime.now();
    if (now.difference(_lastSendTime).inMilliseconds < 150) {
      return true; // Abaikan jika kurang dari 150 ms
    }
    _lastSendTime = now;
    return false;
  }

  // Pengiriman Warna saat menggeser (Throttled 150ms)
  void sendColor(Color color) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    if (_shouldThrottle()) return;

    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();

    _send('C:$r,$g,$b');
  }

  // Pengiriman Warna Langsung saat lepas jari (onPanEnd)
  void sendColorDirect(Color color) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    _lastSendTime = DateTime.now();

    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();

    _send('C:$r,$g,$b');
  }

  // Pengiriman Kecerahan saat menggeser (Throttled 150ms)
  void sendBrightness(int brightness) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    if (_shouldThrottle()) return;

    final val = brightness.clamp(0, 255);
    _send('B:$val');
  }

  // Pengiriman Kecerahan Langsung saat lepas jari (onChangeEnd)
  void sendBrightnessDirect(int brightness) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    _lastSendTime = DateTime.now();

    final val = brightness.clamp(0, 255);
    _send('B:$val');
  }

  // Pengiriman Kecepatan Animasi saat menggeser (Throttled 150ms)
  void sendSpeed(int speedMs) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    if (_shouldThrottle()) return;

    final val = speedMs.clamp(100, 3000);
    _send('S:$val');
  }

  // Pengiriman Kecepatan Langsung saat lepas jari (onChangeEnd)
  void sendSpeedDirect(int speedMs) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    _lastSendTime = DateTime.now();

    final val = speedMs.clamp(100, 3000);
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
