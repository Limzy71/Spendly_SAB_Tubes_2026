import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../transaction/presentation/add_transaction_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/transaction_item.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final Color barRed = const Color(0xFFD93F3C);
  String selectedFilter = 'Harian';
  final List<String> filters = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Analisis Laporan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FAF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: filters.map((filter) {
                  bool isSelected = selectedFilter == filter;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade600,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pengeluaran Bulan Ini', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rp 8.420.000', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.arrow_outward, color: Colors.red, size: 16),
                          const SizedBox(width: 2),
                          const Text('12%', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('65% dari anggaran Rp 13.000.000', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kategori Pengeluaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildPieChart(),
                  const SizedBox(height: 24),
                  _buildPieLegendItem(AppColors.primaryGreen, 'Makan & Minum', '40%'),
                  const SizedBox(height: 12),
                  _buildPieLegendItem(const Color(0xFF4F46E5), 'Belanja', '20%'),
                  const SizedBox(height: 12),
                  _buildPieLegendItem(const Color(0xFFFF8FA3), 'Transportasi', '15%'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text('Pemasukan vs\nPengeluaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3)),
                      ),
                      Row(
                        children: [
                          const CircleAvatar(radius: 4, backgroundColor: AppColors.primaryGreen),
                          const SizedBox(width: 4),
                          const Text('Masuk', style: TextStyle(fontSize: 11, color: Colors.black87)),
                          const SizedBox(width: 12),
                          CircleAvatar(radius: 4, backgroundColor: barRed),
                          const SizedBox(width: 4),
                          const Text('Keluar', style: TextStyle(fontSize: 11, color: Colors.black87)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildBarChart(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaksi Terbesar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: () {},
                    child: const Text('Lihat Semua', style: TextStyle(color: AppColors.primaryGreen, fontSize: 13))
                ),
              ],
            ),
            TransactionItem(
              title: 'Belanja Bulanan',
              subtitle: '12 Mei 2024 • Supermarket',
              amount: '- Rp 1.250.000',
              bgIconColor: const Color(0xFFF3E5F5),
              icon: Icons.shopping_bag,
              amountColor: barRed,
            ),
            TransactionItem(
              title: 'Gaji Bulanan',
              subtitle: '25 April 2024 • PT Solusi Digital',
              amount: '+ Rp 15.000.000',
              bgIconColor: const Color(0xFFF1FAF5),
              icon: Icons.wallet,
              amountColor: AppColors.primaryGreen,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('75%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
              Text('TOTAL', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 65,
              startDegreeOffset: 270,
              sections: [
                PieChartSectionData(color: AppColors.primaryGreen, value: 40, title: '', radius: 15),
                PieChartSectionData(color: const Color(0xFF4F46E5), value: 20, title: '', radius: 15),
                PieChartSectionData(color: const Color(0xFFFF8FA3), value: 15, title: '', radius: 15),
                PieChartSectionData(color: Colors.grey.shade200, value: 25, title: '', radius: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegendItem(Color color, String title, String percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 6, backgroundColor: color),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          ],
        ),
        Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 20,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(color: Colors.grey, fontSize: 11);
                  String text;
                  switch (value.toInt()) {
                    case 0: text = 'Jan'; break;
                    case 1: text = 'Feb'; break;
                    case 2: text = 'Mar'; break;
                    case 3: text = 'Apr'; break;
                    case 4: text = 'Mei'; break;
                    default: text = ''; break;
                  }
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
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 12, color: AppColors.primaryGreen, width: 8, borderRadius: BorderRadius.circular(2)), BarChartRodData(toY: 8, color: barRed, width: 8, borderRadius: BorderRadius.circular(2))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 16, color: AppColors.primaryGreen, width: 8, borderRadius: BorderRadius.circular(2)), BarChartRodData(toY: 10, color: barRed, width: 8, borderRadius: BorderRadius.circular(2))]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: AppColors.primaryGreen, width: 8, borderRadius: BorderRadius.circular(2)), BarChartRodData(toY: 6, color: barRed, width: 8, borderRadius: BorderRadius.circular(2))]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 18, color: AppColors.primaryGreen, width: 8, borderRadius: BorderRadius.circular(2)), BarChartRodData(toY: 15, color: barRed, width: 8, borderRadius: BorderRadius.circular(2))]),
            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 15, color: AppColors.primaryGreen, width: 8, borderRadius: BorderRadius.circular(2)), BarChartRodData(toY: 11, color: barRed, width: 8, borderRadius: BorderRadius.circular(2))]),
          ],
        ),
      ),
    );
  }
}