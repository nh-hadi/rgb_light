import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. MENGATUR MODE FULL SCREEN IMMERSIVE (NAVIGASI HP BAWAH SEMBUNYI OTOMATIS)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // 2. KUSTOMISASI WARNA STATUS BAR & BAR NAVIGASI HP (SISTEM)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent / menyatu dengan latar
      statusBarIconBrightness: Brightness.dark, // Ikon status bar gelap (jam, battery)
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
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
