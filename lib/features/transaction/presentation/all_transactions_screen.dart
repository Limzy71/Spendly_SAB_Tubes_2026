import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';
import 'edit_transaction_screen.dart';
import '../../wallet/presentation/edit_transfer_sheet.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/category_helper.dart';
import '../../../../widgets/wallet_helper.dart';
import '../../../../widgets/network_helper.dart';
import '../../../../widgets/date_helper.dart';

class AllTransactionsScreen extends StatefulWidget {
  final String filterType;

  const AllTransactionsScreen({super.key, this.filterType = 'all'});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _userWallets = [];

  late String _selectedTypeFilter; // 'all', 'expense', 'income', 'transfer'
  int? _selectedWalletId;
  String? _selectedCategory;

  String _selectedTimeFilter = 'Bulan Ini';
  final List<String> _timeFilters = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini', 'Semua Waktu'];
  DateTimeRange? _customDateRange;

  Map<String, String> _customIcons = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _selectedTypeFilter = widget.filterType;
    _fetchAllTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateHelper.minDate,
      lastDate: DateHelper.nextMonthEnd(),
      builder: (BuildContext context, Widget? child) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: AppColors.primaryGreen, onPrimary: Colors.white, surface: Color(0xFF1E1E1E), onSurface: Colors.white)
                : const ColorScheme.light(primary: AppColors.primaryGreen, onPrimary: Colors.white),
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? const Color(0xFF252525) : AppColors.primaryGreen,
              iconTheme: const IconThemeData(color: Colors.white),
              actionsIconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTimeFilter = 'Kustom';
        _customDateRange = picked;
      });
      _fetchAllTransactions();
    }
  }

  Future<void> _fetchAllTransactions() async {
    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!hasConnection) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      Map<String, String> tempIcons = {};
      void loadCustomIcons(String listKey, String iconPrefix) {
        final customCats = prefs.getStringList(listKey) ?? [];
        for (final cat in customCats) {
          tempIcons[cat.toLowerCase()] = prefs.getString('$iconPrefix$cat') ?? 'star';
        }
      }

      loadCustomIcons('custom_transaction_expense_categories_v5', 'custom_transaction_expense_icon_v5_');
      loadCustomIcons('custom_transaction_income_categories_v5', 'custom_transaction_income_icon_v5_');
      loadCustomIcons('custom_transaction_expense_categories_v4', 'custom_transaction_expense_icon_v4_');
      loadCustomIcons('custom_transaction_income_categories_v4', 'custom_transaction_income_icon_v4_');
      loadCustomIcons('custom_transaction_expense_categories', 'custom_transaction_expense_icon_');
      loadCustomIcons('custom_transaction_income_categories', 'custom_transaction_income_icon_');
      loadCustomIcons('custom_budget_categories', 'custom_budget_icon_');

      final walletResponse = await supabase.from('wallets').select().eq('user_id', userId).order('id');
      final txResponse = await supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      Map<int, Map<String, dynamic>> walletData = {};
      List<Map<String, dynamic>> loadedWallets = [];
      for (var w in walletResponse) {
        int wId = int.tryParse(w['id'].toString()) ?? -1;
        if (wId != -1) {
          String wName = w['name'].toString();
          int currentBal = int.tryParse(w['balance']?.toString() ?? '0') ?? 0;
          String? iconName = w['icon_name']?.toString();

          int expenseTxCount = 0;
          int totalTxCount = 0;
          for (var tx in txResponse) {
            int txWalletId = int.tryParse(tx['wallet_id'].toString()) ?? -1;
            if (txWalletId == wId) {
              totalTxCount++;
              int txAmount = int.tryParse(tx['amount'].toString()) ?? 0;
              if (tx['is_expense'] == true) {
                expenseTxCount++;
                currentBal -= txAmount;
              } else {
                currentBal += txAmount;
              }
            }
          }

          int usageScore = (expenseTxCount * 3) + totalTxCount;

          walletData[wId] = {'name': wName};
          loadedWallets.add({
            'id': wId,
            'name': wName,
            'color': WalletHelper.getColor(wName),
            'icon': WalletHelper.getIcon(iconName, wName, color: WalletHelper.getColor(wName), size: 14),
            'icon_name': iconName,
            'balance': currentBal,
            'usage_score': usageScore,
          });
        }
      }

      loadedWallets.sort((a, b) {
        int scoreA = a['usage_score'] as int? ?? 0;
        int scoreB = b['usage_score'] as int? ?? 0;
        if (scoreB != scoreA) {
          return scoreB.compareTo(scoreA); // Most active wallet first
        }
        int balA = a['balance'] as int? ?? 0;
        int balB = b['balance'] as int? ?? 0;
        return balB.compareTo(balA);
      });

      List<Map<String, dynamic>> displayTx = [];
      Set<int> processedIds = {};

      DateTime now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      if (_selectedTimeFilter == 'Hari Ini') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_selectedTimeFilter == 'Minggu Ini') {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      } else if (_selectedTimeFilter == 'Bulan Ini') {
        startDate = DateTime(now.year, now.month, 1);
      } else if (_selectedTimeFilter == 'Tahun Ini') {
        startDate = DateTime(now.year, 1, 1);
      } else if (_selectedTimeFilter == 'Kustom' && _customDateRange != null) {
        startDate = _customDateRange!.start;
        endDate = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
      } else {
        startDate = null;
        endDate = null;
      }

      String getWalletName(Map<String, dynamic> t) {
        String savedName = t['wallet_name']?.toString() ?? '';
        if (savedName.trim().isNotEmpty) return savedName;
        int wId = int.tryParse(t['wallet_id'].toString()) ?? -1;
        if (walletData.containsKey(wId)) return walletData[wId]!['name'];
        return 'Dompet (Dihapus)';
      }

      for (var tx in txResponse) {
        int id = int.tryParse(tx['id'].toString()) ?? -1;
        if (processedIds.contains(id)) continue;

        int amount = int.tryParse(tx['amount'].toString()) ?? 0;
        bool isExpense = tx['is_expense'] as bool? ?? false;
        String category = tx['category']?.toString() ?? '';
        DateTime txDate = DateTime.parse(tx['transaction_date']);

        if (startDate != null && endDate != null) {
          if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) {
            continue;
          }
        }

        if (category.toLowerCase() == 'transfer') {
          final txGroupId = tx['group_id']?.toString();
          Map<String, dynamic> partner = {};
          if (txGroupId != null && txGroupId.isNotEmpty) {
            partner = txResponse.firstWhere(
                  (t) => (t['group_id']?.toString() ?? '') == txGroupId &&
                  t['category']?.toString().toLowerCase() != 'biaya admin' &&
                  (int.tryParse(t['id'].toString()) ?? -1) != id &&
                  !processedIds.contains(int.tryParse(t['id'].toString()) ?? -1),
              orElse: () => <String, dynamic>{},
            );
          }
          if (partner.isEmpty) {
            partner = txResponse.firstWhere(
                  (t) => t['category']?.toString().toLowerCase() == 'transfer' &&
                  (int.tryParse(t['amount'].toString()) ?? 0) == amount &&
                  t['is_expense'] != isExpense &&
                  t['transaction_date'] == tx['transaction_date'] &&
                  !processedIds.contains(int.tryParse(t['id'].toString()) ?? -1),
              orElse: () => <String, dynamic>{},
            );
          }

          var mergedTx = Map<String, dynamic>.from(tx);
          if (isExpense) {
            mergedTx['from_wallet'] = getWalletName(tx);
            mergedTx['to_wallet'] = partner.isNotEmpty ? getWalletName(partner) : 'Dompet (Dihapus)';
          } else {
            mergedTx['to_wallet'] = getWalletName(tx);
            mergedTx['from_wallet'] = partner.isNotEmpty ? getWalletName(partner) : 'Dompet (Dihapus)';
          }

          mergedTx['partner_id'] = partner.isNotEmpty ? partner['id'] : null;
          mergedTx['partner_wallet_id'] = partner.isNotEmpty ? partner['wallet_id'] : null;

          displayTx.add(mergedTx);
          processedIds.add(id);
          if (partner.isNotEmpty) processedIds.add(int.tryParse(partner['id'].toString()) ?? -1);
        } else {
          var mergedTx = Map<String, dynamic>.from(tx);
          mergedTx['wallet_name'] = getWalletName(tx);
          displayTx.add(mergedTx);
          processedIds.add(id);
        }
      }

      if (mounted) {
        setState(() {
          _customIcons = tempIcons;
          _userWallets = loadedWallets;
          _transactions = displayTx;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal mengambil data');
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(bool isTransfer) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isTransfer ? 'Hapus Transfer?' : 'Hapus Transaksi?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          isTransfer
              ? 'Seluruh mutasi transfer ini (termasuk biaya admin jika ada) akan dihapus dan saldo dompet akan disesuaikan.'
              : 'Transaksi ini akan dihapus secara permanen dan saldo dompet akan disesuaikan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeleteTransaction(Map<String, dynamic> tx) async {
    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!hasConnection) return;

    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      bool isTransfer = tx['category']?.toString().toLowerCase() == 'transfer';
      int mainId = tx['id'];

      if (isTransfer) {
        final groupId = tx['group_id']?.toString();
        if (groupId != null && groupId.isNotEmpty) {
          await supabase.from('transactions').delete().eq('group_id', groupId).eq('user_id', userId);
        } else if (tx['partner_id'] != null) {
          int partnerId = tx['partner_id'];
          await supabase.from('transactions').delete().eq('id', mainId).eq('user_id', userId);
          await supabase.from('transactions').delete().eq('id', partnerId).eq('user_id', userId);
        } else {
          await supabase.from('transactions').delete().eq('id', mainId).eq('user_id', userId);
        }
      } else {
        await supabase.from('transactions').delete().eq('id', mainId).eq('user_id', userId);
      }

      if (mounted) {
        CustomNotification.show(context, 'Transaksi berhasil dihapus.');
        _fetchAllTransactions();
      }
    } catch (e) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal menghapus');
        setState(() => _isLoading = false);
      }
    }
  }

  void _openWalletFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _userWallets.where((w) {
              if (searchQuery.trim().isEmpty) return true;
              return w['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            final bool isSheetDark = Theme.of(ctx).brightness == Brightness.dark;
            final Color sheetTextColor = Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black87;

            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.52,
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 4),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSheetDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filter Berdasarkan Dompet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sheetTextColor)),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: sheetTextColor),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    if (_userWallets.length > 5) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: TextField(
                          style: TextStyle(color: sheetTextColor, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari dompet...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                            filled: true,
                            fillColor: isSheetDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => setSheetState(() => searchQuery = val),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    ListTile(
                      dense: true,
                      onTap: () {
                        setState(() => _selectedWalletId = null);
                        Navigator.pop(ctx);
                      },
                      leading: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: FaIcon(FontAwesomeIcons.wallet, color: AppColors.primaryGreen, size: 18),
                        ),
                      ),
                      title: const Text('Semua Dompet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      trailing: _selectedWalletId == null ? const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20) : null,
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Dompet tidak ditemukan', style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                              itemBuilder: (context, index) {
                                final w = filtered[index];
                                final wId = int.tryParse(w['id'].toString());
                                final isSelected = wId == _selectedWalletId;
                                final wName = w['name'].toString();
                                final wColor = WalletHelper.getColor(wName);
                                final int balance = int.tryParse(w['balance']?.toString() ?? '0') ?? 0;

                                return ListTile(
                                  dense: true,
                                  onTap: () {
                                    setState(() => _selectedWalletId = wId);
                                    Navigator.pop(ctx);
                                  },
                                  leading: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Center(
                                      child: WalletHelper.getIcon(w['icon_name']?.toString(), wName, color: wColor, size: 14),
                                    ),
                                  ),
                                  title: Text(wName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatCurrency(balance),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 18),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCategoryFilterSheet(List<String> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String catSearchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredCategories = categories.where((c) {
              if (catSearchQuery.trim().isEmpty) return true;
              return c.toLowerCase().contains(catSearchQuery.toLowerCase());
            }).toList();

            final bool isSheetDark = Theme.of(ctx).brightness == Brightness.dark;
            final Color sheetTextColor = Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black87;

            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.52,
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 4),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSheetDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filter Berdasarkan Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sheetTextColor)),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: sheetTextColor),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    if (categories.length > 5) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: TextField(
                          style: TextStyle(color: sheetTextColor, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari kategori...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                            filled: true,
                            fillColor: isSheetDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => setSheetState(() => catSearchQuery = val),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    ListTile(
                      dense: true,
                      onTap: () {
                        setState(() => _selectedCategory = null);
                        Navigator.pop(ctx);
                      },
                      leading: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: FaIcon(FontAwesomeIcons.tags, color: AppColors.primaryGreen, size: 18),
                        ),
                      ),
                      title: const Text('Semua Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      trailing: _selectedCategory == null ? const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20) : null,
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    Flexible(
                      child: filteredCategories.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Kategori tidak ditemukan', style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredCategories.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                              itemBuilder: (context, index) {
                                final cat = filteredCategories[index];
                                final isSelected = cat.toLowerCase() == (_selectedCategory ?? '').toLowerCase();
                                final color = CategoryHelper.getColor(cat, customIcons: _customIcons);

                                return ListTile(
                                  dense: true,
                                  onTap: () {
                                    setState(() => _selectedCategory = cat);
                                    Navigator.pop(ctx);
                                  },
                                  leading: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Center(
                                      child: FaIcon(CategoryHelper.getIcon(cat, customIcons: _customIcons), color: color, size: 18),
                                    ),
                                  ),
                                  title: Text(cat, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
                                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20) : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatCurrency(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

  String _formatDate(String dateString) {
    try { return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(dateString)); }
    catch (e) { return dateString; }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    final filteredList = _transactions.where((tx) {
      final isExp = tx['is_expense'] as bool? ?? false;
      final category = (tx['category'] ?? '').toString();
      final isTransfer = category.toLowerCase() == 'transfer';

      // 1. Type Filter
      if (_selectedTypeFilter == 'income' && (isExp || isTransfer)) return false;
      if (_selectedTypeFilter == 'expense' && (!isExp || isTransfer)) return false;
      if (_selectedTypeFilter == 'transfer' && !isTransfer) return false;

      // 2. Category Filter
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (category.toLowerCase() != _selectedCategory!.toLowerCase()) return false;
      }

      // 3. Wallet Filter
      if (_selectedWalletId != null) {
        final txWalletId = int.tryParse(tx['wallet_id']?.toString() ?? '-1') ?? -1;
        final partnerWalletId = int.tryParse(tx['partner_wallet_id']?.toString() ?? '-1') ?? -1;
        if (isTransfer) {
          if (txWalletId != _selectedWalletId && partnerWalletId != _selectedWalletId) {
            return false;
          }
        } else {
          if (txWalletId != _selectedWalletId) return false;
        }
      }

      // 4. Search Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final note = (tx['note'] ?? '').toString().toLowerCase();
        final cat = category.toLowerCase();
        final walletName = (tx['wallet_name'] ?? '').toString().toLowerCase();
        final fromWallet = (tx['from_wallet'] ?? '').toString().toLowerCase();
        final toWallet = (tx['to_wallet'] ?? '').toString().toLowerCase();
        final amount = (tx['amount'] ?? '').toString();
        return note.contains(q) || cat.contains(q) || walletName.contains(q) || fromWallet.contains(q) || toWallet.contains(q) || amount.contains(q);
      }

      return true;
    }).toList();

    // Extract and sort available categories based on real usage frequency
    Map<String, int> categoryUsageCounts = {};
    for (var t in _transactions) {
      final isExp = t['is_expense'] as bool? ?? false;
      final cat = (t['category'] ?? '').toString().trim();
      if (cat.isEmpty || cat.toLowerCase() == 'transfer') continue;
      if (_selectedTypeFilter == 'income' && isExp) continue;
      if (_selectedTypeFilter == 'expense' && !isExp) continue;

      categoryUsageCounts[cat] = (categoryUsageCounts[cat] ?? 0) + 1;
    }

    final availableCategories = categoryUsageCounts.keys.toList()
      ..sort((a, b) {
        int countA = categoryUsageCounts[a] ?? 0;
        int countB = categoryUsageCounts[b] ?? 0;
        if (countB != countA) {
          return countB.compareTo(countA); // Most frequently used category first!
        }
        return a.compareTo(b);
      });

    final selectedWalletObj = _userWallets.firstWhere(
      (w) => w['id'] == _selectedWalletId,
      orElse: () => <String, dynamic>{},
    );
    final String selectedWalletName = selectedWalletObj.isNotEmpty ? selectedWalletObj['name'].toString() : 'Semua Dompet';

    final bool hasActiveFilter = _selectedWalletId != null || _selectedCategory != null || _selectedTypeFilter != 'all' || _selectedTimeFilter != 'Bulan Ini' || _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: const SubAppBar(title: 'Semua Transaksi'),
      body: Column(
        children: [
          // 1. Time Filter Bar (Horizontal)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ..._timeFilters.map((filter) {
                  bool isSelected = _selectedTimeFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedTimeFilter = filter);
                      _fetchAllTransactions();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryGreen : (isDark ? Colors.white12 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _pickCustomDateRange,
                  child: Container(
                    margin: const EdgeInsets.only(left: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _selectedTimeFilter == 'Kustom' ? AppColors.primaryGreen : (isDark ? Colors.white12 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.calendarDays,
                          size: 13,
                          color: _selectedTimeFilter == 'Kustom' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        if (_selectedTimeFilter == 'Kustom') ...[
                          const SizedBox(width: 6),
                          const Text('Kustom', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Type Filter Tabs (Semua, Pengeluaran, Pemasukan, Transfer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildTypeTab(label: 'Semua', value: 'all', isDark: isDark),
                const SizedBox(width: 8),
                _buildTypeTab(label: 'Pengeluaran', value: 'expense', isDark: isDark, dotColor: Colors.red),
                const SizedBox(width: 8),
                _buildTypeTab(label: 'Pemasukan', value: 'income', isDark: isDark, dotColor: AppColors.primaryGreen),
                const SizedBox(width: 8),
                _buildTypeTab(label: 'Transfer', value: 'transfer', isDark: isDark, dotColor: Colors.blue),
              ],
            ),
          ),

          // 3. Filter Bar (Dompet & Kategori Pickers)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // Dompet Filter Button
                Expanded(
                  child: InkWell(
                    onTap: _openWalletFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedWalletId != null
                            ? AppColors.primaryGreen.withValues(alpha: 0.12)
                            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedWalletId != null ? AppColors.primaryGreen : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.wallet,
                            size: 13,
                            color: _selectedWalletId != null ? AppColors.primaryGreen : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              selectedWalletName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedWalletId != null ? FontWeight.bold : FontWeight.w500,
                                color: _selectedWalletId != null ? AppColors.primaryGreen : textColor,
                              ),
                            ),
                          ),
                          if (_selectedWalletId != null)
                            GestureDetector(
                              onTap: () => setState(() => _selectedWalletId = null),
                              child: const Icon(Icons.close, size: 14, color: AppColors.primaryGreen),
                            )
                          else
                            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Kategori Filter Button (only for non-transfer)
                if (_selectedTypeFilter != 'transfer') ...[
                  Expanded(
                    child: InkWell(
                      onTap: () => _openCategoryFilterSheet(availableCategories),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategory != null
                              ? AppColors.primaryGreen.withValues(alpha: 0.12)
                              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedCategory != null ? AppColors.primaryGreen : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.tags,
                              size: 13,
                              color: _selectedCategory != null ? AppColors.primaryGreen : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedCategory ?? 'Semua Kategori',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedCategory != null ? FontWeight.bold : FontWeight.w500,
                                  color: _selectedCategory != null ? AppColors.primaryGreen : textColor,
                                ),
                              ),
                            ),
                            if (_selectedCategory != null)
                              GestureDetector(
                                onTap: () => setState(() => _selectedCategory = null),
                                child: const Icon(Icons.close, size: 14, color: AppColors.primaryGreen),
                              )
                            else
                              const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                if (hasActiveFilter) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Reset Filter',
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      setState(() {
                        _selectedWalletId = null;
                        _selectedCategory = null;
                        _selectedTypeFilter = 'all';
                        _selectedTimeFilter = 'Bulan Ini';
                        _searchQuery = '';
                        _searchController.clear();
                      });
                      _fetchAllTransactions();
                    },
                  ),
                ],
              ],
            ),
          ),

          // 4. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari catatan, kategori, atau nominal...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          const SizedBox(height: 4),

          // 5. Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : filteredList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.receipt, size: 42, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "Tidak ada transaksi yang cocok dengan pencarian."
                                : "Tidak ada transaksi untuk filter terpilih.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          if (hasActiveFilter) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedWalletId = null;
                                  _selectedCategory = null;
                                  _selectedTypeFilter = 'all';
                                  _selectedTimeFilter = 'Bulan Ini';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                _fetchAllTransactions();
                              },
                              child: const Text('Reset Semua Filter', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final tx = filteredList[index];
                      return _buildTransactionItem(tx, textColor, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab({
    required String label,
    required String value,
    required bool isDark,
    Color? dotColor,
  }) {
    bool isSelected = _selectedTypeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTypeFilter = value;
            if (value == 'transfer') {
              _selectedCategory = null;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx, Color textColor, bool isDark) {
    bool isTransfer = tx['category']?.toString().toLowerCase() == 'transfer';
    bool isExpense = tx['is_expense'] as bool? ?? false;

    Color amountColor = isTransfer ? Colors.blue : (isExpense ? Colors.red : AppColors.primaryGreen);
    Color iconColor = isTransfer ? Colors.blue : CategoryHelper.getColor(tx['category'] ?? '', customIcons: _customIcons);
    Color bgIconColor = iconColor.withValues(alpha: 0.12);

    dynamic icon = isTransfer
        ? FontAwesomeIcons.rightLeft
        : CategoryHelper.getIcon(tx['category'] ?? '', customIcons: _customIcons);

    String note = tx['note'] ?? '';
    String title = isTransfer ? "Transfer" : (tx['category'] ?? "Lainnya");

    String walletNameStr = tx['wallet_name'] != null ? "  |  ${tx['wallet_name']}" : "";
    String subtitle = "${_formatDate(tx['transaction_date'] ?? "")}$walletNameStr";
    String transferPath = isTransfer ? "${tx['from_wallet']} → ${tx['to_wallet']}" : "";

    return Dismissible(
      key: Key('tx_${tx['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(isTransfer);
      },
      onDismissed: (direction) {
        _executeDeleteTransaction(tx);
      },
      child: InkWell(
        onTap: () async {
          if (isTransfer) {
            final changed = await showEditTransferSheet(context, tx: tx);
            if (changed && mounted) {
              _fetchAllTransactions();
            }
            return;
          }

          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditTransactionScreen(transaction: tx)));
          if (!mounted) return;
          if (result != null) {
            _fetchAllTransactions();
            String msg = result is String ? result : 'Transaksi Berhasil Diperbarui!';
            CustomNotification.show(context, msg);
          }
        },
        onLongPress: () async {
          bool? confirm = await _showDeleteConfirmationDialog(isTransfer);
          if (confirm == true) {
            _executeDeleteTransaction(tx);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(12)),
                  child: FaIcon(icon, color: iconColor, size: 20)
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (DateHelper.isUpcoming(tx['transaction_date']?.toString() ?? '')) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Mendatang', style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('"$note"', style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    if (isTransfer) ...[
                      const SizedBox(height: 6),
                      Text(transferPath, style: TextStyle(color: Colors.blue.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]
                  ],
                ),
              ),
              Text(
                  isTransfer ? _formatCurrency(tx['amount'] ?? 0) : "${isExpense ? '-' : '+'} ${_formatCurrency(tx['amount'] ?? 0)}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: amountColor, fontSize: 14)
              ),
            ],
          ),
        ),
      ),
    );
  }
}