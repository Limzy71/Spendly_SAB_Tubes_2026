import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _showSimpleDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(height: 1.5, fontSize: 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tentang Spendly', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Logo Aplikasi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(FontAwesomeIcons.wallet, size: 60, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text('Spendly', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text('Versi 1.0.0', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 30),

            // Deskripsi Singkat
            Text(
              'Spendly adalah aplikasi pencatatan keuangan cerdas yang membantu Anda mengelola pemasukan, pengeluaran, dan anggaran dengan mudah dan aman.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 40),

            // Info Tim Pengembang (Tubes Kelompok 7)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('TIM PENGEMBANG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ANGGOTA 1 (Kamu)
                    const Row(
                      children: [
                        FaIcon(FontAwesomeIcons.userGear, size: 18, color: AppColors.primaryGreen),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dhaffa Galang Fahriza', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Back-End Developer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // ANGGOTA 2
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.laptopCode, size: 18, color: AppColors.primaryGreen),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mudor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Front-End & UI/UX', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // ANGGOTA 3
                    const Row(
                      children: [
                        FaIcon(FontAwesomeIcons.userPen, size: 18, color: AppColors.primaryGreen),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Iksan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Database Administrator / QA', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // IDENTITAS KELOMPOK (Pindah ke bawah agar jadi kesimpulan tim)
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.graduationCap, size: 18, color: Colors.blue.shade400),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kelompok Keren', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Teknik Informatika - Univ. Pasundan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Info Legal
            Align(
              alignment: Alignment.centerLeft,
              child: Text('LEGAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.shieldHalved, size: 18, color: Colors.grey),
                    title: const Text('Kebijakan Privasi', style: TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      _showSimpleDialog(
                          context,
                          'Kebijakan Privasi',
                          'Data keuangan Anda disimpan dengan aman menggunakan enkripsi. Aplikasi Spendly tidak akan membagikan data pribadi Anda kepada pihak ketiga tanpa izin. Semua data backup di Google Drive sepenuhnya berada di bawah kendali akun Google Anda sendiri.'
                      );
                    },
                  ),
                  Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.fileContract, size: 18, color: Colors.grey),
                    title: const Text('Syarat & Ketentuan', style: TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      _showSimpleDialog(
                          context,
                          'Syarat & Ketentuan',
                          'Dengan menggunakan aplikasi Spendly, Anda setuju untuk tidak menyalahgunakan fitur-fitur yang ada. Aplikasi ini dibuat sebagai proyek akademik, sehingga pengembang tidak bertanggung jawab atas kerugian finansial yang diakibatkan oleh kesalahan input data.'
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text('© 2026 Spendly - Kelompok 7', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}