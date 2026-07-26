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
      _socket = await WebSocket.connect(_wsUrl).timeout(
        const Duration(seconds: 3),
      );
      connectionState.value = EspConnectionState.connected;

      _socket?.listen(
        (data) {},
        onDone: () => _handleDisconnect(),
        onError: (error) => _handleDisconnect(),
      );
    } catch (e) {
      _handleDisconnect();
    }
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

  // Pengiriman Warna Throttled (Max 1 paket per 30 ms)
  void sendColor(Color color) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;

    final now = DateTime.now();
    if (now.difference(_lastSendTime).inMilliseconds < 30) {
      return;
    }
    _lastSendTime = now;

    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();

    _socket?.add('C:$r,$g,$b');
  }

  // Pengiriman Kecerahan (Format "B:Val")
  void sendBrightness(int brightness) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    final val = brightness.clamp(0, 255);
    _socket?.add('B:$val');
  }

  // Pengiriman Mode Efek (Format "M:ModeID")
  void sendMode(int modeId) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    _socket?.add('M:$modeId');
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _socket?.close();
  }
}
