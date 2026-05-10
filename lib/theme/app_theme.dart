import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // 1. TAMBAHKAN lightTheme (Ini yang tadi hilang)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
    ),
  );

  // 2. PERBAIKI darkTheme (Hapus 'const' yang menyebabkan error)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.black,
    cardColor: const Color(0xFF1E1E1E),

    // Hapus 'const' di sini
    colorScheme: ColorScheme.dark(
      surface: Colors.black,
      onSurface: Colors.white,
      primary: AppColors.primaryGreen,
      onPrimary: Colors.white,
    ),

    // // --- TAMBAHKAN APPBAR THEME DI SINI ---
    // appBarTheme: const AppBarTheme(
    //   backgroundColor: Colors.black,
    //   elevation: 0,
    //   centerTitle: true,
    //   iconTheme: IconThemeData(color: Colors.white),
    //   titleTextStyle: TextStyle(
    //     color: Colors.white,
    //     fontSize: 18,
    //     fontWeight: FontWeight.bold,
    //   ),
    // ),

    // --- TAMBAHKAN BOTTOM NAV THEME DI SINI ---
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: Colors.grey,
      elevation: 0,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),

    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white38),
      ),
      // Hapus 'const' di sini
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryGreen),
      ),
    ),
  );
}