import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // MENGATUR HANYA BAR NAVIGASI SISTEM HP BAWAH YANG HILANG, STATUS BAR ATAS TETAP TAMPIL
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top], // Hanya tampilkan Status Bar Atas, Sembunyikan Navigasi Bawah HP!
  );

  // KUSTOMISASI WARNA STATUS BAR ATAS
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF8FAFC), // Warna latar atas menyatu dengan aplikasi
      statusBarIconBrightness: Brightness.dark, // Ikon status bar gelap (jam, baterai)
      statusBarBrightness: Brightness.light,
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
