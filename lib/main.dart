import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'features/profile/logic/theme_cubit.dart';
import 'theme/app_theme.dart';
import 'features/main_layout/presentation/main_navigation.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/passcode_screen.dart';
import 'widgets/pin_helper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class NotificationHelper {
  static Future<void> scheduleDailyNotification(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Pengingat Harian',
      channelDescription: 'Notifikasi untuk mencatat keuangan harian',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon', // <-- SUDAH DIPERBAIKI DI SINI
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Waktunya Mencatat! 📝',
      'Jangan lupa catat pengeluaran dan pemasukanmu hari ini ya!',
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session = Supabase.instance.client.auth.currentSession;
  Future<bool>? _pinFuture;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (_session != null) {
      _pinFuture = _isPinEnabled();
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;

      setState(() {
        _session = authState.session;
        _pinFuture = _session == null ? null : _isPinEnabled();
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _isPinEnabled() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    await PinHelper.migrateLegacyPinIfNeeded(userId);

    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin_$userId');
    final isEnabled = prefs.getBool('is_pin_enabled_$userId') ?? false;

    return pin != null && isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const LoginScreen();
    }

    return FutureBuilder<bool>(
      future: _pinFuture ??= _isPinEnabled(),
      builder: (context, pinSnapshot) {
        if (pinSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
        }

        final hasPin = pinSnapshot.data ?? false;

        if (hasPin) {
          return const PasscodeScreen();
        }

        return const MainNavigation();
      },
    );
  }
}