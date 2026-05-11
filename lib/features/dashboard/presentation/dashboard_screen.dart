import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/transaction_item.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool hasTransactions = true;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            const Text("Selamat Pagi,", style: TextStyle(color: Colors.grey, fontSize: 14)),
            // nanti di isi dengan nick user dari database
            const Text("Budi Santoso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 16),

            _buildBalanceCard(context, AppColors.primaryGreen, hasTransactions),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: "Pemasukan",
                    amount: hasTransactions ? "Rp 12.5M" : "Rp 0",
                    indicatorColor: AppColors.primaryGreen,
                    icon: Icons.trending_up,
                    iconBgColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.withOpacity(0.1)
                        : const Color(0xFFF1FAF5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: "Pengeluaran",
                    amount: hasTransactions ? "Rp 4.2M" : "Rp 0",
                    indicatorColor: Colors.red,
                    icon: Icons.trending_down,
                    iconBgColor: Colors.red.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Transaksi Terakhir",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color // Warna dinamis
                  ),
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
              // Widget TransactionItem harus dipastikan mendukung Dark Mode di dalamnya
              TransactionItem(
                title: "Gaji",
                subtitle: "25 Okt 2023",
                amount: "+ Rp 15.000.000",
                bgIconColor: Colors.green.withOpacity(0.1),
                icon: Icons.wallet,
                amountColor: AppColors.primaryGreen,
              ),
              TransactionItem(
                title: "Makan Siang",
                subtitle: "24 Okt 2023",
                amount: "- Rp 85.000",
                bgIconColor: Colors.orange.withOpacity(0.1),
                icon: Icons.restaurant,
                amountColor: Colors.red,
              ),
              TransactionItem(
                title: "Transportasi",
                subtitle: "24 Okt 2023",
                amount: "- Rp 450.000",
                bgIconColor: Colors.blue.withOpacity(0.1),
                icon: Icons.directions_car,
                amountColor: Colors.red,
              ),
            ] else ...[
              _buildEmptyState(context, AppColors.primaryGreen),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Menambahkan 'BuildContext context' di argumen agar Theme.of(context) bisa jalan
  Widget _buildEmptyState(BuildContext context, Color primaryGreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 64, color: primaryGreen.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            "Belum ada transaksi",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color
            ),
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

  Widget _buildBalanceCard(BuildContext context, Color primaryColor, bool hasData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Otomatis Hitam/Putih
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)
          ),
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
          Text(
              hasData ? "Rp 42.680.500" : "Rp 0",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color
              )
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildMiniWalletCard(context, "Tunai", hasData ? "5.2M" : "0")),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniWalletCard(context, "Bank", hasData ? "32.4M" : "0")),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniWalletCard(context, "E-Wallet", hasData ? "5.0M" : "0")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniWalletCard(BuildContext context, String name, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFE6F7ED),
          borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required String title, required String amount, required Color indicatorColor, required IconData icon, required Color iconBgColor}) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12)
      ),
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