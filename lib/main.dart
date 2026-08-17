import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // MENGATUR MODE IMMERSIVE STICKY: NAVIGASI BISTEM HP TIDAK AKAN MUNCUL SAAT LAYAR DISENTUH!
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // KUSTOMISASI STATUS BAR ATAS
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
