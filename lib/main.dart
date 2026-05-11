import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/profile/logic/theme_cubit.dart';
import 'theme/app_theme.dart';
import 'features/main_layout/presentation/main_navigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Bungkus dengan BlocProvider agar ThemeCubit aktif di seluruh aplikasi
    return BlocProvider(
      create: (context) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Spendly',
            debugShowCheckedModeBanner: false,

            // 5. Gunakan tema dari file AppTheme yang sudah kita buat
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,

            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}