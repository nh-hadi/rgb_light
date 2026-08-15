import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. TAMPILKAN STATUS BAR & BAR NAVIGASI SISTEM HP SECARA NORMAL (STANDAR)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values, // Status bar & Navigasi HP tetap tampil normal
  );

  // 2. KUSTOMISASI WARNA STATUS BAR AGAR MONOKROM / WARNA LATAR APLIKASI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF8FAFC), // Warna sama persis dengan latar belakang app
      statusBarIconBrightness: Brightness.dark, // Ikon status bar gelap (jam, baterai)
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF8FAFC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ControlledApp());
}

class ControlledApp extends StatelessWidget {
  const ControlledApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ambient Light',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}
