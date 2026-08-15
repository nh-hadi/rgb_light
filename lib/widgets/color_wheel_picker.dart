import 'dart:math' as math;
import 'package:flutter/material.dart';

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

  @override
  void didUpdateWidget(covariant ColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      _currentHsv = HSVColor.fromColor(widget.initialColor);
    }
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
