import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPinEnabled = false;
  bool _isBiometricEnabled = false;
  String? _profileImagePath;
  String _userName = 'Pengguna Spendly';

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isBillReminderEnabled = true;

  final LocalAuthentication _localAuth = LocalAuthentication();

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

    setState(() {
      _isPinEnabled = prefs.getBool('is_pin_enabled') ?? false;
      _isBiometricEnabled = prefs.getBool('is_biometric_enabled') ?? false;

      if (supabaseAvatarUrl != null && supabaseAvatarUrl.isNotEmpty) {
        _profileImagePath = supabaseAvatarUrl;
      } else {
        _profileImagePath = prefs.getString('profile_image_path');
      }

      final int savedHour = prefs.getInt('reminder_hour') ?? 20;
      final int savedMinute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      _isBillReminderEnabled = prefs.getBool('bill_reminder_enabled') ?? true;
    });
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
                Navigator.pop(dialogContext);
                setState(() => _userName = nameController.text.trim());
                await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'full_name': nameController.text.trim()}));
                if (mounted) {
                  CustomNotification.show(context, 'Nama berhasil diubah!');
                }
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
    final savedPin = prefs.getString('user_pin');

    if (value == true && (savedPin == null || savedPin.isEmpty)) {
      CustomNotification.show(context, 'Silakan Buat PIN terlebih dahulu!', isWarning: true);
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PasscodeSettingsScreen())).then((_) {
        _loadSecuritySettings();
      });
      return;
    }

    await prefs.setBool('is_pin_enabled', value);
    setState(() => _isPinEnabled = value);

    if (value == false) {
      await prefs.setBool('is_biometric_enabled', false);
      setState(() => _isBiometricEnabled = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value == true && !_isPinEnabled) {
      CustomNotification.show(context, 'Aktifkan PIN Keamanan terlebih dahulu!', isWarning: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

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
          await prefs.setBool('is_biometric_enabled', true);
          setState(() => _isBiometricEnabled = true);
          CustomNotification.show(context, 'Biometrik berhasil diaktifkan!');
        } else {
          setState(() => _isBiometricEnabled = false);
        }
      } catch (e) {
        CustomNotification.show(context, 'Gagal verifikasi biometrik', isError: true);
      }
    } else {
      await prefs.setBool('is_biometric_enabled', false);
      setState(() => _isBiometricEnabled = false);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      setState(() => _reminderTime = picked);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminder_hour', picked.hour);
      await prefs.setInt('reminder_minute', picked.minute);

      await NotificationHelper.scheduleDailyNotification(picked.hour, picked.minute);
      if (mounted) CustomNotification.show(context, 'Pengingat harian disimpan!');
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
                Navigator.pop(dialogContext);
                await Supabase.instance.client.auth.signOut();

                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
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
                                await prefs.setString('profile_image_path', newPath);

                                if (context.mounted) {
                                  CustomNotification.show(context, 'Foto profil berhasil diperbarui!');
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
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1FAF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pengingat Harian', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor)),
                          Text(_reminderTime.format(context), style: GoogleFonts.plusJakartaSans(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final newValue = !_isBillReminderEnabled;
                      setState(() => _isBillReminderEnabled = newValue);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('bill_reminder_enabled', newValue);

                      if (newValue) {
                        CustomNotification.show(context, 'Pengingat tagihan diaktifkan');
                      } else {
                        CustomNotification.show(context, 'Pengingat tagihan dimatikan', isWarning: true);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1FAF5), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pengingat Tagihan', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor)),
                          Icon(
                            _isBillReminderEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: _isBillReminderEnabled ? AppColors.primaryGreen : Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                                  Navigator.pop(sheetContext);
                                  await DriveSyncService.backupToDrive(context);
                                },
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
                                            selected: selectedFilter == 0,
                                            selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                                            onSelected: (val) => setSheetState(() => selectedFilter = 0),
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            label: Text('Bulan Ini', style: GoogleFonts.plusJakartaSans()),
                                            selected: selectedFilter == 1,
                                            selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
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
                                        Navigator.pop(sheetContext);
                                        await ExportService.exportTransactionsToCSV(context, selectedFilter);
                                      },
                                    ),
                                    ListTile(
                                      leading: const FaIcon(FontAwesomeIcons.filePdf, color: Colors.red),
                                      title: Text('Ekspor sebagai PDF', style: GoogleFonts.plusJakartaSans(color: sheetTextColor)),
                                      subtitle: Text('Format rapi, siap untuk dicetak', style: GoogleFonts.plusJakartaSans()),
                                      onTap: () async {
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
                subtitle: 'v1.0.0 (Kebijakan Privasi, Layanan)',
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