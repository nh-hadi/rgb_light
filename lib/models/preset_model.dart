import 'dart:convert';
import 'package:flutter/material.dart';
import '../ws2812fx_modes.dart';

class PresetItem {
  final int mode;
  final int kecepatan; // delayMs (100 - 3000 ms)
  final String colorHex; // e.g. "0xFF00FFFF" or "#00FFFF"
  final int durasi; // seconds

  const PresetItem({
    required this.mode,
    required this.kecepatan,
    required this.colorHex,
    required this.durasi,
  });

  Color get color {
    try {
      String cleanHex = colorHex.replaceAll('#', '').replaceAll('0x', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return Colors.red;
    }
  }

  String get modeName {
    final found = kWS2812FXModes.firstWhere(
      (m) => m.id == mode,
      orElse: () => WS2812FXMode(mode, 'Mode $mode'),
    );
    return found.name;
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'kecepatan': kecepatan,
      'color': colorHex,
      'durasi': durasi,
    };
  }

  factory PresetItem.fromJson(Map<String, dynamic> json) {
    return PresetItem(
      mode: json['mode'] as int? ?? 0,
      kecepatan: json['kecepatan'] as int? ?? 1000,
      colorHex: json['color'] as String? ?? '0xFFFF0000',
      durasi: json['durasi'] as int? ?? 10,
    );
  }
}

class StripConfigPresets {
  final int kecerahan;
  final List<PresetItem> presets;

  const StripConfigPresets({
    required this.kecerahan,
    required this.presets,
  });

  Map<String, dynamic> toJson() {
    return {
      'kecerahan': kecerahan,
      'presets': presets.map((p) => p.toJson()).toList(),
    };
  }

  factory StripConfigPresets.fromJson(Map<String, dynamic> json) {
    var rawPresets = json['presets'] as List<dynamic>? ?? [];
    List<PresetItem> parsedPresets =
        rawPresets.map((p) => PresetItem.fromJson(p as Map<String, dynamic>)).toList();

    return StripConfigPresets(
      kecerahan: json['kecerahan'] as int? ?? 255,
      presets: parsedPresets,
    );
  }

  String encodeJson() => jsonEncode(toJson());

  factory StripConfigPresets.decodeJson(String jsonStr) =>
      StripConfigPresets.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}
