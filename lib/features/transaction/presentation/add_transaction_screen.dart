import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/category_helper.dart';
import '../../../../widgets/network_helper.dart';
import '../../wallet/presentation/add_wallet_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final supabase = Supabase.instance.client;

  static const String _expenseCategoryListKey = 'custom_transaction_expense_categories';
  static const String _incomeCategoryListKey = 'custom_transaction_income_categories';
  static const String _expenseCategoryHiddenKey = 'custom_transaction_expense_categories_hidden';
  static const String _incomeCategoryHiddenKey = 'custom_transaction_income_categories_hidden';
  static const String _expenseCategoryIconPrefix = 'custom_transaction_expense_icon_';
  static const String _incomeCategoryIconPrefix = 'custom_transaction_income_icon_';
  static const String _legacyMigrationKey = 'custom_transaction_categories_migrated_v1';

  bool isExpense = true;
  String selectedCategory = "Makanan";
  int? selectedWalletId;
  DateTime selectedDate = DateTime.now();
  File? _imageFile;
  bool _isLoading = false;

  List<Map<String, dynamic>> _wallets = [];
  bool _walletsLoaded = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FocusNode _amountFocusNode = FocusNode();

  List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Makanan', 'icon': FontAwesomeIcons.utensils, 'color': Colors.redAccent},
    {'name': 'Transportasi', 'icon': FontAwesomeIcons.car, 'color': Colors.blue},
    {'name': 'Belanja', 'icon': FontAwesomeIcons.bagShopping, 'color': Colors.purple},
    {'name': 'Tagihan', 'icon': FontAwesomeIcons.fileInvoiceDollar, 'color': Colors.orange},
    {'name': 'Hiburan', 'icon': FontAwesomeIcons.film, 'color': Colors.teal},
    {'name': 'Baru', 'icon': FontAwesomeIcons.plus, 'color': Colors.grey},
  ];

  List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Gaji', 'icon': FontAwesomeIcons.moneyBillWave, 'color': AppColors.primaryGreen},
    {'name': 'Bonus', 'icon': FontAwesomeIcons.gift, 'color': Colors.amber.shade600},
    {'name': 'Investasi', 'icon': FontAwesomeIcons.arrowTrendUp, 'color': Colors.blueAccent},
    {'name': 'Dana', 'icon': FontAwesomeIcons.wallet, 'color': Colors.indigo},
    {'name': 'BCA', 'icon': FontAwesomeIcons.buildingColumns, 'color': Colors.teal},
    {'name': 'Baru', 'icon': FontAwesomeIcons.plus, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _fetchWallets();
    _loadCustomCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  String _categoryListKey(bool expense) {
    return expense ? _expenseCategoryListKey : _incomeCategoryListKey;
  }

  String _hiddenCategoryListKey(bool expense) {
    return expense ? _expenseCategoryHiddenKey : _incomeCategoryHiddenKey;
  }

  String _categoryIconKey(bool expense, String categoryName) {
    return '${expense ? _expenseCategoryIconPrefix : _incomeCategoryIconPrefix}$categoryName';
  }

  List<Map<String, dynamic>> _customIconsForType(bool expense) {
    if (expense) {
      return [
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
    }

    return [
      {'id': 'bank', 'icon': FontAwesomeIcons.buildingColumns},
      {'id': 'wallet', 'icon': FontAwesomeIcons.wallet},
      {'id': 'coins', 'icon': FontAwesomeIcons.coins},
      {'id': 'piggy', 'icon': FontAwesomeIcons.piggyBank},
      {'id': 'salary', 'icon': FontAwesomeIcons.moneyBillWave},
      {'id': 'chart', 'icon': FontAwesomeIcons.chartLine},
      {'id': 'briefcase', 'icon': FontAwesomeIcons.briefcase},
      {'id': 'giftbox', 'icon': FontAwesomeIcons.gift},
      {'id': 'arrow', 'icon': FontAwesomeIcons.arrowTrendUp},
      {'id': 'safe', 'icon': FontAwesomeIcons.boxArchive},
    ];
  }

  String _defaultIconIdForType(bool expense) {
    return expense ? 'invoice' : 'bank';
  }

  Future<void> _migrateLegacyCategoriesIfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool(_legacyMigrationKey) == true) {
      return;
    }

    final legacyCategories = prefs.getStringList('custom_budget_categories') ?? [];
    if (legacyCategories.isEmpty) {
      await prefs.setBool(_legacyMigrationKey, true);
      return;
    }

    Future<void> migrateForType({required bool expense}) async {
      final listKey = _categoryListKey(expense);
      final iconPrefix = expense ? _expenseCategoryIconPrefix : _incomeCategoryIconPrefix;
      final currentCategories = prefs.getStringList(listKey) ?? [];
      final mergedCategories = [...currentCategories];

      for (final catName in legacyCategories) {
        if (!mergedCategories.contains(catName)) {
          mergedCategories.add(catName);
        }

        final legacyIconId = prefs.getString('custom_budget_icon_$catName') ?? _defaultIconIdForType(expense);
        final newIconKey = '$iconPrefix$catName';
        if (!prefs.containsKey(newIconKey)) {
          await prefs.setString(newIconKey, legacyIconId);
        }
      }

      await prefs.setStringList(listKey, mergedCategories);
    }

    await migrateForType(expense: true);
    await migrateForType(expense: false);
    await prefs.setBool(_legacyMigrationKey, true);
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyCategoriesIfNeeded(prefs);

    setState(() {
      void loadCustomCategoriesForType({required bool expense, required List<Map<String, dynamic>> targetList}) {
        final customCats = prefs.getStringList(_categoryListKey(expense)) ?? [];
        final hiddenCats = prefs.getStringList(_hiddenCategoryListKey(expense)) ?? [];

        for (String catName in customCats) {
          if (hiddenCats.contains(catName)) {
            continue;
          }

          if (targetList.any((c) => c['name'] == catName)) {
            continue;
          }

          final iconId = prefs.getString(_categoryIconKey(expense, catName)) ?? _defaultIconIdForType(expense);
          final newCat = {
            'name': catName,
            'icon': CategoryHelper.getCustomIconById(iconId),
            'color': expense ? Colors.redAccent : AppColors.primaryGreen,
          };

          targetList.insert(targetList.length - 1, newCat);
        }
      }

      loadCustomCategoriesForType(expense: true, targetList: expenseCategories);
      loadCustomCategoriesForType(expense: false, targetList: incomeCategories);
    });
  }

  void _confirmDeleteCategory(String catName) {
    List<Map<String, dynamic>> currentList = isExpense ? expenseCategories : incomeCategories;

    if (currentList.length <= 2) {
      CustomNotification.show(context, 'Minimal harus ada 1 kategori tersisa!', isWarning: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kategori?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hapus kategori "$catName" dari daftar pilihan? Transaksi yang sudah ada tetap memakai nama dan icon lamanya.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

              final prefs = await SharedPreferences.getInstance();
              final hiddenKey = _hiddenCategoryListKey(isExpense);
              final hiddenCats = prefs.getStringList(hiddenKey) ?? [];
              if (!hiddenCats.contains(catName)) {
                hiddenCats.add(catName);
                await prefs.setStringList(hiddenKey, hiddenCats);
              }

              setState(() {
                currentList.removeWhere((c) => c['name'] == catName);
                if (selectedCategory == catName && currentList.isNotEmpty) {
                  selectedCategory = currentList.first['name'];
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

  Future<void> _fetchWallets() async {
    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!hasConnection) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final walletResponse = await supabase.from('wallets').select().eq('user_id', userId).order('id');
      final txResponse = await supabase.from('transactions').select().eq('user_id', userId);

      List<Map<String, dynamic>> processedWallets = [];

      for (var w in walletResponse) {
        int wId = w['id'] as int;
        String wName = w['name'].toString();
        int currentBal = w['balance'] as int;

        for (var tx in txResponse) {
          if (tx['wallet_id'] == wId) {
            if (tx['is_expense'] == true) {
              currentBal -= tx['amount'] as int;
            } else {
              currentBal += tx['amount'] as int;
            }
          }
        }

        processedWallets.add({
          'id': wId,
          'name': wName,
          'balance': currentBal,
        });
      }

      if (mounted) {
        setState(() {
          _wallets = processedWallets;
          _walletsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _walletsLoaded = true);
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Center(child: Text('Pilih Sumber Gambar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.primaryGreen),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    TextEditingController catController = TextEditingController();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> availableIcons = _customIconsForType(isExpense);

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
                          hintText: 'Contoh: Hadiah',
                          hintStyle: TextStyle(color: Colors.grey),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Pilih Ikon:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
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
                        final listKey = _categoryListKey(isExpense);
                        final hiddenKey = _hiddenCategoryListKey(isExpense);
                        final iconKey = _categoryIconKey(isExpense, newCatName);
                        List<String> customCats = prefs.getStringList(listKey) ?? [];
                        List<String> hiddenCats = prefs.getStringList(hiddenKey) ?? [];

                        if (!customCats.contains(newCatName)) {
                          customCats.add(newCatName);
                          await prefs.setStringList(listKey, customCats);
                          await prefs.setString(iconKey, tempIconId);
                        }

                        if (hiddenCats.contains(newCatName)) {
                          hiddenCats.remove(newCatName);
                          await prefs.setStringList(hiddenKey, hiddenCats);
                        }

                        setState(() {
                          var newCategory = {
                            'name': newCatName,
                            'icon': tempIcon,
                            'color': isExpense ? Colors.redAccent : AppColors.primaryGreen,
                          };

                          if (isExpense) {
                            if (!expenseCategories.any((c) => c['name'] == newCatName)) {
                              expenseCategories.insert(expenseCategories.length - 1, newCategory);
                            }
                          } else {
                            if (!incomeCategories.any((c) => c['name'] == newCatName)) {
                              incomeCategories.insert(incomeCategories.length - 1, newCategory);
                            }
                          }
                          selectedCategory = newCatName;
                        });
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime lastSelectableDate = DateTime(today.year, today.month, today.day);
    final DateTime initialDate = selectedDate.isAfter(lastSelectableDate) ? lastSelectableDate : selectedDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: lastSelectableDate,
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen)), child: child!);
      },
    );
    if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
  }

  void _showWalletSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Pilih Dompet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (_wallets.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Belum ada dompet', style: TextStyle(color: Colors.grey)),
                )
              else
                ..._wallets.map((wallet) {
                  return InkWell(
                    onTap: () {
                      setState(() => selectedWalletId = wallet['id']);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(wallet['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          Text(_formatCurrency(wallet['balance']), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || _amountController.text == '0') {
      CustomNotification.show(context, 'Nominal wajib diisi', isWarning: true);
      return;
    }

    if (selectedWalletId == null) {
      CustomNotification.show(context, 'Pilih dompet terlebih dahulu', isWarning: true);
      return;
    }

    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!hasConnection) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final cleanAmount = _amountController.text.replaceAll('.', '');
      final amount = int.parse(cleanAmount);

      String? imageUrl;

      if (_imageFile != null) {
        final fileExt = _imageFile!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await supabase.storage.from('receipts').upload(fileName, _imageFile!);
        imageUrl = supabase.storage.from('receipts').getPublicUrl(fileName);
      }

      await supabase.from('transactions').insert({
        'amount': amount,
        'is_expense': isExpense,
        'category': selectedCategory,
        'wallet_id': selectedWalletId,
        'transaction_date': selectedDate.toIso8601String().split('T')[0],
        'note': _noteController.text.isEmpty ? null : _noteController.text,
        'image_path': imageUrl,
        'user_id': userId,
      });

      if (mounted) {
        Navigator.pop(context, 'Transaksi Berhasil Disimpan!');
      }
    } catch (e) {
      if (mounted) CustomNotification.show(context, 'Gagal menyimpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    Color dividerColor = isDark ? Colors.white24 : Colors.grey.shade300;

    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = (screenWidth - 40 - 32) / 5;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SubAppBar(title: 'Tambah Transaksi'),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getAmountInputSection(isDark, cardColor, textColor),
            const SizedBox(height: 35), // Peregangan jarak atas judul kategori
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('KATEGORI (Tekan Tahan untuk Hapus)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))
            ),
            const SizedBox(height: 18), // Peregangan jarak bawah judul kategori

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 16.0,
                alignment: WrapAlignment.start,
                children: (isExpense ? expenseCategories : incomeCategories).map((cat) {
                  bool isNew = cat['name'] == 'Baru';
                  return _buildCatItem(cat['icon'], cat['name'], cat['color'], isDark, cardColor, itemWidth, isNew: isNew);
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  children: [
                    InkWell(
                      onTap: (_walletsLoaded && _wallets.isNotEmpty)
                          ? _showWalletSelector
                          : () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWalletScreen()));
                        if (!mounted) return;
                        if (result == true) _fetchWallets();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.wallet, color: AppColors.primaryGreen, size: 20),
                            const SizedBox(width: 15),
                            Expanded(
                              child: !_walletsLoaded
                                  ? const Text("Memuat dompet...", style: TextStyle(color: Colors.grey, fontSize: 14))
                                  : (_wallets.isEmpty
                                  ? Row(
                                children: [
                                  Expanded(child: const Text("Belum ada dompet. Silakan buat terlebih dahulu.", style: TextStyle(color: Colors.grey, fontSize: 14))),
                                  TextButton(
                                            onPressed: () async {
                                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWalletScreen()));
                                              if (!mounted) return;
                                              if (result == true) {
                                                _fetchWallets();
                                              }
                                            },
                                    child: const Text('Buat Dompet', style: TextStyle(color: AppColors.primaryGreen)),
                                  )
                                ],
                              )
                                  : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedWalletId == null
                                          ? "Pilih Dompet"
                                          : _wallets.firstWhere((w) => w['id'] == selectedWalletId)['name'],
                                      style: TextStyle(fontSize: 14, color: selectedWalletId == null ? Colors.grey : textColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                ],
                              )),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 30, color: dividerColor, thickness: 1),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.calendarDays, color: AppColors.primaryGreen, size: 20),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                DateFormat('EEEE, dd MMMM yyyy', 'id').format(selectedDate),
                                style: TextStyle(fontSize: 14, color: textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CATATAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(hintText: "Beli apa hari ini?", hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white30 : Colors.grey), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                    ),
                    Divider(height: 20, color: dividerColor, thickness: 1),
                    InkWell(
                      onTap: _showImagePickerBottomSheet,
                      child: Column(
                        children: [
                          if (_imageFile != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                              ),
                            ),
                          Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.camera, color: AppColors.primaryGreen, size: 18),
                              const SizedBox(width: 15),
                              Text(_imageFile == null ? "Lampirkan Foto Struk" : "Ubah Foto Struk", style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget getAmountInputSection(bool isDark, Color cardColor, Color textColor) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).requestFocus(_amountFocusNode),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: cardColor, boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1FAF5), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _buildTabItem("Pengeluaran", isExpense, isDark, cardColor),
                  _buildTabItem("Pemasukan", !isExpense, isDark, cardColor),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text('NOMINAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Rp', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                const SizedBox(width: 10),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor),
                    cursorColor: AppColors.primaryGreen,
                    decoration: InputDecoration(border: InputBorder.none, hintText: "0", hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38)),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        String clean = value.replaceAll('.', '');
                        String formatted = NumberFormat.decimalPattern('id').format(int.parse(clean));
                        _amountController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, bool active, bool isDark, Color cardColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          bool targetIsExpense = (title == "Pengeluaran");
          if (isExpense != targetIsExpense) {
            setState(() {
              isExpense = targetIsExpense;
              selectedCategory = isExpense ? expenseCategories[0]['name'] : incomeCategories[0]['name'];
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: active ? (isDark ? Colors.white24 : Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : []),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: active ? AppColors.primaryGreen : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildCatItem(dynamic icon, String label, Color color, bool isDark, Color cardColor, double itemWidth, {bool isNew = false}) {
    bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        if (isNew) {
          _showAddCategoryDialog();
        } else {
          setState(() => selectedCategory = label);
        }
      },
      onLongPress: () {
        if (!isNew) {
          _confirmDeleteCategory(label);
        }
      },
      child: SizedBox(
        width: itemWidth,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isNew ? cardColor : (isSelected ? color.withValues(alpha: 0.2) : cardColor),
                shape: BoxShape.circle,
                border: isNew ? Border.all(color: Colors.grey.shade500) : (isSelected ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent)),
                boxShadow: (isDark || isSelected) ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: FaIcon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}