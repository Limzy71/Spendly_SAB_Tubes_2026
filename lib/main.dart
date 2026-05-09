import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/main_layout/presentation/main_navigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,

      // Menerapkan Custom Font & Warna Utama ke seluruh aplikasi
      theme: ThemeData(
        primaryColor: const Color(0xFF05A660),

        // Menerapkan font "Plus Jakarta Sans" ke seluruh teks
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),

        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF05A660)),
        useMaterial3: true,
      ),

      // Halaman pertama yang dimuat adalah MainNavigation (Bottom Bar)
      home: const MainNavigation(),
    );
  }
}