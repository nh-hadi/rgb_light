import 'dart:io';
import 'package:flutter/material.dart';

class EspUdpService {
  static final EspUdpService _instance = EspUdpService._internal();
  factory EspUdpService() => _instance;
  EspUdpService._internal();

  RawDatagramSocket? _socket;
  static const String _espIp = '192.168.4.1';
  static const int _espPort = 8888;
  DateTime _lastSendTime = DateTime.now();

  void init() async {
    if (_socket != null) return;
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      debugPrint('UDP Bind Error: $e');
    }
  }

  void _send(String message) {
    if (_socket == null) {
      init();
    }
    try {
      final data = message.codeUnits;
      _socket?.send(data, InternetAddress(_espIp), _espPort);
    } catch (e) {
      debugPrint('UDP Send Error: $e');
    }
  }

  // Throttling 20 ms (50 FPS) sangat halus tanpa membebankan jaringan
  bool _shouldThrottle() {
    final now = DateTime.now();
    if (now.difference(_lastSendTime).inMilliseconds < 20) {
      return true;
    }
    _lastSendTime = now;
    return false;
  }

  // Pengiriman Warna Real-Time via UDP
  void sendColor(Color color) {
    if (_shouldThrottle()) return;
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    _send('C:$r,$g,$b');
  }

  void sendColorDirect(Color color) {
    _lastSendTime = DateTime.now();
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    _send('C:$r,$g,$b');
  }

  // Pengiriman Kecerahan Real-Time via UDP
  void sendBrightness(int brightness) {
    if (_shouldThrottle()) return;
    final val = brightness.clamp(0, 255);
    _send('B:$val');
  }

  void sendBrightnessDirect(int brightness) {
    _lastSendTime = DateTime.now();
    final val = brightness.clamp(0, 255);
    _send('B:$val');
  }

  // Pengiriman Kecepatan Real-Time via UDP
  void sendSpeed(int speedMs) {
    if (_shouldThrottle()) return;
    final val = speedMs.clamp(100, 3000);
    _send('S:$val');
  }

  void sendSpeedDirect(int speedMs) {
    _lastSendTime = DateTime.now();
    final val = speedMs.clamp(100, 3000);
    _send('S:$val');
  }

  // Pengiriman Mode Efek Real-Time via UDP
  void sendMode(int modeId) {
    _send('M:$modeId');
  }

  void dispose() {
    _socket?.close();
    _socket = null;
  }
}
