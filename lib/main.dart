import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/profile/logic/theme_cubit.dart';
import 'theme/app_theme.dart';
import 'features/main_layout/presentation/main_navigation.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/passcode_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kkyqghphrvnfycukwpyk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtreXFnaHBocnZuZnljdWt3cHlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1OTIwMDQsImV4cCI6MjA5NDE2ODAwNH0.0-YLNAcZG1U4ZL6Nrz0EdY4_Dioaq4C7sEy-VhWDtaA',
  );

  runApp(const MyApp());
}

class NoOverscrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
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
            scrollBehavior: NoOverscrollBehavior(),
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}