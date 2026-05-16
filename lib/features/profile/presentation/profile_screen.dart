import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import 'change_password_screen.dart';
import 'widgets/update_profile_screen.dart';
import '../../../theme/app_colors.dart';
import '../logic/theme_cubit.dart';
import '../logic/export_service.dart';
import '../logic/drive_sync_service.dart';
import 'faq_screen.dart'; // <-- IMPORT HALAMAN FAQ DITAMBAHKAN DI SINI

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPinEnabled = false;
  bool _isBiometricEnabled = false;
  String? _profileImagePath;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isBillReminderEnabled = true;

  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPinEnabled = prefs.getBool('is_pin_enabled') ?? false;
      _isBiometricEnabled = prefs.getBool('is_biometric_enabled') ?? false;
    });
  }

  void _showTopNotification(BuildContext context, String message, {bool isError = false, bool isWarning = false}) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    Color bgColor = const Color(0xFF00AA5B);
    IconData icon = Icons.check;

    if (isError) {
      bgColor = const Color(0xFFE63946);
      icon = Icons.close;
    } else if (isWarning) {
      bgColor = Colors.orange.shade600;
      icon = Icons.warning_amber_rounded;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: -100, end: 0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: bgColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry != null && overlayEntry!.mounted) {
        overlayEntry!.remove();
      }
    });
  }

  Future<void> _togglePin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin');

    if (value == true && (savedPin == null || savedPin.isEmpty)) {
      _showTopNotification(context, 'Silakan Buat PIN terlebih dahulu!', isWarning: true);
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen())).then((_) {
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
      _showTopNotification(context, 'Aktifkan PIN Keamanan terlebih dahulu!', isWarning: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (value == true) {
      try {
        final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

        if (!canAuthenticate) {
          _showTopNotification(context, 'Perangkat tidak mendukung biometrik.', isError: true);
          return;
        }

        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Pindai sidik jari / wajah Anda untuk mengaktifkan',
        );

        if (didAuthenticate) {
          await prefs.setBool('is_biometric_enabled', true);
          setState(() => _isBiometricEnabled = true);
          _showTopNotification(context, 'Biometrik berhasil diaktifkan!');
        } else {
          setState(() => _isBiometricEnabled = false);
        }
      } catch (e) {
        _showTopNotification(context, 'Gagal verifikasi biometrik', isError: true);
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
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Keluar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Hapus Seluruh Data?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: const Text("Tindakan ini tidak dapat dibatalkan. Semua catatan transaksi Anda akan terhapus."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Hapus Permanen", style: TextStyle(color: Colors.white)),
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
    final userName = user?.userMetadata?['full_name'] ?? 'Pengguna Spendly';

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
                          backgroundImage: _profileImagePath != null
                              ? FileImage(File(_profileImagePath!)) as ImageProvider
                              : null,
                          child: _profileImagePath == null
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
                              builder: (context) => const UpdateProfileScreen(),
                            );
                            if (newPath != null) {
                              setState(() => _profileImagePath = newPath);
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
                  Text(userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(userEmail, style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                ).then((_) => _loadSecuritySettings());
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
                  ListTile(leading: FaIcon(FontAwesomeIcons.bell, color: textColor, size: 20), title: Text('Pengaturan Notifikasi', style: TextStyle(fontSize: 15, color: textColor))),
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
                          Text('Pengingat Harian', style: TextStyle(fontSize: 14, color: textColor)),
                          Text(_reminderTime.format(context), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _isBillReminderEnabled = !_isBillReminderEnabled);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1FAF5), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pengingat Tagihan', style: TextStyle(fontSize: 14, color: textColor)),
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
                    title: Text('Tema Aplikasi', style: TextStyle(fontSize: 15, color: textColor)),
                    subtitle: BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, themeMode) {
                        return Text(themeMode == ThemeMode.dark ? 'Gelap (Dark)' : 'Terang (Light)', style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12));
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

            // --- BAGIAN CADANGKAN & SINKRONISASI ---
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
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sheetTextColor),
                                ),
                              ),
                              ListTile(
                                leading: const FaIcon(FontAwesomeIcons.cloudArrowUp, color: Colors.green),
                                title: Text('Cadangkan Data', style: TextStyle(color: sheetTextColor)),
                                subtitle: const Text('Simpan seluruh data ke Google Drive'),
                                onTap: () async {
                                  Navigator.pop(sheetContext);
                                  await DriveSyncService.backupToDrive(context);
                                },
                              ),
                              ListTile(
                                leading: const FaIcon(FontAwesomeIcons.cloudArrowDown, color: Colors.blue),
                                title: Text('Sinkronisasi Data', style: TextStyle(color: sheetTextColor)),
                                subtitle: const Text('Pulihkan data dari Google Drive ke HP'),
                                onTap: () async {
                                  Navigator.pop(sheetContext);
                                  await DriveSyncService.restoreFromDrive(context);
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

            // --- BAGIAN EKSPOR DATA ---
            _buildListTile(
                icon: FontAwesomeIcons.fileExport,
                title: 'Ekspor Data (.csv, .pdf)',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  showModalBottomSheet(
                    context: context, // Ini Context layar utama (tidak mati)
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
                                  'Pilih Format Ekspor',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sheetTextColor),
                                ),
                              ),
                              ListTile(
                                leading: const FaIcon(FontAwesomeIcons.fileCsv, color: Colors.green),
                                title: Text('Ekspor sebagai CSV', style: TextStyle(color: sheetTextColor)),
                                subtitle: const Text('Cocok untuk Excel / Spreadsheet'),
                                onTap: () async {
                                  Navigator.pop(sheetContext); // Tutup pop-up pakai sheetContext
                                  await ExportService.exportTransactionsToCSV(context); // Ekspor pakai context utama
                                },
                              ),
                              ListTile(
                                leading: const FaIcon(FontAwesomeIcons.filePdf, color: Colors.red),
                                title: Text('Ekspor sebagai PDF', style: TextStyle(color: sheetTextColor)),
                                subtitle: const Text('Format rapi, siap untuk dicetak'),
                                onTap: () async {
                                  Navigator.pop(sheetContext); // Tutup pop-up pakai sheetContext
                                  await ExportService.exportTransactionsToPDF(context); // Ekspor pakai context utama
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
            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),

            _buildSectionTitle('BANTUAN & INFO'),

            // --- BAGIAN PUSAT BANTUAN (DIUBAH ONTAP-NYA DI SINI) ---
            _buildListTile(
                icon: FontAwesomeIcons.circleQuestion,
                title: 'Pusat Bantuan (FAQ)',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey), // Mengubah icon panah menjadi seragam
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FaqScreen()),
                  );
                }
            ),

            _buildListTile(icon: FontAwesomeIcons.circleInfo, title: 'Tentang Spendly', subtitle: 'v1.0.0 (Kebijakan Privasi, Layanan)', trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: () {}),

            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),
            _buildSectionTitle('ZONA BERBAHAYA', color: Colors.redAccent),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.red, size: 20),
              title: const Text('Hapus Seluruh Data', style: TextStyle(color: Colors.red, fontSize: 14)),
              onTap: _showDeleteDataDialog,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket, color: Colors.red, size: 18),
                label: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
    );
  }

  Widget _buildListTile({required dynamic icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: FaIcon(icon, color: Colors.grey[600], size: 20),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildSwitchTile({required dynamic icon, required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged, required Color activeColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: FaIcon(icon, color: Colors.grey[600], size: 20),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: activeColor),
      dense: true,
    );
  }
}