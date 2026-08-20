import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

enum ToastType { success, info, warning, error }

class CustomFloatingToast {
  static OverlayEntry? _currentEntry;
  static Timer? _toastTimer;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    ToastType type = ToastType.success,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    _toastTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _FloatingToastWidget(
          title: title,
          message: message,
          icon: icon,
          type: type,
          duration: duration,
          onDismiss: () {
            _currentEntry?.remove();
            _currentEntry = null;
          },
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }
}

class _FloatingToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _FloatingToastWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_FloatingToastWidget> createState() => _FloatingToastWidgetState();
}

class _FloatingToastWidgetState extends State<_FloatingToastWidget>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    // 1. ANIMASI MASUK & KELUAR (SLIDE + SPRING ELASTIC SCALE)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    );

    // 2. ANIMASI GARIS BORDER LOADING MENYUSUT (100% -> 0%)
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animController.forward();
    _progressController.forward();

    // 3. TIMER HILANG OTOMATIS SAAT BORDER LOADING SELESAI
    _autoDismissTimer = Timer(widget.duration, () {
      _triggerExitAnimation();
    });
  }

  void _triggerExitAnimation() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      _animController.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomInset + 84.0;

    Color iconTextColor;

    switch (widget.type) {
      case ToastType.success:
        iconTextColor = const Color(0xFF059669); // Emerald Green
        break;
      case ToastType.info:
        iconTextColor = const Color(0xFF0284C7); // Sky Blue
        break;
      case ToastType.warning:
        iconTextColor = const Color(0xFFD97706); // Amber Gold
        break;
      case ToastType.error:
        iconTextColor = const Color(0xFFE11D48); // Rose Red
        break;
    }

    return Positioned(
      bottom: bottomPadding,
      left: 20,
      right: 20,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _slideAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: IntrinsicWidth(
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      final double progress = (1.0 - _progressController.value).clamp(0.0, 1.0);
                      return CustomPaint(
                        foregroundPainter: _GradientProgressBorderPainter(
                          progress: progress,
                          gradientColors: const [Color(0xFF2C2493), Color(0xFF38BDF8)],
                          strokeWidth: 2.0,
                          borderRadius: 20.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white, // Latar belakang TETAP PUTIH
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Murni selebar teks!
                            children: [
                              Icon(widget.icon, color: iconTextColor, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: iconTextColor,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: _triggerExitAnimation,
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// PAINTER BORDER GRADASI BIRU SEBAGAI INDIKATOR LOADING MENYUSUT TERHUBUNG (100% -> 0%)
class _GradientProgressBorderPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final double strokeWidth;
  final double borderRadius;

  _GradientProgressBorderPainter({
    required this.progress,
    required this.gradientColors,
    this.strokeWidth = 2.0,
    this.borderRadius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final PathMetrics metrics = path.computeMetrics();

    final Paint paint = Paint()
      ..shader = LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final PathMetric metric in metrics) {
      final double extractLength = metric.length * progress.clamp(0.0, 1.0);
      final Path extractPath = metric.extractPath(0.0, extractLength);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientProgressBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
