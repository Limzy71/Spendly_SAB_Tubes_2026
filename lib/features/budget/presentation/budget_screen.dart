import 'package:flutter/material.dart';
import 'add_budget_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SubAppBar(title: 'Rincian Anggaran'), // Menggunakan SubAppBar pelindung
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anggaran Saya',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pantau pengeluaran bulanan Anda agar tetap terkendali.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Peringatan Anggaran
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.withOpacity(0.1) : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade100),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peringatan Anggaran',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Anggaran Makanan mencapai 80%! Sebaiknya kurangi makan di luar minggu ini.',
                          style: TextStyle(color: Colors.red, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progress Bar Total
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Terpakai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                      const Text('Mei 2024', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rp 4.250.000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('/ Rp 6.000.000', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.71,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('71% Terpakai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      Text('Sisa Rp 1.750.000', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text('Kategori Anggaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),

            _buildBudgetItem(cardColor, textColor, isDark, Icons.restaurant, Colors.redAccent, 'Makanan', 'Rp 1.600k', 'Rp 2.000k', 0.80),
            _buildBudgetItem(cardColor, textColor, isDark, Icons.directions_car_outlined, AppColors.primaryGreen, 'Transportasi', 'Rp 150k', 'Rp 500k', 0.30),
            _buildBudgetItem(cardColor, textColor, isDark, Icons.shopping_bag_outlined, Colors.purple, 'Belanja', 'Rp 950k', 'Rp 1.000k', 0.95),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBudgetScreen()));
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
    );
  }

  Widget _buildBudgetItem(Color cardColor, Color textColor, bool isDark, IconData icon, Color iconColor, String title, String spent, String limit, double percentage) {
    final bool isWarning = percentage >= 0.75;
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
              value: percentage,
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