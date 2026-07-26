import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'esp_websocket_service.dart';
import 'ws2812fx_modes.dart';

void main() {
  runApp(const ControlledApp());
}

class ControlledApp extends StatelessWidget {
  const ControlledApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ambient Light',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
      ),
      home: const ColorControlScreen(),
    );
  }
}

class ColorControlScreen extends StatefulWidget {
  const ColorControlScreen({super.key});

  @override
  State<ColorControlScreen> createState() => _ColorControlScreenState();
}

class _ColorControlScreenState extends State<ColorControlScreen> {
  // Status Warna, Kecerahan, Kecepatan, dan Mode Efek
  Color _selectedColor = const Color(0xFFFF3B30); // Warna Awal (Merah)
  double _brightness = 255.0; // Kecerahan 0 - 255
  double _speedPercent = 70.0; // Default 70% (~1000ms delay)

  // Default Mode ke Mode 12 (Rainbow Cycle)
  WS2812FXMode _selectedMode = kWS2812FXModes[12];

  final EspWebSocketService _espService = EspWebSocketService();

  @override
  void initState() {
    super.initState();
    _espService.connect();
  }

  @override
  void dispose() {
    _espService.dispose();
    super.dispose();
  }

  void _triggerManualConnect() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mencoba menghubungkan ke WiFi AP ESP8266 (192.168.4.1)...'),
        duration: Duration(seconds: 2),
      ),
    );
    _espService.forceReconnect();
  }

  int _calculateDelayMs(double percent) {
    final delay = 3000 - ((percent / 100.0) * 2900);
    return delay.round().clamp(100, 3000);
  }

  @override
  Widget build(BuildContext context) {
    final int r = (_selectedColor.r * 255).round();
    final int g = (_selectedColor.g * 255).round();
    final int b = (_selectedColor.b * 255).round();

    final String hexCode =
        '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFF9500),
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Smart Ambient Light',
              style: TextStyle(
                color: Color(0xFF1D1B20),
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          // TOMBOL KONEKSI WIFI TERINTEGRASI DI APPBAR
          ValueListenableBuilder<EspConnectionState>(
            valueListenable: _espService.connectionState,
            builder: (context, state, child) {
              final isConnected = state == EspConnectionState.connected;
              final isConnecting = state == EspConnectionState.connecting;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _triggerManualConnect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isConnected
                            ? const Color(0xFFE8F5E9)
                            : (isConnecting ? Colors.orange[50] : Colors.blue[50]),
                        border: Border.all(
                          color: isConnected
                              ? const Color(0xFF34C759)
                              : (isConnecting ? Colors.orange : Colors.blueAccent),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isConnecting)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orange,
                              ),
                            )
                          else
                            Icon(
                              isConnected
                                  ? Icons.wifi_rounded
                                  : Icons.wifi_tethering_rounded,
                              size: 16,
                              color: isConnected
                                  ? const Color(0xFF34C759)
                                  : Colors.blueAccent,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected
                                ? 'Terhubung'
                                : (isConnecting ? 'Menghubungkan...' : 'Hubungkan WiFi'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isConnected
                                  ? const Color(0xFF2E7D32)
                                  : (isConnecting ? Colors.orange[900] : Colors.blue[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // 1. RODA WARNA (COLOR WHEEL) INTERAKTIF DENGAN BOLA SELEKTOR AKTIF
              Center(
                child: ColorWheelPicker(
                  initialColor: _selectedColor,
                  onColorChanged: (color) {
                    setState(() {
                      _selectedColor = color;
                    });
                    _espService.sendColor(color);
                  },
                  onColorEnd: (color) {
                    _espService.sendColorDirect(color);
                  },
                ),
              ),

              const SizedBox(height: 28),

              // 2. KOTAK PREVIEW WARNA + TEKS KODE WARNA (HEX & RGB) SEAMLESS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedColor,
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hexCode,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'RGB: $r, $g, $b',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 3. SLIDER KECERAHAN (BRIGHTNESS SLIDER) SEAMLESS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_rounded,
                            size: 20,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Kecerahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1B20),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${((_brightness / 255.0) * 100).round()}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.amber[600],
                      inactiveTrackColor: Colors.grey[200],
                      thumbColor: Colors.amber[700],
                      overlayColor: Colors.amber[100]?.withValues(alpha: 0.5),
                      trackHeight: 8,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 11,
                      ),
                    ),
                    child: Slider(
                      value: _brightness,
                      min: 0,
                      max: 255,
                      onChanged: (val) {
                        setState(() {
                          _brightness = val;
                        });
                        _espService.sendBrightness(val.round());
                      },
                      onChangeEnd: (val) {
                        _espService.sendBrightnessDirect(val.round());
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. SLIDER KECEPATAN ANIMASI (SEMAKIN FULL = SEMAKIN CEPAT)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 20,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Kecepatan Animasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1B20),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_speedPercent.round()}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue[600],
                      inactiveTrackColor: Colors.grey[200],
                      thumbColor: Colors.blue[700],
                      overlayColor: Colors.blue[100]?.withValues(alpha: 0.5),
                      trackHeight: 8,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 11,
                      ),
                    ),
                    child: Slider(
                      value: _speedPercent,
                      min: 0,
                      max: 100,
                      onChanged: (val) {
                        setState(() {
                          _speedPercent = val;
                        });
                        final delayMs = _calculateDelayMs(val);
                        _espService.sendSpeed(delayMs);
                      },
                      onChangeEnd: (val) {
                        final delayMs = _calculateDelayMs(val);
                        _espService.sendSpeedDirect(delayMs);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. DROPDOWN LIST EFEK ANIMASI WS2812FX SEAMLESS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.style_rounded,
                        size: 20,
                        color: Colors.purple[600],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Efek Animasi LED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<WS2812FXMode>(
                        value: _selectedMode,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.purple[700], size: 28),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1B20),
                        ),
                        items: kWS2812FXModes.map((mode) {
                          return DropdownMenuItem<WS2812FXMode>(
                            value: mode,
                            child: Text(mode.name),
                          );
                        }).toList(),
                        onChanged: (mode) {
                          if (mode != null) {
                            setState(() {
                              _selectedMode = mode;
                            });
                            _espService.sendMode(mode.id);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET COLOR WHEEL PICKER DENGAN BOLA SELEKTOR AKTIF MATEMATIS HARMONIS
// ============================================================================
class ColorWheelPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<Color>? onColorEnd;
  final double size;

  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.onColorEnd,
    this.size = 270.0,
  });

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  late HSVColor _currentHsv;

  @override
  void initState() {
    super.initState();
    _currentHsv = HSVColor.fromColor(widget.initialColor);
  }

  Offset _calculateThumbPosition(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;

    final angle = (_currentHsv.hue * math.pi) / 180.0;
    final distance = _currentHsv.saturation * radius;

    final x = center.dx + distance * math.cos(angle);
    final y = center.dy + distance * math.sin(angle);

    return Offset(x, y);
  }

  void _updateColorFromPosition(Offset localPosition, Size size, {bool isEnd = false}) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    double angle = math.atan2(dy, dx);
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    final hue = (angle * 180.0) / math.pi;

    final distance = math.sqrt(dx * dx + dy * dy);
    final saturation = (distance / radius).clamp(0.0, 1.0);

    final newHsv = HSVColor.fromAHSV(1.0, hue, saturation, 1.0);
    final newColor = newHsv.toColor();

    setState(() {
      _currentHsv = newHsv;
    });

    if (isEnd) {
      widget.onColorEnd?.call(newColor);
    } else {
      widget.onColorChanged(newColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wheelSize = math.min(widget.size, constraints.maxWidth - 32);
        final size = Size(wheelSize, wheelSize);
        final thumbPos = _calculateThumbPosition(size);

        return GestureDetector(
          onPanStart: (details) => _updateColorFromPosition(details.localPosition, size),
          onPanUpdate: (details) => _updateColorFromPosition(details.localPosition, size),
          onPanEnd: (details) => widget.onColorEnd?.call(_currentHsv.toColor()),
          onTapDown: (details) => _updateColorFromPosition(details.localPosition, size, isEnd: true),
          child: SizedBox(
            width: wheelSize,
            height: wheelSize,
            child: Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _ColorWheelPainter(),
                ),
                Positioned(
                  left: thumbPos.dx - 16,
                  top: thumbPos.dy - 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentHsv.toColor(),
                      border: Border.all(
                        color: Colors.white,
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;

    final List<Color> colors = const [
      Color(0xFFFF0000),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
      Color(0xFFFF0000),
    ];

    final sweepGradient = SweepGradient(colors: colors);
    final paintSweep = Paint()
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paintSweep);

    final radialGradient = RadialGradient(
      colors: [
        Colors.white,
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    );

    final paintRadial = Paint()
      ..shader = radialGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paintRadial);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
