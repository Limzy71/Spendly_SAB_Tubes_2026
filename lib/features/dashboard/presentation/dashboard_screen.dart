import 'package:flutter/material.dart';
import '../../transaction/presentation/add_transaction_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/transaction_item.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool hasTransactions = true;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            const Text("Selamat Pagi,", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const Text("Budi Santoso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 16),

            _buildBalanceCard(AppColors.primaryGreen, hasTransactions),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: "Pemasukan",
                    amount: hasTransactions ? "Rp 12.5M" : "Rp 0",
                    indicatorColor: AppColors.primaryGreen,
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
                    child: const Text("Lihat Semua", style: TextStyle(color: AppColors.primaryGreen, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasTransactions) ...[
              TransactionItem(
                title: "Gaji",
                subtitle: "25 Okt 2023",
                amount: "+ Rp 15.000.000",
                bgIconColor: const Color(0xFFF1FAF5),
                icon: Icons.wallet,
                amountColor: AppColors.primaryGreen,
              ),
              TransactionItem(
                title: "Makan Siang",
                subtitle: "24 Okt 2023",
                amount: "- Rp 85.000",
                bgIconColor: const Color(0xFFFFF3E0),
                icon: Icons.restaurant,
                amountColor: Colors.red,
              ),
              TransactionItem(
                title: "Transportasi",
                subtitle: "24 Okt 2023",
                amount: "- Rp 450.000",
                bgIconColor: const Color(0xFFE3F2FD),
                icon: Icons.directions_car,
                amountColor: Colors.red,
              ),
            ] else ...[
              _buildEmptyState(AppColors.primaryGreen),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

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
}