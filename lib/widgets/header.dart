import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../esp_udp_service.dart';
import 'developer_inspector_modal.dart';

class RtcHeader extends StatefulWidget {
  final DateTime? now;
  final EspUdpService udpService;
  final VoidCallback? onWifiTap;

  const RtcHeader({
    super.key,
    this.now,
    required this.udpService,
    this.onWifiTap,
  });

  @override
  State<RtcHeader> createState() => _RtcHeaderState();
}

class _RtcHeaderState extends State<RtcHeader> {
  Timer? _timer;
  late DateTime _currentTime;

  int _brandTapCount = 0;
  Timer? _brandTapResetTimer;

  void _handleBrandTap() {
    _brandTapCount++;
    _brandTapResetTimer?.cancel();
    _brandTapResetTimer = Timer(const Duration(milliseconds: 2500), () {
      _brandTapCount = 0;
    });

    // Ketukan rahasia (7x) tanpa pemberitahuan angka ketukan di toast
    if (_brandTapCount >= 7) {
      _brandTapCount = 0;
      _brandTapResetTimer?.cancel();
      DeveloperInspectorModal.showPinDialog(
        context: context,
        udpService: widget.udpService,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _currentTime = widget.now ?? DateTime.now();
    if (widget.now == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _currentTime = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant RtcHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.now != null) {
      _currentTime = widget.now!;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _brandTapResetTimer?.cancel();
    super.dispose();
  }

  String _getFormattedFullDate(DateTime dateTime) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[dateTime.weekday % 7];
    final monthName = months[dateTime.month];
    return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = _currentTime;
    final hour   = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute:$second';
    final dateStr = _getFormattedFullDate(now);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final scale = (w / 360).clamp(0.72, 1.0);

        final badgePadH  = 10.0 * scale;
        final badgePadV  = 5.0 * scale;
        final pillPadH   = 10.0 * scale;
        final pillPadV   = 5.0 * scale;
        final iconSz     = 12.0 * scale;
        final dateFontSz = 11.0 * scale;
        final timeFontSz = 11.0 * scale;
        final brandFontSz = 10.0 * scale;
        final gap        = 6.0 * scale;

        return Container(
          margin: EdgeInsets.fromLTRB(12, 10 * scale, 12, 6 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 6 * scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FC),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE2E8F5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── KIRI: IDS-TECH (SILENT 7-TAP UNTUK PIN 020304 DEVELOPER INSPECTOR) ────
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _handleBrandTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: badgePadH, vertical: badgePadV),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2493),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BlinkingLedDot(udpService: widget.udpService, size: 9.0 * scale),
                          SizedBox(width: 5 * scale),
                          Text(
                            'IDS-TECH',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: brandFontSz,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: gap),

              // ── TENGAH: DATE + TIME PILLS ───────────────────
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // DATE PILL
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: pillPadH, vertical: pillPadV),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: const Color(0xFF3B3A98),
                              size: iconSz,
                            ),
                            SizedBox(width: 4 * scale),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: const Color(0xFF3B3A98),
                                fontWeight: FontWeight.w700,
                                fontSize: dateFontSz,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: gap),

                      // TIME PILL
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: pillPadH, vertical: pillPadV),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C2493), Color(0xFF5B4CE0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              color: Colors.white,
                              size: iconSz,
                            ),
                            SizedBox(width: 5 * scale),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: timeFontSz,
                                letterSpacing: 0.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: gap),

              // ── KANAN: STATUS BLINKING LED DOT + WIFI BUTTON ─────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _BlinkingLedDot(udpService: widget.udpService, size: 9.0 * scale),
                  SizedBox(width: 5 * scale),
                  GestureDetector(
                    onTap: widget.onWifiTap,
                    child: Container(
                      padding: EdgeInsets.all(5 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0), width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.wifi_rounded,
                          color: const Color(0xFF525B75),
                          size: 14 * scale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// LED BLINKING DOT
class _BlinkingLedDot extends StatefulWidget {
  final EspUdpService udpService;
  final double size;

  const _BlinkingLedDot({
    required this.udpService,
    this.size = 9.0,
  });

  @override
  State<_BlinkingLedDot> createState() => _BlinkingLedDotState();
}

class _BlinkingLedDotState extends State<_BlinkingLedDot> {
  Timer? _blinkTimer;
  int _colorIndex = 0;

  static const List<Color> _blinkColors = [
    Color(0xFFFF3B30),
    Color(0xFF007AFF),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (mounted) {
        setState(() {
          _colorIndex = (_colorIndex + 1) % _blinkColors.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EspConnectionState>(
      valueListenable: widget.udpService.connectionState,
      builder: (context, state, child) {
        final bool isConnected = state == EspConnectionState.connected;

        final Color dotColor = isConnected
            ? _blinkColors[_colorIndex]
            : Colors.white;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isConnected
                  ? dotColor.withValues(alpha: 0.6)
                  : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: isConnected
                ? [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
        );
      },
    );
  }
}
