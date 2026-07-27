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

  /// Inisialisasi socket UDP. Aman dipanggil berulang — akan skip jika socket
  /// sudah aktif, atau reinit jika socket sudah tertutup/rusak.
  void init() async {
    // Jika socket sudah ada dan masih aktif, skip
    if (_socket != null) {
      try {
        // Probe: coba kirim 0 byte untuk deteksi socket masih valid
        _socket!.send(const [], InternetAddress.anyIPv4, 0);
        // Tidak error = socket masih valid, sudah cukup
        return;
      } catch (_) {
        // Socket sudah mati — tutup dan buat ulang di bawah
        _socket?.close();
        _socket = null;
      }
    }

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = false; // Nonaktifkan broadcast — hanya kirim ke IP spesifik

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
          // Socket error — tutup dan izinkan reinit di heartbeat berikutnya
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
    // Langsung query pertama kali saat init
    queryState();

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _checkConnectionTimeout();
      queryState();
    });
  }

  /// Cek apakah ESP masih merespons. Jika timeout → set disconnected.
  void _checkConnectionTimeout() {
    if (connectionState.value == EspConnectionState.connected) {
      final elapsed = DateTime.now().difference(_lastResponseTime);
      if (elapsed > _connectionTimeout) {
        debugPrint('UDP: Timeout — tidak ada response dari ESP selama ${elapsed.inSeconds}s');
        connectionState.value = EspConnectionState.disconnected;
      }
    }
  }

  void queryState() {
    _send('Q');
  }

  /// Fungsi pengujian koneksi IP manual (dari dialog atur IP)
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

      // Kirim query test ke IP yang diuji
      final data = 'Q'.codeUnits;
      testSocket.send(data, InternetAddress(testIp.trim()), _espPort);

      timeoutTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
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
        final r          = int.parse(parts[0]);
        final g          = int.parse(parts[1]);
        final b          = int.parse(parts[2]);
        final brightness = int.parse(parts[3]);
        final modeId     = int.parse(parts[4]);
        final speedMs    = int.parse(parts[5]);

        // ✅ Status connected HANYA diupdate saat benar-benar ada response
        _lastResponseTime = DateTime.now();
        connectionState.value = EspConnectionState.connected;

        espStateNotifier.value = {
          'color':      Color.fromARGB(255, r, g, b),
          'brightness': brightness.toDouble(),
          'modeId':     modeId,
          'speedMs':    speedMs.toDouble(),
        };
      }
    } catch (e) {
      debugPrint('Error Parse State UDP: $e');
    }
  }

  void _send(String message) {
    // Jika socket null atau mati, coba reinit
    if (_socket == null) {
      init();
      return;
    }

    // ✅ Jangan set connectionState = connected di sini!
    // Status hanya berubah berdasarkan RESPONSE dari ESP, bukan saat kirim.
    try {
      final data = message.codeUnits;
      // Kirim HANYA ke IP spesifik ESP — tidak ada broadcast 255.255.255.255
      _socket?.send(data, InternetAddress(_espIp), _espPort);
    } catch (e) {
      debugPrint('UDP Send Error: $e');
      // Socket error saat kirim — tandai socket mati
      _socket?.close();
      _socket = null;
      connectionState.value = EspConnectionState.disconnected;
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
