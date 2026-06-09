import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:async';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'features/profile/logic/theme_cubit.dart';
import 'theme/app_theme.dart';
import 'features/main_layout/presentation/main_navigation.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/passcode_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'widgets/app_bootstrap.dart';
import 'widgets/pin_helper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class NotificationHelper {
  static bool _isInitialized = false;
  static const String _dailyChannelId = 'daily_reminder_v2';
  static const String _billChannelId = 'bill_reminder_v2';
  static Timer? _dailyReminderTimer;
  static Timer? _billReminderTimer;

  static String _scopeKey() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId == null || userId.isEmpty ? 'guest' : userId;
  }

  static String _historyKey() => 'notification_history_v1_${_scopeKey()}';

  static Future<bool> canScheduleExactAlarms() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    return await androidImplementation?.canScheduleExactNotifications() ?? true;
  }

  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    try {
      await androidImplementation?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification Permission Error: $e');
    }

    try {
      await androidImplementation?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact Alarm Permission Error: $e');
    }

    _isInitialized = true;
  }

  static Future<void> _handleNotificationResponse(NotificationResponse response) async {
    await recordHistory(
      title: 'Notifikasi dibuka',
      body: response.payload == null ? 'Pengguna membuka notifikasi dari sistem.' : 'Notifikasi ${response.payload} dibuka.',
      type: 'opened',
      payload: response.payload,
    );
  }

  static Future<void> recordHistory({
    required String title,
    required String body,
    required String type,
    String? payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey()) ?? <String>[];

    final entry = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.insert(0, jsonEncode(entry));
    if (history.length > 30) {
      history.removeRange(30, history.length);
    }

    await prefs.setStringList(_historyKey(), history);
  }

  static Future<List<Map<String, dynamic>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey()) ?? <String>[];

    return history
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList(growable: false);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey());
  }

  static Future<void> scheduleDailyNotification(int hour, int minute) async {
    await ensureInitialized();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    _dailyReminderTimer?.cancel();
    if (now.hour == hour && now.minute == minute) {
      try {
        const AndroidNotificationDetails immediateAndroidDetails = AndroidNotificationDetails(
          _dailyChannelId,
          'Pengingat Harian',
          channelDescription: 'Notifikasi untuk mencatat keuangan harian',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        );

        const NotificationDetails immediatePlatformDetails = NotificationDetails(android: immediateAndroidDetails);

        await flutterLocalNotificationsPlugin.show(
          1000,
          'Catatan Keuangan 📝',
          'Catat transaksi keuangan Anda hari ini',
          immediatePlatformDetails,
          payload: 'daily_reminder',
        );

        await recordHistory(
          title: 'Pengingat Harian tampil',
          body: 'Pengingat harian ditampilkan tepat pada jam yang dipilih.',
          type: 'sent_daily',
          payload: 'daily_reminder',
        );
      } catch (e) {
        debugPrint('Daily Notification Error (immediate): $e');
      }
    } else if (scheduledDate.isAfter(now)) {
      _dailyReminderTimer = Timer(scheduledDate.difference(now), () async {
        try {
          const AndroidNotificationDetails immediateAndroidDetails = AndroidNotificationDetails(
            _dailyChannelId,
            'Pengingat Harian',
            channelDescription: 'Notifikasi untuk mencatat keuangan harian',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          );

          const NotificationDetails immediatePlatformDetails = NotificationDetails(android: immediateAndroidDetails);

          await flutterLocalNotificationsPlugin.show(
            1000,
            'Catatan Keuangan 📝',
            'Catat transaksi keuangan Anda hari ini',
            immediatePlatformDetails,
            payload: 'daily_reminder',
          );

          await recordHistory(
            title: 'Pengingat Harian tampil',
            body: 'Pengingat harian ditampilkan pada jadwal pertama hari ini.',
            type: 'sent_daily',
            payload: 'daily_reminder',
          );
        } catch (e) {
          debugPrint('Daily Notification Error (timer): $e');
        }
      });
    }

    final repeatingDate = scheduledDate.add(const Duration(days: 1));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _dailyChannelId,
      'Pengingat Harian',
      channelDescription: 'Notifikasi untuk mencatat keuangan harian',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.cancel(0);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Catatan Keuangan 📝',
      'Catat transaksi keuangan Anda hari ini',
      repeatingDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    final pendingRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    final hasDailyReminder = pendingRequests.any((request) => request.id == 0);
    if (!hasDailyReminder) {
      throw StateError('Pengingat harian gagal masuk pending notifications.');
    }

    await recordHistory(
      title: 'Pengingat Harian dijadwalkan',
      body: 'Akan muncul setiap hari pukul ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}.',
      type: 'scheduled_daily',
      payload: 'daily_reminder',
    );
  }

  static Future<void> scheduleBillReminderNotification(int hour, int minute) async {
    await ensureInitialized();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    _billReminderTimer?.cancel();
    if (now.hour == hour && now.minute == minute) {
      try {
        const AndroidNotificationDetails immediateAndroidDetails = AndroidNotificationDetails(
          _billChannelId,
          'Pengingat Tagihan',
          channelDescription: 'Notifikasi untuk mengingatkan pembayaran tagihan',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        );

        const NotificationDetails immediatePlatformDetails = NotificationDetails(android: immediateAndroidDetails);

        await flutterLocalNotificationsPlugin.show(
          1001,
          'Pengingat Tagihan 💳',
          'Periksa dan bayar tagihan Anda',
          immediatePlatformDetails,
          payload: 'bill_reminder',
        );

        await recordHistory(
          title: 'Pengingat Tagihan tampil',
          body: 'Pengingat tagihan ditampilkan tepat pada jam yang dipilih.',
          type: 'sent_bill',
          payload: 'bill_reminder',
        );
      } catch (e) {
        debugPrint('Bill Reminder Error (immediate): $e');
      }
    } else if (scheduledDate.isAfter(now)) {
      _billReminderTimer = Timer(scheduledDate.difference(now), () async {
        try {
          const AndroidNotificationDetails immediateAndroidDetails = AndroidNotificationDetails(
            _billChannelId,
            'Pengingat Tagihan',
            channelDescription: 'Notifikasi untuk mengingatkan pembayaran tagihan',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          );

          const NotificationDetails immediatePlatformDetails = NotificationDetails(android: immediateAndroidDetails);

          await flutterLocalNotificationsPlugin.show(
            1001,
            'Pengingat Tagihan 💳',
            'Periksa dan bayar tagihan Anda',
            immediatePlatformDetails,
            payload: 'bill_reminder',
          );

          await recordHistory(
            title: 'Pengingat Tagihan tampil',
            body: 'Pengingat tagihan ditampilkan pada jadwal pertama hari ini.',
            type: 'sent_bill',
            payload: 'bill_reminder',
          );
        } catch (e) {
          debugPrint('Bill Reminder Error (timer): $e');
        }
      });
    }

    final repeatingDate = scheduledDate.add(const Duration(days: 1));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _billChannelId,
      'Pengingat Tagihan',
      channelDescription: 'Notifikasi untuk mengingatkan pembayaran tagihan',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.cancel(1);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Pengingat Tagihan 💳',
      'Periksa dan bayar tagihan Anda',
      repeatingDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'bill_reminder',
    );

    final pendingRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    final hasBillReminder = pendingRequests.any((request) => request.id == 1);
    if (!hasBillReminder) {
      throw StateError('Pengingat tagihan gagal masuk pending notifications.');
    }

    await recordHistory(
      title: 'Pengingat Tagihan dijadwalkan',
      body: 'Akan mengikuti jadwal harian pada ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}.',
      type: 'scheduled_bill',
      payload: 'bill_reminder',
    );
  }

  static Future<void> cancelAllNotifications() async {
    _dailyReminderTimer?.cancel();
    _billReminderTimer?.cancel();
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> cancelBillReminderNotification() async {
    _billReminderTimer?.cancel();
    await flutterLocalNotificationsPlugin.cancel(1);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  await NotificationHelper.ensureInitialized();

  AppBootstrap.start();
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
            home: const SplashScreen(),
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
  String? _currentUserId;
  Future<bool>? _pinFuture;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _currentUserId = _session?.user.id;
    if (_session != null) {
      _pinFuture = _isPinEnabled();
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;

      final nextUserId = authState.session?.user.id;
      final hasUserChanged = _currentUserId != nextUserId;

      if (hasUserChanged) {
        NotificationHelper.cancelAllNotifications();
      }

      setState(() {
        _session = authState.session;
        _currentUserId = nextUserId;
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