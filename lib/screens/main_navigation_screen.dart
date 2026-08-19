import 'dart:ui';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../esp_udp_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/header.dart';
import 'placeholder_screen.dart';
import 'strip_control_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final EspUdpService _udpService = EspUdpService();

  @override
  void initState() {
    super.initState();
    _udpService.init();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  @override
  void dispose() {
    _udpService.dispose();
    super.dispose();
  }

  void _openWifiSettings() {
    try {
      AppSettings.openAppSettings(type: AppSettingsType.wifi);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buka Pengaturan WiFi dari Menu HP Anda.')),
      );
    }
  }

  void _showWifiOptionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_ethernet_rounded, color: Color(0xFF0284C7)),
                  title: const Text('Atur & Tes IP ESP', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ubah alamat IP koneksi UDP'),
                  onTap: () {
                    Navigator.pop(context);
                    _showManualIpDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.wifi_find_rounded, color: Color(0xFF2563EB)),
                  title: const Text('Pengaturan WiFi HP', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Buka menu pengaturan WiFi perangkat'),
                  onTap: () {
                    Navigator.pop(context);
                    _openWifiSettings();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualIpDialog() {
    final controller = TextEditingController(text: _udpService.currentTargetIp);
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.router_rounded, color: Color(0xFF0284C7)),
                  SizedBox(width: 10),
                  Text('Atur & Tes IP ESP',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan IP ESP8266 (Default AP: 192.168.4.1):',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'IP Address ESP',
                      hintText: '192.168.4.1',
                      prefixIcon: const Icon(Icons.lan_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isTesting
                      ? null
                      : () async {
                          setDialogState(() {
                            isTesting = true;
                          });

                          final testIp = controller.text.trim();
                          final bool success =
                              await _udpService.testConnection(testIp);

                          if (mounted) {
                            setDialogState(() {
                              isTesting = false;
                            });

                            Navigator.pop(dialogContext);

                            if (success) {
                              _udpService.updateTargetIp(testIp);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green[700],
                                  content: Text(
                                      '✅ Berhasil Terhubung ke ESP ($testIp)!'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red[700],
                                  content: Text(
                                      '❌ ESP ($testIp) Tidak Merespons. Cek Koneksi WiFi HP.'),
                                ),
                              );
                            }
                          }
                        },
                  child: isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Tes & Simpan IP'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      SingleStripControlScreen(
        targetId: 1,
        title: 'Jam Utama (D4)',
        accentColor: const Color(0xFF0284C7),
        udpService: _udpService,
      ),
      SingleStripControlScreen(
        targetId: 2,
        title: 'Nama Custom (D5)',
        accentColor: const Color(0xFF2563EB),
        udpService: _udpService,
      ),
      const DevelopmentPlaceholderScreen(
        title: 'Setting Alarm',
        icon: Icons.alarm_rounded,
      ),
      const DevelopmentPlaceholderScreen(
        title: 'Pengaturan App',
        icon: Icons.tune_rounded,
      ),
      const DevelopmentPlaceholderScreen(
        title: 'Tentang Perangkat',
        icon: Icons.info_outline_rounded,
      ),
    ];

    // NAV ITEMS ULTRA-MODERN BLUE GRADIENTS
    final List<NavItemData> navItems = [
      const NavItemData(
        icon: Icons.schedule_outlined,
        selectedIcon: Icons.schedule_rounded,
        label: 'Jam D4',
        gradientColors: [Color(0xFF1D4ED8), Color(0xFF0284C7), Color(0xFF38BDF8)],
      ),
      const NavItemData(
        icon: Icons.palette_outlined,
        selectedIcon: Icons.palette_rounded,
        label: 'Nama D5',
        gradientColors: [Color(0xFF0284C7), Color(0xFF06B6D4), Color(0xFF22D3EE)],
      ),
      const NavItemData(
        icon: Icons.alarm_outlined,
        selectedIcon: Icons.alarm_rounded,
        label: 'Alarm',
        gradientColors: [Color(0xFF1D4ED8), Color(0xFF0284C7), Color(0xFF38BDF8)],
      ),
      const NavItemData(
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune_rounded,
        label: 'Setting',
        gradientColors: [Color(0xFF0284C7), Color(0xFF06B6D4), Color(0xFF22D3EE)],
      ),
      const NavItemData(
        icon: Icons.info_outline_rounded,
        selectedIcon: Icons.info_rounded,
        label: 'Tentang',
        gradientColors: [Color(0xFF1D4ED8), Color(0xFF0284C7), Color(0xFF38BDF8)],
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: Stack(
        children: [
          // Layer konten utama full-screen di belakang header & bottom bar
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),

          // Strip Blur Full-Width di belakang Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: const Color(0xFFF8FAFC).withValues(alpha: 0.70),
                  child: SafeArea(
                    bottom: false,
                    child: RtcHeader(
                      udpService: _udpService,
                      onWifiTap: _showWifiOptionsModal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Strip Blur Full-Width di belakang Floating Bottom Nav Bar
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: const Color(0xFFF8FAFC).withValues(alpha: 0.70),
            child: CustomFloatingBottomNavBar(
              selectedIndex: _currentIndex,
              onItemSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: navItems,
            ),
          ),
        ),
      ),
    );
  }
}
