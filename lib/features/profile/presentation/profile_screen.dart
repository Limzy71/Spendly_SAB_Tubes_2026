import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- IMPORT MEMORI LOKAL
import 'change_password_screen.dart';
import 'widgets/update_profile_screen.dart';
import '../../../theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/theme_cubit.dart';
import 'dart:io';
import '../logic/export_service.dart';
import '../logic/drive_sync_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPinEnabled = false; // <-- Default dimatikan dulu
  bool _isBiometricEnabled = false;
  String? _profileImagePath;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isBillReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPinStatus(); // <-- Cek status PIN saat halaman dibuka
  }

  // --- FUNGSI CEK STATUS SAKELAR PIN DARI MEMORI HP ---
  Future<void> _loadPinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPinEnabled = prefs.getBool('is_pin_enabled') ?? false;
    });
  }

  // --- FUNGSI SAAT SAKELAR PIN DIGESER ---
  Future<void> _togglePin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin');

    // Cek: Kalau user mau mengaktifkan PIN tapi belum pernah buat PIN sama sekali
    if (value == true && savedPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan Buat PIN terlebih dahulu!'), backgroundColor: Colors.orange),
      );
      // Lempar ke halaman buat PIN
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen())).then((_) {
        _loadPinStatus(); // Update status sakelar setelah kembali dari halaman buat PIN
      });
      return;
    }

    // Simpan status sakelar ke memori HP
    await prefs.setBool('is_pin_enabled', value);
    setState(() {
      _isPinEnabled = value; // Ubah tampilan sakelar
    });
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
      setState(() {
        _reminderTime = picked;
      });
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
              onPressed: () {
                Navigator.pop(context);
              },
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
                          backgroundImage: _profileImagePath != null
                              ? FileImage(File(_profileImagePath!)) as ImageProvider
                              : const NetworkImage('https://i.pravatar.cc/150?img=11'),
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
                ).then((_) {
                  _loadPinStatus(); // Update status PIN kalau habis diubah
                });
              },
            ),

            // --- SAKELAR PIN YANG SUDAH DIPERBAIKI ---
            _buildSwitchTile(
                icon: FontAwesomeIcons.shieldHalved,
                title: 'PIN Keamanan',
                value: _isPinEnabled,
                onChanged: _togglePin, // Memanggil fungsi simpan ke memori
                activeColor: AppColors.primaryGreen
            ),

            _buildSwitchTile(icon: FontAwesomeIcons.fingerprint, title: 'Autentikasi Biometrik', subtitle: 'Sidik Jari / Pemindai Wajah', value: _isBiometricEnabled, onChanged: (val) => setState(() => _isBiometricEnabled = val), activeColor: AppColors.primaryGreen),
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
                      setState(() {
                        _isBillReminderEnabled = !_isBillReminderEnabled;
                      });
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
            _buildListTile(
                icon: FontAwesomeIcons.cloudArrowUp,
                title: 'Cadangkan & Sinkronisasi',
                subtitle: 'Terhubung ke Google Drive',
                trailing: ElevatedButton(
                    onPressed: () async {
                      // PANGGIL SERVICE DRIVE DI SINI
                      await DriveSyncService.backupToDrive(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(0, 32)
                    ),
                    child: const Text('Sinkron', style: TextStyle(fontSize: 12, color: Colors.white))
                )
            ),
            _buildListTile(
                icon: FontAwesomeIcons.fileExport,
                title: 'Ekspor Data (.csv, .pdf)',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).cardColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (BuildContext context) {
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
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Menyiapkan file CSV...'))
                                  );
                                  await ExportService.exportTransactionsToCSV(context);
                                },
                              ),
                              ListTile(
                                leading: const FaIcon(FontAwesomeIcons.filePdf, color: Colors.red),
                                title: Text('Ekspor sebagai PDF', style: TextStyle(color: sheetTextColor)),
                                subtitle: const Text('Format rapi, siap untuk dicetak'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Menyiapkan file PDF...'))
                                  );
                                  await ExportService.exportTransactionsToPDF(context);
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
            _buildListTile(icon: FontAwesomeIcons.circleQuestion, title: 'Pusat Bantuan (FAQ)', trailing: const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, color: Colors.grey, size: 16), onTap: () {}),
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