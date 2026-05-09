import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final Color primaryGreen = const Color(0xFF05A660);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  String? selectedFromAccount;
  String? selectedToAccount;
  final List<String> accountOptions = ['Uang Tunai', 'BCA', 'GoPay', 'OVO'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
            const SizedBox(width: 10),
            Text(
              'Spendly',
              style: TextStyle(
                color: primaryGreen,
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

      // --- KONTEN UTAMA ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU TOTAL SALDO (Warna Hijau Solid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Saldo',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rp 42.850.000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('2.4%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. DAFTAR DOMPET
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daftar Dompet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.add_circle_outline, color: primaryGreen, size: 18),
                  label: Text('Tambah', style: TextStyle(color: primaryGreen)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Item-item dompet
            _buildWalletItem(icon: Icons.money, iconColor: primaryGreen, title: 'Uang Tunai', subtitle: 'Fisik', amount: 'Rp 1.250.000'),
            _buildWalletItem(icon: Icons.account_balance, iconColor: Colors.indigo, title: 'BCA', subtitle: 'Bank Transfer', amount: 'Rp 35.600.000'),
            _buildWalletItem(icon: Icons.account_balance_wallet, iconColor: Colors.blue, title: 'GoPay', subtitle: 'E-Wallet', amount: 'Rp 4.500.000'),
            _buildWalletItem(icon: Icons.account_balance_wallet, iconColor: Colors.purple, title: 'OVO', subtitle: 'E-Wallet', amount: 'Rp 1.500.000'),

            const SizedBox(height: 24),
            const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 24),

            // 3. TRANSFER ANTAR AKUN
            Row(
              children: [
                Icon(Icons.swap_horiz, color: primaryGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transfer Antar Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Pindahkan saldo antar dompet Anda.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FAF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryGreen, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ini adalah transfer internal, tidak akan dicatat sebagai pengeluaran.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Transfer
            _buildFormLabel('Dari Akun'),
            _buildDropdown(
              value: selectedFromAccount,
              hint: 'Pilih Akun Asal',
              onChanged: (val) => setState(() => selectedFromAccount = val),
            ),
            const SizedBox(height: 16),

            _buildFormLabel('Ke Akun'),
            _buildDropdown(
              value: selectedToAccount,
              hint: 'Pilih Akun Tujuan',
              onChanged: (val) => setState(() => selectedToAccount = val),
            ),
            const SizedBox(height: 16),

            _buildFormLabel('Nominal'),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                // Menggunakan prefixIcon agar 'Rp' selalu tampil permanen
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Text(
                      'Rp',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '0', // Teks placeholder "0"
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen)),
              ),
            ),
            const SizedBox(height: 16),

            _buildFormLabel('Catatan'),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tambah keterangan (opsional)...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen)),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Konfirmasi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                label: const Text(
                  'Konfirmasi Transfer',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

  // --- WIDGET HELPER ---

  // Helper untuk List Dompet
  Widget _buildWalletItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Helper untuk Label Form
  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13)),
    );
  }

  // Helper untuk Dropdown Transfer
  Widget _buildDropdown({required String? value, required String hint, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen)),
      ),
      items: accountOptions.map((String account) {
        return DropdownMenuItem<String>(
          value: account,
          child: Text(account),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}