import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../transaction/presentation/edit_transaction_screen.dart';
import '../../transaction/presentation/all_transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  int _totalIncome = 0;
  int _totalExpense = 0;
  int _totalBalance = 0;

  int _tunaiBalance = 0;
  int _bankBalance = 0;
  int _ewalletBalance = 0;

  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final walletResponse = await supabase.from('wallets').select();
      Map<int, Map<String, dynamic>> walletData = {};
      for (var w in walletResponse) {
        walletData[w['id'] as int] = {
          'name': w['name'].toString(),
          'balance': w['balance'] as int,
        };
      }

      final txResponse = await supabase
          .from('transactions')
          .select()
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      int tempIncome = 0;
      int tempExpense = 0;

      for (var tx in txResponse) {
        int amount = tx['amount'] as int;
        bool isExpense = tx['is_expense'] as bool;
        int walletId = tx['wallet_id'] as int;
        String category = tx['category']?.toString() ?? '';

        if (isExpense) {
          if (walletData.containsKey(walletId)) walletData[walletId]!['balance'] -= amount;
        } else {
          if (walletData.containsKey(walletId)) walletData[walletId]!['balance'] += amount;
        }

        if (category.toLowerCase() != 'transfer') {
          if (isExpense) {
            tempExpense += amount;
          } else {
            tempIncome += amount;
          }
        }
      }

      List<Map<String, dynamic>> displayTx = [];
      Set<int> processedIds = {};

      for (var tx in txResponse) {
        int id = tx['id'] as int;
        if (processedIds.contains(id)) continue;

        int amount = tx['amount'] as int;
        bool isExpense = tx['is_expense'] as bool;
        int walletId = tx['wallet_id'] as int;
        String category = tx['category']?.toString() ?? '';

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

      int grandTotal = 0;
      int tempTunai = 0, tempBank = 0, tempEwallet = 0;

      walletData.forEach((id, data) {
        String name = data['name'].toLowerCase();
        int bal = data['balance'];
        grandTotal += bal;
        if (name.contains('tunai')) { tempTunai += bal; }
        else if (name.contains('gopay') || name.contains('ovo') || name.contains('dana')) { tempEwallet += bal; }
        else { tempBank += bal; }
      });

      if (mounted) {
        setState(() {
          _totalIncome = tempIncome;
          _totalExpense = tempExpense;
          _totalBalance = grandTotal;
          _tunaiBalance = tempTunai;
          _bankBalance = tempBank;
          _ewalletBalance = tempEwallet;
          _recentTransactions = displayTx.take(5).toList();
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

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _formatShortCurrency(int amount) {
    if (amount == 0) return "0";
    return NumberFormat.decimalPattern('id').format(amount);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'id').format(date);
    } catch (e) { return dateString; }
  }

  @override
  Widget build(BuildContext context) {
    bool hasTransactions = _recentTransactions.isNotEmpty;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: AppColors.primaryGreen,
        child: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (OverscrollIndicatorNotification overscroll) {
            overscroll.disallowIndicator();
            return true;
          },
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text("Selamat Pagi,", style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text("Budi Santoso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor)),
                const SizedBox(height: 16),
                _buildBalanceCard(context, AppColors.primaryGreen, hasTransactions),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const AllTransactionsScreen(filterType: 'income')));
                            _fetchDashboardData();
                          },
                          child: _buildSummaryCard(context, title: "Pemasukan", amount: _formatCurrency(_totalIncome), indicatorColor: AppColors.primaryGreen, icon: FontAwesomeIcons.arrowTrendUp, iconBgColor: isDark ? Colors.green.withValues(alpha: 0.1) : const Color(0xFFF1FAF5)),
                        )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const AllTransactionsScreen(filterType: 'expense')));
                            _fetchDashboardData();
                          },
                          child: _buildSummaryCard(context, title: "Pengeluaran", amount: _formatCurrency(_totalExpense), indicatorColor: Colors.red, icon: FontAwesomeIcons.arrowTrendDown, iconBgColor: Colors.red.withValues(alpha: 0.1)),
                        )
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Transaksi Terakhir", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                    if (hasTransactions)
                      TextButton(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const AllTransactionsScreen()));
                            _fetchDashboardData();
                          },
                          child: const Text("Lihat Semua", style: TextStyle(color: AppColors.primaryGreen, fontSize: 13))
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (hasTransactions)
                  ..._recentTransactions.map((tx) => _buildTransactionItem(tx, textColor, isDark)).toList()
                else
                  _buildEmptyState(context, AppColors.primaryGreen),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
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

    // PERBAIKAN: Menggunakan Garis Vertikal ( | )
    String walletNameStr = tx['wallet_name'] != null ? "  |  ${tx['wallet_name']}" : "";
    String subtitle = "${_formatDate(tx['transaction_date'] ?? "")}$walletNameStr";

    String transferPath = isTransfer ? "${tx['from_wallet']} → ${tx['to_wallet']}" : "";

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditTransactionScreen(transaction: tx)));
        if (result == true) _fetchDashboardData();
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

  Widget _buildEmptyState(BuildContext context, Color primaryGreen) { return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle), child: FaIcon(FontAwesomeIcons.fileInvoice, size: 48, color: primaryGreen.withValues(alpha: 0.5))), const SizedBox(height: 24), Text("Belum ada transaksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)), const SizedBox(height: 8), const Text("Catat pengeluaran dan pemasukan\npertamamu hari ini!", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5))],)); }

  Widget _buildBalanceCard(BuildContext context, Color primaryColor, bool hasData) { return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Saldo", style: TextStyle(color: Colors.grey, fontSize: 14)), FaIcon(FontAwesomeIcons.wallet, color: primaryColor, size: 24)]), const SizedBox(height: 4), Text(_formatCurrency(_totalBalance), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _totalBalance < 0 ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color)), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: _buildMiniWalletCard(context, "Tunai", _formatShortCurrency(_tunaiBalance))), const SizedBox(width: 8), Expanded(child: _buildMiniWalletCard(context, "Bank", _formatShortCurrency(_bankBalance))), const SizedBox(width: 8), Expanded(child: _buildMiniWalletCard(context, "E-Wallet", _formatShortCurrency(_ewalletBalance)))])])); }

  Widget _buildMiniWalletCard(BuildContext context, String name, String value) { return Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE6F7ED), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 11)), const SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)))],)); }

  Widget _buildSummaryCard(BuildContext context, {required String title, required String amount, required Color indicatorColor, required dynamic icon, required Color iconBgColor}) { return Container(decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: IntrinsicHeight(child: Row(children: [Container(width: 4, color: indicatorColor), Expanded(child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle), child: FaIcon(icon, size: 12, color: indicatorColor)), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12))]), const SizedBox(height: 8), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(amount, style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold, fontSize: 16)))],),),),],),),),); }
}