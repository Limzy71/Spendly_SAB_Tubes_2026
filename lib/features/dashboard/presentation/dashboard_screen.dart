import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Warna hijau mint yang sesuai dengan gambar Figma
    const Color mintBgColor = Color(0xFFEDF7F7);
    const Color primaryTeal = Color(0xFF008080);

    return Scaffold(
      // Menggunakan warna latar belakang yang sedikit lebih gelap agar elemen kartu menonjol
      backgroundColor: mintBgColor, // Pastikan ini terpanggil
      appBar: AppBar(
        // UBAH: Ganti menjadi Colors.white agar kontras dengan background body
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 20.0, right: 10.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            backgroundImage: AssetImage('assets/profile.png'),
          ),
        ),

        title: const Text(
          'Spendly',
          style: TextStyle(
            color: Color(0xFF008080), // Warna Teal sesuai brand
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 16),
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // 1a. Total Saldo Card
            _buildBalanceCard(),

            const SizedBox(height: 20),

            // 1b. Ringkasan Pemasukan & Pengeluaran
            // CARI Row ringkasan ini dan GANTI isinya:
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: "Pemasukan",
                    amount: "Rp 12.5M",
                    indicatorColor: Colors.teal,
                    icon: Icons.trending_up,
                    iconBgColor: const Color(0xFFE0F2F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: "Pengeluaran",
                    amount: "Rp 4.2M",
                    indicatorColor: Colors.red,
                    icon: Icons.trending_down,
                    iconBgColor: const Color(0xFFFFEBEE),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 1d. Daftar Transaksi Terakhir
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transaksi Terakhir",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFF008080), fontSize: 13)),
                ),
              ],
            ),

            _buildTransactionItem("Gaji", "25 Okt 2023", "+ Rp 15.000.000", const Color(0xFFF3E5F5), Icons.wallet, Colors.green),
            _buildTransactionItem("Makan Siang", "24 Okt 2023", "- Rp 85.000", const Color(0xFFFFF3E0), Icons.restaurant, Colors.red),
            _buildTransactionItem("Transportasi", "24 Okt 2023", "- Rp 450.000", const Color(0xFFE3F2FD), Icons.directions_car, Colors.red),
            _buildTransactionItem("Belanja", "22 Okt 2023", "- Rp 1.240.000", const Color(0xFFE8F5E9), Icons.shopping_bag, Colors.red),
            _buildTransactionItem("Listrik & Air ", "22 Okt 2023", "- Rp 640.000", const Color(0xFFFFF176), Icons.electric_bolt, Colors.red),

            const SizedBox(height: 80), // Ruang agar tidak tertutup FAB
          ],
        ),
      ),

      // 1c. Quick Add Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF008080),
        elevation: 4,
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF008080),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Anggaran'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }

  // Widget Helper untuk Kartu Saldo
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Saldo",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              // Ikon dompet di pojok kanan atas kartu
              Icon(
                Icons.account_balance_wallet_rounded,
                color: const Color(0xFF008080).withValues(alpha: 0.2),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Rp 42.680.500",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          // Bagian rincian akun dengan background kotak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildMiniWalletCard("Tunai", "5.2M")),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniWalletCard("Bank", "32.4M")),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniWalletCard("E-Wallet", "5.0M")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniWalletCard(String name, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD8EBEB), // Warna kotak akun yang lebih gelap
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // GANTI fungsi _buildStatCard LAMA dengan ini:
  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required Color indicatorColor,
    required IconData icon,
    required Color iconBgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Garis indikator vertikal di samping kiri sesuai Figma [cite: 25]
              Container(
                width: 4,
                color: indicatorColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: iconBgColor,
                                shape: BoxShape.circle
                            ),
                            child: Icon(icon, size: 14, color: indicatorColor),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        amount,
                        style: TextStyle(
                          color: indicatorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String date, String amount, Color bgIcon, IconData icon, Color amountCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // Harus putih agar pop-out
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgIcon, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 24, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(color: amountCol, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}