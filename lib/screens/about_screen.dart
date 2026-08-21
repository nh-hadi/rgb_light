import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../esp_udp_service.dart';
import '../security_config.dart';
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
    if (widget.udpService.connectionState.value == EspConnectionState.connected) {
      widget.udpService.fetchHardwareInfo();
    }
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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Row(
                children: const [
                  Icon(Icons.system_update_rounded, color: Color(0xFF0284C7), size: 20),
                  SizedBox(width: 8),
                  Text('Perbarui Sistem', style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'Sistem & Firmware perangkat Anda sudah menggunakan versi paling baru.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
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

  void _showDetailSpecsModal(Map<String, dynamic>? hwInfo) {
    final String sig = hwInfo?['signature'] ?? '';
    final bool isConnected = widget.udpService.connectionState.value == EspConnectionState.connected;
    final bool isVerified = isConnected && (sig == SecurityConfig.appSecuritySignature);

    final String securityStatusText = isVerified
        ? 'Aktif (Terdaftar)'
        : (isConnected ? 'Tidak Terdaftar' : 'Offline (Tidak Aktif)');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Info Detail dan Spesifikasi',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.developer_board_rounded,
                iconColor: const Color(0xFF0284C7),
                label: 'Model Hardware',
                value: hwInfo?['hardwareModel'] ?? 'Unknown',
              ),
              _buildDetailRow(
                icon: Icons.memory_rounded,
                iconColor: const Color(0xFF8B5CF6),
                label: 'Firmware Version',
                value: hwInfo?['firmwareVersion'] ?? 'Unknown',
              ),
              _buildDetailRow(
                icon: Icons.qr_code_2_rounded,
                iconColor: const Color(0xFFEC4899),
                label: 'Chip ID',
                value: hwInfo?['chipId'] ?? 'Unknown',
              ),
              _buildDetailRow(
                icon: Icons.storage_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: 'Flash Memory',
                value: hwInfo?['flashSize'] ?? 'Unknown',
              ),
              _buildDetailRow(
                icon: Icons.verified_user_rounded,
                iconColor: isVerified ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                label: 'Status Keamanan',
                value: securityStatusText,
              ),
              _buildDetailRow(
                icon: Icons.engineering_rounded,
                iconColor: const Color(0xFF6366F1),
                label: 'Pengembang',
                value: 'IDS-TECH Engineering Team',
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Toko Resmi & Workshop',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.map_rounded, color: Color(0xFF0284C7), size: 16),
                      label: const Text('Lokasi Workshop', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        _openExternalUrl('https://maps.google.com/?q=IDS-TECH', 'Google Maps');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.chat_rounded, color: Color(0xFF10B981), size: 16),
                      label: const Text('WhatsApp CS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        _openExternalUrl('https://wa.me/6281234567890', 'WhatsApp CS');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // TEMA TERANG APLIKASI
      body: Stack(
        children: [
          // KONTEN UTAMA DENGAN CLEARANCE TOP PRESISI (72px)
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // 1. TOP CLEARANCE PRESISI SAMA SEPERTI MENU LAIN (72px)
                const SizedBox(height: 72),

                // 2. KARTU HEADER IDS-STORE DENGAN GRADASI BIRU TUA MEWAH
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                        Color(0xFF2C2493),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2C2493).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // TITLE: IDS-STORE
                      const Text(
                        'IDS-STORE',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // SUBTITLE: SMART DUAL-STRIP LED CONTROLLER V2
                      const Text(
                        'SMART DUAL-STRIP LED CONTROLLER V2',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // STATUS BADGE: VERIFIED OFFICIAL HARDWARE DENGAN ICON CENTANG
                      ValueListenableBuilder<Map<String, dynamic>?>(
                        valueListenable: widget.udpService.hardwareInfoNotifier,
                        builder: (context, hwInfo, _) {
                          final String sig = hwInfo?['signature'] ?? '';
                          final bool isConnected =
                              widget.udpService.connectionState.value == EspConnectionState.connected;
                          final bool isVerified = isConnected && (sig == SecurityConfig.appSecuritySignature);

                          final Color badgeBg = isVerified
                              ? const Color(0xFF059669).withValues(alpha: 0.25)
                              : (isConnected
                                  ? const Color(0xFFD97706).withValues(alpha: 0.25)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.25));

                          final Color badgeBorder = isVerified
                              ? const Color(0xFF34D399)
                              : (isConnected ? const Color(0xFFFBBF24) : const Color(0xFFF87171));

                          final String badgeText = isVerified
                              ? 'VERIFIED OFFICIAL HARDWARE'
                              : (isConnected ? 'UNVERIFIED HARDWARE' : 'HARDWARE OFFLINE');

                          final IconData badgeIcon = isVerified
                              ? Icons.verified_rounded
                              : (isConnected ? Icons.gpp_maybe_rounded : Icons.wifi_off_rounded);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: badgeBorder, width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, color: badgeBorder, size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: badgeBorder,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. HYPEROS STACKED CARDS TEMA TERANG APLIKASI
                ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: widget.udpService.hardwareInfoNotifier,
                  builder: (context, hwInfo, _) {
                    final String model = hwInfo?['hardwareModel'] ?? 'Unknown';
                    final String firmware = hwInfo?['firmwareVersion'] ?? 'Unknown';
                    final String chipId = hwInfo?['chipId'] ?? 'Unknown';
                    final String flashSize = hwInfo?['flashSize'] ?? 'Unknown';
                    final String sig = hwInfo?['signature'] ?? '';

                    final bool isConnected =
                        widget.udpService.connectionState.value == EspConnectionState.connected;
                    final bool isVerified = isConnected && (sig == SecurityConfig.appSecuritySignature);

                    return Column(
                      children: [
                        // CARD 1: NAMA PERANGKAT
                        _buildHyperCardTile(
                          label: 'Nama perangkat',
                          value: model,
                          onTap: null,
                        ),
                        const SizedBox(height: 6),

                        // CARD 2: PENYIMPANAN SYSTEM
                        _buildHyperCardTile(
                          label: 'Penyimpanan System',
                          value: flashSize,
                          onTap: null,
                        ),
                        const SizedBox(height: 6),

                        // CARD 3: STATUS KEAMANAN
                        _buildHyperCardTile(
                          label: 'Status Keamanan',
                          valueWidget: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isVerified
                                      ? const Color(0xFF10B981)
                                      : (isConnected ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isVerified
                                    ? 'Aktif & Terdaftar'
                                    : (isConnected ? 'Tidak Terdaftar' : 'Offline'),
                                style: TextStyle(
                                  color: isVerified
                                      ? const Color(0xFF10B981)
                                      : (isConnected ? const Color(0xFFD97706) : const Color(0xFFEF4444)),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          onTap: null,
                        ),
                        const SizedBox(height: 6),

                        // CARD 4: VERSI FIRMWARE
                        _buildHyperCardTile(
                          label: 'Versi Firmware ESP',
                          value: firmware,
                          onTap: null,
                        ),
                        const SizedBox(height: 6),

                        // CARD 5: VERSI APLIKASI
                        _buildHyperCardTile(
                          label: 'Versi Aplikasi Mobile',
                          value: 'v2.4.0 (Build 2026.08)',
                          onTap: null,
                        ),
                        const SizedBox(height: 6),

                        // CARD 6: CHIP ID
                        _buildHyperCardTile(
                          label: 'Chip ID Controller',
                          value: chipId,
                          onTap: null,
                        ),
                        const SizedBox(height: 6),

                        // CARD 7: INFO DETAIL DAN SPESIFIKASI (SATU-SATUNYA YANG BISA DIKLIK!)
                        _buildHyperCardTile(
                          label: 'Info detail dan spesifikasi',
                          value: '',
                          isClickable: true,
                          onTap: () => _showDetailSpecsModal(hwInfo),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 4. BARIS IKON BRAND LOGO ASLI (WA, IG, SHOPEE, WEB, MAPS)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AnimatedBrandButton(
                      label: 'WhatsApp',
                      brandType: _BrandLogoType.whatsapp,
                      brandColor: const Color(0xFF25D366),
                      onTap: () => _openExternalUrl('https://wa.me/6281234567890', 'WhatsApp CS'),
                    ),
                    _AnimatedBrandButton(
                      label: 'Instagram',
                      brandType: _BrandLogoType.instagram,
                      brandColor: const Color(0xFFE1306C),
                      onTap: () => _openExternalUrl('https://instagram.com/idstech_official', 'Instagram Official'),
                    ),
                    _AnimatedBrandButton(
                      label: 'Shopee',
                      brandType: _BrandLogoType.shopee,
                      brandColor: const Color(0xFFEE4D2D),
                      onTap: () => _openExternalUrl('https://shopee.co.id/idstech', 'Shopee Official Store'),
                    ),
                    _AnimatedBrandButton(
                      label: 'Website',
                      brandType: _BrandLogoType.website,
                      brandColor: const Color(0xFF0284C7),
                      onTap: () => _openExternalUrl('https://idstech.co.id', 'Website Resmi'),
                    ),
                    _AnimatedBrandButton(
                      label: 'Maps',
                      brandType: _BrandLogoType.maps,
                      brandColor: const Color(0xFFEF4444),
                      onTap: () => _openExternalUrl('https://maps.google.com/?q=IDS-TECH', 'Google Maps Workshop'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // FOOTER COPYRIGHT
                const Text(
                  '© 2026 IDS-TECH Engineering Team.\nAll Rights Reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),

                // 5. BOTTOM CLEARANCE UNTUK FLOATING BOTTOM NAV BAR (95px)
                const SizedBox(height: 95),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHyperCardTile({
    required String label,
    String? value,
    Widget? valueWidget,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClickable
              ? const Color(0xFF0284C7)
              : const Color(0xFFE2E8F0),
          width: isClickable ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isClickable
                ? const Color(0xFF0284C7).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: isClickable ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isClickable ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: isClickable ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
                if (valueWidget != null) ...[
                  const SizedBox(width: 8),
                  valueWidget,
                ] else if (value != null && value.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (isClickable) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF0284C7),
                    size: 13,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _BrandLogoType { whatsapp, instagram, shopee, website, maps }

/// TOMBOL LOGO BRAND ASLI DENGAN MIKRO-ANIMASI
class _AnimatedBrandButton extends StatefulWidget {
  final String label;
  final _BrandLogoType brandType;
  final Color brandColor;
  final VoidCallback onTap;

  const _AnimatedBrandButton({
    required this.label,
    required this.brandType,
    required this.brandColor,
    required this.onTap,
  });

  @override
  State<_AnimatedBrandButton> createState() => _AnimatedBrandButtonState();
}

class _AnimatedBrandButtonState extends State<_AnimatedBrandButton> {
  bool _isPressed = false;

  Widget _buildBrandLogo() {
    switch (widget.brandType) {
      case _BrandLogoType.whatsapp:
        return CustomPaint(
          size: const Size(20, 20),
          painter: _WhatsAppLogoPainter(color: widget.brandColor),
        );
      case _BrandLogoType.instagram:
        return CustomPaint(
          size: const Size(20, 20),
          painter: _InstagramLogoPainter(color: widget.brandColor),
        );
      case _BrandLogoType.shopee:
        return CustomPaint(
          size: const Size(20, 20),
          painter: _ShopeeLogoPainter(color: widget.brandColor),
        );
      case _BrandLogoType.website:
        return CustomPaint(
          size: const Size(20, 20),
          painter: _WebLogoPainter(color: widget.brandColor),
        );
      case _BrandLogoType.maps:
        return CustomPaint(
          size: const Size(20, 20),
          painter: _MapsLogoPainter(color: widget.brandColor),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.brandColor.withValues(alpha: _isPressed ? 0.85 : 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.brandColor.withValues(alpha: _isPressed ? 0.35 : 0.1),
                    blurRadius: _isPressed ? 10 : 6,
                    spreadRadius: _isPressed ? 1.0 : 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: Center(child: _buildBrandLogo()),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CUSTOM LOGO PAINTERS ────────────────────────────────────────────────────

class _WhatsAppLogoPainter extends CustomPainter {
  final Color color;
  _WhatsAppLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.48), radius: size.width * 0.42));
    path.moveTo(size.width * 0.22, size.height * 0.78);
    path.lineTo(size.width * 0.10, size.height * 0.90);
    path.lineTo(size.width * 0.35, size.height * 0.85);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.42), 2.2, fillPaint);
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.58), 2.2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InstagramLogoPainter extends CustomPainter {
  final Color color;
  _InstagramLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(rrect, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4.2, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width - 5, 5), 1.3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShopeeLogoPainter extends CustomPainter {
  final Color color;
  _ShopeeLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final handlePath = Path();
    handlePath.addArc(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.05, size.width * 0.4, size.height * 0.4),
      math.pi,
      math.pi,
    );
    canvas.drawPath(handlePath, strokePaint);

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, size.height * 0.28, size.width - 4, size.height * 0.68),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(bodyRRect, strokePaint);

    final sPath = Path();
    sPath.moveTo(size.width * 0.60, size.height * 0.44);
    sPath.cubicTo(size.width * 0.40, size.height * 0.44, size.width * 0.40, size.height * 0.58, size.width * 0.50, size.height * 0.62);
    sPath.cubicTo(size.width * 0.60, size.height * 0.66, size.width * 0.60, size.height * 0.80, size.width * 0.40, size.height * 0.80);
    canvas.drawPath(sPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WebLogoPainter extends CustomPainter {
  final Color color;
  _WebLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    canvas.drawCircle(center, radius, strokePaint);
    canvas.drawLine(Offset(1, center.dy), Offset(size.width - 1, center.dy), strokePaint);

    final meridianPath = Path();
    meridianPath.addOval(Rect.fromLTWH(size.width * 0.22, 1, size.width * 0.56, size.height - 2));
    canvas.drawPath(meridianPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapsLogoPainter extends CustomPainter {
  final Color color;
  _MapsLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pinPath = Path();
    pinPath.moveTo(size.width * 0.5, size.height * 0.95);
    pinPath.cubicTo(
      size.width * 0.15, size.height * 0.60,
      size.width * 0.10, size.height * 0.35,
      size.width * 0.50, size.height * 0.10,
    );
    pinPath.cubicTo(
      size.width * 0.90, size.height * 0.35,
      size.width * 0.85, size.height * 0.60,
      size.width * 0.50, size.height * 0.95,
    );

    canvas.drawPath(pinPath, strokePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), 2.8, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
