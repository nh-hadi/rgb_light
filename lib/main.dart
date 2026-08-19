import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // HANYA TAMPILKAN STATUS BAR ATAS & SEMBUNYIKAN NAVIGASI BAWAH SISTEM HP (AGAR TIDAK NONGTOL/NGALANGIN)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  // KUSTOMISASI STATUS BAR TRANSPARAN (MENYATU WARNA APLIKASI DENGAN IKON GELAP)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
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
