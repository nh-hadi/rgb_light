import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'models/preset_model.dart';
import 'security_config.dart';

enum EspConnectionState { disconnected, connecting, connected }

class EspUdpService {
  static final EspUdpService _instance = EspUdpService._internal();
  factory EspUdpService() => _instance;
  EspUdpService._internal();

  RawDatagramSocket? _socket;
  Timer? _heartbeatTimer;

  DateTime _lastResponseTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _connectionTimeout = Duration(seconds: 8);
  static const Duration _heartbeatInterval = Duration(seconds: 2);

  final ValueNotifier<EspConnectionState> connectionState =
      ValueNotifier<EspConnectionState>(EspConnectionState.disconnected);

  final ValueNotifier<bool> isDeviceAuthorized = ValueNotifier<bool>(true);

  final ValueNotifier<Map<String, dynamic>?> espStateNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  final ValueNotifier<List<PresetItem>> playlistNotifierD4 =
      ValueNotifier<List<PresetItem>>([]);
  final ValueNotifier<List<PresetItem>> playlistNotifierD5 =
      ValueNotifier<List<PresetItem>>([]);

  final ValueNotifier<int> brightnessNotifierD4 = ValueNotifier<int>(255);
  final ValueNotifier<int> brightnessNotifierD5 = ValueNotifier<int>(255);

  String _espIp = '192.168.4.1';
  int _espPort = 8888;

  String get currentTargetIp => _espIp;
  int get currentTargetPort => _espPort;

  void updateTargetIp(String newIp) {
    if (newIp.trim().isNotEmpty) {
      _espIp = newIp.trim();
      queryState();
      fetchPlaylistJson(1);
      fetchPlaylistJson(2);
    }
  }

