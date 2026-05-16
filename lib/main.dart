import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/profile/logic/theme_cubit.dart';
import 'theme/app_theme.dart';
import 'features/main_layout/presentation/main_navigation.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/passcode_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi koneksi ke database Supabase milik Anda
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
            debugShowCheckedModeBanner: false, // Menghilangkan pita "DEBUG" di pojok kanan atas
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            scrollBehavior: NoOverscrollBehavior(),
            home: const AuthGate(), // Aplikasi selalu mulai dari Gerbang Satpam (AuthGate)
          );
        },
      ),
    );
  }
}

// --- GERBANG AUTENTIKASI (SATPAM APLIKASI) ---
// Tugasnya: Mengecek apakah user sudah login, dan mengecek apakah user mengaktifkan PIN
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Fungsi ini bertugas mengintip memori HP (SharedPreferences)
  // Untuk melihat apakah user pernah membuat PIN dan mengaktifkannya
  Future<bool> _isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin'); // Ambil PIN yang tersimpan
    final isEnabled = prefs.getBool('is_pin_enabled') ?? false; // Cek status sakelar PIN

    // Kembalikan nilai TRUE hanya jika PIN tidak kosong DAN statusnya aktif
    return pin != null && isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder terus memantau status login Supabase secara real-time
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Tampilkan loading saat aplikasi sedang mengecek status ke server Supabase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Ambil data sesi (session). Jika null, berarti belum login.
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // JIKA USER SUDAH LOGIN DI SUPABASE
        if (session != null) {
          // Jangan langsung masuk Dashboard! Cek dulu keamanan PIN-nya pakai FutureBuilder
          return FutureBuilder<bool>(
            future: _isPinEnabled(),
            builder: (context, pinSnapshot) {
              // Loading saat mengintip memori HP
              if (pinSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
              }

              final hasPin = pinSnapshot.data ?? false;

              // Jika user mengaktifkan PIN, lempar ke halaman PasscodeScreen untuk verifikasi
              if (hasPin) {
                return const PasscodeScreen();
              }

              // Jika user tidak pakai PIN, langsung bukakan pintu ke Dashboard (MainNavigation)
              return const MainNavigation();
            },
          );
        }

        // JIKA USER BELUM LOGIN SAMA SEKALI, lempar ke halaman Login
        return const LoginScreen();
      },
    );
  }
}