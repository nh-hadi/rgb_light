import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../esp_udp_service.dart';
import '../models/preset_model.dart';
import 'custom_toast.dart';

/// Modal Inspeksi Developer & PIN Dialog Rahasia (020304)
class DeveloperInspectorModal {
  static const String secretPin = '020304';

  static void showPinDialog({
    required BuildContext context,
    required EspUdpService udpService,
  }) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
          ),
          title: Row(
            children: const [
              Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Opsi Pengembang',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan PIN Pengembang Rahasia:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 6,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: const TextStyle(color: Color(0xFF475569), letterSpacing: 4),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF38BDF8), size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                final enteredPin = pinController.text.trim();
                Navigator.pop(dialogContext);

                if (enteredPin == secretPin) {
                  CustomFloatingToast.show(
                    context,
                    title: 'Opsi Pengembang',
                    message: 'Akses Inspector JSON Berhasil!',
                    icon: Icons.verified_rounded,
                    type: ToastType.success,
                  );
                  showInspector(context: context, udpService: udpService);
                } else {
                  CustomFloatingToast.show(
                    context,
                    title: 'Akses Ditolak',
                    message: 'PIN Pengembang Salah!',
                    icon: Icons.error_outline_rounded,
                    type: ToastType.error,
                  );
                }
              },
              child: const Text('Verifikasi PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  static void showInspector({
    required BuildContext context,
    required EspUdpService udpService,
  }) {
    udpService.fetchHardwareInfo();
    udpService.fetchPlaylistJson(1);
    udpService.fetchPlaylistJson(2);
    udpService.queryState();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Developer Inspector',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          child: Dialog(
            backgroundColor: const Color(0xFF0B1120),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
            ),
            insetPadding: const EdgeInsets.all(12),
            child: DefaultTabController(
              length: 5,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // TOP BAR CONSOLE IDE STYLE
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.terminal_rounded, color: Color(0xFF38BDF8), size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEVELOPER JSON INSPECTOR',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'Inspeksi JSON Real-Time ESP8266 & Socket UDP',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // TAB BAR KARTU RESMI UNTUK JSON VIEW
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF94A3B8),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        isScrollable: true,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'info.json'),
                          Tab(text: 'presets_d4.json'),
                          Tab(text: 'presets_d5.json'),
                          Tab(text: 'state.json'),
                          Tab(text: '⚙️ UDP Settings'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildHardwareInfoJsonView(udpService),
                          _buildJsonView(udpService, 1),
                          _buildJsonView(udpService, 2),
                          _buildStateJsonView(udpService),
                          _NetworkSettingsTabWidget(udpService: udpService),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // FOOTER UDP STATS & REFRESH BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'IP: ${udpService.currentTargetIp}:${udpService.currentTargetPort}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontFamily: 'monospace'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('Refresh JSON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            udpService.fetchHardwareInfo();
                            udpService.fetchPlaylistJson(1);
                            udpService.fetchPlaylistJson(2);
                            udpService.queryState();
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

  static Widget _buildHardwareInfoJsonView(EspUdpService udpService) {
    return ValueListenableBuilder<EspConnectionState>(
      valueListenable: udpService.connectionState,
      builder: (context, connState, child) {
        final bool isConnected = connState == EspConnectionState.connected;
        return ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: udpService.hardwareInfoNotifier,
          builder: (context, hwInfo, _) {
            String jsonString;
            if (!isConnected || hwInfo == null) {
              jsonString = const JsonEncoder.withIndent('  ').convert({
                "status": "OFFLINE / ESP8266 BELUM TERHUBUNG",
                "hardwareModel": "Unknown",
                "firmwareVersion": "Unknown",
                "chipId": "Unknown",
                "signature": "Unknown",
                "flashSize": "Unknown"
              });
            } else {
              jsonString = const JsonEncoder.withIndent('  ').convert(hwInfo);
            }

            return _buildConsoleCodeBox(context, jsonString, isConnected);
          },
        );
      },
    );
  }

  static Widget _buildJsonView(EspUdpService udpService, int targetId) {
    return ValueListenableBuilder<EspConnectionState>(
      valueListenable: udpService.connectionState,
      builder: (context, connState, child) {
        final bool isConnected = connState == EspConnectionState.connected;

        final brightnessNotifier = targetId == 2
            ? udpService.brightnessNotifierD5
            : udpService.brightnessNotifierD4;

        final playlistNotifier = targetId == 2
            ? udpService.playlistNotifierD5
            : udpService.playlistNotifierD4;

        return ValueListenableBuilder<int>(
          valueListenable: brightnessNotifier,
          builder: (context, currentBrightness, _) {
            return ValueListenableBuilder<List<PresetItem>>(
              valueListenable: playlistNotifier,
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
                  final config = StripConfigPresets(
                    kecerahan: currentBrightness,
                    presets: presets,
                  );
                  jsonString = const JsonEncoder.withIndent('  ').convert(config.toJson());
                }

                return _buildConsoleCodeBox(context, jsonString, isConnected);
              },
            );
          },
        );
      },
    );
  }

  static Widget _buildStateJsonView(EspUdpService udpService) {
    return ValueListenableBuilder<EspConnectionState>(
      valueListenable: udpService.connectionState,
      builder: (context, connState, child) {
        final bool isConnected = connState == EspConnectionState.connected;
        return ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: udpService.espStateNotifier,
          builder: (context, stateMap, _) {
            String jsonString;
            if (!isConnected || stateMap == null) {
              jsonString = const JsonEncoder.withIndent('  ').convert({
                "status": "OFFLINE / ESP8266 BELUM TERHUBUNG",
                "color": "RGB(0,0,0)",
                "brightness": 0,
                "modeId": 0,
                "speedMs": 0,
                "isPreview": false
              });
            } else {
              jsonString = const JsonEncoder.withIndent('  ').convert(stateMap);
            }

            return _buildConsoleCodeBox(context, jsonString, isConnected);
          },
        );
      },
    );
  }

  static Widget _buildConsoleCodeBox(BuildContext context, String jsonString, bool isConnected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SelectableText(
                jsonString,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: isConnected ? const Color(0xFF34D399) : const Color(0xFFF87171),
                  height: 1.35,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.copy_rounded, color: Color(0xFF64748B), size: 16),
              tooltip: 'Salin JSON',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                CustomFloatingToast.show(
                  context,
                  title: 'Salin',
                  message: 'JSON berhasil disalin ke clipboard',
                  icon: Icons.content_copy_rounded,
                  type: ToastType.info,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ PENGATURAN ALAMAT IP & PORT UDP ESP8266',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              decoration: InputDecoration(
                labelText: 'Target IP Address (ESP8266 AP)',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                prefixIcon: const Icon(Icons.router_rounded, color: Color(0xFF38BDF8), size: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              decoration: InputDecoration(
                labelText: 'Target Port UDP',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                prefixIcon: const Icon(Icons.settings_ethernet_rounded, color: Color(0xFF38BDF8), size: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 14),
                    label: const Text('Simpan & Reconnect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isTestingPing
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                      : const Icon(Icons.network_check_rounded, size: 14),
                  label: const Text('Tes Ping', style: TextStyle(fontSize: 11)),
                  onPressed: _isTestingPing ? null : _testPing,
                ),
              ],
            ),
            if (_pingResult.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  _pingResult,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0), fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
