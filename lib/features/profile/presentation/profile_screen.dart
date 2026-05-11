import 'package:flutter/material.dart';
import 'widgets/update_profile_screen.dart';
import '../../../theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/theme_cubit.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPinEnabled = true;
  bool _isBiometricEnabled = false;
  String? _profileImagePath;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  bool _isBillReminderEnabled = true;

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
              onPressed: () {
                Navigator.pop(context);
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
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
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
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
                              backgroundColor: Colors.transparent,
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
                            child: const Icon(Icons.edit, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Budi Santoso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  const Text('budi.santoso@email.com', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('PENGATURAN AKUN'),
            _buildListTile(icon: Icons.lock_outline, title: 'Ubah Kata Sandi', trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: () {}),
            _buildSwitchTile(icon: Icons.pin_outlined, title: 'PIN Keamanan', value: _isPinEnabled, onChanged: (val) => setState(() => _isPinEnabled = val), activeColor: AppColors.primaryGreen),
            _buildSwitchTile(icon: Icons.fingerprint, title: 'Autentikasi Biometrik', subtitle: 'Sidik Jari / Pemindai Wajah', value: _isBiometricEnabled, onChanged: (val) => setState(() => _isBiometricEnabled = val), activeColor: AppColors.primaryGreen),
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
                  ListTile(leading: Icon(Icons.notifications_none_outlined, color: textColor), title: Text('Pengaturan Notifikasi', style: TextStyle(fontSize: 15, color: textColor))),

                  // FITUR: Pengingat Harian
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1FAF5),
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

                  // FITUR: Pengingat Tagihan
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isBillReminderEnabled = !_isBillReminderEnabled;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1FAF5), borderRadius: BorderRadius.circular(8)),
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
                    leading: Icon(Icons.palette_outlined, color: textColor),
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
            _buildListTile(icon: Icons.cloud_outlined, title: 'Cadangkan & Sinkronisasi', subtitle: 'Terhubung ke Google Drive', trailing: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), minimumSize: const Size(0, 32)), child: const Text('Sinkron', style: TextStyle(fontSize: 12, color: Colors.white)))),
            _buildListTile(icon: Icons.download_outlined, title: 'Ekspor Data (.csv, .pdf)', trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: () {}),
            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),
            _buildSectionTitle('BANTUAN & INFO'),
            _buildListTile(icon: Icons.help_outline, title: 'Pusat Bantuan (FAQ)', trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 20), onTap: () {}),
            _buildListTile(icon: Icons.info_outline, title: 'Tentang Spendly', subtitle: 'v1.0.0 (Kebijakan Privasi, Layanan)', trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: () {}),
            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),
            _buildSectionTitle('ZONA BERBAHAYA', color: Colors.redAccent),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Hapus Seluruh Data', style: TextStyle(color: Colors.red, fontSize: 14)),
              onTap: _showDeleteDataDialog,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade200), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: Colors.red.shade50.withOpacity(0.3)),
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

  Widget _buildListTile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged, required Color activeColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: activeColor),
      dense: true,
    );
  }
}