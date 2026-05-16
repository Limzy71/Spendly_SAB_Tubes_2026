import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Package untuk membuka aplikasi lain
import '../../../theme/app_colors.dart'; // Sesuaikan path ini dengan lokasimu

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    // Daftar Pertanyaan dan Jawaban resmi sesuai Perancangan Aplikasi Spendly
    final List<Map<String, String>> faqs = [
      {
        'question': 'Bagaimana cara cepat mencatat transaksi?',
        'answer': 'Anda dapat menekan tombol "Plus" (+) Akses Cepat di halaman utama (Dashboard). Anda bisa memasukkan nominal, menyesuaikan tanggal, menambahkan catatan khusus, hingga melampirkan foto struk belanja sebagai bukti transaksi.'
      },
      {
        'question': 'Apa perbedaan fitur Dompet dan Anggaran?',
        'answer': 'Dompet (Wallet) adalah tempat penyimpanan uang Anda seperti Uang Tunai, rekening BCA, atau GoPay. Sedangkan Anggaran (Budget) adalah batas maksimal pengeluaran bulanan yang Anda tetapkan untuk kategori tertentu (misal: Anggaran Makan Rp 2.000.000).'
      },
      {
        'question': 'Apakah saya bisa memindahkan saldo antar dompet?',
        'answer': 'Bisa! Spendly menyediakan fitur "Transfer Antar Akun" (misalnya dari BCA ke GoPay). Transaksi ini hanya memindahkan saldo dan tidak akan dihitung sebagai pengeluaran Anda.'
      },
      {
        'question': 'Apakah data keuangan saya di Spendly aman?',
        'answer': 'Sangat aman. Spendly dilengkapi dengan fitur keamanan tingkat tinggi. Anda dapat mengaktifkan Passcode/PIN 4-6 digit serta menggunakan Autentikasi Biometrik (Sidik Jari / Face ID) melalui menu Pengaturan Akun di halaman Profil.'
      },
      {
        'question': 'Bagaimana jika pengeluaran saya melebihi batas?',
        'answer': 'Fitur Anggaran kami memiliki indikator visual (progress bar). Sistem akan otomatis mengirimkan notifikasi peringatan (alert) apabila pengeluaran Anda sudah mencapai 80% atau 100% dari batas anggaran yang ditentukan.'
      },
      {
        'question': 'Bagaimana cara memindahkan data ke HP baru?',
        'answer': 'Gunakan menu "Cadangkan & Sinkronisasi" di halaman Profil. Lakukan "Cadangkan Data" pada HP lama untuk menyimpan data ke Cloud (Google Drive). Di HP baru, cukup login dan pilih "Sinkronisasi Data" untuk memulihkannya.'
      },
      {
        'question': 'Bisakah saya mencetak laporan keuangan saya?',
        'answer': 'Tentu. Anda dapat menggunakan menu "Ekspor Data" di halaman Profil untuk mengunduh riwayat laporan keuangan Anda ke dalam format Excel (.csv) atau PDF, lalu menyimpannya di folder perangkat Anda.'
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pusat Bantuan (FAQ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 0,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: AppColors.primaryGreen,
                      collapsedIconColor: Colors.grey,
                      title: Text(
                        faqs[index]['question']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: Text(
                            faqs[index]['answer']!,
                            style: TextStyle(
                              height: 1.5,
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bagian Bawah: Info Kontak Developer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade50,
              border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Text(
                  'Masih butuh bantuan?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jika Anda menemukan kendala lain, silakan hubungi tim dukungan kami.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),

                // --- TOMBOL HUBUNGI KAMI YANG SUDAH BERFUNGSI ---
                ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Tentukan alamat email tujuan
                    const String emailTujuan = 'email.spendly@gmail.com'; // GANTI DENGAN EMAIL KAMU
                    const String subjek = 'Bantuan Aplikasi Spendly';

                    // 2. Format URL khusus untuk membuka email (mailto:)
                    final Uri emailUri = Uri.parse('mailto:$emailTujuan?subject=${Uri.encodeComponent(subjek)}');

                    // 3. Coba buka aplikasi email
                    try {
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        // Jika di HP tidak ada aplikasi email sama sekali
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tidak dapat menemukan aplikasi Email di perangkat ini.'), backgroundColor: Colors.orange)
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Terjadi kesalahan saat membuka aplikasi Email.'), backgroundColor: Colors.red)
                        );
                      }
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.envelope, size: 16, color: Colors.white),
                  label: const Text('Hubungi Kami', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 45)
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}