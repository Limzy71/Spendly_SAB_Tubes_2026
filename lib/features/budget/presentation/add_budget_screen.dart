import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/category_helper.dart';
import '../../../../widgets/network_helper.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final supabase = Supabase.instance.client;

  String? selectedCategory;
  bool isAlertEnabled = true;
  bool _isLoading = false;
  final TextEditingController _limitController = TextEditingController(text: "");
  final FocusNode _limitFocusNode = FocusNode();
  final ScrollController _categoryScrollController = ScrollController();

  List<Map<String, dynamic>> categories = [
    {'name': 'Makanan', 'icon': FontAwesomeIcons.utensils, 'color': const Color(0xFFFF9800)},
    {'name': 'Transportasi', 'icon': FontAwesomeIcons.car, 'color': const Color(0xFF2196F3)},
    {'name': 'Belanja', 'icon': FontAwesomeIcons.bagShopping, 'color': const Color(0xFF9C27B0)},
    {'name': 'Tagihan', 'icon': FontAwesomeIcons.fileInvoiceDollar, 'color': const Color(0xFFF44336)},
    {'name': 'Hiburan', 'icon': FontAwesomeIcons.film, 'color': const Color(0xFF009688)},
    {'name': 'Baru', 'icon': FontAwesomeIcons.plus, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  @override
  void dispose() {
    _limitController.dispose();
    _limitFocusNode.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> customCats = prefs.getStringList('custom_transaction_expense_categories_v5') ?? [];
    List<String> hiddenCats = prefs.getStringList('custom_transaction_expense_categories_hidden_v5') ?? [];

    if (!mounted) return;
    setState(() {
      for (String catName in customCats) {
        if (hiddenCats.contains(catName)) continue;
        if (!categories.any((c) => c['name'] == catName)) {
          String iconId = prefs.getString('custom_transaction_expense_icon_v5_$catName') ?? 'invoice';
          categories.insert(categories.length - 1, {
            'name': catName,
            'icon': CategoryHelper.getCustomIconById(iconId),
            'color': CategoryHelper.getColorForIcon(iconId),
          });
        }
      }
    });
  }

  void _confirmDeleteCategory(String catName) {
    if (categories.length <= 2) {
      CustomNotification.show(context, 'Minimal harus ada 1 kategori tersisa!', isWarning: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kategori?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hapus kategori "$catName" dari daftar pilihan? (Ini juga akan menghapusnya dari pilihan transaksi)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

              final prefs = await SharedPreferences.getInstance();
              final hiddenCats = prefs.getStringList('custom_transaction_expense_categories_hidden_v5') ?? [];
              if (!hiddenCats.contains(catName)) {
                hiddenCats.add(catName);
                await prefs.setStringList('custom_transaction_expense_categories_hidden_v5', hiddenCats);
              }

              setState(() {
                categories.removeWhere((c) => c['name'] == catName);
                if (selectedCategory == catName && categories.isNotEmpty) {
                  selectedCategory = categories.first['name'];
                }
              });

              if (mounted) {
                CustomNotification.show(context, 'Kategori "$catName" berhasil dihapus.');
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    TextEditingController catController = TextEditingController();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> availableIcons = [
      {'id': 'utensils', 'icon': FontAwesomeIcons.utensils},
      {'id': 'car', 'icon': FontAwesomeIcons.car},
      {'id': 'bag', 'icon': FontAwesomeIcons.bagShopping},
      {'id': 'invoice', 'icon': FontAwesomeIcons.fileInvoiceDollar},
      {'id': 'film', 'icon': FontAwesomeIcons.film},
      {'id': 'coffee', 'icon': FontAwesomeIcons.mugHot},
      {'id': 'plane', 'icon': FontAwesomeIcons.plane},
      {'id': 'house', 'icon': FontAwesomeIcons.house},
      {'id': 'hospital', 'icon': FontAwesomeIcons.hospital},
      {'id': 'edu', 'icon': FontAwesomeIcons.graduationCap},
      {'id': 'paw', 'icon': FontAwesomeIcons.paw},
      {'id': 'game', 'icon': FontAwesomeIcons.gamepad},
      {'id': 'shirt', 'icon': FontAwesomeIcons.shirt},
      {'id': 'laptop', 'icon': FontAwesomeIcons.laptop},
      {'id': 'train', 'icon': FontAwesomeIcons.train},
      {'id': 'building', 'icon': FontAwesomeIcons.building},
      {'id': 'star', 'icon': FontAwesomeIcons.star},
      {'id': 'music', 'icon': FontAwesomeIcons.music},
      {'id': 'dumbbell', 'icon': FontAwesomeIcons.dumbbell},
      {'id': 'book', 'icon': FontAwesomeIcons.book},
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
                          Color iconColor = CategoryHelper.getColorForIcon(item['id']);

                          return GestureDetector(
                            onTap: () => setStateDialog(() {
                              tempIconId = item['id'];
                              tempIcon = item['icon'];
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? iconColor.withValues(alpha: 0.2) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? iconColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
                              ),
                              child: FaIcon(item['icon'], color: iconColor, size: 20),
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
                        List<String> customCats = prefs.getStringList('custom_transaction_expense_categories_v5') ?? [];

                        if (!customCats.contains(newCatName)) {
                          customCats.add(newCatName);
                          await prefs.setStringList('custom_transaction_expense_categories_v5', customCats);
                          await prefs.setString('custom_transaction_expense_icon_v5_$newCatName', tempIconId);
                        }

                        if (!mounted) return;
                        setState(() {
                          if (!categories.any((c) => c['name'] == newCatName)) {
                            categories.insert(categories.length - 1, {
                              'name': newCatName,
                              'icon': tempIcon,
                              'color': CategoryHelper.getColorForIcon(tempIconId),
                            });
                          }
                          selectedCategory = newCatName;
                        });
                        if (!ctx.mounted) return;
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

    bool isOnline = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!isOnline) return;

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final cleanLimit = _limitController.text.replaceAll('.', '');
      final limitAmount = int.tryParse(cleanLimit) ?? 0;

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
        final int oldLimit = existingBudget['limit_amount'] as int? ?? 0;
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(_limitFocusNode),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Rp', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: IntrinsicWidth(
                            child: TextField(
                              controller: _limitController,
                              focusNode: _limitFocusNode,
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor),
                              keyboardType: TextInputType.number,
                              inputFormatters: [LengthLimitingTextInputFormatter(18)],
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38)
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  String clean = value.replaceAll('.', '');
                                  clean = clean.replaceFirst(RegExp(r'^0+'), '');
                                  if (clean.isEmpty) {
                                    _limitController.value = const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
                                    return;
                                  }
                                  String formatted = NumberFormat.decimalPattern('id').format(int.tryParse(clean) ?? 0);
                                  _limitController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('PILIH KATEGORI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                Text('Tahan untuk hapus', style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: RawScrollbar(
                controller: _categoryScrollController,
                thumbVisibility: true,
                radius: const Radius.circular(8),
                thickness: 4,
                thumbColor: Colors.grey.withValues(alpha: 0.3),
                child: SingleChildScrollView(
                  controller: _categoryScrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 8),
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
                        onLongPress: isNew ? null : () => _confirmDeleteCategory(cat['name']),
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
                    activeTrackColor: AppColors.primaryGreen.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.primaryGreen,
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