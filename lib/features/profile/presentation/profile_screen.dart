import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

import 'passcode_settings_screen.dart';
import 'update_account_password_screen.dart';
import 'widgets/update_profile_screen.dart';
import '../../../theme/app_colors.dart';
import '../logic/theme_cubit.dart';
import '../logic/export_service.dart';
import '../logic/drive_sync_service.dart';
import 'faq_screen.dart';
import 'about_screen.dart';
import '../../main_layout/presentation/main_navigation.dart';
import '../../../../main.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/network_helper.dart';
import '../../../../widgets/profile_image_cache.dart';

import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPinEnabled = false;
  bool _isBiometricEnabled = false;
  
  String? _profileImagePath;
  String _userName = 'Pengguna Spendly';

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isDailyReminderEnabled = true;
  bool _isBillReminderEnabled = true;

  final LocalAuthentication _localAuth = LocalAuthentication();

  String _currentUserId() {
    return Supabase.instance.client.auth.currentUser?.id ?? 'guest';
  }

  String _reminderHourKey() => 'reminder_hour_${_currentUserId()}';
  String _reminderMinuteKey() => 'reminder_minute_${_currentUserId()}';
  String _dailyReminderEnabledKey() => 'daily_reminder_enabled_${_currentUserId()}';
  String _billReminderEnabledKey() => 'bill_reminder_enabled_${_currentUserId()}';

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      setState(() {
        _userName = user.userMetadata!['full_name'] ?? 'Pengguna Spendly';
      });
    }
  }

  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    final String? supabaseAvatarUrl = user?.userMetadata?['avatar_url'];
    final userId = user?.id ?? '';

    setState(() {
      _isPinEnabled = prefs.getBool('is_pin_enabled_$userId') ?? prefs.getBool('is_pin_enabled') ?? false;
      _isBiometricEnabled = prefs.getBool('is_biometric_enabled_$userId') ?? prefs.getBool('is_biometric_enabled') ?? false;

      _profileImagePath = supabaseAvatarUrl != null && supabaseAvatarUrl.isNotEmpty
          ? supabaseAvatarUrl
          : (userId.isNotEmpty ? prefs.getString(ProfileImageCache.keyForUser(userId)) : null);

      final int savedHour = prefs.getInt(_reminderHourKey()) ?? 20;
      final int savedMinute = prefs.getInt(_reminderMinuteKey()) ?? 0;
      _reminderTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      _isDailyReminderEnabled = prefs.getBool(_dailyReminderEnabledKey()) ?? true;
      _isBillReminderEnabled = prefs.getBool(_billReminderEnabledKey()) ?? true;
    });

    await _syncReminderNotifications(promptIfNeeded: false);
  }

  Future<void> _showNotificationPermissionDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Izin Notifikasi Diperlukan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: Text(
            'Aktifkan izin notifikasi agar pengingat harian dan tagihan bisa muncul tepat waktu.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Nanti', style: GoogleFonts.plusJakartaSans()),
            ),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
                if (!mounted) return;
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: Text('Buka Settings', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _ensureNotificationPermission({bool promptIfNeeded = true}) async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    if (!promptIfNeeded) {
      return false;
    }

    final result = await Permission.notification.request();
    if (result.isGranted) {
      return true;
    }

    
    await _showNotificationPermissionDialog();
    return false;
  }

  Future<bool> _ensureExactAlarmPermission({bool promptIfNeeded = true}) async {
    final canScheduleExactAlarms = await NotificationHelper.canScheduleExactAlarms();
    
    if (canScheduleExactAlarms) return true;

    if (!promptIfNeeded) return false;

    await NotificationHelper.ensureInitialized();
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImplementation?.requestExactAlarmsPermission();

    final refreshed = await NotificationHelper.canScheduleExactAlarms();
    

    if (!refreshed && granted != true && mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Alarm Tepat Waktu Diperlukan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            content: Text(
              'Agar pengingat muncul tepat di jam yang dipilih, aktifkan izin alarm tepat waktu untuk Spendly.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Nanti', style: GoogleFonts.plusJakartaSans()),
              ),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: Text('Buka Settings', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }

    return refreshed;
  }

  Future<bool> _ensureBatteryOptimizationExemption({bool promptIfNeeded = true}) async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;
    if (!promptIfNeeded) return false;

    final result = await Permission.ignoreBatteryOptimizations.request();
    if (result.isGranted) {
      return true;
    }

    await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Izinkan Latar Belakang', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            content: Text(
              'Agar pengingat muncul tepat waktu, izinkan Spendly berjalan tanpa dibatasi baterai.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Nanti', style: GoogleFonts.plusJakartaSans()),
              ),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: Text('Buka Settings', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
              ),
            ],
          );
        },
      );

    return result.isGranted;
  }

  Future<bool> _syncReminderNotifications({bool promptIfNeeded = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSavedReminder = prefs.containsKey(_reminderHourKey()) && prefs.containsKey(_reminderMinuteKey());
    if (!hasSavedReminder) {
      return false;
    }

    try {
      final hasPermission = await _ensureNotificationPermission(promptIfNeeded: promptIfNeeded);
      if (!hasPermission) {
        return false;
      }

      final hasExactAlarmPermission = await _ensureExactAlarmPermission(promptIfNeeded: promptIfNeeded);
      if (!hasExactAlarmPermission) {
        return false;
      }

      final hasBatteryOptimizationExemption = await _ensureBatteryOptimizationExemption(promptIfNeeded: promptIfNeeded);
      if (!hasBatteryOptimizationExemption) {
        return false;
      }

      if (_isDailyReminderEnabled) {
        await NotificationHelper.scheduleDailyNotification(_reminderTime.hour, _reminderTime.minute);
      } else {
        await NotificationHelper.cancelAllNotifications();
      }

      if (_isDailyReminderEnabled && _isBillReminderEnabled) {
        await Future.delayed(const Duration(seconds: 10));
      }

      if (_isBillReminderEnabled) {
        await NotificationHelper.scheduleBillReminderNotification(_reminderTime.hour, _reminderTime.minute);
      } else {
        await NotificationHelper.cancelBillReminderNotification();
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  void _showEditNameDialog() {
    TextEditingController nameController = TextEditingController(text: _userName);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Ubah Nama", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        content: TextField(
          controller: nameController,
          style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "Masukkan nama baru",
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                bool isOnline = await NetworkHelper.checkConnection(context);
                if (!mounted) return;
                if (!isOnline) return;

                Navigator.pop(dialogContext);
                setState(() => _userName = nameController.text.trim());
                await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'full_name': nameController.text.trim()}));
                if (!mounted) return;
                CustomNotification.show(context, 'Nama berhasil diubah!');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: Text("Simpan", style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final savedPin = prefs.getString('user_pin_$userId') ?? prefs.getString('user_pin');

    if (value == true && (savedPin == null || savedPin.isEmpty)) {
      CustomNotification.show(context, 'Silakan Buat PIN terlebih dahulu!', isWarning: true);
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PasscodeSettingsScreen())).then((_) {
        _loadSecuritySettings();
      });
      return;
    }

    await prefs.setBool('is_pin_enabled_$userId', value);
    setState(() => _isPinEnabled = value);

    if (value == false) {
      await prefs.setBool('is_biometric_enabled_$userId', false);
      setState(() => _isBiometricEnabled = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value == true && !_isPinEnabled) {
      CustomNotification.show(context, 'Aktifkan PIN Keamanan terlebih dahulu!', isWarning: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    if (value == true) {
      try {
        final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

        if (!canAuthenticate) {
          CustomNotification.show(context, 'Perangkat tidak mendukung biometrik.', isError: true);
          return;
        }

        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Pindai sidik jari / wajah Anda untuk mengaktifkan',
        );

        if (didAuthenticate) {
          await prefs.setBool('is_biometric_enabled_$userId', true);
          setState(() => _isBiometricEnabled = true);
          CustomNotification.show(context, 'Biometrik berhasil diaktifkan!');
        } else {
          setState(() => _isBiometricEnabled = false);
        }
      } catch (e) {
        CustomNotification.show(context, 'Gagal verifikasi biometrik', isError: true);
      }
    } else {
      await prefs.setBool('is_biometric_enabled_$userId', false);
      setState(() => _isBiometricEnabled = false);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: AppColors.primaryGreen)
                : const ColorScheme.light(primary: AppColors.primaryGreen),
            dialogBackgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              dialBackgroundColor: isDark ? const Color(0xFF242424) : const Color(0xFFF1FAF5),
              hourMinuteTextColor: isDark ? Colors.white : Colors.black87,
              hourMinuteColor: AppColors.primaryGreen,
              dayPeriodTextColor: isDark ? Colors.white : Colors.black87,
              dayPeriodColor: AppColors.primaryGreen.withValues(alpha: 0.12),
              dialHandColor: AppColors.primaryGreen,
              dialTextColor: isDark ? Colors.white : Colors.black87,
              entryModeIconColor: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final isSameTimeAsBefore = picked == _reminderTime;
      final now = TimeOfDay.now();
      final isPickedTimePassed = picked.hour < now.hour ||
          (picked.hour == now.hour && picked.minute < now.minute);

      setState(() => _reminderTime = picked);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_reminderHourKey(), picked.hour);
      await prefs.setInt(_reminderMinuteKey(), picked.minute);

      try {
        final saved = await _syncReminderNotifications();
        if (!mounted) return;
        CustomNotification.show(
          context,
          saved
              ? (isPickedTimePassed
                  ? 'Waktu diperbarui, aktif mulai besok'
                  : (isSameTimeAsBefore ? 'Disinkronkan' : 'Tersimpan'))
              : 'Gagal dijadwalkan',
          isError: !saved,
        );
      } catch (_) {
        if (!mounted) return;
        CustomNotification.show(context, 'Gagal mengaktifkan pengingat. Cek izin notifikasi.', isError: true);
      }
    }
  }

  Future<void> _toggleDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final hasPermission = await _ensureNotificationPermission();
      if (!hasPermission) return;
      final hasExactAlarmPermission = await _ensureExactAlarmPermission();
      if (!hasExactAlarmPermission) return;
      final hasBatteryOptimizationExemption = await _ensureBatteryOptimizationExemption();
      if (!hasBatteryOptimizationExemption) return;
    }

    await prefs.setBool(_dailyReminderEnabledKey(), value);
    if (!mounted) return;
    setState(() => _isDailyReminderEnabled = value);

    if (value) {
      try {
        final now = TimeOfDay.now();
        final isReminderTimePassed = _reminderTime.hour < now.hour ||
          (_reminderTime.hour == now.hour && _reminderTime.minute < now.minute);

        await NotificationHelper.scheduleDailyNotification(_reminderTime.hour, _reminderTime.minute);
        if (!mounted) return;
        CustomNotification.show(
          context,
          isReminderTimePassed ? 'Aktif mulai besok' : 'Aktif',
        );
      } catch (_) {
        if (!mounted) return;
        CustomNotification.show(context, 'Gagal mengaktifkan pengingat harian.', isError: true);
      }
    } else {
      await NotificationHelper.cancelAllNotifications();
      if (_isBillReminderEnabled) {
        try {
          await NotificationHelper.scheduleBillReminderNotification(_reminderTime.hour, _reminderTime.minute);
        } catch (_) {
          // ignore
        }
      }
      if (!mounted) return;
      CustomNotification.show(context, 'Pengingat Harian Dimatikan', isWarning: true);
    }
  }

  Future<void> _toggleBillReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final hasPermission = await _ensureNotificationPermission();
      if (!hasPermission) return;
      final hasExactAlarmPermission = await _ensureExactAlarmPermission();
      if (!hasExactAlarmPermission) return;
      final hasBatteryOptimizationExemption = await _ensureBatteryOptimizationExemption();
      if (!hasBatteryOptimizationExemption) return;
    }

    await prefs.setBool(_billReminderEnabledKey(), value);
    if (!mounted) return;
    setState(() => _isBillReminderEnabled = value);

    if (value) {
      try {
        final now = TimeOfDay.now();
        final isReminderTimePassed = _reminderTime.hour < now.hour ||
          (_reminderTime.hour == now.hour && _reminderTime.minute < now.minute);

        await NotificationHelper.scheduleBillReminderNotification(_reminderTime.hour, _reminderTime.minute);
        if (!mounted) return;
        CustomNotification.show(
          context,
          isReminderTimePassed ? 'Aktif mulai besok' : 'Aktif',
        );
      } catch (_) {
        if (!mounted) return;
        CustomNotification.show(context, 'Gagal mengaktifkan pengingat tagihan.', isError: true);
      }
    } else {
      await NotificationHelper.cancelBillReminderNotification();
      if (!mounted) return;
      CustomNotification.show(context, 'Pengingat Tagihan Dimatikan', isWarning: true);
    }
  }

  void _showLogoutDialog() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Keluar", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          content: Text("Apakah Anda yakin ingin keluar dari aplikasi?", style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                bool isOnline = await NetworkHelper.checkConnection(context);
                if (!mounted) return;
                if (!isOnline) return;

                Navigator.pop(dialogContext);
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Keluar", style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDataDialog() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Reset Riwayat Transaksi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text("Tindakan ini akan menghapus semua riwayat transaksi Anda. Nama, foto profil, dan dompet akan tetap tersimpan. Lanjutkan?", style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                bool isOnline = await NetworkHelper.checkConnection(context);
                if (!isOnline) return;

                Navigator.pop(dialogContext);
                CustomNotification.show(context, 'Sedang menghapus riwayat transaksi...', isWarning: true);

                try {
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  if (userId != null) {
                    await Supabase.instance.client.from('transactions').delete().eq('user_id', userId);

                    if (mounted) {
                      CustomNotification.show(context, 'Data transaksi berhasil direset!');
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MainNavigation()),
                            (route) => false,
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) CustomNotification.show(context, 'Gagal mereset data: $e', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Reset Sekarang", style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Hapus Akun & Data',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Tindakan ini akan menghapus akun Spendly Anda beserta semua data di dalamnya, termasuk transaksi, dompet, anggaran, foto profil, file struk, dan data lokal aplikasi. Proses ini tidak bisa dibatalkan.',
            style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                bool isOnline = await NetworkHelper.checkConnection(context);
                if (!isOnline) return;

                Navigator.pop(dialogContext);
                if (!mounted) return;
                CustomNotification.show(context, 'Sedang menghapus akun dan data...', isWarning: true);

                try {
                  final supabase = Supabase.instance.client;
                  final user = supabase.auth.currentUser;
                  if (user == null) return;

                  await supabase.functions.invoke(
                    'delete-account',
                    body: {
                      'user_id': user.id,
                      'avatar_url': user.userMetadata?['avatar_url'],
                    },
                  );

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  await supabase.auth.signOut();

                  if (!mounted) return;
                  CustomNotification.show(context, 'Akun dan data berhasil dihapus.');
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  if (mounted) {
                    CustomNotification.show(context, 'Gagal menghapus akun: $e', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Hapus Akun', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'Email tidak ditemukan';

    ImageProvider? imageProvider;
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      if (_profileImagePath!.startsWith('http')) {
        imageProvider = NetworkImage(_profileImagePath!);
      } else {
        imageProvider = FileImage(File(_profileImagePath!));
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: imageProvider,
                          child: imageProvider == null
                              ? const Icon(Icons.person, size: 45, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final String? newPath = await showModalBottomSheet<String>(
                              context: context,
                              backgroundColor: Theme.of(context).cardColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (modalContext) => const UpdateProfileScreen(),
                            );

                            if (newPath != null) {
                              bool isOnline = await NetworkHelper.checkConnection(context);
                              if (!isOnline) return;

                              setState(() => _profileImagePath = newPath);

                              CustomNotification.show(context, 'Sedang menyimpan foto...', isWarning: true);

                              try {
                                final user = Supabase.instance.client.auth.currentUser;
                                if (user == null) return;

                                final File file = File(newPath);
                                final String fileExtension = newPath.split('.').last;
                                final String fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

                                await Supabase.instance.client.storage
                                    .from('avatars')
                                    .upload(fileName, file);

                                final String imageUrl = Supabase.instance.client.storage
                                    .from('avatars')
                                    .getPublicUrl(fileName);

                                await Supabase.instance.client.auth.updateUser(
                                  UserAttributes(data: {'avatar_url': imageUrl}),
                                );

                                final prefs = await SharedPreferences.getInstance();
                                final userId = user.id;
                                await prefs.setString(ProfileImageCache.keyForUser(userId), newPath);
                                await prefs.remove(ProfileImageCache.legacyKey);

                                if (context.mounted) {
                                  CustomNotification.show(context, 'Foto profil berhasil diperbarui!');
                                  if (widget.onProfileUpdated != null) {
                                    widget.onProfileUpdated!();
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  CustomNotification.show(context, 'Gagal menyimpan foto: $e', isError: true);
                                }
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_userName, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showEditNameDialog,
                        child: Icon(Icons.edit, size: 16, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(userEmail, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('PENGATURAN AKUN'),
            _buildListTile(
              icon: FontAwesomeIcons.lock,
              title: 'Ubah PIN',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PasscodeSettingsScreen()),
                ).then((_) => _loadSecuritySettings());
              },
            ),
            _buildListTile(
              icon: FontAwesomeIcons.key,
              title: 'Ubah Kata Sandi Akun',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateAccountPasswordScreen()),
                );
              },
            ),
            _buildSwitchTile(
                icon: FontAwesomeIcons.shieldHalved,
                title: 'PIN Keamanan',
                value: _isPinEnabled,
                onChanged: _togglePin,
                activeColor: AppColors.primaryGreen
            ),
            _buildSwitchTile(
                icon: FontAwesomeIcons.fingerprint,
                title: 'Autentikasi Biometrik',
                subtitle: 'Sidik Jari / Pemindai Wajah',
                value: _isBiometricEnabled,
                onChanged: _toggleBiometric,
                activeColor: AppColors.primaryGreen
            ),
            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),
            _buildSectionTitle('PENGATURAN APLIKASI', color: AppColors.primaryGreen),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(leading: FaIcon(FontAwesomeIcons.bell, color: textColor, size: 20), title: Text('Pengaturan Notifikasi', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textColor))),
                  // Jam pengingat (tampil paling atas)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.05),
                                Colors.white.withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFFF7FCF9),
                                Color(0xFFEAF8F0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFD8EBDF)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _selectTime(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.18 : 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.access_time_rounded, color: AppColors.primaryGreen, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Waktu Pengingat',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ketuk untuk mengubah jam',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.85 : 1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFDDE8E0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _reminderTime.format(context),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.keyboard_arrow_right_rounded, size: 18, color: AppColors.primaryGreen),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Pengingat Harian toggle (di bawah jam)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1FAF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      title: Text('Pengingat Harian', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor)),
                      subtitle: Text('Aktif setiap hari pada jam pilihan', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 11)),
                      trailing: Switch.adaptive(
                        value: _isDailyReminderEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: _toggleDailyReminder,
                      ),
                    ),
                  ),


                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1FAF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      title: Text('Pengingat Tagihan', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor)),
                      subtitle: Text('Mengikuti jadwal pengingat harian', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 11)),
                      trailing: Switch.adaptive(
                        value: _isBillReminderEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: _toggleBillReminder,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Jika dua pengingat aktif, notifikasi dikirim selang 10 detik.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFF0F0F0)),
                  ListTile(
                    leading: FaIcon(FontAwesomeIcons.palette, color: textColor, size: 20),
                    title: Text('Tema Aplikasi', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textColor)),
                    subtitle: BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, themeMode) {
                        return Text(themeMode == ThemeMode.dark ? 'Gelap (Dark)' : 'Terang (Light)', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryGreen, fontSize: 12));
                      },
                    ),
                    trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    onTap: () {
                      final cubit = context.read<ThemeCubit>();
                      cubit.toggleTheme(cubit.state != ThemeMode.dark);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),
            _buildSectionTitle('DATA & SINKRONISASI'),
            _buildListTile(
                icon: FontAwesomeIcons.cloudArrowUp,
                title: 'Cadangkan & Sinkronisasi',
                subtitle: 'Amankan data ke Google Drive',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).cardColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (BuildContext sheetContext) {
                      Color sheetTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                child: Text(
                                  'Google Drive Sync',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: sheetTextColor),
                                ),
                              ),
                              ListTile(
                                  leading: const FaIcon(FontAwesomeIcons.cloudArrowUp, color: Colors.green),
                                  title: Text('Cadangkan Data', style: GoogleFonts.plusJakartaSans(color: sheetTextColor)),
                                  subtitle: Text('Simpan seluruh data ke Google Drive', style: GoogleFonts.plusJakartaSans()),
                                  onTap: () async {
                                    bool isOnline = await NetworkHelper.checkConnection(context);
                                    if (!isOnline) return;
                                    Navigator.pop(sheetContext);
                                    await DriveSyncService.backupToDrive(context);
                                  }
                              ),
                              ListTile(
                                leading: const FaIcon(FontAwesomeIcons.cloudArrowDown, color: Colors.blue),
                                title: Text('Sinkronisasi Data', style: GoogleFonts.plusJakartaSans(color: sheetTextColor)),
                                subtitle: Text('Pulihkan data dari Google Drive ke HP', style: GoogleFonts.plusJakartaSans()),
                                onTap: () async {
                                  Navigator.pop(sheetContext);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
            ),
            _buildListTile(
                icon: FontAwesomeIcons.fileExport,
                title: 'Ekspor Data (.csv, .pdf)',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  int selectedFilter = 0;

                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).cardColor,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (BuildContext sheetContext) {
                      Color sheetTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
                      final bool isDarkSheet = Theme.of(context).brightness == Brightness.dark;
                      return StatefulBuilder(
                          builder: (BuildContext stateContext, StateSetter setSheetState) {
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                      child: Text('Pilih Format Ekspor', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: sheetTextColor)),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                      child: Row(
                                        children: [
                                          ChoiceChip(
                                            label: Text('Semua Waktu', style: GoogleFonts.plusJakartaSans()),
                                            labelStyle: GoogleFonts.plusJakartaSans(
                                              color: selectedFilter == 0
                                                  ? (isDarkSheet ? Colors.white : AppColors.primaryGreen)
                                                  : (isDarkSheet ? Colors.white70 : Colors.black87),
                                              fontWeight: selectedFilter == 0 ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                            selected: selectedFilter == 0,
                                            selectedColor: isDarkSheet
                                                ? AppColors.primaryGreen.withValues(alpha: 0.35)
                                                : AppColors.primaryGreen.withValues(alpha: 0.2),
                                            backgroundColor: isDarkSheet ? Colors.white10 : Colors.white,
                                            side: BorderSide(color: isDarkSheet ? Colors.white30 : Colors.grey.shade300),
                                            checkmarkColor: selectedFilter == 0
                                                ? (isDarkSheet ? Colors.white : AppColors.primaryGreen)
                                                : (isDarkSheet ? Colors.white70 : Colors.black54),
                                            onSelected: (val) => setSheetState(() => selectedFilter = 0),
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            label: Text('Bulan Ini', style: GoogleFonts.plusJakartaSans()),
                                            labelStyle: GoogleFonts.plusJakartaSans(
                                              color: selectedFilter == 1
                                                  ? (isDarkSheet ? Colors.white : AppColors.primaryGreen)
                                                  : (isDarkSheet ? Colors.white70 : Colors.black87),
                                              fontWeight: selectedFilter == 1 ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                            selected: selectedFilter == 1,
                                            selectedColor: isDarkSheet
                                                ? AppColors.primaryGreen.withValues(alpha: 0.35)
                                                : AppColors.primaryGreen.withValues(alpha: 0.2),
                                            backgroundColor: isDarkSheet ? Colors.white10 : Colors.white,
                                            side: BorderSide(color: isDarkSheet ? Colors.white30 : Colors.grey.shade300),
                                            checkmarkColor: selectedFilter == 1
                                                ? (isDarkSheet ? Colors.white : AppColors.primaryGreen)
                                                : (isDarkSheet ? Colors.white70 : Colors.black54),
                                            onSelected: (val) => setSheetState(() => selectedFilter = 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(),

                                    ListTile(
                                      leading: const FaIcon(FontAwesomeIcons.fileCsv, color: Colors.green),
                                      title: Text('Ekspor sebagai CSV', style: GoogleFonts.plusJakartaSans(color: sheetTextColor)),
                                      subtitle: Text('Cocok untuk Excel / Spreadsheet', style: GoogleFonts.plusJakartaSans()),
                                      onTap: () async {
                                        bool isOnline = await NetworkHelper.checkConnection(context);
                                        if (!isOnline) return;
                                        Navigator.pop(sheetContext);
                                        await ExportService.exportTransactionsToCSV(context, selectedFilter);
                                      },
                                    ),
                                    ListTile(
                                      leading: const FaIcon(FontAwesomeIcons.filePdf, color: Colors.red),
                                      title: Text('Ekspor sebagai PDF', style: GoogleFonts.plusJakartaSans(color: sheetTextColor)),
                                      subtitle: Text('Format rapi, siap untuk dicetak', style: GoogleFonts.plusJakartaSans()),
                                      onTap: () async {
                                        bool isOnline = await NetworkHelper.checkConnection(context);
                                        if (!isOnline) return;
                                        Navigator.pop(sheetContext);
                                        await ExportService.exportTransactionsToPDF(context, selectedFilter);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                      );
                    },
                  );
                }
            ),
            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),
            _buildSectionTitle('BANTUAN & INFO'),
            _buildListTile(
                icon: FontAwesomeIcons.circleQuestion,
                title: 'Pusat Bantuan (FAQ)',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FaqScreen()),
                  );
                }
            ),
            _buildListTile(
                icon: FontAwesomeIcons.circleInfo,
                title: 'Tentang Spendly',
                subtitle: 'v1.0.7 (Kebijakan Privasi, Layanan)',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                }
            ),
            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),
            _buildSectionTitle('ZONA BERBAHAYA', color: Colors.redAccent),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.red, size: 20),
              title: Text('Reset Riwayat Transaksi', style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 14)),
              onTap: _showDeleteDataDialog,
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.userSlash, color: Colors.red, size: 20),
              title: Text('Hapus Akun & Data', style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 14)),
              onTap: _showDeleteAccountDialog,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket, color: Colors.red, size: 18),
                label: Text('Keluar', style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade200), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: Colors.red.shade50.withValues(alpha: 0.3)),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8, top: 8),
      child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
    );
  }

  Widget _buildListTile({required dynamic icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: FaIcon(icon, color: Colors.grey[600], size: 20),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildSwitchTile({required dynamic icon, required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged, required Color activeColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: FaIcon(icon, color: Colors.grey[600], size: 20),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: activeColor),
      dense: true,
    );
  }
}