import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/sub_app_bar.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({Key? key}) : super(key: key);

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  String? selectedCategory;
  bool isAlertEnabled = true;
  final TextEditingController _limitController = TextEditingController(text: "2.000.000");

  final List<Map<String, dynamic>> categories = [
    {'name': 'Makanan', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Transportasi', 'icon': Icons.directions_car, 'color': Colors.green},
    {'name': 'Hiburan', 'icon': Icons.movie, 'color': Colors.blue},
    {'name': 'Belanja', 'icon': Icons.shopping_bag, 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('Rp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _limitController,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
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
                          if (count != 0 && count % 3 == 0) {
                            formatted = '.$formatted';
                          }
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: categories.map((cat) {
                  bool isSelected = selectedCategory == cat['name'];
                  return ListTile(
                    onTap: () => setState(() => selectedCategory = cat['name']),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(cat['icon'], color: cat['color'] == Colors.green ? AppColors.primaryGreen : cat['color']),
                    ),
                    title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, color: AppColors.primaryGreen),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aktifkan Peringatan', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Beri tahu jika sudah mencapai 80%', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Buat Anggaran',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}