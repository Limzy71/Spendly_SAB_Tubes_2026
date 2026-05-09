import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPinEnabled = true;
  bool _isBiometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // Placeholder untuk logo Spendly kecil
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Spendly',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // --- Bagian Profil Header ---
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=11'), // Ganti dengan asset lokal jika ada
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Budi Santoso',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'budi.santoso@email.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- PENGATURAN AKUN ---
            _buildSectionTitle('PENGATURAN AKUN'),
            _buildListTile(
              icon: Icons.lock_outline,
              title: 'Ubah Kata Sandi',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {},
            ),
            _buildSwitchTile(
              icon: Icons.pin_outlined,
              title: 'PIN Keamanan',
              value: _isPinEnabled,
              onChanged: (val) => setState(() => _isPinEnabled = val),
            ),
            _buildSwitchTile(
              icon: Icons.fingerprint,
              title: 'Autentikasi Biometrik',
              subtitle: 'Fingerprint / Face ID',
              value: _isBiometricEnabled,
              onChanged: (val) => setState(() => _isBiometricEnabled = val),
            ),

            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),

            // --- PENGATURAN APLIKASI ---
            _buildSectionTitle('PENGATURAN APLIKASI'),
            _buildListTile(
              icon: Icons.notifications_outlined,
              title: 'Pengaturan Notifikasi',
              subtitleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Daily Reminders', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const Text('20:00', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bill Reminders', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const Icon(Icons.check, color: Colors.green, size: 16),
                    ],
                  ),
                ],
              ),
              onTap: () {},
            ),
            _buildListTile(
              icon: Icons.palette_outlined,
              title: 'Tema Aplikasi',
              subtitle: 'Terang (Light)',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {},
            ),

            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),

            // --- DATA & SINKRONISASI ---
            _buildSectionTitle('DATA & SINKRONISASI'),
            _buildListTile(
              icon: Icons.cloud_outlined,
              title: 'Cloud Backup & Sync',
              subtitle: 'Terhubung ke Google Drive',
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Sync Now', style: TextStyle(fontSize: 12)),
              ),
            ),
            _buildListTile(
              icon: Icons.download_outlined,
              title: 'Ekspor Data (.csv, .pdf)',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {},
            ),

            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),

            // --- BANTUAN & INFO ---
            _buildSectionTitle('BANTUAN & INFO'),
            _buildListTile(
              icon: Icons.help_outline,
              title: 'Pusat Bantuan (FAQ)',
              trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 20),
              onTap: () {},
            ),
            _buildListTile(
              icon: Icons.info_outline,
              title: 'Tentang Spendly',
              subtitle: 'v1.0.1 (Kebijakan Privasi, Layanan)',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {},
            ),

            const Divider(height: 30, thickness: 1, color: Color(0xFFF0F0F0)),

            // --- ZONA BERBAHAYA ---
            _buildSectionTitle('ZONA BERBAHAYA', color: Colors.redAccent),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Hapus Seluruh Data', style: TextStyle(color: Colors.red, fontSize: 14)),
              onTap: () {},
            ),

            const SizedBox(height: 20),

            // --- TOMBOL KELUAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red.shade50.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitleWidget ?? (subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null),
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: Colors.green,
      ),
      dense: true,
    );
  }
}