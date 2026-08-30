import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';
import 'add_wallet_screen.dart';
import 'wallet_detail_screen.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/wallet_helper.dart';
import '../../../widgets/network_helper.dart';
import '../../../widgets/date_helper.dart';
import '../../../widgets/spendly_date_picker.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  int _totalBalance = 0;
  List<Map<String, dynamic>> _wallets = [];

  int? selectedFromAccountId;
  int? selectedToAccountId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _adminFeeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isTransferring = false;
  DateTime _transferDate = DateTime.now();
  bool _isWalletListExpanded = false;
  String _walletSearchQuery = '';
  final TextEditingController _walletSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _fetchWalletData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _adminFeeController.dispose();
    _noteController.dispose();
    _walletSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
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

      final walletResponse = await supabase.from('wallets').select().eq('user_id', userId).order('id');
      final txResponse = await supabase.from('transactions').select().eq('user_id', userId);

      int grandTotal = 0;
      List<Map<String, dynamic>> processedWallets = [];

      for (var w in walletResponse) {
        int wId = int.tryParse(w['id'].toString()) ?? -1;
        String wName = w['name'].toString();
        int currentBal = int.tryParse(w['balance'].toString()) ?? 0;
        String? iconName = w['icon_name']?.toString();

        for (var tx in txResponse) {
          int txWalletId = int.tryParse(tx['wallet_id'].toString()) ?? -1;
          if (txWalletId == wId) {
            int txAmount = int.tryParse(tx['amount'].toString()) ?? 0;
            if (tx['is_expense'] == true) {
              currentBal -= txAmount;
            } else {
              currentBal += txAmount;
            }
          }
        }

        grandTotal += currentBal;
        processedWallets.add({
          'id': wId,
          'name': wName,
          'balance': currentBal,
          'subtitle': WalletHelper.getSubtitle(wName),
          'icon': WalletHelper.getIcon(iconName, wName, color: WalletHelper.getColor(wName), size: 16),
          'color': WalletHelper.getColor(wName),
        });
      }

      processedWallets.sort((a, b) => (b['balance'] as int).compareTo(a['balance'] as int));

      if (mounted) {
        setState(() {
          _wallets = processedWallets;
          _totalBalance = grandTotal;
          if (!_wallets.any((w) => w['id'] == selectedFromAccountId)) selectedFromAccountId = null;
          if (!_wallets.any((w) => w['id'] == selectedToAccountId)) selectedToAccountId = null;
        });
      }
    } catch (e) {
      if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal mengambil data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processTransfer() async {
    if (selectedFromAccountId == null || selectedToAccountId == null) {
      CustomNotification.show(context, 'Pilih dompet asal dan tujuan!', isWarning: true);
      return;
    }
    if (_amountController.text.isEmpty || _amountController.text == '0') {
      CustomNotification.show(context, 'Nominal transfer wajib diisi!', isWarning: true);
      return;
    }

    final cleanAmount = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(cleanAmount) ?? 0;

    final cleanAdminFee = _adminFeeController.text.replaceAll('.', '');
    final adminFee = int.tryParse(cleanAdminFee) ?? 0;
    final totalDeduction = amount + adminFee;

    final fromWallet = _wallets.firstWhere((w) => w['id'] == selectedFromAccountId);
    final toWallet = _wallets.firstWhere((w) => w['id'] == selectedToAccountId);

    if (totalDeduction > fromWallet['balance']) {
      CustomNotification.show(
        context,
        adminFee > 0
            ? 'Gagal: Saldo tidak mencukupi untuk transfer & biaya admin (Total: ${_formatCurrency(totalDeduction)})!'
            : 'Gagal: Saldo dompet asal tidak mencukupi!',
        isError: true,
      );
      return;
    }

    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!hasConnection) return;

    setState(() => _isTransferring = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final today = _transferDate.toIso8601String().split('T')[0];
      final note = _noteController.text.isNotEmpty ? _noteController.text : 'Transfer Internal';
      final groupId = DateTime.now().microsecondsSinceEpoch.toString();

      final List<Map<String, dynamic>> records = [
        {
          'amount': amount,
          'is_expense': true,
          'category': 'Transfer',
          'wallet_id': selectedFromAccountId,
          'wallet_name': fromWallet['name'],
          'transaction_date': today,
          'note': note,
          'group_id': groupId,
          'user_id': userId,
        },
        {
          'amount': amount,
          'is_expense': false,
          'category': 'Transfer',
          'wallet_id': selectedToAccountId,
          'wallet_name': toWallet['name'],
          'transaction_date': today,
          'note': note,
          'group_id': groupId,
          'user_id': userId,
        }
      ];

      if (adminFee > 0) {
        records.add({
          'amount': adminFee,
          'is_expense': true,
          'category': 'Biaya Admin',
          'wallet_id': selectedFromAccountId,
          'wallet_name': fromWallet['name'],
          'transaction_date': today,
          'note': 'Biaya admin transfer ke ${toWallet['name']}',
          'group_id': groupId,
          'user_id': userId,
        });
      }

      await supabase.from('transactions').insert(records);

      if (mounted) {
        CustomNotification.show(context, 'Transfer Berhasil!');
        _amountController.clear();
        _adminFeeController.clear();
        _noteController.clear();
        setState(() => _transferDate = DateTime.now());
        _fetchWalletData();
      }
    } catch (e) {
      if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Transfer gagal');
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  void _showWalletSelector({required bool isFromAccount}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isSheetDark = Theme.of(ctx).brightness == Brightness.dark;
            final Color sheetTextColor = Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black87;

            final selectableWallets = _wallets
                .where((w) => isFromAccount ? w['id'] != selectedToAccountId : w['id'] != selectedFromAccountId)
                .where((w) {
                  if (searchQuery.trim().isEmpty) return true;
                  return w['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
                })
                .toList();

            final currentSelectedId = isFromAccount ? selectedFromAccountId : selectedToAccountId;

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
                          Text(
                            isFromAccount ? 'Pilih Dompet Asal' : 'Pilih Dompet Tujuan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sheetTextColor),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: sheetTextColor),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    if (_wallets.length > 5) ...[
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
                          onChanged: (query) => setSheetState(() => searchQuery = query),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (_wallets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 42, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Belum ada dompet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            SizedBox(height: 6),
                            Text(
                              'Tambahkan dompet terlebih dahulu agar transfer bisa dilakukan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else if (selectableWallets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Dompet tidak ditemukan', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: selectableWallets.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
                          itemBuilder: (context, index) {
                            final wallet = selectableWallets[index];
                            final wId = wallet['id'];
                            final isSelected = wId == currentSelectedId;
                            final wName = wallet['name'].toString();
                            final wColor = WalletHelper.getColor(wName);
                            final int balance = int.tryParse(wallet['balance']?.toString() ?? '0') ?? 0;

                            return ListTile(
                              dense: true,
                              onTap: () {
                                setState(() {
                                  if (isFromAccount) {
                                    selectedFromAccountId = wId;
                                  } else {
                                    selectedToAccountId = wId;
                                  }
                                });
                                Navigator.pop(ctx);
                              },
                              leading: SizedBox(
                                width: 32,
                                height: 32,
                                child: Center(
                                  child: WalletHelper.getIcon(wallet['icon_name']?.toString(), wName, color: wColor, size: 14),
                                ),
                              ),
                              title: Text(
                                wName,
                                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14, color: sheetTextColor),
                              ),
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

  String _formatCurrency(int amount) {
    bool isNegative = amount < 0;
    int absAmount = amount.abs();

    if (absAmount >= 1000000000000000) {
      return isNegative ? '-Rp 999 T+' : 'Rp 999 T+';
    } else if (absAmount >= 1000000000000) {
      double inT = absAmount / 1000000000000;
      String formatted = inT.toStringAsFixed(2).replaceAll('.', ',');
      if (formatted.endsWith(',00')) {
        formatted = formatted.substring(0, formatted.length - 3);
      }
      return isNegative ? '-Rp $formatted T' : 'Rp $formatted T';
    }

    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        color: AppColors.primaryGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Saldo', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(_formatCurrency(_totalBalance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Tersedia', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar Dompet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddWalletScreen()),
                      );
                      if (result == true) {
                        _fetchWalletData();
                      }
                    },
                    icon: const FaIcon(FontAwesomeIcons.circlePlus, color: AppColors.primaryGreen, size: 16),
                    label: const Text('Tambah', style: TextStyle(color: AppColors.primaryGreen)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_wallets.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text("Belum ada dompet terdaftar.")))
              else ...[
                if (_wallets.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _walletSearchController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari dari ${_wallets.length} dompet...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                        suffixIcon: _walletSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                onPressed: () {
                                  _walletSearchController.clear();
                                  setState(() => _walletSearchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setState(() => _walletSearchQuery = val),
                    ),
                  ),

                Builder(builder: (context) {
                  final filteredWallets = _wallets.where((w) {
                    if (_walletSearchQuery.trim().isEmpty) return true;
                    return w['name'].toString().toLowerCase().contains(_walletSearchQuery.toLowerCase());
                  }).toList();

                  if (filteredWallets.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('Dompet tidak ditemukan', style: TextStyle(color: Colors.grey, fontSize: 13))),
                    );
                  }

                  final List<Map<String, dynamic>> displayedWallets = (_walletSearchQuery.isNotEmpty || _isWalletListExpanded || filteredWallets.length <= 4)
                      ? filteredWallets
                      : filteredWallets.take(4).toList();

                  return Column(
                    children: [
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedWallets.length,
                        itemBuilder: (context, index) {
                          return _buildWalletItem(
                            wallet: displayedWallets[index],
                            isDarkMode: isDarkMode,
                          );
                        },
                      ),
                      if (_wallets.length > 4 && _walletSearchQuery.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _isWalletListExpanded = !_isWalletListExpanded),
                              icon: FaIcon(
                                _isWalletListExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                                size: 11,
                                color: AppColors.primaryGreen,
                              ),
                              label: Text(
                                _isWalletListExpanded ? 'Tampilkan Lebih Sedikit' : 'Lihat Semua Dompet (${_wallets.length})',
                                style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],

              const SizedBox(height: 12),
              Divider(thickness: 1, color: isDarkMode ? Colors.white12 : const Color(0xFFEEEEEE)),
              const SizedBox(height: 16),

              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.rightLeft, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transfer Antar Dompet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        const Text('Pindahkan saldo antar dompet Anda.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.teal.withValues(alpha: 0.1) : const Color(0xFFF1FAF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.circleInfo, color: AppColors.primaryGreen, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Transfer internal ini akan dicatat dalam riwayat transaksi Anda untuk pelacakan.', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black87))),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildFormLabel('Dari Dompet'),
              InkWell(
                onTap: () => _showWalletSelector(isFromAccount: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedFromAccountId == null
                              ? "Pilih Dompet Asal"
                              : _wallets.firstWhere((w) => w['id'] == selectedFromAccountId, orElse: () => {'name': 'Pilih Dompet Asal'})['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: selectedFromAccountId == null ? Colors.grey.shade500 : textColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildFormLabel('Ke Dompet'),
              InkWell(
                onTap: () => _showWalletSelector(isFromAccount: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedToAccountId == null
                              ? "Pilih Dompet Tujuan"
                              : _wallets.firstWhere((w) => w['id'] == selectedToAccountId, orElse: () => {'name': 'Pilih Dompet Tujuan'})['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: selectedToAccountId == null ? Colors.grey.shade500 : textColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildFormLabel('Nominal'),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [LengthLimitingTextInputFormatter(18)],
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  prefixIcon: Padding(padding: const EdgeInsets.only(left: 16.0, right: 8.0), child: Text('Rp', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16))),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    String clean = value.replaceAll('.', '');
                    if (clean.startsWith('0') && clean.length > 1) {
                      clean = clean.replaceFirst(RegExp(r'^0+'), '');
                      if (clean.isEmpty) clean = '0';
                    }
                    String formatted = NumberFormat.decimalPattern('id').format(int.tryParse(clean) ?? 0);
                    _amountController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                  }
                },
              ),
              const SizedBox(height: 16),

              _buildFormLabel('Biaya Admin (Opsional)'),
              TextFormField(
                controller: _adminFeeController,
                keyboardType: TextInputType.number,
                inputFormatters: [LengthLimitingTextInputFormatter(18)],
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Text('Rp', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    String clean = value.replaceAll('.', '');
                    if (clean.startsWith('0') && clean.length > 1) {
                      clean = clean.replaceFirst(RegExp(r'^0+'), '');
                      if (clean.isEmpty) clean = '0';
                    }
                    String formatted = NumberFormat.decimalPattern('id').format(int.tryParse(clean) ?? 0);
                    _adminFeeController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              _buildFormLabel('Tanggal Transfer'),
              const SizedBox(height: 8),
              InkWell(
                  onTap: () async {
                    DateTime? picked = await SpendlyDatePicker.show(
                    context,
                    initialDate: _transferDate,
                    firstDate: DateHelper.minDate,
                    lastDate: DateHelper.nextMonthEnd(),
                  );
                  if (picked != null) {
                    setState(() => _transferDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.calendarDays, size: 14, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd MMMM yyyy', 'id').format(_transferDate),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Builder(builder: (context) {
                final cleanAmt = _amountController.text.replaceAll('.', '');
                final cleanFee = _adminFeeController.text.replaceAll('.', '');
                final int amtVal = int.tryParse(cleanAmt) ?? 0;
                final int feeVal = int.tryParse(cleanFee) ?? 0;
                final int totalDeduction = amtVal + feeVal;

                // Hanya tampilkan kotak rincian jika ada biaya admin agar tidak membingungkan pengguna
                if (amtVal > 0 && feeVal > 0) {
                  final fromWallet = _wallets.firstWhere((w) => w['id'] == selectedFromAccountId, orElse: () => <String, dynamic>{});
                  final fromWalletName = fromWallet.isNotEmpty ? fromWallet['name'] : 'Dompet Asal';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rincian Potongan Saldo ($fromWalletName):', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Nominal Transfer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_formatCurrency(amtVal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Biaya Admin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('+ ${_formatCurrency(feeVal)}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Saldo Berkurang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            Text(
                              _formatCurrency(totalDeduction),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              _buildFormLabel('Catatan'),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Tambah keterangan (opsional)...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTransferring ? null : _processTransfer,
                  icon: _isTransferring ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const FaIcon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 16),
                  label: Text(_isTransferring ? 'Memproses...' : 'Konfirmasi Transfer', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletItem({required Map<String, dynamic> wallet, required bool isDarkMode}) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WalletDetailScreen(
              wallet: wallet,
              allWallets: _wallets,
            ),
          ),
        );
        if (result == true) {
          _fetchWalletData();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.shade200)
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: wallet['icon'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wallet['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 2),
                  Text(wallet['subtitle'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_formatCurrency(wallet['balance']), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}