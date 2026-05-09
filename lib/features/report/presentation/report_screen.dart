import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedFilter = 'Bulanan';
  final List<String> filters = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // HEADER (APP BAR)
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leadingWidth: 60,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: CircleAvatar(
            // Menggunakan gambar placeholder sementara dari internet
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
        ),
        title: Text(
          'Spendly',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: Colors.black54)
          ),
          const SizedBox(width: 8),
        ],
      ),

      // TOMBOL TAMBAH MELAYANG (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Tombol tambah ditekan!");
        },
        backgroundColor: const Color(0xFF05A660),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),

      // KONTEN UTAMA
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Analisis Laporan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),

            // FILTER WAKTU (Chips)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: filters.map((filter) {
                bool isSelected = selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) => setState(() => selectedFilter = filter),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // KARTU RINGKASAN PENGELUARAN
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pengeluaran Bulan Ini', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rp 8.420.000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Row(
                        children: const [
                          Icon(Icons.trending_up, color: Colors.red, size: 16),
                          Text(' 12%', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('65% dari anggaran Rp 13.000.000', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BAGIAN GRAFIK LINGKARAN (PIE CHART)
            const Text('Kategori Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPieChart(),
            const SizedBox(height: 24),

            // BAGIAN GRAFIK BATANG (BAR CHART)
            const Text('Pemasukan vs Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildBarChart(),
            const SizedBox(height: 24),

            // BAGIAN TRANSAKSI TERBESAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaksi Terbesar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: () {},
                    child: Text('Lihat Semua', style: TextStyle(color: Theme.of(context).colorScheme.primary))
                ),
              ],
            ),

            // LIST TRANSAKSI
            _buildTopTransactionItem('Belanja Bulanan', '12 Mei 2024 • Supermarket', '- Rp 1.250.000', Colors.orange, Icons.shopping_bag),
            _buildTopTransactionItem('Gaji Bulanan', '25 April 2024 • PT Solusi Digital', '+ Rp 15.000.000', Colors.green, Icons.money),

            // Jarak agar list paling bawah tidak tertutup tombol FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membuat Grafik Lingkaran
  Widget _buildPieChart() {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text('100%\nTOTAL', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60, // Lubang di tengah
              sections: [
                PieChartSectionData(color: Colors.green, value: 40, title: '40%', radius: 20, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                PieChartSectionData(color: Colors.blue, value: 20, title: '20%', radius: 20, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                PieChartSectionData(color: Colors.orange, value: 15, title: '15%', radius: 20, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membuat Grafik Batang
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
                  const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
                  String text;
                  switch (value.toInt()) {
                    case 0: text = 'Jan'; break;
                    case 1: text = 'Feb'; break;
                    case 2: text = 'Mar'; break;
                    default: text = ''; break;
                  }
                  return SideTitleWidget(meta: meta, space: 4, child: Text(text, style: style));
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
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 15, color: Colors.green, width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 10, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 18, color: Colors.green, width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 12, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: Colors.green, width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 16, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4))]),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membuat Item Transaksi
  Widget _buildTopTransactionItem(String title, String subtitle, String amount, Color iconColor, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
              amount,
              style: TextStyle(
                  color: amount.contains('+') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14
              )
          ),
        ],
      ),
    );
  }
}