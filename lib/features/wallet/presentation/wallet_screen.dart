import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';
import 'add_wallet_screen.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/wallet_helper.dart';
import '../../../widgets/network_helper.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

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
      if (userId == null) return; // Langsung lompat ke finally

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
          'icon': WalletHelper.getIcon(iconName, wName),
          'color': WalletHelper.getColor(wName),
        });
      }

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
      CustomNotification.show(context, 'Nominal wajib diisi!', isWarning: true);
      return;
    }

    final cleanAmount = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(cleanAmount) ?? 0;

    final fromWallet = _wallets.firstWhere((w) => w['id'] == selectedFromAccountId);
    if (amount > fromWallet['balance']) {
      CustomNotification.show(context, 'Gagal: Saldo dompet asal tidak mencukupi!', isError: true);
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

      await supabase.from('transactions').insert({
        'amount': amount,
        'is_expense': true,
        'category': 'Transfer',
        'wallet_id': selectedFromAccountId,
        'transaction_date': today,
        'note': note,
        'user_id': userId,
      });

      await supabase.from('transactions').insert({
        'amount': amount,
        'is_expense': false,
        'category': 'Transfer',
        'wallet_id': selectedToAccountId,
        'transaction_date': today,
        'note': note,
        'user_id': userId,
      });

      if (mounted) {
        CustomNotification.show(context, 'Transfer Berhasil!');
        _amountController.clear();
        _noteController.clear();
        _fetchWalletData();
      }
    } catch (e) {
      if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Transfer gagal');
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  Future<void> _deleteWallet(int id, String name) async {
    if (_wallets.length <= 1) {
      CustomNotification.show(context, 'Tidak bisa menghapus satu-satunya dompet!', isWarning: true);
      return;
    }

    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!hasConnection) return;

    setState(() => _isLoading = true);
    try {
      final txCheck = await supabase.from('transactions').select('id').eq('wallet_id', id);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (txCheck.isNotEmpty) {
        if (!mounted) return;
        CustomNotification.show(context, 'Gagal: Dompet masih memiliki riwayat transaksi!', isError: true);
        return;
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal mengecek data');
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dompet?'),
        content: Text('Anda yakin ingin menghapus dompet "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
    if (!mounted) return;

    if (confirm) {
      setState(() => _isLoading = true);
      try {
        await supabase.from('wallets').delete().eq('id', id);
        _fetchWalletData();
        if (mounted) CustomNotification.show(context, 'Dompet berhasil dihapus.');
      } catch (e) {
        if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal menghapus dompet');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showEditWalletOptions(Map<String, dynamic> wallet) {
    TextEditingController editNameController = TextEditingController(text: wallet['name']);
    TextEditingController editBalanceController = TextEditingController(
        text: NumberFormat.decimalPattern('id').format(wallet['balance'])
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Dompet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.red, size: 20),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteWallet(wallet['id'], wallet['name']);
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
              const SizedBox(height: 24),

              const Text('SALDO SAAT INI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: editBalanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    String clean = value.replaceAll('.', '');
                    String formatted = NumberFormat.decimalPattern('id').format(int.parse(clean));
                    editBalanceController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                  }
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    bool hasConnection = await NetworkHelper.checkConnection(context);
                    if (!mounted) return;
                    if (!hasConnection) return;

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      int newBalance = int.tryParse(editBalanceController.text.replaceAll('.', '')) ?? 0;

                      final walletData = await supabase.from('wallets').select('balance').eq('id', wallet['id']).single();
                      int dbBalance = int.tryParse(walletData['balance'].toString()) ?? 0;

                      int totalTxEffect = (wallet['balance'] as int) - dbBalance;
                      int newBaseBalance = newBalance - totalTxEffect;

                      await supabase.from('wallets').update({
                        'name': editNameController.text.trim(),
                        'balance': newBaseBalance,
                      }).eq('id', wallet['id']);

                      _fetchWalletData();
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
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showWalletSelector({required bool isFromAccount}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final selectableWallets = _wallets
            .where((w) => isFromAccount ? w['id'] != selectedToAccountId : w['id'] != selectedFromAccountId)
            .toList();
        final bool needsScrollableList = selectableWallets.length > 3;

        return SafeArea(
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
                SizedBox(
                  height: needsScrollableList ? MediaQuery.of(ctx).size.height * 0.5 : null,
                  child: ListView.separated(
                    shrinkWrap: !needsScrollableList,
                    physics: needsScrollableList ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
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
                              Text(wallet['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              Text(_formatCurrency(wallet['balance']), style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
        );
      },
    );
  }

  String _formatCurrency(int amount) {
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
          physics: const ClampingScrollPhysics(),
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
                    Text(_formatCurrency(_totalBalance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Dinikmati', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                ..._wallets.map((wallet) => _buildWalletItem(
                  wallet: wallet,
                  isDarkMode: isDarkMode,
                )),

              const SizedBox(height: 24),
              Divider(thickness: 1, color: isDarkMode ? Colors.white12 : const Color(0xFFEEEEEE)),
              const SizedBox(height: 24),

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
                      Text(
                        selectedFromAccountId == null
                            ? "Pilih Dompet Asal"
                            : _wallets.firstWhere((w) => w['id'] == selectedFromAccountId, orElse: () => {'name': 'Pilih Dompet Asal'})['name'],
                        style: TextStyle(fontSize: 14, color: selectedFromAccountId == null ? Colors.grey.shade500 : textColor),
                      ),
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
                      Text(
                        selectedToAccountId == null
                            ? "Pilih Dompet Tujuan"
                            : _wallets.firstWhere((w) => w['id'] == selectedToAccountId, orElse: () => {'name': 'Pilih Dompet Tujuan'})['name'],
                        style: TextStyle(fontSize: 14, color: selectedToAccountId == null ? Colors.grey.shade500 : textColor),
                      ),
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
                    String formatted = NumberFormat.decimalPattern('id').format(int.parse(clean));
                    _amountController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                  }
                },
              ),
              const SizedBox(height: 16),

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
      onTap: () => _showEditWalletOptions(wallet),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.shade200)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: wallet['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: FaIcon(wallet['icon'], color: wallet['color'], size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wallet['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 2),
                  Text(wallet['subtitle'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Text(_formatCurrency(wallet['balance']), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
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