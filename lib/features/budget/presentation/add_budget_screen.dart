import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({Key? key}) : super(key: key);

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final supabase = Supabase.instance.client;

  String? selectedCategory;
  bool isAlertEnabled = true;
  bool _isLoading = false;
  final TextEditingController _limitController = TextEditingController(text: "2.000.000");

  final List<Map<String, dynamic>> categories = [
    {'name': 'Makanan', 'icon': FontAwesomeIcons.utensils, 'color': Colors.orange},
    {'name': 'Transportasi', 'icon': FontAwesomeIcons.car, 'color': Colors.green},
    {'name': 'Hiburan', 'icon': FontAwesomeIcons.film, 'color': Colors.blue},
    {'name': 'Belanja', 'icon': FontAwesomeIcons.bagShopping, 'color': Colors.purple},
  ];

  Future<void> _saveBudget() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih kategori terlebih dahulu')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final cleanLimit = _limitController.text.replaceAll('.', '');
      final limitAmount = int.parse(cleanLimit);

      final now = DateTime.now();
      final periodMonth = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];

      final List<dynamic> existingBudgets = await supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('category', selectedCategory!)
          .eq('period_month', periodMonth);

      final Map<String, dynamic>? existingBudget =
      existingBudgets.isEmpty ? null : existingBudgets.first;

      if (existingBudget != null) {
        final int oldLimit = existingBudget['limit_amount'] as int;
        final int finalLimit = oldLimit + limitAmount;

        await supabase
            .from('budgets')
            .update({'limit_amount': finalLimit})
            .eq('id', existingBudget['id'])
            .eq('user_id', userId);
      } else {
        await supabase.from('budgets').insert({
          'category': selectedCategory,
          'limit_amount': limitAmount,
          'period_month': periodMonth,
          'user_id': userId,
        });
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anggaran berhasil diperbarui!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
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
      appBar: const SubAppBar(title: 'Tambah Anggaran Baru'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BATAS ANGGARAN BULANAN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Text('Rp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _limitController,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38)
                      ),
                      onChanged: (value) {
                        String digits = value.replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) {
                          _limitController.text = '';
                          return;
                        }
                        String formatted = '';
                        int count = 0;
                        for (int i = digits.length - 1; i >= 0; i--) {
                          if (count != 0 && count % 3 == 0) formatted = '.$formatted';
                          formatted = digits[i] + formatted;
                          count++;
                        }
                        _limitController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('PILIH KATEGORI',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: categories.map((cat) {
                  bool isSelected = selectedCategory == cat['name'];
                  return ListTile(
                    onTap: () => setState(() => selectedCategory = cat['name']),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat['color'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(cat['icon'], color: cat['color'] == Colors.green ? AppColors.primaryGreen : cat['color'], size: 20),
                    ),
                    title: Text(cat['name'], style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                    trailing: isSelected
                        ? const FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.primaryGreen)
                        : const FaIcon(FontAwesomeIcons.circle, color: Colors.grey),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.bell, color: AppColors.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aktifkan Peringatan', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        const Text('Beri tahu jika sudah mencapai 80%', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch(
                    value: isAlertEnabled,
                    onChanged: (val) => setState(() => isAlertEnabled = val),
                    activeColor: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buat Anggaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}