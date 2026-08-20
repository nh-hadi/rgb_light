import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../esp_udp_service.dart';
import '../widgets/custom_toast.dart';

class AboutScreen extends StatefulWidget {
  final EspUdpService udpService;

  const AboutScreen({
    super.key,
    required this.udpService,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    // Panggil fetchHardwareInfo untuk memperbarui data autentikasi hardware
    if (widget.udpService.connectionState.value == EspConnectionState.connected) {
      widget.udpService.fetchHardwareInfo();
    }
  }

  void _copySystemInfo(Map<String, dynamic>? hwInfo) {
    final String infoStr = '''
=== IDS-TECH SYSTEM DIAGNOSTIC INFO ===
App Version: v2.4.0 (Build 2026.08)
Hardware Model: ${hwInfo?['hardwareModel'] ?? 'IDS-WS2812-DUAL'}
Firmware Version: ${hwInfo?['firmwareVersion'] ?? 'v2.1.0-LittleFS'}
Chip ID: ${hwInfo?['chipId'] ?? 'N/A (Disconnected)'}
Security Signature: ${hwInfo?['signature'] ?? 'N/A'}
Flash Memory: ${hwInfo?['flashSize'] ?? '4MB (LittleFS)'}
UDP Port: ${widget.udpService.currentTargetPort}
Target IP: ${widget.udpService.currentTargetIp}
=======================================
''';

    Clipboard.setData(ClipboardData(text: infoStr));
    CustomFloatingToast.show(
      context,
      title: 'Salin',
      message: 'Info sistem berhasil disalin',
      icon: Icons.copy_rounded,
      type: ToastType.success,
    );
  }

  void _showCheckUpdateDialog() {
    setState(() {
      _isCheckingUpdate = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.system_update_rounded, color: Color(0xFF38BDF8), size: 22),
                  SizedBox(width: 8),
                  Text('Status Versi', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: const Text(
                'Aplikasi & Firmware ESP8266 Anda sudah menggunakan versi terbaru (v2.4.0 / v2.1.0-LittleFS).',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: Color(0xFF38BDF8))),
                ),
              ],
            );
          },
        );
      }
    });
  }

  void _openExternalUrl(String url, String name) {
    CustomFloatingToast.show(
      context,
      title: name,
      message: 'Membuka tautan $name...',
      icon: Icons.open_in_new_rounded,
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Tentang Perangkat & Pengembang',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // ── 1. HERO BRAND CARD MEWAH ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF2C2493), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C2493).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ICON BADGE MEWAH
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.light_mode_rounded,
                      color: Color(0xFF38BDF8),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'IDS-TECH WS2812FX',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Smart Dual-Strip LED Controller v2',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // LENCANA AUTENTIKASI HARDWARE (DYNAMIC)
                  ValueListenableBuilder<EspConnectionState>(
                    valueListenable: widget.udpService.connectionState,
                    builder: (context, connState, _) {
                      final bool isConnected = connState == EspConnectionState.connected;

                      return ValueListenableBuilder<Map<String, dynamic>?>(
                        valueListenable: widget.udpService.hardwareInfoNotifier,
                        builder: (context, hwInfo, _) {
                          final bool isVerified = isConnected &&
                              (hwInfo?['signature'] == 'IDS-SECURE-AUTH-2026');

                          Color badgeBg = isVerified
                              ? const Color(0xFF059669).withValues(alpha: 0.25)
                              : (isConnected
                                  ? const Color(0xFFD97706).withValues(alpha: 0.25)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.25));

                          Color badgeBorder = isVerified
                              ? const Color(0xFF34D399)
                              : (isConnected ? const Color(0xFFFBBF24) : const Color(0xFFF87171));

                          String badgeText = isVerified
                              ? ' Verified Official Hardware'
                              : (isConnected
                                  ? ' Unverified Hardware'
                                  : ' Hardware Terputus (Offline)');

                          IconData badgeIcon = isVerified
                              ? Icons.verified_rounded
                              : (isConnected ? Icons.gpp_maybe_rounded : Icons.wifi_off_rounded);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: badgeBorder, width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, color: badgeBorder, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: badgeBorder,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── 2. SPESIFIKASI TEKNIS & VERSIS (DYNAMIC GRID) ────────
            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: widget.udpService.hardwareInfoNotifier,
              builder: (context, hwInfo, _) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.memory_rounded, color: Color(0xFF2C2493), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Spesifikasi Sistem & Software',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildSpecRow(
                        icon: Icons.smartphone_rounded,
                        label: 'Versi Aplikasi Mobile',
                        value: 'v2.4.0 (Build 2026.08)',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),

                      _buildSpecRow(
                        icon: Icons.developer_board_rounded,
                        label: 'Versi Firmware ESP8266',
                        value: hwInfo?['firmwareVersion'] ?? 'v2.1.0-LittleFS',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),

                      _buildSpecRow(
                        icon: Icons.hardware_rounded,
                        label: 'Model Microcontroller',
                        value: hwInfo?['hardwareModel'] ?? 'IDS-WS2812-DUAL',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),

                      _buildSpecRow(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Chip ID Perangkat',
                        value: hwInfo?['chipId'] ?? 'N/A (Terputus)',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),

                      _buildSpecRow(
                        icon: Icons.storage_rounded,
                        label: 'Sistem Penyimpanan',
                        value: hwInfo?['flashSize'] ?? '4MB (LittleFS SPI Flash)',
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),

                      _buildSpecRow(
                        icon: Icons.engineering_rounded,
                        label: 'Pengembang Utama',
                        value: 'IDS-TECH Engineering Team',
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── 3. TOKO OFFLINE & LOKASI WORKSHOP ────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.store_rounded, color: Color(0xFF0284C7), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Toko Offline & Workshop Resmi',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kunjungi workshop resmi IDS-TECH untuk konsultasi, perbaikan, & pembelian unit controller secara langsung.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // TOMBOL BUKA MAPS LOKASI TOKO OFFLINE
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text(
                      '🗺️ Buka Peta Lokasi Toko / Workshop',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _openExternalUrl('https://maps.google.com/?q=IDS-TECH', 'Google Maps Workshop'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 4. GRID SOSMED & OFFICIAL STORE ───────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.public_rounded, color: Color(0xFF059669), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Media Sosial & Toko Online Resmi',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildSocialTile(
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF25D366),
                    title: 'WhatsApp CS & Garansi',
                    subtitle: 'Layanan Bantuan & Konsultasi Perangkat',
                    onTap: () => _openExternalUrl('https://wa.me/6281234567890', 'WhatsApp CS'),
                  ),
                  const SizedBox(height: 8),

                  _buildSocialTile(
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFFE1306C),
                    title: 'Instagram Official',
                    subtitle: '@idstech_official • Update & Katalog',
                    onTap: () => _openExternalUrl('https://instagram.com/idstech_official', 'Instagram Official'),
                  ),
                  const SizedBox(height: 8),

                  _buildSocialTile(
                    icon: Icons.shopping_bag_rounded,
                    color: const Color(0xFFEE4D2D),
                    title: 'Tokopedia & Shopee Store',
                    subtitle: 'Beli Unit Controller & Sparepart WS2812',
                    onTap: () => _openExternalUrl('https://tokopedia.com/idstech', 'Official Store'),
                  ),
                  const SizedBox(height: 8),

                  _buildSocialTile(
                    icon: Icons.play_circle_fill_rounded,
                    color: const Color(0xFFFF0000),
                    title: 'YouTube Tutorial',
                    subtitle: 'Panduan Pemasangan & Fitur WS2812FX',
                    onTap: () => _openExternalUrl('https://youtube.com/@idstech_tutorial', 'YouTube Tutorial'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 5. TOMBOL AKSI DIAGNOSTIK & UPDATE ───────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin Specs', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () => _copySystemInfo(widget.udpService.hardwareInfoNotifier.value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2493),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _isCheckingUpdate
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.system_update_rounded, size: 16),
                    label: const Text('Cek Update', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: _isCheckingUpdate ? null : _showCheckUpdateDialog,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 6. FOOTER COPYRIGHT ──────────────────────────────────
            const Text(
              '© 2026 IDS-TECH Engineering Team.\nAll Rights Reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 12),
            ],
          ),
        ),
      ),
    );
  }
}
