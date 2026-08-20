import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../esp_udp_service.dart';
import '../models/preset_model.dart';
import 'custom_toast.dart';

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
      CustomFloatingToast.show(
        context,
        title: 'Developer',
        message: 'Ketuk ${5 - _brandTapCount}x lagi',
        icon: Icons.developer_mode_rounded,
        type: ToastType.info,
        duration: const Duration(milliseconds: 1000),
      );
    }
  }

  void _showDeveloperJsonModal() {
    widget.udpService.fetchPlaylistJson(1);
    widget.udpService.fetchPlaylistJson(2);

    showGeneralDialog(
      context: context,
      barrierDismissible: false, // HARUS KLIK TOMBOL (X) DULU BARU KELUAR
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
              length: 3, // 3 TAB: D4, D5, KONEKSI UDP
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440, maxHeight: 530),
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
                                'Developer Inspector',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Inspeksi JSON LittleFS & Tes UDP WiFi',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        // TOMBOL (X) KHUSUS UNTUK KELUAR
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // TAB BAR UNTUK D4, D5 & NETWORK SETTINGS
                    const TabBar(
                      indicatorColor: Color(0xFF38BDF8),
                      labelColor: Color(0xFF38BDF8),
                      unselectedLabelColor: Color(0xFF64748B),
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'presets_d4.json'),
                        Tab(text: 'presets_d5.json'),
                        Tab(text: '⚙️ Network & UDP'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildJsonView(1),
                          _buildJsonView(2),
                          _buildNetworkSettingsTab(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // REFRESH BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target: ${widget.udpService.currentTargetIp}:${widget.udpService.currentTargetPort}',
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

  Widget _buildNetworkSettingsTab() {
    return _NetworkSettingsTabWidget(udpService: widget.udpService);
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

// LED BLINKING DOT: PUTIH SAAT DISCONNECTED, KEDIP-KEDIP MERAH-BIRU-PUTIH SAAT CONNECTED
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
    Color(0xFFFF3B30), // Red
    Color(0xFF007AFF), // Blue
    Color(0xFFFFFFFF), // White
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

// PANEL TAB NETWORK & UDP SETTINGS DI DALAM DEVELOPER MODAL
class _NetworkSettingsTabWidget extends StatefulWidget {
  final EspUdpService udpService;
  const _NetworkSettingsTabWidget({required this.udpService});

  @override
  State<_NetworkSettingsTabWidget> createState() => _NetworkSettingsTabWidgetState();
}

class _NetworkSettingsTabWidgetState extends State<_NetworkSettingsTabWidget> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  String _pingResult = '';
  bool _isTestingPing = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.udpService.currentTargetIp);
    _portController = TextEditingController(text: widget.udpService.currentTargetPort.toString());
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testPing() async {
    setState(() {
      _isTestingPing = true;
      _pingResult = 'Menguji koneksi UDP ke ESP8266...';
    });

    final stopwatch = Stopwatch()..start();
    widget.udpService.queryState();

    await Future.delayed(const Duration(milliseconds: 600));
    stopwatch.stop();

    if (mounted) {
      final bool isConn = widget.udpService.connectionState.value == EspConnectionState.connected;
      setState(() {
        _isTestingPing = false;
        if (isConn) {
          _pingResult = '⚡ PING OK: Latensi ${stopwatch.elapsedMilliseconds} ms (${widget.udpService.currentTargetIp}:${widget.udpService.currentTargetPort})';
        } else {
          _pingResult = '❌ PING GAGAL: ESP8266 Tidak Merespons di ${widget.udpService.currentTargetIp}:${widget.udpService.currentTargetPort}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ PENGATURAN ALAMAT IP & PORT UDP ESP8266',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Target IP Address (ESP8266 AP)',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                prefixIcon: const Icon(Icons.router_rounded, color: Color(0xFF38BDF8), size: 18),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Target Port UDP',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                prefixIcon: const Icon(Icons.settings_ethernet_rounded, color: Color(0xFF38BDF8), size: 18),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Simpan & Reconnect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final ip = _ipController.text.trim();
                      final port = int.tryParse(_portController.text.trim()) ?? 8888;
                      widget.udpService.updateConnectionSettings(ip, port);
                      CustomFloatingToast.show(
                        context,
                        title: 'Koneksi',
                        message: 'Pengaturan IP UDP disimpan',
                        icon: Icons.wifi_protected_setup_rounded,
                        type: ToastType.success,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFF38BDF8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isTestingPing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                      : const Icon(Icons.network_check_rounded, size: 16),
                  label: const Text('Tes Ping', style: TextStyle(fontSize: 12)),
                  onPressed: _isTestingPing ? null : _testPing,
                ),
              ],
            ),
            if (_pingResult.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  _pingResult,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFE2E8F0), fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
