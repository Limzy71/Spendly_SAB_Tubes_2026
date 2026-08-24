import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';
import 'add_wallet_screen.dart';
import 'wallet_detail_screen.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/wallet_helper.dart';
import '../../../widgets/network_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _adminFeeController.dispose();
    _noteController.dispose();
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

      final today = DateTime.now().toIso8601String().split('T')[0];
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
        final selectableWallets = _wallets
            .where((w) => isFromAccount ? w['id'] != selectedToAccountId : w['id'] != selectedFromAccountId)
            .toList();

        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    isFromAccount ? 'Pilih Dompet Asal' : 'Pilih Dompet Tujuan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
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
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, size: 42, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Tidak ada dompet tujuan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text(
                          'Buat dompet lain dulu supaya transfer antar dompet bisa dipilih.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: selectableWallets.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 24, endIndent: 24),
                      itemBuilder: (context, index) {
                        final wallet = selectableWallets[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isFromAccount) {
                                selectedFromAccountId = wallet['id'];
                              } else {
                                selectedToAccountId = wallet['id'];
                              }
                            });
                            Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(wallet['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(_formatCurrency(wallet['balance']), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _wallets.length,
                    itemBuilder: (context, index) {
                      return _buildWalletItem(
                        wallet: _wallets[index],
                        isDarkMode: isDarkMode,
                      );
                    },
                  ),
                ),

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

              Builder(builder: (context) {
                final cleanAmt = _amountController.text.replaceAll('.', '');
                final cleanFee = _adminFeeController.text.replaceAll('.', '');
                final int amtVal = int.tryParse(cleanAmt) ?? 0;
                final int feeVal = int.tryParse(cleanFee) ?? 0;
                final int totalDeduction = amtVal + feeVal;

                if (amtVal > 0) {
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Nominal Transfer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_formatCurrency(amtVal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (feeVal > 0) ...[
                          const SizedBox(height: 6),
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
                            Text('Total Potongan ($fromWalletName)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(
                              _formatCurrency(totalDeduction),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: wallet['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)
              ),
              child: wallet['icon'],
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