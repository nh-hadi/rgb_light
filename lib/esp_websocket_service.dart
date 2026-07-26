import 'dart:async';
import 'dart:io' if (dart.library.html) 'dart:html' as ws_impl;
import 'dart:io' as io_impl;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum EspConnectionState { disconnected, connecting, connected }

class EspWebSocketService {
  static final EspWebSocketService _instance = EspWebSocketService._internal();
  factory EspWebSocketService() => _instance;
  EspWebSocketService._internal();

  dynamic _socket;
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
      if (!kIsWeb) {
        // Platform Mobile (Android / iOS)
        final ioSocket = await io_impl.WebSocket.connect(_wsUrl).timeout(
          const Duration(seconds: 3),
        );
        _socket = ioSocket;
        connectionState.value = EspConnectionState.connected;

        ioSocket.listen(
          (data) {},
          onDone: () => _handleDisconnect(),
          onError: (error) => _handleDisconnect(),
        );
      } else {
        // Platform Web Browser (Testing di Browser)
        final webSocket = ws_impl.WebSocket(_wsUrl);
        _socket = webSocket;

        webSocket.onOpen.listen((event) {
          connectionState.value = EspConnectionState.connected;
        });

        webSocket.onClose.listen((event) {
          _handleDisconnect();
        });

        webSocket.onError.listen((event) {
          _handleDisconnect();
        });
      }
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

    _send('C:$r,$g,$b');
  }

  // Pengiriman Kecerahan (Format "B:Val")
  void sendBrightness(int brightness) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    final val = brightness.clamp(0, 255);
    _send('B:$val');
  }

  // Pengiriman Mode Efek (Format "M:ModeID")
  void sendMode(int modeId) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    _send('M:$modeId');
  }

  // Pengiriman Kecepatan Animasi (Format "S:SpeedVal" - 10ms s/d 65535ms)
  void sendSpeed(int speedMs) {
    if (connectionState.value != EspConnectionState.connected || _socket == null) return;
    final val = speedMs.clamp(10, 65535);
    _send('S:$val');
  }

  void _send(String message) {
    try {
      if (!kIsWeb && _socket is io_impl.WebSocket) {
        (_socket as io_impl.WebSocket).add(message);
      } else if (kIsWeb && _socket != null) {
        _socket.send(message);
      }
    } catch (e) {
      _handleDisconnect();
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    try {
      if (!kIsWeb && _socket is io_impl.WebSocket) {
        (_socket as io_impl.WebSocket).close();
      } else if (kIsWeb && _socket != null) {
        _socket.close();
      }
    } catch (e) {}
  }
}
