import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../esp_udp_service.dart';
import '../models/preset_model.dart';

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
    _brandTapResetTimer = Timer(const Duration(seconds: 2), () {
      _brandTapCount = 0;
    });

    if (_brandTapCount >= 5) {
      _brandTapCount = 0;
      _brandTapResetTimer?.cancel();
      _showDeveloperJsonModal();
    } else if (_brandTapCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 700),
          content: Text('🛠️ Opsi Developer dalam ${5 - _brandTapCount} ketukan lagi...'),
        ),
      );
    }
  }

  void _showDeveloperJsonModal() {
    widget.udpService.fetchPlaylistJson(1);
    widget.udpService.fetchPlaylistJson(2);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Developer Console',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: Dialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.all(16),
            child: DefaultTabController(
              length: 2,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    // HEADER DEVELOPER CONSOLE
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.code_rounded, color: Color(0xFF38BDF8), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Developer JSON Inspector',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Inspeksi File LittleFS ESP8266 Real-Time',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // TAB BAR UNTUK D4 vs D5
                    const TabBar(
                      indicatorColor: Color(0xFF38BDF8),
                      labelColor: Color(0xFF38BDF8),
                      unselectedLabelColor: Color(0xFF64748B),
                      tabs: [
                        Tab(text: 'presets_d4.json (Jam)'),
                        Tab(text: 'presets_d5.json (Nama)'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildJsonView(1),
                          _buildJsonView(2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // REFRESH BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'IP: ${widget.udpService.currentTargetIp}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh ESP JSON', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            widget.udpService.fetchPlaylistJson(1);
                            widget.udpService.fetchPlaylistJson(2);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJsonView(int targetId) {
    return ValueListenableBuilder<EspConnectionState>(
      valueListenable: widget.udpService.connectionState,
      builder: (context, connState, child) {
        final bool isConnected = connState == EspConnectionState.connected;

        return ValueListenableBuilder<List<PresetItem>>(
          valueListenable: targetId == 2
              ? widget.udpService.playlistNotifierD5
              : widget.udpService.playlistNotifierD4,
          builder: (context, presets, child) {
            String jsonString;
            if (!isConnected) {
              jsonString = const JsonEncoder.withIndent('  ').convert({
                "status": "OFFLINE / ESP8266 BELUM TERHUBUNG",
                "file": targetId == 2 ? "presets_d5.json" : "presets_d4.json",
                "kecerahan": 0,
                "presets": [],
              });
            } else {
              final config = StripConfigPresets(kecerahan: 255, presets: presets);
              jsonString = const JsonEncoder.withIndent('  ').convert(config.toJson());
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonString,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: isConnected ? const Color(0xFF34D399) : const Color(0xFFF87171),
                    height: 1.4,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
              // ── KIRI: IDS-TECH (5-TAP FOR DEVELOPER JSON INSPECTOR) ────
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
                          Icon(Icons.bolt_rounded, color: Colors.white, size: iconSz),
                          SizedBox(width: 3 * scale),
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

                      // TIME PILL (purple gradient)
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

              // ── KANAN: STATUS DOT + WIFI BUTTON ─────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ValueListenableBuilder<EspConnectionState>(
                    valueListenable: widget.udpService.connectionState,
                    builder: (context, state, _) {
                      final isConnected = state == EspConnectionState.connected;
                      return Container(
                        width: 8 * scale,
                        height: 8 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          boxShadow: [
                            BoxShadow(
                              color: (isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
