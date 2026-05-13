import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'add_budget_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  int _totalBudgetLimit = 0;
  int _totalBudgetSpent = 0;
  List<Map<String, dynamic>> _budgets = [];

  @override
  void initState() {
    super.initState();
    _fetchBudgetData();
  }

  Future<void> _fetchBudgetData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Mengambil data Anggaran (Budgets)
      final budgetResponse = await supabase.from('budgets').select();

      // 2. Mengambil data Pengeluaran (Transactions) di bulan ini
      final DateTime now = DateTime.now();
      final String firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final String lastDayOfMonth = DateTime(now.year, now.month + 1, 0).toIso8601String();

      final transactionResponse = await supabase
          .from('transactions')
          .select()
          .eq('is_expense', true)
          .gte('transaction_date', firstDayOfMonth)
          .lte('transaction_date', lastDayOfMonth);

      int tempTotalLimit = 0;
      int tempTotalSpent = 0;
      List<Map<String, dynamic>> processedBudgets = [];

      // 3. Menggabungkan data Anggaran dengan Pengeluaran per kategori
      for (var budget in budgetResponse) {
        String category = budget['category'] as String;
        int limit = budget['limit_amount'] as int;
        tempTotalLimit += limit;

        // Hitung pengeluaran khusus untuk kategori ini
        int spent = 0;
        for (var tx in transactionResponse) {
          if (tx['category'] == category) {
            spent += tx['amount'] as int;
          }
        }
        tempTotalSpent += spent;

        processedBudgets.add({
          'category': category,
          'limit': limit,
          'spent': spent,
          'percentage': limit == 0 ? 0.0 : (spent / limit),
        });
      }

      if (mounted) {
        setState(() {
          _totalBudgetLimit = tempTotalLimit;
          _totalBudgetSpent = tempTotalSpent;
          _budgets = processedBudgets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil data anggaran: $e')));
      }
    }
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1).replaceAll('.0', '')}Jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toInt()}k';
    }
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _formatFullCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Icons.restaurant;
      case 'transportasi': return Icons.directions_car_outlined;
      case 'belanja': return Icons.shopping_bag_outlined;
      case 'hiburan': return Icons.movie;
      default: return Icons.category;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Colors.redAccent;
      case 'transportasi': return AppColors.primaryGreen;
      case 'belanja': return Colors.purple;
      case 'hiburan': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    double totalPercentage = _totalBudgetLimit == 0 ? 0.0 : (_totalBudgetSpent / _totalBudgetLimit);
    int totalRemaining = _totalBudgetLimit - _totalBudgetSpent;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SubAppBar(title: 'Rincian Anggaran'),
      body: RefreshIndicator(
        onRefresh: _fetchBudgetData,
        color: AppColors.primaryGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anggaran Saya', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text('Pantau pengeluaran bulanan Anda agar tetap terkendali.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),

              // Fitur Peringatan Dinamis: Akan muncul jika ada kategori yang >= 80%
              ..._budgets.where((b) => b['percentage'] >= 0.8).map((budget) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.red.withOpacity(0.1) : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Peringatan Anggaran', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                'Anggaran ${budget['category']} mencapai ${(budget['percentage'] * 100).toInt()}%! Sebaiknya kurangi pengeluaran di kategori ini.',
                                style: const TextStyle(color: Colors.red, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Progress Bar Total
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Terpakai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                        Text(DateFormat('MMMM yyyy', 'id').format(DateTime.now()), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatFullCurrency(_totalBudgetSpent), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('/ ${_formatFullCurrency(_totalBudgetLimit)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: totalPercentage.clamp(0.0, 1.0), // Clamp mencegah error jika melebihi 100%
                        backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(totalPercentage >= 0.8 ? Colors.red : AppColors.primaryGreen),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(totalPercentage * 100).toInt()}% Terpakai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: totalPercentage >= 0.8 ? Colors.red : AppColors.primaryGreen)),
                        Text(totalRemaining < 0 ? 'Overbudget ${_formatFullCurrency(totalRemaining.abs())}' : 'Sisa ${_formatFullCurrency(totalRemaining)}', style: TextStyle(fontSize: 12, color: totalRemaining < 0 ? Colors.red : Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text('Kategori Anggaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 16),

              if (_budgets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("Belum ada anggaran yang dibuat.", style: TextStyle(color: Colors.grey[600])),
                  ),
                )
              else
                ..._budgets.map((budget) {
                  return _buildBudgetItem(
                    cardColor,
                    textColor,
                    isDark,
                    _getIconForCategory(budget['category']),
                    _getColorForCategory(budget['category']),
                    budget['category'],
                    _formatCurrency(budget['spent']),
                    _formatCurrency(budget['limit']),
                    budget['percentage'],
                  );
                }).toList(),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBudgetScreen()));
                    _fetchBudgetData(); // Refresh otomatis jika ada data baru
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Tambah Anggaran Baru', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetItem(Color cardColor, Color textColor, bool isDark, IconData icon, Color iconColor, String title, String spent, String limit, double percentage) {
    final bool isWarning = percentage >= 0.80; // Peringatan saat 80%
    final Color progressColor = isWarning ? Colors.red : AppColors.primaryGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    const SizedBox(height: 4),
                    Text('$spent / $limit', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Text('${(percentage * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: progressColor, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}