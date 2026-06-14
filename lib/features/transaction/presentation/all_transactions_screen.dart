import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';
import 'edit_transaction_screen.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/category_helper.dart';
import '../../../../widgets/network_helper.dart';

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
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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

      loadCustomIcons('custom_transaction_expense_categories', 'custom_transaction_expense_icon_');
      loadCustomIcons('custom_transaction_income_categories', 'custom_transaction_income_icon_');
      loadCustomIcons('custom_budget_categories', 'custom_budget_icon_');

      final walletResponse = await supabase.from('wallets').select().eq('user_id', userId);
      Map<int, Map<String, dynamic>> walletData = {};
      for (var w in walletResponse) {
        walletData[w['id'] as int] = {'name': w['name'].toString()};
      }

      final txResponse = await supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

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
        int id = tx['id'] as int? ?? 0;
        if (processedIds.contains(id)) continue;

        int amount = tx['amount'] as int? ?? 0;
        bool isExpense = tx['is_expense'] as bool? ?? false;
        String category = tx['category']?.toString() ?? '';
        DateTime txDate = DateTime.parse(tx['transaction_date']);

        if (widget.filterType == 'income' && (isExpense || category.toLowerCase() == 'transfer')) continue;
        if (widget.filterType == 'expense' && (!isExpense || category.toLowerCase() == 'transfer')) continue;

        if (startDate != null && endDate != null) {
          if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) {
            continue;
          }
        }

        if (category.toLowerCase() == 'transfer') {
          final partner = txResponse.firstWhere(
                (t) => t['category']?.toString().toLowerCase() == 'transfer' &&
                t['amount'] == amount &&
                t['is_expense'] != isExpense &&
                !processedIds.contains(int.tryParse(t['id'].toString()) ?? -1),
            orElse: () => <String, dynamic>{},
          );

          var mergedTx = Map<String, dynamic>.from(tx);
          if (isExpense) {
            mergedTx['from_wallet'] = getWalletName(tx);
            mergedTx['to_wallet'] = partner.isNotEmpty ? getWalletName(partner) : 'Dompet (Dihapus)';
          } else {
            mergedTx['to_wallet'] = getWalletName(tx);
            mergedTx['from_wallet'] = partner.isNotEmpty ? getWalletName(partner) : 'Dompet (Dihapus)';
          }

          mergedTx['partner_id'] = partner.isNotEmpty ? partner['id'] : null;

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
        title: const Text('Hapus Transaksi?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(isTransfer
            ? 'Hapus riwayat transfer ini? Saldo yang dipindahkan akan otomatis dikembalikan ke dompet asal.'
            : 'Data pengeluaran/pemasukan ini akan dihapus secara permanen dan saldo akan disesuaikan.'),
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

      if (isTransfer && tx['partner_id'] != null) {
        int partnerId = tx['partner_id'];
        await supabase.from('transactions').delete().eq('id', mainId).eq('user_id', userId);
        await supabase.from('transactions').delete().eq('id', partnerId).eq('user_id', userId);
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

  String _formatCurrency(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

  String _formatDate(String dateString) {
    try { return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(dateString)); }
    catch (e) { return dateString; }
  }

  String _getAppBarTitle() {
    if (widget.filterType == 'income') return 'Riwayat Pemasukan';
    if (widget.filterType == 'expense') return 'Riwayat Pengeluaran';
    return 'Semua Transaksi';
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    final filteredList = _transactions.where((tx) {
      if (_searchQuery.isEmpty) return true;
      final note = (tx['note'] ?? '').toString().toLowerCase();
      final cat = (tx['category'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return note.contains(q) || cat.contains(q);
    }).toList();

    return Scaffold(
      appBar: SubAppBar(title: _getAppBarTitle()),
      body: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              scrollbarTheme: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(Colors.transparent),
                trackColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTimeFilter == 'Kustom' ? AppColors.primaryGreen : (isDark ? Colors.white12 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          FaIcon(
                              FontAwesomeIcons.calendarDays,
                              size: 14,
                              color: _selectedTimeFilter == 'Kustom' ? Colors.white : (isDark ? Colors.white70 : Colors.black87)
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
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari catatan atau kategori...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : filteredList.isEmpty
                ? Center(child: Text(
              _searchQuery.isNotEmpty ? "Tidak ada transaksi yang cocok." :
              widget.filterType == 'income' ? "Belum ada pemasukan di periode ini." :
              widget.filterType == 'expense' ? "Belum ada pengeluaran di periode ini." :
              "Belum ada riwayat transaksi di periode ini.",
              style: const TextStyle(color: Colors.grey),
            ))
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

  Widget _buildTransactionItem(Map<String, dynamic> tx, Color textColor, bool isDark) {
    bool isTransfer = tx['category']?.toString().toLowerCase() == 'transfer';
    bool isExpense = tx['is_expense'] as bool? ?? false;

    Color amountColor = isTransfer ? Colors.blue : (isExpense ? Colors.red : AppColors.primaryGreen);
    Color bgIconColor = amountColor.withValues(alpha: 0.1);

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
            CustomNotification.show(context, 'Transfer tidak bisa diedit. Tahan atau geser ke kiri untuk menghapus.', isWarning: true);
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
                  child: FaIcon(icon, color: amountColor, size: 20)
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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