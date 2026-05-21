import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_budget_screen.dart';
import 'edit_budget_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/category_helper.dart';

// IMPORT NETWORK HELPER
import '../../../../widgets/network_helper.dart';

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
  Map<String, String> _customIcons = {};

  @override
  void initState() {
    super.initState();
    _fetchBudgetData();
  }

  Future<void> _fetchBudgetData() async {
    // INTEGRASI NETWORK HELPER SEBELUM FETCH DATA
    if (!await NetworkHelper.checkConnection(context)) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      List<String> customCats = prefs.getStringList('custom_budget_categories') ?? [];
      Map<String, String> tempIcons = {};
      for (String cat in customCats) {
        tempIcons[cat.toLowerCase()] = prefs.getString('custom_budget_icon_$cat') ?? 'star';
      }

      final DateTime now = DateTime.now();
      final String currentPeriodMonth = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final String firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final String lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

      final budgetResponse = await supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('period_month', currentPeriodMonth);

      final transactionResponse = await supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('is_expense', true)
          .gte('transaction_date', firstDayOfMonth)
          .lte('transaction_date', lastDayOfMonth);

      int tempTotalLimit = 0;
      int tempTotalSpent = 0;

      Map<String, Map<String, dynamic>> accumulatedBudgets = {};

      for (var budget in budgetResponse) {
        String category = budget['category'] as String;
        int limit = budget['limit_amount'] as int;

        if (accumulatedBudgets.containsKey(category)) {
          accumulatedBudgets[category]!['limit'] += limit;
        } else {
          accumulatedBudgets[category] = {
            'category': category,
            'limit': limit,
            'spent': 0,
          };
        }
      }

      accumulatedBudgets.forEach((category, data) {
        int spent = 0;
        for (var tx in transactionResponse) {
          if (tx['category']?.toString().toLowerCase() ==
              category.toLowerCase()) {
            spent += tx['amount'] as int;
          }
        }

        data['spent'] = spent;
        tempTotalLimit += data['limit'] as int;
        tempTotalSpent += spent;
      });

      List<Map<String, dynamic>> processedBudgets = accumulatedBudgets.values
          .map((data) {
        int limit = data['limit'] as int;
        int spent = data['spent'] as int;
        return {
          'category': data['category'],
          'limit': limit,
          'spent': spent,
          'percentage': limit == 0 ? 0.0 : (spent / limit),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _customIcons = tempIcons;
          _totalBudgetLimit = tempTotalLimit;
          _totalBudgetSpent = tempTotalSpent;
          _budgets = processedBudgets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomNotification.show(context, 'Gagal mengambil data anggaran: $e', isError: true);
      }
    }
  }

  String _formatFullCurrency(int amount) {
    return NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
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
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anggaran Saya', style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text('Pantau pengeluaran bulanan Anda agar tetap terkendali.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),

              ..._budgets.where((b) => b['percentage'] >= 0.8).map((budget) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? Colors.red.withValues(alpha: 0.3) : Colors.red.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Peringatan Anggaran',
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                'Anggaran ${budget['category']} mencapai ${(budget['percentage'] * 100).toInt()}%! Sebaiknya kurangi pengeluaran di kategori ini.',
                                style: const TextStyle(color: Colors.red,
                                    fontSize: 12,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Terpakai',
                            style: TextStyle(fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textColor)),
                        Text(DateFormat('MMMM yyyy', 'id').format(DateTime
                            .now()), style: const TextStyle(color: Colors.grey,
                            fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatFullCurrency(_totalBudgetSpent),
                            style: TextStyle(fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('/ ${_formatFullCurrency(
                              _totalBudgetLimit)}', style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: totalPercentage.clamp(0.0, 1.0),
                        backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            totalPercentage >= 0.8 ? Colors.red : AppColors.primaryGreen),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(totalPercentage * 100).toInt()}% Terpakai',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: totalPercentage >= 0.8
                                    ? Colors.red
                                    : AppColors.primaryGreen)),
                        Text(totalRemaining < 0
                            ? 'Overbudget ${_formatFullCurrency(
                            totalRemaining.abs())}'
                            : 'Sisa ${_formatFullCurrency(totalRemaining)}',
                            style: TextStyle(
                                fontSize: 12, color: totalRemaining < 0 ? Colors
                                .red : Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text('Kategori Anggaran', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 16),

              if (_budgets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("Belum ada anggaran yang dibuat.",
                        style: TextStyle(color: Colors.grey[600])),
                  ),
                )
              else
                ..._budgets.map((budget) {
                  return _buildBudgetItem(
                    cardColor,
                    textColor,
                    isDark,
                    CategoryHelper.getIcon(budget['category'], customIcons: _customIcons),
                    CategoryHelper.getColor(budget['category'], customIcons: _customIcons),
                    budget['category'],
                    _formatFullCurrency(budget['spent']),
                    _formatFullCurrency(budget['limit']),
                    budget['percentage'],
                    budget['limit'],
                  );
                }).toList(),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const AddBudgetScreen()));
                    _fetchBudgetData();
                  },
                  icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 16),
                  label: const Text('Tambah Anggaran Baru', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

  Widget _buildBudgetItem(Color cardColor, Color textColor, bool isDark,
      dynamic icon, Color iconColor, String title, String spent, String limit,
      double percentage, int rawLimit) {
    final bool isWarning = percentage >= 0.80;
    final Color progressColor = isWarning ? Colors.red : AppColors.primaryGreen;

    final bool isOverbudget = percentage > 1.0;
    final int excessAmount = isOverbudget ? ((percentage - 1.0) * rawLimit).round() : 0;

    return GestureDetector(
      onTap: () async {
        final isDataChanged = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EditBudgetScreen(
                  category: title,
                  currentLimit: rawLimit,
                  icon: icon,
                  iconColor: iconColor,
                ),
          ),
        );

        if (isDataChanged == true) {
          _fetchBudgetData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: FaIcon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor)),
                      const SizedBox(height: 4),
                      Text('$spent / $limit', style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text('${(percentage * 100).toInt()}%', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                    fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            if (isOverbudget) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '${(percentage * 100).toInt()}% Terpakai',
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                      )
                  ),
                  Text(
                      'Overbudget ${_formatFullCurrency(excessAmount)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      )
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}