  void updateConnectionSettings(String newIp, int newPort) {
    if (newIp.trim().isNotEmpty) {
      _espIp = newIp.trim();
    }
    if (newPort > 0 && newPort <= 65535) {
      _espPort = newPort;
    }
    _socket?.close();
    _socket = null;
    init();
    queryState();
    fetchPlaylistJson(1);
    fetchPlaylistJson(2);
  }

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
              if (message.startsWith('STATE')) {
                _handleStateResponse(message);
              } else if (message.startsWith('JSON')) {
                _handleJsonPlaylistResponse(message);
              } else if (message.startsWith('INFO:')) {
                _handleHardwareInfoResponse(message);
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

  void queryState({int targetId = 0}) {
    if (targetId == 1) _send('Q1');
    else if (targetId == 2) _send('Q2');
    else _send('Q');
  }

  void fetchPlaylistJson(int targetId) {
    if (targetId == 2) _send('LIST2');
    else _send('LIST1');
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
            if (msg.startsWith('STATE')) {
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

  final ValueNotifier<Map<String, dynamic>?> hardwareInfoNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  void _handleStateResponse(String message) {
    try {
      final colonIdx = message.indexOf(':');
      if (colonIdx == -1) return;

      final parts = message.substring(colonIdx + 1).split(',');
      if (parts.length >= 6) {
        _lastResponseTime = DateTime.now();
        final bool wasDisconnected = connectionState.value != EspConnectionState.connected;
        connectionState.value = EspConnectionState.connected;

        if (wasDisconnected) {
          debugPrint('⚡ ESP8266 Terhubung! Auto-reload playlist JSON & Hardware INFO...');
          fetchPlaylistJson(1);
          fetchPlaylistJson(2);
          fetchHardwareInfo();
        }

        espStateNotifier.value = {
          'color': Color.fromARGB(255, int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
          'brightness': int.parse(parts[3]).toDouble(),
          'modeId': int.parse(parts[4]),
          'speedMs': int.parse(parts[5]).toDouble(),
          'isPreview': parts.length >= 7 ? parts[6] == '1' : false,
        };
      }
    } catch (e) {
      debugPrint('Error Parse State UDP: $e');
    }
  }

  void fetchHardwareInfo() {
    _send('INFO');
  }

  void _handleHardwareInfoResponse(String message) {
    try {
      _lastResponseTime = DateTime.now();
      connectionState.value = EspConnectionState.connected;

      final jsonRaw = message.substring(5);
      final decoded = jsonDecode(jsonRaw) as Map<String, dynamic>;
      hardwareInfoNotifier.value = decoded;

      // Verifikasi Signature Keamanan Perangkat (Anti-Kloning)
      final String? espSignature = decoded['signature'] as String?;
      if (espSignature == SecurityConfig.appSecuritySignature) {
        isDeviceAuthorized.value = true;
        debugPrint('🛡️ Autentikasi Hardware BERHASIL! Signature cocok.');
      } else {
        isDeviceAuthorized.value = false;
        debugPrint('❌ PERANGKAT UN-AUTHORIZED / PALSU! Signature ($espSignature) tidak cocok dengan SecurityConfig.');
      }
    } catch (e) {
      debugPrint('Error Parse Hardware INFO UDP: $e');
    }
  }

  void _handleJsonPlaylistResponse(String message) {
    try {
      _lastResponseTime = DateTime.now();
      connectionState.value = EspConnectionState.connected;

      final isD5 = message.startsWith('JSON2:');
      final jsonRaw = message.substring(6);
      final decoded = jsonDecode(jsonRaw) as Map<String, dynamic>;
      final parsed = StripConfigPresets.fromJson(decoded);

      if (isD5) {
        brightnessNotifierD5.value = parsed.kecerahan;
        playlistNotifierD5.value = parsed.presets;
      } else {
        brightnessNotifierD4.value = parsed.kecerahan;
        playlistNotifierD4.value = parsed.presets;
      }
      debugPrint('Sync Playlist dari ESP8266 berhasil (${isD5 ? "D5" : "D4"})');
    } catch (e) {
      debugPrint('Error Parse Playlist JSON UDP: $e');
    }
  }

  void _send(String message) {
    if (_socket == null) {
      init();
      return;
    }

    // Hanya ijinkan command query jika perangkat belum terverifikasi
    final isQueryCommand = message == 'INFO' || message == 'Q' || message == 'Q1' || message == 'Q2' || message == 'LIST1' || message == 'LIST2';
    if (!isQueryCommand && !isDeviceAuthorized.value) {
      debugPrint('🚫 BLOKIR: Pengiriman perintah ("$message") dibatalkan karena perangkat tidak terverifikasi (Signature tidak cocok).');
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

  // TARGET INDEPENDENT COMMANDS (targetId = 1 untuk D4 Jam, targetId = 2 untuk D5 Nama)
  void sendColor(Color color, {int targetId = 0}) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final prefix = targetId == 1 ? 'C1:' : (targetId == 2 ? 'C2:' : 'C:');
    _send('$prefix$r,$g,$b');
  }

  void sendColorDirect(Color color, {int targetId = 0}) => sendColor(color, targetId: targetId);

  void sendBrightness(int brightness, {int targetId = 0}) {
    final prefix = targetId == 1 ? 'B1:' : (targetId == 2 ? 'B2:' : 'B:');
    _send('$prefix${brightness.clamp(0, 255)}');
  }

  void sendBrightnessDirect(int brightness, {int targetId = 0}) => sendBrightness(brightness, targetId: targetId);

  void saveBrightness(int brightness, {required int targetId}) {
    final prefix = targetId == 1 ? 'BSAVE1:' : 'BSAVE2:';
    _send('$prefix${brightness.clamp(0, 255)}');
    Timer(const Duration(milliseconds: 150), () => fetchPlaylistJson(targetId));
  }

  void sendSpeed(int speedMs, {int targetId = 0}) {
    final prefix = targetId == 1 ? 'S1:' : (targetId == 2 ? 'S2:' : 'S:');
    _send('$prefix${speedMs.clamp(100, 3000)}');
  }

  void sendSpeedDirect(int speedMs, {int targetId = 0}) => sendSpeed(speedMs, targetId: targetId);

  void sendMode(int modeId, {int targetId = 0}) {
    final prefix = targetId == 1 ? 'M1:' : (targetId == 2 ? 'M2:' : 'M:');
    _send('$prefix$modeId');
  }

  void sendPreviewState(bool isPreview, {required int targetId}) {
    final prefix = targetId == 1 ? 'P1:' : 'P2:';
    _send('$prefix${isPreview ? 1 : 0}');
  }

  void sendAddPreset(int mode, int delayMs, String colorHex, int durationSec, {required int targetId}) {
    final prefix = targetId == 1 ? 'ADD1:' : 'ADD2:';
    _send('$prefix$mode,$delayMs,$colorHex,$durationSec');
    Timer(const Duration(milliseconds: 150), () => fetchPlaylistJson(targetId));
  }

  void sendDeletePreset(int index, {required int targetId}) {
    final prefix = targetId == 1 ? 'DEL1:' : 'DEL2:';
    _send('$prefix$index');
    Timer(const Duration(milliseconds: 150), () => fetchPlaylistJson(targetId));
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _socket?.close();
    _socket = null;
  }
}
