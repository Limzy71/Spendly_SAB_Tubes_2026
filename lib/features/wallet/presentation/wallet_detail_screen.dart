import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/category_helper.dart';
import '../../../widgets/wallet_helper.dart';
import '../../../widgets/network_helper.dart';
import '../../../widgets/sub_app_bar.dart';
import '../../transaction/presentation/edit_transaction_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  final Map<String, dynamic> wallet;
  final List<Map<String, dynamic>>? allWallets;

  const WalletDetailScreen({
    super.key,
    required this.wallet,
    this.allWallets,
  });

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  final supabase = Supabase.instance.client;

  late Map<String, dynamic> _currentWallet;
  List<Map<String, dynamic>> _allWallets = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  List<Map<String, dynamic>> _walletTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];

  int _totalIncome = 0;
  int _totalExpense = 0;
  int _netFlow = 0;
  int _calculatedBalance = 0;

  String _selectedTimeFilter = 'Bulan Ini';
  final List<String> _timeFilters = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini', 'Semua Waktu', 'Kustom'];
  DateTimeRange? _customDateRange;

  String _selectedTypeFilter = 'Semua';
  final List<String> _typeFilters = ['Semua', 'Pemasukan', 'Pengeluaran', 'Transfer'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _customIcons = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _currentWallet = Map<String, dynamic>.from(widget.wallet);
    if (widget.allWallets != null) {
      _allWallets = List<Map<String, dynamic>>.from(widget.allWallets!);
    }
    _fetchWalletDetailData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletDetailData() async {
    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!hasConnection) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

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
      loadCustomIcons('custom_budget_categories', 'custom_budget_icon_');

      final walletResponse = await supabase.from('wallets').select().eq('user_id', userId).order('id');
      final txResponse = await supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      Map<int, Map<String, dynamic>> walletMap = {};
      List<Map<String, dynamic>> updatedWalletsList = [];

      for (var w in walletResponse) {
        int wId = int.tryParse(w['id'].toString()) ?? -1;
        if (wId == -1) continue;
        String wName = w['name'].toString();
        int baseBal = int.tryParse(w['balance'].toString()) ?? 0;
        String? iconName = w['icon_name']?.toString();

        int dynamicBal = baseBal;
        for (var tx in txResponse) {
          int txWalletId = int.tryParse(tx['wallet_id'].toString()) ?? -1;
          if (txWalletId == wId) {
            int txAmount = int.tryParse(tx['amount'].toString()) ?? 0;
            if (tx['is_expense'] == true) {
              dynamicBal -= txAmount;
            } else {
              dynamicBal += txAmount;
            }
          }
        }

        final processedW = {
          'id': wId,
          'name': wName,
          'balance': dynamicBal,
          'base_balance': baseBal,
          'subtitle': WalletHelper.getSubtitle(wName),
          'icon': WalletHelper.getIcon(iconName, wName, color: WalletHelper.getColor(wName), size: 16),
          'color': WalletHelper.getColor(wName),
        };

        walletMap[wId] = processedW;
        updatedWalletsList.add(processedW);
      }

      int targetWalletId = _currentWallet['id'];
      if (walletMap.containsKey(targetWalletId)) {
        _currentWallet = walletMap[targetWalletId]!;
        _calculatedBalance = _currentWallet['balance'];
      }

      _allWallets = updatedWalletsList;

      List<Map<String, dynamic>> walletTxList = [];

      for (var tx in txResponse) {
        int txWalletId = int.tryParse(tx['wallet_id'].toString()) ?? -1;
        if (txWalletId != targetWalletId) continue;

        int amount = int.tryParse(tx['amount'].toString()) ?? 0;
        bool isExpense = tx['is_expense'] == true;
        String category = tx['category']?.toString() ?? '';
        String txDateStr = tx['transaction_date']?.toString() ?? '';

        var txItem = Map<String, dynamic>.from(tx);

        if (category.toLowerCase() == 'transfer') {
          final txGroupId = txItem['group_id']?.toString();
          Map<String, dynamic> partner = {};
          if (txGroupId != null && txGroupId.isNotEmpty) {
            partner = txResponse.firstWhere(
              (t) =>
                  (t['group_id']?.toString() ?? '') == txGroupId &&
                  t['id'] != tx['id'] &&
                  (t['category']?.toString().toLowerCase() != 'biaya admin'),
              orElse: () => <String, dynamic>{},
            );
          }
          if (partner.isEmpty) {
            partner = txResponse.firstWhere(
              (t) =>
                  t['category']?.toString().toLowerCase() == 'transfer' &&
                  (int.tryParse(t['amount'].toString()) ?? 0) == amount &&
                  t['is_expense'] != isExpense &&
                  t['transaction_date'] == txDateStr &&
                  t['id'] != tx['id'],
              orElse: () => <String, dynamic>{},
            );
          }

          int partnerWalletId = int.tryParse(partner['wallet_id']?.toString() ?? '') ?? -1;
          String partnerWalletName = partner['wallet_name']?.toString() ?? '';
          if (partnerWalletName.isEmpty && walletMap.containsKey(partnerWalletId)) {
            partnerWalletName = walletMap[partnerWalletId]!['name'];
          }
          if (partnerWalletName.isEmpty) {
            partnerWalletName = 'Dompet Lain';
          }

          txItem['partner_id'] = partner.isNotEmpty ? partner['id'] : null;
          txItem['partner_wallet_name'] = partnerWalletName;
          txItem['is_transfer'] = true;
          txItem['transfer_direction'] = isExpense ? 'out' : 'in';
        } else {
          txItem['is_transfer'] = false;
        }

        walletTxList.add(txItem);
      }

      if (mounted) {
        setState(() {
          _customIcons = tempIcons;
          _walletTransactions = walletTxList;
          _applyFiltersAndCalculateTotals();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal memuat detail dompet');
      }
    }
  }

  void _applyFiltersAndCalculateTotals() {
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
      endDate = DateTime(
        _customDateRange!.end.year,
        _customDateRange!.end.month,
        _customDateRange!.end.day,
        23,
        59,
        59,
      );
    } else {
      startDate = null;
      endDate = null;
    }

    int periodIncome = 0;
    int periodExpense = 0;
    List<Map<String, dynamic>> filtered = [];

    for (var tx in _walletTransactions) {
      DateTime txDate;
      try {
        txDate = DateTime.parse(tx['transaction_date']);
      } catch (_) {
        txDate = DateTime.now();
      }

      if (startDate != null && endDate != null) {
        if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) {
          continue;
        }
      }

      int amount = int.tryParse(tx['amount'].toString()) ?? 0;
      bool isExpense = tx['is_expense'] == true;
      bool isTransfer = tx['is_transfer'] == true;
      String category = (tx['category'] ?? '').toString();
      String note = (tx['note'] ?? '').toString();
      String partnerName = (tx['partner_wallet_name'] ?? '').toString();

      if (isExpense) {
        periodExpense += amount;
      } else {
        periodIncome += amount;
      }

      if (_selectedTypeFilter == 'Pemasukan' && (isExpense || isTransfer)) continue;
      if (_selectedTypeFilter == 'Pengeluaran' && (!isExpense || isTransfer)) continue;
      if (_selectedTypeFilter == 'Transfer' && !isTransfer) continue;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCategory = category.toLowerCase().contains(q);
        final matchNote = note.toLowerCase().contains(q);
        final matchPartner = partnerName.toLowerCase().contains(q);
        final matchAmount = amount.toString().contains(q);

        if (!matchCategory && !matchNote && !matchPartner && !matchAmount) {
          continue;
        }
      }

      filtered.add(tx);
    }

    _totalIncome = periodIncome;
    _totalExpense = periodExpense;
    _netFlow = periodIncome - periodExpense;
    _filteredTransactions = filtered;
  }

  Future<void> _pickCustomDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                  ),
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
        _applyFiltersAndCalculateTotals();
      });
    }
  }

  String _formatCurrency(int amount, {bool showSign = false}) {
    bool isNegative = amount < 0;
    int absAmount = amount.abs();

    String formatted;
    if (absAmount >= 1000000000000000) {
      formatted = 'Rp 999 T+';
    } else if (absAmount >= 1000000000000) {
      double inT = absAmount / 1000000000000;
      String f = inT.toStringAsFixed(2).replaceAll('.', ',');
      if (f.endsWith(',00')) {
        f = f.substring(0, f.length - 3);
      }
      formatted = 'Rp $f T';
    } else {
      formatted = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(absAmount);
    }

    if (showSign) {
      if (isNegative) return '- $formatted';
      if (amount > 0) return '+ $formatted';
    } else if (isNegative) {
      return '- $formatted';
    }

    return formatted;
  }

  void _showEditWalletModal() {
    TextEditingController editNameController = TextEditingController(text: _currentWallet['name']);
    TextEditingController editBalanceController = TextEditingController(
      text: NumberFormat.decimalPattern('id').format(_currentWallet['balance']),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: bottomInset > 0 ? bottomInset + 16 : bottomPadding + 20,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Dompet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.red, size: 18),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteWallet();
                      },
                    )
                  ],
                ),
                const SizedBox(height: 16),
                const Text('NAMA DOMPET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                TextField(
                  controller: editNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('SALDO SAAT INI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: editBalanceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(18)],
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      String clean = value.replaceAll('.', '');
                      if (clean.startsWith('0') && clean.length > 1) {
                        clean = clean.replaceFirst(RegExp(r'^0+'), '');
                        if (clean.isEmpty) clean = '0';
                      }
                      String formatted = NumberFormat.decimalPattern('id').format(int.tryParse(clean) ?? 0);
                      editBalanceController.value =
                          TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                    }
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      bool hasConnection = await NetworkHelper.checkConnection(context);
                      if (!mounted) return;
                      if (!hasConnection) return;

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      try {
                        int newBalance = int.tryParse(editBalanceController.text.replaceAll('.', '')) ?? 0;
                        int walletId = _currentWallet['id'];

                        final walletData = await supabase.from('wallets').select('balance').eq('id', walletId).single();
                        int dbBalance = int.tryParse(walletData['balance'].toString()) ?? 0;

                        int totalTxEffect = (_currentWallet['balance'] as int) - dbBalance;
                        int newBaseBalance = newBalance - totalTxEffect;

                        await supabase.from('wallets').update({
                          'name': editNameController.text.trim(),
                          'balance': newBaseBalance,
                        }).eq('id', walletId);

                        await supabase.from('transactions').update({
                          'wallet_name': editNameController.text.trim(),
                        }).eq('wallet_id', walletId);

                        _hasChanges = true;
                        _fetchWalletDetailData();
                        if (mounted) CustomNotification.show(context, 'Dompet berhasil diperbarui!');
                      } catch (e) {
                        if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal memperbarui');
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteWallet() async {
    if (_allWallets.length <= 1) {
      CustomNotification.show(context, 'Tidak bisa menghapus satu-satunya dompet!', isWarning: true);
      return;
    }

    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!hasConnection) return;

    setState(() => _isLoading = true);
    int walletId = _currentWallet['id'];
    String walletName = _currentWallet['name'];

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final txCheck = await supabase.from('transactions').select('id').eq('wallet_id', walletId).limit(1);

      if (txCheck.isNotEmpty) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Tindakan Ditolak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: const Text(
              'Dompet ini tidak dapat dihapus karena masih terhubung dengan riwayat transaksi (pemasukan, pengeluaran, atau transfer).\n\nSilakan hapus atau pindahkan transaksi tersebut terlebih dahulu.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal mengecek data');
      return;
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Hapus Dompet?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Text('Anda yakin ingin menghapus dompet "$walletName"?', style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;

    if (confirm) {
      setState(() => _isLoading = true);
      try {
        await supabase.from('wallets').delete().eq('id', walletId);
        if (mounted) {
          CustomNotification.show(context, 'Dompet berhasil dihapus.');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal menghapus dompet');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showTransferSheet() {
    int fromId = _currentWallet['id'];
    int? toId;

    final otherWallets = _allWallets.where((w) => w['id'] != fromId).toList();
    if (otherWallets.isNotEmpty) {
      toId = otherWallets.first['id'];
    }

    final TextEditingController transferAmountController = TextEditingController();
    final TextEditingController transferAdminFeeController = TextEditingController();
    final TextEditingController transferNoteController = TextEditingController();
    bool isProcessingTransfer = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final isDarkMode = Theme.of(ctx).brightness == Brightness.dark;
        final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;
            final bottomPadding = MediaQuery.of(modalContext).padding.bottom;

            final cleanAmt = transferAmountController.text.replaceAll('.', '');
            final cleanFee = transferAdminFeeController.text.replaceAll('.', '');
            final int amtVal = int.tryParse(cleanAmt) ?? 0;
            final int feeVal = int.tryParse(cleanFee) ?? 0;
            final int totalDeduction = amtVal + feeVal;

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: bottomInset > 0 ? bottomInset + 16 : bottomPadding + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.rightLeft, color: AppColors.primaryGreen, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Transfer dari ${_currentWallet['name']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(modalContext).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('TUJUAN TRANSFER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (otherWallets.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Text('Buat dompet kedua terlebih dahulu untuk transfer.', style: TextStyle(fontSize: 12)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: toId,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                            items: otherWallets.map((w) {
                              return DropdownMenuItem<int>(
                                value: w['id'],
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: (w['color'] as Color? ?? Colors.grey).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: w['icon'] ?? const Icon(Icons.wallet, size: 14),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        w['name'],
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => toId = val);
                              }
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text('NOMINAL TRANSFER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: transferAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [LengthLimitingTextInputFormatter(18)],
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: '0',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          String clean = val.replaceAll('.', '');
                          if (clean.startsWith('0') && clean.length > 1) {
                            clean = clean.replaceFirst(RegExp(r'^0+'), '');
                            if (clean.isEmpty) clean = '0';
                          }
                          String formatted = NumberFormat.decimalPattern('id').format(int.tryParse(clean) ?? 0);
                          transferAmountController.value =
                              TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                        }
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('BIAYA ADMIN (OPSIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: transferAdminFeeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [LengthLimitingTextInputFormatter(18)],
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: '0',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          String clean = val.replaceAll('.', '');
                          if (clean.startsWith('0') && clean.length > 1) {
                            clean = clean.replaceFirst(RegExp(r'^0+'), '');
                            if (clean.isEmpty) clean = '0';
                          }
                          String formatted = NumberFormat.decimalPattern('id').format(int.tryParse(clean) ?? 0);
                          transferAdminFeeController.value =
                              TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                        }
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    if (amtVal > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Nominal Transfer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(_formatCurrency(amtVal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (feeVal > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Biaya Admin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(_formatCurrency(feeVal), style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Potongan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(
                                  _formatCurrency(totalDeduction),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const Text('CATATAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: transferNoteController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Tambah keterangan transfer...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isProcessingTransfer || otherWallets.isEmpty
                            ? null
                            : () async {
                                if (toId == null) {
                                  CustomNotification.show(context, 'Pilih dompet tujuan!', isWarning: true);
                                  return;
                                }
                                if (amtVal <= 0) {
                                  CustomNotification.show(context, 'Nominal transfer wajib diisi!', isWarning: true);
                                  return;
                                }
                                if (totalDeduction > (_currentWallet['balance'] as int)) {
                                  CustomNotification.show(
                                    context,
                                    'Saldo tidak mencukupi untuk transfer dan biaya admin!',
                                    isError: true,
                                  );
                                  return;
                                }

                                if (!mounted) return;
                                bool hasConn = await NetworkHelper.checkConnection(context);
                                if (!mounted || !hasConn) return;

                                setModalState(() => isProcessingTransfer = true);

                                try {
                                  final userId = supabase.auth.currentUser?.id;
                                  if (userId == null) return;

                                  final targetW = otherWallets.firstWhere((w) => w['id'] == toId);
                                  final today = DateTime.now().toIso8601String().split('T')[0];
                                  final noteText = transferNoteController.text.trim().isNotEmpty
                                      ? transferNoteController.text.trim()
                                      : 'Transfer Internal';
                                  final groupId = DateTime.now().microsecondsSinceEpoch.toString();

                                  final List<Map<String, dynamic>> records = [
                                    {
                                      'amount': amtVal,
                                      'is_expense': true,
                                      'category': 'Transfer',
                                      'wallet_id': fromId,
                                      'wallet_name': _currentWallet['name'],
                                      'transaction_date': today,
                                      'note': noteText,
                                      'group_id': groupId,
                                      'user_id': userId,
                                    },
                                    {
                                      'amount': amtVal,
                                      'is_expense': false,
                                      'category': 'Transfer',
                                      'wallet_id': toId,
                                      'wallet_name': targetW['name'],
                                      'transaction_date': today,
                                      'note': noteText,
                                      'group_id': groupId,
                                      'user_id': userId,
                                    }
                                  ];

                                  if (feeVal > 0) {
                                    records.add({
                                      'amount': feeVal,
                                      'is_expense': true,
                                      'category': 'Biaya Admin',
                                      'wallet_id': fromId,
                                      'wallet_name': _currentWallet['name'],
                                      'transaction_date': today,
                                      'note': 'Biaya admin transfer ke ${targetW['name']}',
                                      'group_id': groupId,
                                      'user_id': userId,
                                    });
                                  }

                                  await supabase.from('transactions').insert(records);

                                  if (modalContext.mounted) {
                                    Navigator.pop(modalContext);
                                  }

                                  _hasChanges = true;
                                  _fetchWalletDetailData();

                                  if (mounted) {
                                    CustomNotification.show(context, 'Transfer Berhasil!');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    NetworkHelper.handleSupabaseError(context, e, prefix: 'Transfer gagal');
                                  }
                                } finally {
                                  if (modalContext.mounted) {
                                    setModalState(() => isProcessingTransfer = false);
                                  }
                                }
                              },
                        icon: isProcessingTransfer
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const FaIcon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 16),
                        label: Text(
                          isProcessingTransfer ? 'Memproses...' : 'Konfirmasi Transfer',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
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

  Future<void> _deleteTransaction(Map<String, dynamic> tx) async {
    bool isTransfer = tx['is_transfer'] == true;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(isTransfer
            ? 'Hapus riwayat transfer ini? Saldo kedua dompet akan otomatis disesuaikan kembali.'
            : 'Data transaksi ini akan dihapus permanen dan saldo dompet akan diperbarui.'),
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

    if (confirm != true) return;
    if (!mounted) return;

    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted || !hasConnection) return;

    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      int mainId = tx['id'];
      final groupId = tx['group_id']?.toString();
      if (isTransfer && groupId != null && groupId.isNotEmpty) {
        await supabase.from('transactions').delete().eq('group_id', groupId).eq('user_id', userId);
      } else if (isTransfer && tx['partner_id'] != null) {
        int partnerId = tx['partner_id'];
        await supabase.from('transactions').delete().eq('id', mainId).eq('user_id', userId);
        await supabase.from('transactions').delete().eq('id', partnerId).eq('user_id', userId);
      } else {
        await supabase.from('transactions').delete().eq('id', mainId).eq('user_id', userId);
      }

      _hasChanges = true;
      _fetchWalletDetailData();
      if (mounted) CustomNotification.show(context, 'Transaksi berhasil dihapus.');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal menghapus');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final bodyColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        appBar: SubAppBar(
          title: _currentWallet['name'],
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 18),
              tooltip: 'Edit Dompet',
              onPressed: _showEditWalletModal,
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.trashCan, size: 18, color: Colors.redAccent),
              tooltip: 'Hapus Dompet',
              onPressed: _deleteWallet,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchWalletDetailData,
          color: AppColors.primaryGreen,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWalletHeaderCard(isDarkMode),
                      const SizedBox(height: 16),
                      _buildQuickActionButtons(),
                      const SizedBox(height: 20),
                      _buildStatisticalCards(isDarkMode),
                      const SizedBox(height: 24),
                      _buildTimeFilterSection(isDarkMode),
                      const SizedBox(height: 14),
                      _buildTypeFilterChips(isDarkMode),
                      const SizedBox(height: 14),
                      _buildSearchBar(isDarkMode),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Riwayat Mutasi (${_filteredTransactions.length})',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: bodyColor),
                          ),
                          if (_selectedTimeFilter == 'Kustom' && _customDateRange != null)
                            Text(
                              "${DateFormat('dd MMM', 'id').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy', 'id').format(_customDateRange!.end)}",
                              style: const TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTransactionList(isDarkMode, cardColor, bodyColor),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWalletHeaderCard(bool isDarkMode) {
    Color walletColor = _currentWallet['color'] as Color? ?? AppColors.primaryGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [walletColor, walletColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: walletColor.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _currentWallet['icon'] ?? const FaIcon(FontAwesomeIcons.wallet, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentWallet['name'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentWallet['subtitle'] ?? 'Dompet',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Saldo Dompet', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(_calculatedBalance),
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showTransferSheet,
            icon: const FaIcon(FontAwesomeIcons.rightLeft, size: 14, color: Colors.white),
            label: const Text('Transfer Saldo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showEditWalletModal,
            icon: const FaIcon(FontAwesomeIcons.pen, size: 13, color: AppColors.primaryGreen),
            label: const Text('Edit Saldo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticalCards(bool isDarkMode) {
    Color cardBg = isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    Color borderC = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderC),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(FontAwesomeIcons.arrowDown, color: Colors.green, size: 11),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Pemasukan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCurrency(_totalIncome),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderC),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(FontAwesomeIcons.arrowUp, color: Colors.red, size: 11),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Pengeluaran',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCurrency(_totalExpense),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderC),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(FontAwesomeIcons.chartLine, color: Colors.blue, size: 11),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Arus Kas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCurrency(_netFlow, showSign: true),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _netFlow >= 0 ? AppColors.primaryGreen : Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFilterSection(bool isDarkMode) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeFilters.length,
        itemBuilder: (context, index) {
          final filter = _timeFilters[index];
          final isSelected = _selectedTimeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
              ),
              selectedColor: AppColors.primaryGreen,
              backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
              onSelected: (bool selected) {
                if (filter == 'Kustom') {
                  _pickCustomDateRange();
                } else {
                  setState(() {
                    _selectedTimeFilter = filter;
                    _applyFiltersAndCalculateTotals();
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeFilterChips(bool isDarkMode) {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _typeFilters.length,
        itemBuilder: (context, index) {
          final type = _typeFilters[index];
          final isSelected = _selectedTypeFilter == type;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
              ),
              selectedColor: isDarkMode ? Colors.teal.shade700 : AppColors.primaryGreen.withValues(alpha: 0.85),
              backgroundColor: isDarkMode ? Colors.white10 : Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
              onSelected: (bool selected) {
                setState(() {
                  _selectedTypeFilter = type;
                  _applyFiltersAndCalculateTotals();
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Cari transaksi di dompet ini...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _applyFiltersAndCalculateTotals();
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
            _applyFiltersAndCalculateTotals();
          });
        },
      ),
    );
  }

  Widget _buildTransactionList(bool isDarkMode, Color cardColor, Color bodyColor) {
    if (_filteredTransactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada transaksi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Belum ada mutasi yang tercatat untuk filter ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final tx = _filteredTransactions[index];
        return _buildTransactionItem(tx, isDarkMode, cardColor, bodyColor);
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx, bool isDarkMode, Color cardColor, Color bodyColor) {
    int amount = int.tryParse(tx['amount'].toString()) ?? 0;
    bool isExpense = tx['is_expense'] == true;
    bool isTransfer = tx['is_transfer'] == true;
    String category = tx['category']?.toString() ?? 'Lainnya';
    String note = tx['note']?.toString() ?? '';
    String direction = tx['transfer_direction']?.toString() ?? '';
    String partnerWalletName = tx['partner_wallet_name']?.toString() ?? 'Dompet Lain';

    String title;
    String subtitle;
    dynamic icon;
    Color iconBgColor;
    Color amountColor;
    String amountText;

    String dateFormatted = '-';
    try {
      dateFormatted = DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(tx['transaction_date']));
    } catch (_) {}

    if (isTransfer) {
      if (direction == 'out') {
        title = 'Transfer ke $partnerWalletName';
        subtitle = note.isNotEmpty ? '$dateFormatted • $note' : '$dateFormatted • Transfer Keluar';
        icon = FontAwesomeIcons.arrowRight;
        iconBgColor = Colors.red.withValues(alpha: 0.12);
        amountColor = Colors.red;
        amountText = '- ${_formatCurrency(amount)}';
      } else {
        title = 'Transfer dari $partnerWalletName';
        subtitle = note.isNotEmpty ? '$dateFormatted • $note' : '$dateFormatted • Transfer Masuk';
        icon = FontAwesomeIcons.arrowLeft;
        iconBgColor = Colors.green.withValues(alpha: 0.12);
        amountColor = Colors.green;
        amountText = '+ ${_formatCurrency(amount)}';
      }
    } else {
      title = category;
      subtitle = note.isNotEmpty ? '$dateFormatted • $note' : dateFormatted;
      icon = CategoryHelper.getIcon(category, customIcons: _customIcons);
      Color catColor = CategoryHelper.getColor(category, customIcons: _customIcons);
      iconBgColor = catColor.withValues(alpha: 0.15);

      if (isExpense) {
        amountColor = Colors.red;
        amountText = '- ${_formatCurrency(amount)}';
      } else {
        amountColor = AppColors.primaryGreen;
        amountText = '+ ${_formatCurrency(amount)}';
      }
    }

    return Dismissible(
      key: Key('tx_${tx['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.white, size: 18),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Hapus Transaksi?', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(isTransfer
                ? 'Hapus mutasi transfer ini? Saldo kedua dompet akan dikembalikan.'
                : 'Data transaksi ini akan dihapus permanen.'),
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
      },
      onDismissed: (direction) {
        _deleteTransaction(tx);
      },
      child: InkWell(
        onTap: () async {
          if (isTransfer) {
            CustomNotification.show(context, 'Transaksi transfer dapat diedit melalui menu Transfer.', isWarning: true);
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditTransactionScreen(transaction: tx)),
          );

          if (result is String || result == true) {
            _hasChanges = true;
            _fetchWalletDetailData();
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(icon, size: 16, color: isExpense ? Colors.red : (isTransfer ? Colors.green : AppColors.primaryGreen)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: bodyColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amountText,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: amountColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
