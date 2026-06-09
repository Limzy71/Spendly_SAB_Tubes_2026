import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/transaction_item.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../transaction/presentation/edit_transaction_screen.dart';
import '../../../../widgets/category_helper.dart';
import '../../../../widgets/network_helper.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final supabase = Supabase.instance.client;
  final Color barRed = const Color(0xFFD93F3C);

  String selectedFilter = 'Bulanan';
  final List<String> filters = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];

  DateTimeRange? _customDateRange;

  bool _isLoading = true;

  int _filteredExpense = 0;
  List<Map<String, dynamic>> _topTransactions = [];
  Map<String, double> _categoryPercentages = {};
  Map<String, String> _customIcons = {};

  List<double> _chartIncome = [];
  List<double> _chartExpense = [];
  List<String> _chartLabels = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _fetchReportData();
  }

  String _getFilterTitleText() {
    if (selectedFilter == 'Kustom' && _customDateRange != null) {
      return "${DateFormat('dd MMM', 'id').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy', 'id').format(_customDateRange!.end)}";
    }
    if (selectedFilter == 'Mingguan') return '7 Hari Terakhir';
    return selectedFilter;
  }

  Future<void> _pickCustomDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
              secondary: AppColors.primaryGreen,
              onSecondary: Colors.white,
            )
                : const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? const Color(0xFF252525) : AppColors.primaryGreen,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actionsIconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedFilter = 'Kustom';
        _customDateRange = picked;
      });
      _fetchReportData();
    }
  }

  Future<void> _fetchReportData() async {
    bool isOnline = await NetworkHelper.checkConnection(context);
    if (!isOnline) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      Map<String, String> tempIcons = {};

      void loadCustomIcons(String listKey, String iconPrefix) {
        final customCats = prefs.getStringList(listKey) ?? [];
        for (final cat in customCats) {
          tempIcons[cat.toLowerCase()] = prefs.getString('$iconPrefix$cat') ?? 'star';
        }
      }

      loadCustomIcons('custom_transaction_expense_categories', 'custom_transaction_expense_icon_');
      loadCustomIcons('custom_transaction_income_categories', 'custom_transaction_income_icon_');
      loadCustomIcons('custom_budget_categories', 'custom_budget_icon_');

      _customIcons = tempIcons;

      final txResponse = await supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .neq('category', 'Transfer');

      DateTime startDate = DateTime.now();
      DateTime endDate = DateTime.now();
      DateTime now = DateTime.now();

      List<double> tempChartIncome = [];
      List<double> tempChartExpense = [];
      List<String> tempChartLabels = [];
      List<DateTime> last7Days = [];

      if (selectedFilter == 'Kustom' && _customDateRange != null) {
        startDate = _customDateRange!.start;
        endDate = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
      } else if (selectedFilter == 'Harian') {
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (selectedFilter == 'Mingguan') {
        for (int i = 6; i >= 0; i--) {
          last7Days.add(now.subtract(Duration(days: i)));
        }
        startDate = DateTime(last7Days.first.year, last7Days.first.month, last7Days.first.day);
        endDate = DateTime(last7Days.last.year, last7Days.last.month, last7Days.last.day, 23, 59, 59);
      } else if (selectedFilter == 'Tahunan') {
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      } else {
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }

      if (selectedFilter == 'Tahunan') {
        tempChartIncome = List.filled(12, 0.0);
        tempChartExpense = List.filled(12, 0.0);
        tempChartLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        for (var tx in txResponse) {
          DateTime txDate = DateTime.parse(tx['transaction_date']);
          if (txDate.year == startDate.year) {
            int amount = int.tryParse(tx['amount'].toString()) ?? 0;
            if (tx['is_expense'] == true) {
              tempChartExpense[txDate.month - 1] += amount;
            } else {
              tempChartIncome[txDate.month - 1] += amount;
            }
          }
        }
      } else if (selectedFilter == 'Mingguan') {
        tempChartIncome = List.filled(7, 0.0);
        tempChartExpense = List.filled(7, 0.0);
        List<String> dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

        for (var date in last7Days) {
          tempChartLabels.add(dayNames[date.weekday - 1]);
        }

        for (var tx in txResponse) {
          DateTime txDate = DateTime.parse(tx['transaction_date']);
          if (txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && txDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
            int amount = int.tryParse(tx['amount'].toString()) ?? 0;
            int dayIdx = -1;
            for (int i = 0; i < 7; i++) {
              if (txDate.year == last7Days[i].year && txDate.month == last7Days[i].month && txDate.day == last7Days[i].day) {
                dayIdx = i;
                break;
              }
            }
            if (dayIdx != -1) {
              if (tx['is_expense'] == true) {
                tempChartExpense[dayIdx] += amount;
              } else {
                tempChartIncome[dayIdx] += amount;
              }
            }
          }
        }
      } else {
        int days = endDate.difference(startDate).inDays + 1;
        int segments = (days / 7).ceil();
        if (segments == 0) {
          segments = 1;
        }

        tempChartIncome = List.filled(segments, 0.0);
        tempChartExpense = List.filled(segments, 0.0);

        for (int i = 0; i < segments; i++) {
          int startDay = (i * 7) + 1;
          int endDay = (i * 7) + 7;
          if (endDay > days) {
            endDay = days;
          }

          if (selectedFilter == 'Harian') {
            tempChartLabels.add('Hari Ini');
          } else if (selectedFilter == 'Kustom' && days == 1) {
            tempChartLabels.add(DateFormat('dd MMM').format(startDate));
          } else if (startDay == endDay) {
            tempChartLabels.add('$startDay');
          } else {
            tempChartLabels.add('$startDay-$endDay');
          }
        }

        for (var tx in txResponse) {
          DateTime txDate = DateTime.parse(tx['transaction_date']);
          if (txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && txDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
            int amount = int.tryParse(tx['amount'].toString()) ?? 0;
            int diffDays = txDate.difference(startDate).inDays;
            int segIdx = diffDays ~/ 7;
            if (segIdx >= segments) {
              segIdx = segments - 1;
            }
            if (segIdx < 0) {
              segIdx = 0;
            }

            if (tx['is_expense'] == true) {
              tempChartExpense[segIdx] += amount;
            } else {
              tempChartIncome[segIdx] += amount;
            }
          }
        }
      }

      int tempFilteredExpense = 0;
      Map<String, int> categoryTotals = {};
      int totalExpenseForPie = 0;
      List<Map<String, dynamic>> tempTopTx = [];

      for (var tx in txResponse) {
        DateTime txDate = DateTime.parse(tx['transaction_date']);
        if (txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && txDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
          int amount = int.tryParse(tx['amount'].toString()) ?? 0;
          bool isExpense = tx['is_expense'] == true;
          String category = tx['category']?.toString() ?? 'Lainnya';

          if (isExpense) {
            tempFilteredExpense += amount;
            totalExpenseForPie += amount;

            if (categoryTotals.containsKey(category)) {
              categoryTotals[category] = categoryTotals[category]! + amount;
            } else {
              categoryTotals[category] = amount;
            }
          }
        }
      }

      List<Map<String, dynamic>> sortedTxResponse = List<Map<String, dynamic>>.from(txResponse)
        ..sort((a, b) => (int.tryParse(b['amount'].toString()) ?? 0).compareTo(int.tryParse(a['amount'].toString()) ?? 0));

      for (var tx in sortedTxResponse) {
        DateTime txDate = DateTime.parse(tx['transaction_date']);
        if (txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && txDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
          if (tx['is_expense'] == true && tempTopTx.length < 3) {
            tempTopTx.add(tx);
          }
        }
      }

      Map<String, double> tempCategoryPercentages = {};
      if (totalExpenseForPie > 0) {
        var sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (var entry in sortedCategories) {
          tempCategoryPercentages[entry.key] = (entry.value / totalExpenseForPie) * 100;
        }
      }

      if (mounted) {
        setState(() {
          _filteredExpense = tempFilteredExpense;
          _chartIncome = tempChartIncome;
          _chartExpense = tempChartExpense;
          _chartLabels = tempChartLabels;
          _categoryPercentages = tempCategoryPercentages;
          _topTransactions = tempTopTx;
        });
      }
    } catch (e) {
      if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal memuat laporan');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

  String _formatDate(String dateString) {
    try {
      return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchReportData,
        color: AppColors.primaryGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analisis Laporan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1FAF5), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: filters.map((filter) {
                          bool isSelected = selectedFilter == filter;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => selectedFilter = filter);
                                _fetchReportData();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: isSelected ? (isDark ? Colors.white24 : Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : []),
                                alignment: Alignment.center,
                                child: Text(filter, style: TextStyle(color: isSelected ? AppColors.primaryGreen : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _pickCustomDateRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selectedFilter == 'Kustom' ? AppColors.primaryGreen : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1FAF5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(
                          FontAwesomeIcons.calendarDays,
                          color: selectedFilter == 'Kustom' ? Colors.white : AppColors.primaryGreen,
                          size: 20
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BudgetScreen())),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle), child: const FaIcon(FontAwesomeIcons.wallet, size: 20, color: AppColors.primaryGreen)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Anggaran Bulanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)), const SizedBox(height: 4), const Text('Pantau sisa limit pengeluaranmu', style: TextStyle(color: Colors.grey, fontSize: 12))])),
                      const Icon(Icons.chevron_right, color: AppColors.primaryGreen),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pengeluaran (${_getFilterTitleText()})', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(_formatCurrency(_filteredExpense), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kategori Pengeluaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 24),

                    if (_categoryPercentages.isEmpty)
                      Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("Belum ada pengeluaran\n(${_getFilterTitleText()})", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))))
                    else ...[
                      _buildPieChart(textColor),
                      const SizedBox(height: 24),
                      ..._categoryPercentages.entries.map((entry) {
                        Color color = CategoryHelper.getColor(entry.key);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildPieLegendItem(color, entry.key, '${entry.value.toStringAsFixed(1)}%', textColor),
                        );
                      }),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('Tren Pemasukan vs\nPengeluaran ${_getFilterTitleText()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3, color: textColor))),
                        Row(
                          children: [
                            const CircleAvatar(radius: 4, backgroundColor: AppColors.primaryGreen),
                            const SizedBox(width: 4),
                            Text('Masuk', style: TextStyle(fontSize: 11, color: textColor)),
                            const SizedBox(width: 12),
                            CircleAvatar(radius: 4, backgroundColor: barRed),
                            const SizedBox(width: 4),
                            Text('Keluar', style: TextStyle(fontSize: 11, color: textColor)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildBarChart(textColor, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pengeluaran Terbesar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              const SizedBox(height: 12),

              if (_topTransactions.isEmpty)
                Text("Belum ada data transaksi (${_getFilterTitleText()}).", style: const TextStyle(color: Colors.grey))
              else
                ..._topTransactions.map((tx) {
                  final catName = tx['category'] ?? 'Lainnya';
                  final catColor = CategoryHelper.getColor(catName);
                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditTransactionScreen(transaction: tx)));
                      if (!mounted) return;
                      if (result != null) {
                        _fetchReportData();
                      }
                    },
                    child: TransactionItem(
                      title: catName,
                      subtitle: '${_formatDate(tx['transaction_date'])} • ${tx['note'] ?? ''}',
                      amount: '- ${_formatCurrency(int.tryParse(tx['amount'].toString()) ?? 0)}',
                      bgIconColor: catColor.withValues(alpha: 0.1),
                      icon: CategoryHelper.getIcon(catName, customIcons: _customIcons),
                      iconColor: catColor,
                      amountColor: barRed,
                    ),
                  );
                }),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(Color textColor) {
    List<PieChartSectionData> sections = [];
    _categoryPercentages.forEach((key, value) {
      sections.add(
          PieChartSectionData(
            color: CategoryHelper.getColor(key),
            value: value,
            title: '',
            radius: 20,
          )
      );
    });

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                      _formatCurrency(_filteredExpense),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text('TOTAL', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ],
          ),
          PieChart(PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 60,
              startDegreeOffset: 270,
              sections: sections
          )),
        ],
      ),
    );
  }

  Widget _buildPieLegendItem(Color color, String title, String percentage, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 6, backgroundColor: color),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: textColor, fontSize: 13)),
          ],
        ),
        Text(percentage, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
      ],
    );
  }

  Widget _buildBarChart(Color textColor, bool isDark) {
    double maxVal = 0;
    for (int i = 0; i < _chartIncome.length; i++) {
      if (_chartIncome[i] > maxVal) {
        maxVal = _chartIncome[i];
      }
      if (_chartExpense[i] > maxVal) {
        maxVal = _chartExpense[i];
      }
    }
    if (maxVal == 0) {
      maxVal = 100000;
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < _chartLabels.length; i++) {
      barGroups.add(
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: _chartIncome[i], color: AppColors.primaryGreen, width: 8, borderRadius: BorderRadius.circular(2)),
            BarChartRodData(toY: _chartExpense[i], color: barRed, width: 8, borderRadius: BorderRadius.circular(2))
          ])
      );
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => isDark ? Colors.grey.shade800 : Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ').format(rod.toY),
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int idx = value.toInt();
                  String text = (idx >= 0 && idx < _chartLabels.length) ? _chartLabels[idx] : '';
                  return SideTitleWidget(meta: meta, space: 8, child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11)));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 75,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == maxVal * 1.2) return const SizedBox.shrink();
                  
                  // Format dengan cara custom untuk handle angka besar lebih baik
                  String formatted;
                  if (value >= 1000000000000) {
                    // Triliuan
                    formatted = '${(value / 1000000000000).toStringAsFixed(1)} t';
                  } else if (value >= 1000000000) {
                    // Miliaran
                    formatted = '${(value / 1000000000).toStringAsFixed(1)} m';
                  } else if (value >= 1000000) {
                    // Jutaan
                    formatted = '${(value / 1000000).toStringAsFixed(1)} jt';
                  } else if (value >= 1000) {
                    // Ribuan
                    formatted = '${(value / 1000).toStringAsFixed(0)} rb';
                  } else {
                    formatted = value.toStringAsFixed(0);
                  }
                  
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Text(
                      formatted,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxVal / 4) > 0 ? (maxVal / 4) : 100000,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1, dashArray: [5, 5]);
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}