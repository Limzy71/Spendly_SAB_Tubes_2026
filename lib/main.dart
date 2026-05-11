import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/profile/logic/theme_cubit.dart';
import 'theme/app_theme.dart';
import 'features/main_layout/presentation/main_navigation.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/passcode_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Spendly',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,

            // home: const MainNavigation(),
            home: const RegisterScreen(),
            // home: const PasscodeScreen(),
          );
        },
      ),
    );
  }
}