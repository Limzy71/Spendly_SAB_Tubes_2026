import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import 'add_wallet_screen.dart';

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
    setState(() => _isLoading = true);
    try {
      final walletResponse = await supabase.from('wallets').select().order('id');
      final txResponse = await supabase.from('transactions').select();

      int grandTotal = 0;
      List<Map<String, dynamic>> processedWallets = [];

      for (var w in walletResponse) {
        int wId = w['id'] as int;
        String wName = w['name'].toString();
        int currentBal = w['balance'] as int;
        String? iconName = w['icon_name']?.toString();

        for (var tx in txResponse) {
          if (tx['wallet_id'] == wId) {
            if (tx['is_expense'] == true) {
              currentBal -= tx['amount'] as int;
            } else {
              currentBal += tx['amount'] as int;
            }
          }
        }

        grandTotal += currentBal;
        processedWallets.add({
          'id': wId,
          'name': wName,
          'balance': currentBal,
          'subtitle': _getSubtitleForWallet(wName),
          'icon': _getIconFromDbString(iconName, wName),
          'color': _getColorForWallet(wName),
        });
      }

      if (mounted) {
        setState(() {
          _wallets = processedWallets;
          _totalBalance = grandTotal;
          if (!_wallets.any((w) => w['id'] == selectedFromAccountId)) selectedFromAccountId = null;
          if (!_wallets.any((w) => w['id'] == selectedToAccountId)) selectedToAccountId = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil data: $e')));
      }
    }
  }

  Future<void> _processTransfer() async {
    if (selectedFromAccountId == null || selectedToAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih dompet asal dan tujuan!')));
      return;
    }
    if (_amountController.text.isEmpty || _amountController.text == '0') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal wajib diisi!')));
      return;
    }

    setState(() => _isTransferring = true);

    try {
      final cleanAmount = _amountController.text.replaceAll('.', '');
      final amount = int.parse(cleanAmount);
      final today = DateTime.now().toIso8601String().split('T')[0];
      final note = _noteController.text.isNotEmpty ? _noteController.text : 'Transfer Internal';

      await supabase.from('transactions').insert({
        'amount': amount,
        'is_expense': true,
        'category': 'Transfer',
        'wallet_id': selectedFromAccountId,
        'transaction_date': today,
        'note': note,
      });

      await supabase.from('transactions').insert({
        'amount': amount,
        'is_expense': false,
        'category': 'Transfer',
        'wallet_id': selectedToAccountId,
        'transaction_date': today,
        'note': note,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer Berhasil!')));
        _amountController.clear();
        _noteController.clear();
        selectedFromAccountId = null;
        selectedToAccountId = null;
        _fetchWalletData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transfer gagal: $e')));
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  Future<void> _deleteWallet(int id, String name) async {
    if (_wallets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak bisa menghapus satu-satunya dompet!')));
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dompet?'),
        content: Text('Anda yakin ingin menghapus dompet "$name"?\n\nCatatan: Jika ada transaksi yang terkait dengan dompet ini, mungkin akan terjadi error pada riwayat Anda.'),
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

    if (confirm) {
      setState(() => _isLoading = true);
      try {
        await supabase.from('wallets').delete().eq('id', id);
        _fetchWalletData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dompet berhasil dihapus.')));
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus dompet (Pastikan dompet kosong dari transaksi): $e')));
        }
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
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      int newBalance = int.parse(editBalanceController.text.replaceAll('.', ''));

                      int totalTxEffect = wallet['balance'] - (await supabase.from('wallets').select('balance').eq('id', wallet['id']).single())['balance'] as int;
                      int newBaseBalance = newBalance - totalTxEffect;

                      await supabase.from('wallets').update({
                        'name': editNameController.text.trim(),
                        'balance': newBaseBalance,
                      }).eq('id', wallet['id']);

                      _fetchWalletData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dompet berhasil diperbarui!')));
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui: $e')));
                      }
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
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(isFromAccount ? 'Pilih Dompet Asal' : 'Pilih Dompet Tujuan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (_wallets.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Belum ada dompet', style: TextStyle(color: Colors.grey)),
                )
              else
                ..._wallets.where((w) => isFromAccount ? w['id'] != selectedToAccountId : w['id'] != selectedFromAccountId).map((wallet) {
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
                }).toList(),
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

  IconData _getIconFromDbString(String? iconName, String walletName) {
    switch (iconName) {
      case 'money': return Icons.money;
      case 'bank': return Icons.account_balance;
      case 'wallet': return Icons.account_balance_wallet;
      case 'card': return Icons.credit_card;
      case 'savings': return Icons.savings;
      case 'crypto': return Icons.currency_bitcoin;
      case 'business': return Icons.storefront;
      case 'investment': return Icons.trending_up;
      case 'safe': return Icons.lock_outline;
      case 'online': return Icons.payments_outlined;
      default:
        String lower = walletName.toLowerCase();
        if (lower.contains('tunai')) return Icons.money;
        if (lower.contains('gopay') || lower.contains('ovo') || lower.contains('dana') || lower.contains('shopee')) return Icons.account_balance_wallet;
        return Icons.account_balance;
    }
  }

  Color _getColorForWallet(String name) {
    String lower = name.toLowerCase();
    if (lower.contains('tunai')) return AppColors.primaryGreen;
    if (lower.contains('bca') || lower.contains('mandiri') || lower.contains('bri')) return Colors.indigo;
    if (lower.contains('gopay')) return Colors.blue;
    if (lower.contains('ovo')) return Colors.purple;
    if (lower.contains('dana') || lower.contains('shopee')) return Colors.orange;
    if (lower.contains('kripto') || lower.contains('crypto')) return Colors.amber.shade600;
    return Colors.teal;
  }

  String _getSubtitleForWallet(String name) {
    String lower = name.toLowerCase();
    if (lower.contains('tunai')) return 'Fisik';
    if (lower.contains('gopay') || lower.contains('ovo') || lower.contains('dana') || lower.contains('shopee')) return 'E-Wallet';
    return 'Bank / Lainnya';
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
                  boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
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
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
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
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen, size: 18),
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
                )).toList(),

              const SizedBox(height: 24),
              Divider(thickness: 1, color: isDarkMode ? Colors.white12 : const Color(0xFFEEEEEE)),
              const SizedBox(height: 24),

              Row(
                children: [
                  const Icon(Icons.swap_horiz, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
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
                  color: isDarkMode ? Colors.teal.withOpacity(0.1) : const Color(0xFFF1FAF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
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
                  icon: _isTransferring ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white, size: 18),
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
        decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.shade200)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: wallet['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(wallet['icon'], color: wallet['color'], size: 24),
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
      child: Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}