import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({Key? key}) : super(key: key);

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  bool _isLoading = false;

  String selectedIconName = 'wallet';

  final List<Map<String, dynamic>> availableIcons = [
    {'id': 'money', 'icon': Icons.money, 'label': 'Tunai'},
    {'id': 'bank', 'icon': Icons.account_balance, 'label': 'Bank'},
    {'id': 'wallet', 'icon': Icons.account_balance_wallet, 'label': 'E-Wallet'},
    {'id': 'card', 'icon': Icons.credit_card, 'label': 'Kartu'},
    {'id': 'savings', 'icon': Icons.savings, 'label': 'Tabungan'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dompet wajib diisi!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      int initialBalance = 0;
      if (_balanceController.text.isNotEmpty) {
        final cleanAmount = _balanceController.text.replaceAll('.', '');
        initialBalance = int.parse(cleanAmount);
      }

      await supabase.from('wallets').insert({
        'name': _nameController.text.trim(),
        'balance': initialBalance,
        'icon_name': selectedIconName,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dompet berhasil ditambahkan!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SubAppBar(title: 'Tambah Dompet Baru'),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NAMA DOMPET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: TextField(
                controller: _nameController,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                decoration: InputDecoration(hintText: 'Cth: GoPay, BCA, Tabungan', hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal), border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 24),

            const Text('SALDO SAAT INI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(
                children: [
                  const Text('Rp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _balanceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                      decoration: InputDecoration(border: InputBorder.none, hintText: "0", hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38)),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          String clean = value.replaceAll('.', '');
                          String formatted = NumberFormat.decimalPattern('id').format(int.parse(clean));
                          _balanceController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('PILIH IKON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: availableIcons.map((item) {
                bool isSelected = selectedIconName == item['id'];
                return GestureDetector(
                  onTap: () => setState(() => selectedIconName = item['id']),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryGreen.withOpacity(0.2) : cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? AppColors.primaryGreen : Colors.transparent, width: 2),
                          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Icon(item['icon'], color: isSelected ? AppColors.primaryGreen : Colors.grey, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(item['label'], style: TextStyle(fontSize: 11, color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveWallet,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Dompet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}