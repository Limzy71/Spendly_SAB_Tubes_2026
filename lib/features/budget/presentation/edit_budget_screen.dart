import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/custom_notification.dart';

// IMPORT NETWORK HELPER
import '../../../../widgets/network_helper.dart';

class EditBudgetScreen extends StatefulWidget {
  final String category;
  final int currentLimit;
  final dynamic icon;
  final Color iconColor;

  const EditBudgetScreen({
    Key? key,
    required this.category,
    required this.currentLimit,
    required this.icon,
    required this.iconColor,
  }) : super(key: key);

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isDataModified = false;

  List<Map<String, dynamic>> _transactionHistory = [];
  bool _isLoadingHistory = true;

  late TextEditingController _limitController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.category);
    String formattedInitial = _formatNumber(widget.currentLimit.toString());
    _limitController = TextEditingController(text: formattedInitial);
    _fetchTransactionHistory();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  String _formatNumber(String s) {
    String digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '0';
    return NumberFormat.decimalPattern('id').format(int.parse(digits));
  }

  Future<void> _fetchTransactionHistory() async {
    // 1. INTEGRASI NETWORK HELPER
    if (!await NetworkHelper.checkConnection(context)) {
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .ilike('category', widget.category.trim())
          .order('transaction_date', ascending: false);

      if (mounted) {
        setState(() {
          _transactionHistory = List<Map<String, dynamic>>.from(response);
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _updateBudget() async {
    // 2. INTEGRASI NETWORK HELPER
    if (!await NetworkHelper.checkConnection(context)) return;

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final cleanLimit = _limitController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final newLimitAmount = int.parse(cleanLimit);

      final newCategoryName = _categoryController.text.trim();

      final now = DateTime.now();
      final periodMonth = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];

      await supabase
          .from('budgets')
          .update({
        'limit_amount': newLimitAmount,
        'category': newCategoryName
      })
          .eq('user_id', userId)
          .ilike('category', widget.category.trim())
          .eq('period_month', periodMonth);

      if (widget.category.trim().toLowerCase() != newCategoryName.toLowerCase()) {
        await supabase
            .from('transactions')
            .update({'category': newCategoryName})
            .eq('user_id', userId)
            .ilike('category', widget.category.trim());
      }

      if (mounted) {
        setState(() {
          _isDataModified = true;
        });

        _fetchTransactionHistory();

        CustomNotification.show(context, 'Anggaran berhasil diperbarui!');
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.show(context, 'Gagal memperbarui: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Anggaran'),
        content: Text('Apakah Anda yakin ingin menghapus anggaran ${widget.category}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 3. INTEGRASI NETWORK HELPER (Setel di sini agar ngecek internetnya setelah user yakin menghapus)
    if (!await NetworkHelper.checkConnection(context)) return;

    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final periodMonth = DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String().split('T')[0];

      await supabase
          .from('budgets')
          .delete()
          .eq('user_id', userId)
          .eq('category', widget.category)
          .eq('period_month', periodMonth);

      if (mounted) {
        Navigator.pop(context, true);
        CustomNotification.show(context, 'Anggaran berhasil dihapus!');
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.show(context, 'Gagal menghapus: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Edit Anggaran', style: TextStyle(color: textColor, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context, _isDataModified),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.red, size: 20),
            onPressed: _deleteBudget,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KATEGORI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  FaIcon(widget.icon, color: widget.iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('UBAH BATAS ANGGARAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Text('Rp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _limitController,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38)
                      ),
                      onChanged: (value) {
                        String digits = value.replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) {
                          _limitController.text = '';
                          return;
                        }
                        String formatted = _formatNumber(digits);
                        _limitController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text('Riwayat Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),

            _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _transactionHistory.isEmpty
                ? Center(child: Text('Belum ada riwayat transaksi.', style: TextStyle(color: Colors.grey[600])))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactionHistory.length,
              itemBuilder: (context, index) {
                final tx = _transactionHistory[index];

                final amount = tx['amount'] as int;
                final isExpense = tx['is_expense'] as bool;
                final note = tx['note']?.toString() ?? '';
                final txDate = tx['transaction_date'].toString().split('T')[0];

                String formattedAmount = NumberFormat.decimalPattern('id').format(amount);

                final amountColor = isExpense ? Colors.red : AppColors.primaryGreen;
                final sign = isExpense ? '-' : '+';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: widget.iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child: FaIcon(widget.icon, color: widget.iconColor, size: 24),
                      ),

                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(note.isNotEmpty ? note : widget.category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                            const SizedBox(height: 4),
                            Text(txDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('$sign Rp $formattedAmount', style: TextStyle(fontWeight: FontWeight.bold, color: amountColor, fontSize: 14)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}