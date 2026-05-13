import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/transaction_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  int _totalIncome = 0;
  int _totalExpense = 0;
  int _totalBalance = 0;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('transactions')
          .select()
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      int tempIncome = 0;
      int tempExpense = 0;

      for (var transaction in response) {
        int amount = transaction['amount'] as int;
        bool isExpense = transaction['is_expense'] as bool;

        if (isExpense) {
          tempExpense += amount;
        } else {
          tempIncome += amount;
        }
      }

      if (mounted) {
        setState(() {
          _totalIncome = tempIncome;
          _totalExpense = tempExpense;
          _totalBalance = tempIncome - tempExpense;
          _recentTransactions = response.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil data: $e')));
      }
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'id').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasTransactions = _recentTransactions.isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: AppColors.primaryGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              const Text("Selamat Pagi,", style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                      amount: _formatCurrency(_totalIncome),
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
                      amount: _formatCurrency(_totalExpense),
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
                        color: Theme.of(context).textTheme.bodyLarge?.color
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

              if (hasTransactions)
                ..._recentTransactions.map((tx) {
                  bool isExpense = tx['is_expense'] as bool;
                  return TransactionItem(
                    title: tx['category'] ?? "Lainnya",
                    subtitle: _formatDate(tx['transaction_date'] ?? ""),
                    amount: "${isExpense ? '-' : '+'} ${_formatCurrency(tx['amount'] ?? 0)}",
                    bgIconColor: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    icon: _getIconForCategory(tx['category']),
                    amountColor: isExpense ? Colors.red : AppColors.primaryGreen,
                  );
                }).toList()
              else
                _buildEmptyState(context, AppColors.primaryGreen),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    if (category == null) return Icons.receipt;

    switch (category.toLowerCase()) {
      case 'makan': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'belanja': return Icons.shopping_bag;
      case 'gaji': return Icons.wallet;
      default: return Icons.receipt_long;
    }
  }

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
        color: Theme.of(context).cardColor,
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
              _formatCurrency(_totalBalance),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  // Logika Warna Merah jika saldo minus
                  color: _totalBalance < 0
                      ? Colors.red
                      : Theme.of(context).textTheme.bodyLarge?.color
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(amount, style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold, fontSize: 16)),
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
}