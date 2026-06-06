import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/category_helper.dart';

// IMPORT NETWORK HELPER
import '../../../../widgets/network_helper.dart';

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

  List<Map<String, dynamic>> categories = [
    {'name': 'Makanan', 'icon': FontAwesomeIcons.utensils, 'color': Colors.orange},
    {'name': 'Transportasi', 'icon': FontAwesomeIcons.car, 'color': Colors.green},
    {'name': 'Hiburan', 'icon': FontAwesomeIcons.film, 'color': Colors.blue},
    {'name': 'Belanja', 'icon': FontAwesomeIcons.bagShopping, 'color': Colors.purple},
    {'name': 'Baru', 'icon': FontAwesomeIcons.plus, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> customCats = prefs.getStringList('custom_budget_categories') ?? [];

    if (!mounted) return;
    setState(() {
      for (String catName in customCats) {
        if (!categories.any((c) => c['name'] == catName)) {
          String iconId = prefs.getString('custom_budget_icon_$catName') ?? 'star';
          categories.insert(categories.length - 1, {
            'name': catName,
            'icon': CategoryHelper.getCustomIconById(iconId),
            'color': AppColors.primaryGreen,
          });
        }
      }
    });
  }

  void _showAddCategoryDialog() {
    TextEditingController catController = TextEditingController();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> availableIcons = [
      {'id': 'star', 'icon': FontAwesomeIcons.star},
      {'id': 'coffee', 'icon': FontAwesomeIcons.mugHot},
      {'id': 'plane', 'icon': FontAwesomeIcons.plane},
      {'id': 'house', 'icon': FontAwesomeIcons.house},
      {'id': 'hospital', 'icon': FontAwesomeIcons.hospital},
      {'id': 'edu', 'icon': FontAwesomeIcons.graduationCap},
      {'id': 'paw', 'icon': FontAwesomeIcons.paw},
      {'id': 'game', 'icon': FontAwesomeIcons.gamepad},
      {'id': 'shirt', 'icon': FontAwesomeIcons.shirt},
      {'id': 'laptop', 'icon': FontAwesomeIcons.laptop},
      {'id': 'film', 'icon': FontAwesomeIcons.film},
      {'id': 'train', 'icon': FontAwesomeIcons.train},
      {'id': 'building', 'icon': FontAwesomeIcons.building},
      {'id': 'coins', 'icon': FontAwesomeIcons.coins},
      {'id': 'piggy', 'icon': FontAwesomeIcons.piggyBank},
    ];

    String tempIconId = availableIcons[0]['id'];
    dynamic tempIcon = availableIcons[0]['icon'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('Kategori Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: catController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Edukasi',
                          hintStyle: TextStyle(color: Colors.grey),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Pilih Ikon:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: availableIcons.map((item) {
                          bool isSelected = tempIconId == item['id'];
                          return GestureDetector(
                            onTap: () => setStateDialog(() {
                              tempIconId = item['id'];
                              tempIcon = item['icon'];
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.2) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300, width: isSelected ? 2 : 1),
                              ),
                              child: FaIcon(item['icon'], color: isSelected ? AppColors.primaryGreen : Colors.grey, size: 20),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: () async {
                      if (catController.text.trim().isNotEmpty) {
                        String newCatName = catController.text.trim();

                        final prefs = await SharedPreferences.getInstance();
                        List<String> customCats = prefs.getStringList('custom_budget_categories') ?? [];

                        if (!customCats.contains(newCatName)) {
                          customCats.add(newCatName);
                          await prefs.setStringList('custom_budget_categories', customCats);
                          await prefs.setString('custom_budget_icon_$newCatName', tempIconId);
                        }

                        if (!mounted) return;
                        setState(() {
                          if (!categories.any((c) => c['name'] == newCatName)) {
                            categories.insert(categories.length - 1, {
                              'name': newCatName,
                              'icon': tempIcon,
                              'color': AppColors.primaryGreen,
                            });
                          }
                          selectedCategory = newCatName;
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  Future<void> _saveBudget() async {
    if (selectedCategory == null) {
      CustomNotification.show(context, 'Silakan pilih kategori terlebih dahulu', isWarning: true);
      return;
    }

    // INTEGRASI NETWORK HELPER SEBELUM LOADING DIMULAI
    bool isOnline = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!isOnline) return;

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

      bool isNewBudget = true;

      if (existingBudget != null) {
        isNewBudget = false;
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

      if (!mounted) return;
      Navigator.pop(context, true);
      String msg = isNewBudget
          ? 'Anggaran baru berhasil dibuat!'
          : 'Batas anggaran berhasil ditambahkan!';
      CustomNotification.show(context, msg);
    } catch (e) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal menyimpan');
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
                  bool isNew = cat['name'] == 'Baru';

                  return ListTile(
                    onTap: () {
                      if (isNew) {
                        _showAddCategoryDialog();
                      } else {
                        setState(() => selectedCategory = cat['name']);
                      }
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat['color'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(cat['icon'], color: cat['color'] == Colors.green ? AppColors.primaryGreen : cat['color'], size: 20),
                    ),
                    title: Text(cat['name'], style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                    trailing: isNew
                        ? const Icon(Icons.chevron_right, color: Colors.grey)
                        : (isSelected
                        ? const FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.primaryGreen)
                        : const FaIcon(FontAwesomeIcons.circle, color: Colors.grey)),
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