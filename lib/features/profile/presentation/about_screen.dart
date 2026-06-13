import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _showSimpleDialog(BuildContext context, String title, String content) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        content: SingleChildScrollView(
          child: Text(content, style: GoogleFonts.plusJakartaSans(height: 1.5, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
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
        title: Text('Tentang Spendly', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(FontAwesomeIcons.wallet, size: 60, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text('Spendly', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text('Versi 1.0.10', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 30),

            Text(
              'Spendly adalah aplikasi pencatatan keuangan cerdas yang membantu Anda mengelola pemasukan, pengeluaran, and anggaran dengan mudah dan aman.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 40),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('TIM PENGEMBANG', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
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
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.userTie, size: 18, color: AppColors.primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('La Ode Muh. Ikhsan Mbala', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                              Text('Project Manager / Full-stack', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)), // <-- Update Role
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.laptopCode, size: 18, color: AppColors.primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Murod Fikri Fadlurohman', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                              Text('Front-End & UI/UX', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.userPen, size: 18, color: AppColors.primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dhaffa Galang Fahriza', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                              Text('Database Administrator / QA', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.graduationCap, size: 18, color: Colors.blue.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Spendly Project', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                              Text('Teknik Informatika - Univ. Pasundan', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
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

            Align(
              alignment: Alignment.centerLeft,
              child: Text('LEGAL', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
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
                    title: Text('Kebijakan Privasi', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor)),
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
                    title: Text('Syarat & Ketentuan', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor)),
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
            Text('© 2026 Spendly', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade400)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}