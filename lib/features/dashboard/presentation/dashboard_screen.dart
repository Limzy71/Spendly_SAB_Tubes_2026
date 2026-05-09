import 'package:flutter/material.dart';
import '../../transaction/presentation/add_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF05A660);
    const Color backgroundColor = Color(0xFFF8F9FA);

    // --- SIMULASI DATA KOSONG ---
    // Ubah nilai ini menjadi 'true' jika ingin melihat daftar transaksi yang banyak
    // Ubah menjadi 'false' untuk melihat tampilan "Empty State" (Belum ada data)
    bool hasTransactions = false;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 20.0, right: 10.0),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
        ),
        title: const Text(
          'Spendly',
          style: TextStyle(
            color: primaryGreen,
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        backgroundColor: primaryGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // 1. Total Saldo Card (Sengaja dibuat Rp 0 untuk simulasi akun baru)
            _buildBalanceCard(primaryGreen, hasTransactions),

            const SizedBox(height: 20),

            // 2. Ringkasan Pemasukan & Pengeluaran
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: "Pemasukan",
                    amount: hasTransactions ? "Rp 12.5M" : "Rp 0",
                    indicatorColor: primaryGreen,
                    icon: Icons.trending_up,
                    iconBgColor: const Color(0xFFF1FAF5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: "Pengeluaran",
                    amount: hasTransactions ? "Rp 4.2M" : "Rp 0",
                    indicatorColor: Colors.red,
                    icon: Icons.trending_down,
                    iconBgColor: const Color(0xFFFFEBEE),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Header Transaksi Terakhir
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transaksi Terakhir",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (hasTransactions)
                  TextButton(
                    onPressed: () {},
                    child: const Text("Lihat Semua", style: TextStyle(color: primaryGreen, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. LOGIKA TAMPILAN: Menampilkan List Data ATAU Empty State
            if (hasTransactions) ...[
              // Jika data ada, tampilkan ini
              _buildTransactionItem("Gaji", "25 Okt 2023", "+ Rp 15.000.000", const Color(0xFFF1FAF5), Icons.wallet, primaryGreen),
              _buildTransactionItem("Makan Siang", "24 Okt 2023", "- Rp 85.000", const Color(0xFFFFF3E0), Icons.restaurant, Colors.red),
              _buildTransactionItem("Transportasi", "24 Okt 2023", "- Rp 450.000", const Color(0xFFE3F2FD), Icons.directions_car, Colors.red),
            ] else ...[
              // Jika data KOSONG, tampilkan Empty State ini
              _buildEmptyState(primaryGreen),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  // WIDGET BARU: Empty State Design
  Widget _buildEmptyState(Color primaryGreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 64, color: primaryGreen.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Belum ada transaksi",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            "Catat pengeluaran dan pemasukan\npertamamu hari ini!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Color primaryColor, bool hasData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Saldo", style: TextStyle(color: Colors.grey, fontSize: 14)),
              Icon(Icons.account_balance_wallet, color: primaryColor, size: 26),
            ],
          ),
          const SizedBox(height: 4),
          Text(hasData ? "Rp 42.680.500" : "Rp 0", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildMiniWalletCard("Tunai", hasData ? "5.2M" : "0")),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniWalletCard("Bank", hasData ? "32.4M" : "0")),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniWalletCard("E-Wallet", hasData ? "5.0M" : "0")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniWalletCard(String name, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFFE6F7ED), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String amount, required Color indicatorColor, required IconData icon, required Color iconBgColor}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: indicatorColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle), child: Icon(icon, size: 14, color: indicatorColor)),
                          const SizedBox(width: 8),
                          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(amount, style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold, fontSize: 16)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgIcon, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 24, color: Colors.black87)),
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
          Text(amount, style: TextStyle(color: amountCol, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}