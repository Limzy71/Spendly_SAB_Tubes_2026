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
  int _monthlyIncome = 0;
  int _totalWalletBalance = 0;
  final TextEditingController _limitController = TextEditingController(text: "");
  final FocusNode _limitFocusNode = FocusNode();
  final ScrollController _categoryScrollController = ScrollController();

  List<Map<String, dynamic>> categories = [
    {'name': 'Total Uang', 'icon': FontAwesomeIcons.coins, 'color': const Color(0xFFFFB300)},
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
    selectedCategory = categories.first['name'];
    _loadCustomCategories();
    _loadCashflowData();
  }

  Future<void> _loadCashflowData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1).toIso8601String();
      final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

      final incomeRes = await supabase
          .from('transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('is_expense', false)
          .neq('category', 'Transfer')
          .gte('transaction_date', firstDay)
          .lte('transaction_date', lastDay);

      int totalInc = 0;
      for (var tx in incomeRes) {
        totalInc += int.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
      }

      final walletRes = await supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', userId);

      int totalBal = 0;
      for (var w in walletRes) {
        totalBal += int.tryParse(w['balance']?.toString() ?? '0') ?? 0;
      }

      if (mounted) {
        setState(() {
          _monthlyIncome = totalInc;
          _totalWalletBalance = totalBal;
          if (_limitController.text.isEmpty && totalInc > 0) {
            _limitController.text = NumberFormat.decimalPattern('id').format(totalInc);
          }
        });
      }
    } catch (_) {}
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
    final catController = TextEditingController();
    final catFocusNode = FocusNode();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    final List<Map<String, dynamic>> availableIcons = [
      {'id': 'utensils', 'icon': FontAwesomeIcons.utensils},
      {'id': 'coffee', 'icon': FontAwesomeIcons.mugSaucer},
      {'id': 'car', 'icon': FontAwesomeIcons.car},
      {'id': 'motorcycle', 'icon': FontAwesomeIcons.motorcycle},
      {'id': 'gas_pump', 'icon': FontAwesomeIcons.gasPump},
      {'id': 'bag_shopping', 'icon': FontAwesomeIcons.bagShopping},
      {'id': 'cart_shopping', 'icon': FontAwesomeIcons.cartShopping},
      {'id': 'shirt', 'icon': FontAwesomeIcons.shirt},
      {'id': 'receipt', 'icon': FontAwesomeIcons.receipt},
      {'id': 'bolt', 'icon': FontAwesomeIcons.bolt},
      {'id': 'droplet', 'icon': FontAwesomeIcons.droplet},
      {'id': 'wifi', 'icon': FontAwesomeIcons.wifi},
      {'id': 'mobile', 'icon': FontAwesomeIcons.mobileScreen},
      {'id': 'house', 'icon': FontAwesomeIcons.house},
      {'id': 'key', 'icon': FontAwesomeIcons.key},
      {'id': 'hospital', 'icon': FontAwesomeIcons.hospital},
      {'id': 'graduation_cap', 'icon': FontAwesomeIcons.graduationCap},
      {'id': 'book', 'icon': FontAwesomeIcons.book},
      {'id': 'film', 'icon': FontAwesomeIcons.film},
      {'id': 'gamepad', 'icon': FontAwesomeIcons.gamepad},
      {'id': 'music', 'icon': FontAwesomeIcons.music},
      {'id': 'plane', 'icon': FontAwesomeIcons.plane},
      {'id': 'hotel', 'icon': FontAwesomeIcons.hotel},
      {'id': 'paw', 'icon': FontAwesomeIcons.paw},
      {'id': 'baby', 'icon': FontAwesomeIcons.baby},
      {'id': 'heart', 'icon': FontAwesomeIcons.heart},
      {'id': 'hands_praying', 'icon': FontAwesomeIcons.handsPraying},
      {'id': 'smoking', 'icon': FontAwesomeIcons.smoking},
      {'id': 'scissors', 'icon': FontAwesomeIcons.scissors},
      {'id': 'dumbbell', 'icon': FontAwesomeIcons.dumbbell},
      {'id': 'wrench', 'icon': FontAwesomeIcons.wrench},
      {'id': 'laptop', 'icon': FontAwesomeIcons.laptop},
      {'id': 'shield', 'icon': FontAwesomeIcons.shieldHalved},
      {'id': 'credit_card', 'icon': FontAwesomeIcons.creditCard},
      {'id': 'train', 'icon': FontAwesomeIcons.train},
      {'id': 'building', 'icon': FontAwesomeIcons.building},
      {'id': 'star', 'icon': FontAwesomeIcons.star},
    ];

    String tempIconId = availableIcons[0]['id'];
    dynamic tempIcon = availableIcons[0]['icon'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            final isKeyboardOpen = bottomInset > 0;
            final double sheetHeight = isKeyboardOpen ? 0.85 : 0.58;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SafeArea(
                top: false,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * sheetHeight,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tambah Kategori Anggaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: textColor),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: catController,
                        focusNode: catFocusNode,
                        maxLength: 16,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Edukasi / Kursus',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          counterText: '',
                        ),
                        onTap: () {
                          if (!catFocusNode.hasFocus) {
                            catFocusNode.requestFocus();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Pilih Ikon:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${availableIcons.length} pilihan)',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: availableIcons.length,
                          itemBuilder: (context, index) {
                            final item = availableIcons[index];
                            final isSelected = tempIconId == item['id'];
                            final Color iconColor = CategoryHelper.getColorForIcon(item['id']);

                            return GestureDetector(
                              onTap: () => setStateSheet(() {
                                tempIconId = item['id'];
                                tempIcon = item['icon'];
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? iconColor.withValues(alpha: 0.22)
                                      : iconColor.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? iconColor : iconColor.withValues(alpha: 0.25),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: FaIcon(
                                    item['icon'],
                                    color: iconColor,
                                    size: isSelected ? 20 : 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
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
                          child: const Text('Simpan Kategori', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  if (_monthlyIncome > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.primaryGreen),
                        label: Text(
                          'Pemasukan: ${NumberFormat.compactSimpleCurrency(locale: 'id_ID').format(_monthlyIncome)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
                        ),
                        backgroundColor: isDark ? AppColors.primaryGreen.withValues(alpha: 0.15) : const Color(0xFFE8F5E9),
                        side: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          _limitController.text = NumberFormat.decimalPattern('id').format(_monthlyIncome);
                        },
                      ),
                    ),
                  if (_totalWalletBalance > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFF2196F3)),
                        label: Text(
                          'Saldo: ${NumberFormat.compactSimpleCurrency(locale: 'id_ID').format(_totalWalletBalance)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2196F3)),
                        ),
                        backgroundColor: isDark ? const Color(0xFF2196F3).withValues(alpha: 0.15) : const Color(0xFFE3F2FD),
                        side: BorderSide(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          _limitController.text = NumberFormat.decimalPattern('id').format(_totalWalletBalance);
                        },
                      ),
                    ),
                  ...[500000, 1000000, 2000000, 5000000].map((amt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          NumberFormat.compactSimpleCurrency(locale: 'id_ID').format(amt),
                          style: TextStyle(fontSize: 11, color: textColor),
                        ),
                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          _limitController.text = NumberFormat.decimalPattern('id').format(amt);
                        },
                      ),
                    );
                  }),
                ],
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