import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';
import 'edit_transaction_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  final String filterType;

  const AllTransactionsScreen({Key? key, this.filterType = 'all'}) : super(key: key);

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  // PERBAIKAN: Menambahkan filter 'Tahun Ini' dan 'Kustom'
  String _selectedTimeFilter = 'Bulan Ini';
  final List<String> _timeFilters = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini', 'Semua Waktu'];
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _fetchAllTransactions();
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
    setState(() => _isLoading = true);

    try {
      final walletResponse = await supabase.from('wallets').select();
      Map<int, Map<String, dynamic>> walletData = {};
      for (var w in walletResponse) {
        walletData[w['id'] as int] = {'name': w['name'].toString()};
      }

      final txResponse = await supabase
          .from('transactions')
          .select()
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> displayTx = [];
      Set<int> processedIds = {};

      // Konfigurasi rentang tanggal
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
        startDate = null; // Semua Waktu
        endDate = null;
      }

      for (var tx in txResponse) {
        int id = tx['id'] as int;
        if (processedIds.contains(id)) continue;

        int amount = tx['amount'] as int;
        bool isExpense = tx['is_expense'] as bool;
        int walletId = tx['wallet_id'] as int;
        String category = tx['category']?.toString() ?? '';
        DateTime txDate = DateTime.parse(tx['transaction_date']);

        if (widget.filterType == 'income' && (isExpense || category.toLowerCase() == 'transfer')) continue;
        if (widget.filterType == 'expense' && (!isExpense || category.toLowerCase() == 'transfer')) continue;

        // Terapkan filter tanggal
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
                !processedIds.contains(t['id'] as int),
            orElse: () => <String, dynamic>{},
          );

          var mergedTx = Map<String, dynamic>.from(tx);
          if (isExpense) {
            mergedTx['from_wallet'] = walletData[walletId]?['name'] ?? 'Dompet';
            mergedTx['to_wallet'] = partner.isNotEmpty ? (walletData[partner['wallet_id']]?['name'] ?? 'Dompet') : 'Dompet';
          } else {
            mergedTx['to_wallet'] = walletData[walletId]?['name'] ?? 'Dompet';
            mergedTx['from_wallet'] = partner.isNotEmpty ? (walletData[partner['wallet_id']]?['name'] ?? 'Dompet') : 'Dompet';
          }

          displayTx.add(mergedTx);
          processedIds.add(id);
          if (partner.isNotEmpty) processedIds.add(partner['id'] as int);
        } else {
          var mergedTx = Map<String, dynamic>.from(tx);
          mergedTx['wallet_name'] = walletData[walletId]?['name'] ?? 'Dompet';
          displayTx.add(mergedTx);
          processedIds.add(id);
        }
      }

      if (mounted) {
        setState(() {
          _transactions = displayTx;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
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

    return Scaffold(
      appBar: SubAppBar(title: _getAppBarTitle()),
      body: Column(
        children: [
          // Bagian Chips Filter Waktu
          SingleChildScrollView(
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
                // Tombol Kustom Tanggal (Ikon Kalender)
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

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _transactions.isEmpty
                ? Center(child: Text(
              widget.filterType == 'income' ? "Belum ada pemasukan di periode ini." :
              widget.filterType == 'expense' ? "Belum ada pengeluaran di periode ini." :
              "Belum ada riwayat transaksi di periode ini.",
              style: const TextStyle(color: Colors.grey),
            ))
                : ListView.builder(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
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
    bool isExpense = tx['is_expense'] as bool;

    Color amountColor = isTransfer ? Colors.blue : (isExpense ? Colors.red : AppColors.primaryGreen);
    Color bgIconColor = amountColor.withValues(alpha: 0.1);

    dynamic icon = isTransfer ? FontAwesomeIcons.rightLeft : _getIconForCategory(tx['category']);

    String note = tx['note'] ?? '';
    String title = isTransfer ? "Transfer" : (tx['category'] ?? "Lainnya");

    String walletNameStr = tx['wallet_name'] != null ? "  |  ${tx['wallet_name']}" : "";
    String subtitle = "${_formatDate(tx['transaction_date'] ?? "")}$walletNameStr";
    String transferPath = isTransfer ? "${tx['from_wallet']} → ${tx['to_wallet']}" : "";

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditTransactionScreen(transaction: tx)));
        if (result == true) _fetchAllTransactions();
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
    );
  }

  dynamic _getIconForCategory(String? category) {
    if (category == null) return FontAwesomeIcons.fileInvoice;
    switch (category.toLowerCase()) {
      case 'makanan': return FontAwesomeIcons.utensils;
      case 'transportasi': return FontAwesomeIcons.car;
      case 'belanja': return FontAwesomeIcons.bagShopping;
      case 'gaji': return FontAwesomeIcons.moneyBillWave;
      case 'bonus': return FontAwesomeIcons.gift;
      case 'investasi': return FontAwesomeIcons.arrowTrendUp;
      case 'tagihan': return FontAwesomeIcons.fileInvoiceDollar;
      case 'hiburan': return FontAwesomeIcons.film;
      default: return FontAwesomeIcons.boxArchive;
    }
  }
}