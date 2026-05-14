import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/transaction_item.dart';
import '../../budget/presentation/budget_screen.dart';

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

  List<double> _monthlyIncome = List.filled(12, 0.0);
  List<double> _monthlyExpense = List.filled(12, 0.0);

  final List<Color> _pieColors = [
    AppColors.primaryGreen,
    const Color(0xFF4F46E5),
    const Color(0xFFFF8FA3),
    Colors.orange,
    Colors.teal,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _fetchReportData();
  }

  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    if (selectedFilter == 'Kustom' && _customDateRange != null) {
      return _customDateRange!.start;
    } else if (selectedFilter == 'Harian') {
      return DateTime(now.year, now.month, now.day);
    } else if (selectedFilter == 'Mingguan') {
      return now.subtract(Duration(days: now.weekday - 1));
    } else if (selectedFilter == 'Tahunan') {
      return DateTime(now.year, 1, 1);
    }
    return DateTime(now.year, now.month, 1);
  }

  DateTime _getEndDate() {
    DateTime now = DateTime.now();
    if (selectedFilter == 'Kustom' && _customDateRange != null) {
      return DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
    } else if (selectedFilter == 'Harian') {
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (selectedFilter == 'Tahunan') {
      return DateTime(now.year, 12, 31, 23, 59, 59);
    }
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  String _getFilterTitleText() {
    if (selectedFilter == 'Kustom' && _customDateRange != null) {
      return "${DateFormat('dd MMM', 'id').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy', 'id').format(_customDateRange!.end)}";
    }
    return selectedFilter;
  }

  Future<void> _pickCustomDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      // FOKUS PERBAIKAN: Optimalisasi tema adaptif untuk visibilitas total di Dark Mode
      builder: (BuildContext context, Widget? child) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Theme(
          data: Theme.of(context).copyWith(
            // Mengatur skema warna utama picker
            colorScheme: isDark
                ? const ColorScheme.dark(
              primary: AppColors.primaryGreen,   // Warna rentang & tanggal terpilih
              onPrimary: Colors.white,          // Warna teks di atas warna primary
              surface: Color(0xFF1E1E1E),       // Background container kalender (tidak hitam pekat absolut)
              onSurface: Colors.white,          // Warna angka tanggal, inisial hari, & nama bulan
              secondary: AppColors.primaryGreen,
              onSecondary: Colors.white,
            )
                : const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),

            // Perbaikan elemen Header (Judul, Start-End Date, Icon Close, & Icon Pensil)
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? const Color(0xFF252525) : AppColors.primaryGreen,
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Colors.white, // Menjamin icon Close ('X') muncul putih terang
              ),
              actionsIconTheme: const IconThemeData(
                color: Colors.white, // Menjamin icon aksi seperti Pensil muncul putih terang
              ),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Memastikan icon edit/pensil bawaan material mengikuti kontras yang tepat
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),

            // Memastikan tombol teks seperti 'Save' terlihat kontras dan jelas
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // Memaksa teks 'Save' tetap putih di mode gelap
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
    setState(() => _isLoading = true);

    try {
      final txResponse = await supabase
          .from('transactions')
          .select()
          .neq('category', 'Transfer')
          .order('amount', ascending: false);

      DateTime startDate = _getStartDate();
      DateTime endDate = _getEndDate();

      int tempFilteredExpense = 0;
      Map<String, int> categoryTotals = {};
      int totalExpenseForPie = 0;

      List<double> tempIncome = List.filled(12, 0.0);
      List<double> tempExpense = List.filled(12, 0.0);
      List<Map<String, dynamic>> tempTopTx = [];

      for (var tx in txResponse) {
        int amount = tx['amount'] as int;
        bool isExpense = tx['is_expense'] as bool;
        String category = tx['category']?.toString() ?? 'Lainnya';
        DateTime txDate = DateTime.parse(tx['transaction_date']);

        if (txDate.year == DateTime.now().year) {
          if (isExpense) {
            tempExpense[txDate.month - 1] += amount;
          } else {
            tempIncome[txDate.month - 1] += amount;
          }
        }

        if (txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            txDate.isBefore(endDate.add(const Duration(seconds: 1)))) {

          if (isExpense) {
            tempFilteredExpense += amount;
            totalExpenseForPie += amount;

            if (categoryTotals.containsKey(category)) {
              categoryTotals[category] = categoryTotals[category]! + amount;
            } else {
              categoryTotals[category] = amount;
            }

            if (tempTopTx.length < 3) {
              tempTopTx.add(tx);
            }
          }
        }
      }

      Map<String, double> tempCategoryPercentages = {};
      if (totalExpenseForPie > 0) {
        categoryTotals.forEach((key, value) {
          tempCategoryPercentages[key] = (value / totalExpenseForPie) * 100;
        });
      }

      if (mounted) {
        setState(() {
          _filteredExpense = tempFilteredExpense;
          _monthlyIncome = tempIncome;
          _monthlyExpense = tempExpense;
          _categoryPercentages = tempCategoryPercentages;
          _topTransactions = tempTopTx;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat laporan: $e')));
      }
    }
  }

  String _formatCurrency(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

  String _formatDate(String dateString) {
    try { return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(dateString)); }
    catch (e) { return dateString; }
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
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1FAF5), borderRadius: BorderRadius.circular(12)),
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
                                decoration: BoxDecoration(color: isSelected ? (isDark ? Colors.white24 : Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : []),
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
                        color: selectedFilter == 'Kustom' ? AppColors.primaryGreen : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1FAF5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                          Icons.calendar_month,
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
                  decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3))),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle), child: const Icon(Icons.account_balance_wallet, color: AppColors.primaryGreen)),
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
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
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
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10)]),
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
                      ..._categoryPercentages.entries.toList().asMap().entries.map((entry) {
                        int idx = entry.key;
                        var data = entry.value;
                        Color color = _pieColors[idx % _pieColors.length];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildPieLegendItem(color, data.key, '${data.value.toStringAsFixed(1)}%', textColor),
                        );
                      }),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('Tren Pemasukan vs\nPengeluaran Tahun Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3, color: textColor))),
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
                    _buildBarChart(textColor),
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
                  return TransactionItem(
                    title: tx['category'] ?? 'Lainnya',
                    subtitle: '${_formatDate(tx['transaction_date'])} • ${tx['note'] ?? ''}',
                    amount: '- ${_formatCurrency(tx['amount'])}',
                    bgIconColor: Colors.red.withOpacity(0.1),
                    icon: Icons.shopping_bag,
                    amountColor: barRed,
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
    int idx = 0;
    _categoryPercentages.forEach((key, value) {
      sections.add(
          PieChartSectionData(color: _pieColors[idx % _pieColors.length], value: value, title: '', radius: 15)
      );
      idx++;
    });

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('100%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: textColor)),
              const Text('TOTAL', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 65, startDegreeOffset: 270, sections: sections)),
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

  Widget _buildBarChart(Color textColor) {
    double maxVal = 100000;
    for (int i = 0; i < 12; i++) {
      if (_monthlyIncome[i] > maxVal) maxVal = _monthlyIncome[i];
      if (_monthlyExpense[i] > maxVal) maxVal = _monthlyExpense[i];
    }

    int currentMonth = DateTime.now().month;
    List<BarChartGroupData> barGroups = [];

    for (int i = 4; i >= 0; i--) {
      int monthIdx = currentMonth - 1 - i;
      if (monthIdx >= 0 && monthIdx < 12) {
        barGroups.add(
            BarChartGroupData(x: monthIdx, barRods: [
              BarChartRodData(toY: _monthlyIncome[monthIdx], color: AppColors.primaryGreen, width: 8, borderRadius: BorderRadius.circular(2)),
              BarChartRodData(toY: _monthlyExpense[monthIdx], color: barRed, width: 8, borderRadius: BorderRadius.circular(2))
            ])
        );
      }
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(color: Colors.grey, fontSize: 11);
                  List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                  String text = (value >= 0 && value < 12) ? months[value.toInt()] : '';
                  return SideTitleWidget(meta: meta, space: 8, child: Text(text, style: style));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}