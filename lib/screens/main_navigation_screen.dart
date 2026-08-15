import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../esp_udp_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
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

    final String appBarTitle = switch (_currentIndex) {
      0 => 'Lampu Jam Utama (D4)',
      1 => 'Variasi Nama Custom (D5)',
      2 => 'Setting Alarm',
      3 => 'Pengaturan App',
      _ => 'Tentang Perangkat',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF0284C7),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              appBarTitle,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_find_rounded, color: Color(0xFF0284C7)),
            tooltip: 'Buka Pengaturan WiFi HP',
            onPressed: _openWifiSettings,
          ),
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded,
                color: Color(0xFF2563EB)),
            tooltip: 'Atur & Tes IP ESP',
            onPressed: _showManualIpDialog,
          ),
          ValueListenableBuilder<EspConnectionState>(
            valueListenable: _udpService.connectionState,
            builder: (context, state, child) {
              final isConnected = state == EspConnectionState.connected;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _udpService.queryState(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isConnected
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        border: Border.all(
                          color: isConnected
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            size: 15,
                            color: isConnected
                                ? const Color(0xFF34C759)
                                : const Color(0xFFFF3B30),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isConnected ? 'Terhubung' : 'Terputus',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isConnected
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
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
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomFloatingBottomNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: navItems,
      ),
    );
  }
}
