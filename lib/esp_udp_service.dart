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

  // Waktu terakhir RESPONSE valid diterima dari ESP (bukan saat kirim)
  DateTime _lastResponseTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Timeout: jika > 8 detik tidak ada response → anggap terputus
  static const Duration _connectionTimeout = Duration(seconds: 8);

  // Interval heartbeat query 'Q' ke ESP
  static const Duration _heartbeatInterval = Duration(seconds: 2);

  final ValueNotifier<EspConnectionState> connectionState =
      ValueNotifier<EspConnectionState>(EspConnectionState.disconnected);

  final ValueNotifier<Map<String, dynamic>?> espStateNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  String _espIp = '192.168.4.1';
  static const int _espPort = 8888;

  String get currentTargetIp => _espIp;

  void updateTargetIp(String newIp) {
    if (newIp.trim().isNotEmpty) {
      _espIp = newIp.trim();
      queryState();
    }
  }

  /// Inisialisasi socket UDP. Aman dipanggil berulang.
  void init() async {
    if (_socket != null) {
      try {
        _socket!.send(const [], InternetAddress.anyIPv4, 0);
        return;
      } catch (_) {
        _socket?.close();
        _socket = null;
      }
    }

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = false;

      _socket?.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket?.receive();
            if (datagram != null) {
              final message = String.fromCharCodes(datagram.data).trim();
              if (message.startsWith('STATE:')) {
                _handleStateResponse(message);
              }
            }
          }
        },
        onError: (e) {
          debugPrint('UDP Socket Error: $e');
          _socket?.close();
          _socket = null;
          connectionState.value = EspConnectionState.disconnected;
        },
        onDone: () {
          _socket = null;
          connectionState.value = EspConnectionState.disconnected;
        },
        cancelOnError: true,
      );

      _startHeartbeat();
      debugPrint('UDP Socket berhasil diinisialisasi.');
    } catch (e) {
      debugPrint('UDP Bind Error: $e');
      _socket = null;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    queryState();

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _checkConnectionTimeout();
      queryState();
    });
  }

  void _checkConnectionTimeout() {
    if (connectionState.value == EspConnectionState.connected) {
      final elapsed = DateTime.now().difference(_lastResponseTime);
      if (elapsed > _connectionTimeout) {
        debugPrint('UDP: Timeout — tidak ada response selama ${elapsed.inSeconds}s');
        connectionState.value = EspConnectionState.disconnected;
      }
    }
  }

  void queryState() {
    _send('Q');
  }

  Future<bool> testConnection(String testIp) async {
    final Completer<bool> completer = Completer<bool>();
    RawDatagramSocket? testSocket;

    try {
      testSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      testSocket.broadcastEnabled = false;

      Timer? timeoutTimer;

      testSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = testSocket?.receive();
          if (datagram != null) {
            final msg = String.fromCharCodes(datagram.data).trim();
            if (msg.startsWith('STATE:')) {
              if (!completer.isCompleted) {
                timeoutTimer?.cancel();
                _handleStateResponse(msg);
                completer.complete(true);
              }
            }
          }
        }
      });

      final data = 'Q'.codeUnits;
      testSocket.send(data, InternetAddress(testIp.trim()), _espPort);

      timeoutTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!completer.isCompleted) completer.complete(false);
      });
    } catch (e) {
      if (!completer.isCompleted) completer.complete(false);
    } finally {
      Timer(const Duration(milliseconds: 2000), () {
        testSocket?.close();
      });
    }

    return completer.future;
  }

  void _handleStateResponse(String message) {
    try {
      final parts = message.substring(6).split(',');
      if (parts.length >= 6) {
        _lastResponseTime = DateTime.now();
        connectionState.value = EspConnectionState.connected;

        espStateNotifier.value = {
          'color':      Color.fromARGB(255, int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
          'brightness': int.parse(parts[3]).toDouble(),
          'modeId':     int.parse(parts[4]),
          'speedMs':    int.parse(parts[5]).toDouble(),
        };
      }
    } catch (e) {
      debugPrint('Error Parse State UDP: $e');
    }
  }

  void _send(String message) {
    if (_socket == null) {
      init();
      return;
    }
    try {
      _socket?.send(message.codeUnits, InternetAddress(_espIp), _espPort);
    } catch (e) {
      debugPrint('UDP Send Error: $e');
      _socket?.close();
      _socket = null;
      connectionState.value = EspConnectionState.disconnected;
    }
  }

  // Strip tunggal — semua perintah tanpa prefix
  void sendColor(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    _send('C:$r,$g,$b');
  }
  void sendColorDirect(Color color) => sendColor(color);

  void sendBrightness(int brightness) => _send('B:${brightness.clamp(0, 255)}');
  void sendBrightnessDirect(int brightness) => sendBrightness(brightness);

  void sendSpeed(int speedMs) => _send('S:${speedMs.clamp(100, 3000)}');
  void sendSpeedDirect(int speedMs) => sendSpeed(speedMs);

  void sendMode(int modeId) => _send('M:$modeId');

  void dispose() {
    _heartbeatTimer?.cancel();
    _socket?.close();
    _socket = null;
  }
}
