import 'package:flutter/material.dart';
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF05A660),
          primary: const Color(0xFF05A660),
        ),
      ),

      home: const MainNavigation(),
    );
  }
}