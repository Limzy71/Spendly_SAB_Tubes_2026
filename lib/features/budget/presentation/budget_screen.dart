import 'package:flutter/material.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Spendly',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Judul Halaman ---
            const Text(
              'Anggaran Saya',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
            const SizedBox(height: 20),

            // --- Peringatan Anggaran (Alert Box) ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peringatan Anggaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Anggaran Makanan mencapai 80%! Sebaiknya kurangi makan di luar minggu ini.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Ringkasan Total Terpakai ---
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Terpakai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Mei 2024', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Rp 4.250.000',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                // PERBAIKAN DI SINI: Menggunakan widget Padding untuk memberi jarak bawah
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ Rp 6.000.000',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.71, // 71% terpakai
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('71% Terpakai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Sisa Rp 1.750.000', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 30),

            // --- List Kategori Anggaran ---
            const Text(
              'Kategori Anggaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildBudgetItem(
              icon: Icons.restaurant,
              iconColor: Colors.orange,
              title: 'Makanan',
              spent: 'Rp 1.600.000',
              limit: 'Rp 2.000.000',
              percentage: 0.80,
            ),
            _buildBudgetItem(
              icon: Icons.directions_car,
              iconColor: Colors.green,
              title: 'Transportasi',
              spent: 'Rp 150.000',
              limit: 'Rp 500.000',
              percentage: 0.30,
            ),
            _buildBudgetItem(
              icon: Icons.movie,
              iconColor: Colors.blue,
              title: 'Hiburan',
              spent: 'Rp 300.000',
              limit: 'Rp 750.000',
              percentage: 0.40,
            ),
            _buildBudgetItem(
              icon: Icons.shopping_bag,
              iconColor: Colors.purple,
              title: 'Belanja',
              spent: 'Rp 950.000',
              limit: 'Rp 1.000.000',
              percentage: 0.95,
            ),
            const SizedBox(height: 20),

            // --- Tombol Tambah Anggaran Baru ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Tambah Anggaran Baru',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk merender setiap item Kategori Anggaran
  Widget _buildBudgetItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String spent,
    required String limit,
    required double percentage,
  }) {
    // Logika warna: Merah jika >= 75%, selain itu Hijau
    final bool isWarning = percentage >= 0.75;
    final Color progressColor = isWarning ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('$spent / $limit', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Terpakai: $spent', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              Text('Batas: $limit', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}