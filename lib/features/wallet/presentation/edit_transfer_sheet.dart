import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/network_helper.dart';
import '../../../widgets/wallet_helper.dart';

Future<bool> showEditTransferSheet(
  BuildContext context, {
  required Map<String, dynamic> tx,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _EditTransferSheet(tx: tx),
  );
  return result ?? false;
}

class _EditTransferSheet extends StatefulWidget {
  final Map<String, dynamic> tx;

  const _EditTransferSheet({required this.tx});

  @override
  State<_EditTransferSheet> createState() => _EditTransferSheetState();
}

class _EditTransferSheetState extends State<_EditTransferSheet> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _wallets = [];
  Map<String, dynamic>? _expenseRow;
  Map<String, dynamic>? _incomeRow;
  Map<String, dynamic>? _feeRow;

  int? fromId;
  int? toId;
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _adminFeeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _adminFeeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!hasConnection) {
      if (mounted) Navigator.pop(context, false);
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) Navigator.pop(context, false);
        return;
      }

      final walletResponse = await supabase.from('wallets').select().eq('user_id', userId).order('id');
      final allTxResponse = await supabase.from('transactions').select().eq('user_id', userId);

      List<Map<String, dynamic>> processedWallets = [];
      for (var w in walletResponse) {
        int wId = int.tryParse(w['id'].toString()) ?? -1;
        int currentBal = int.tryParse(w['balance']?.toString() ?? '0') ?? 0;
        int expenseTxCount = 0;
        int totalTxCount = 0;
        for (var tx in allTxResponse) {
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
        var wMap = Map<String, dynamic>.from(w);
        wMap['balance'] = currentBal;
        wMap['usage_score'] = (expenseTxCount * 3) + totalTxCount;
        processedWallets.add(wMap);
      }

      processedWallets.sort((a, b) {
        int scoreA = a['usage_score'] as int? ?? 0;
        int scoreB = b['usage_score'] as int? ?? 0;
        if (scoreB != scoreA) {
          return scoreB.compareTo(scoreA); // Most active wallet first
        }
        int balA = a['balance'] as int? ?? 0;
        int balB = b['balance'] as int? ?? 0;
        return balB.compareTo(balA);
      });

      _wallets = processedWallets;

      final gid = widget.tx['group_id']?.toString();
      List<dynamic> rows = [];

      if (gid != null && gid.isNotEmpty) {
        rows = await supabase.from('transactions').select().eq('group_id', gid).eq('user_id', userId);
      }

      if (rows.length < 2) {
        final partnerId = widget.tx['partner_id'];
        if (partnerId == null) {
          if (mounted) {
            CustomNotification.show(context, 'Data pasangan transfer tidak ditemukan. Hapus lalu buat ulang transfer ini.', isWarning: true);
            Navigator.pop(context, false);
          }
          return;
        }
        rows = await supabase
            .from('transactions')
            .select()
            .inFilter('id', [widget.tx['id'], partnerId])
            .eq('user_id', userId);
      }

      for (final r in rows) {
        final cat = r['category']?.toString().toLowerCase() ?? '';
        if (cat == 'biaya admin') {
          _feeRow = r;
        } else if (r['is_expense'] == true) {
          _expenseRow = r;
        } else {
          _incomeRow = r;
        }
      }

      if (_expenseRow == null || _incomeRow == null) {
        if (mounted) {
          CustomNotification.show(context, 'Data transfer tidak lengkap.', isError: true);
          Navigator.pop(context, false);
        }
        return;
      }

      fromId = int.tryParse(_expenseRow!['wallet_id'].toString());
      toId = int.tryParse(_incomeRow!['wallet_id'].toString());
      _amountController.text = NumberFormat.decimalPattern('id').format(int.tryParse(_expenseRow!['amount'].toString()) ?? 0);
      _adminFeeController.text =
          _feeRow != null ? NumberFormat.decimalPattern('id').format(int.tryParse(_feeRow!['amount'].toString()) ?? 0) : '';
      _noteController.text = (_expenseRow!['note']?.toString() ?? '') == 'Transfer Internal' ? '' : (_expenseRow!['note']?.toString() ?? '');
      _selectedDate = DateTime.tryParse(_expenseRow!['transaction_date'].toString()) ?? DateTime.now();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal memuat data transfer');
        Navigator.pop(context, false);
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatCurrency(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

  Future<void> _saveChanges() async {
    if (fromId == null || toId == null) {
      CustomNotification.show(context, 'Pilih dompet asal dan tujuan!', isWarning: true);
      return;
    }
    if (fromId == toId) {
      CustomNotification.show(context, 'Dompet asal dan tujuan tidak boleh sama!', isWarning: true);
      return;
    }

    final amount = int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    final fee = int.tryParse(_adminFeeController.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) {
      CustomNotification.show(context, 'Nominal transfer wajib diisi!', isWarning: true);
      return;
    }

    final fromWallet = _wallets.firstWhere((w) => int.tryParse(w['id'].toString()) == fromId, orElse: () => {});
    final toWallet = _wallets.firstWhere((w) => int.tryParse(w['id'].toString()) == toId, orElse: () => {});
    if (fromWallet.isEmpty || toWallet.isEmpty) {
      CustomNotification.show(context, 'Dompet tidak ditemukan!', isError: true);
      return;
    }

    final allGroupRows = [
      if (_expenseRow != null) _expenseRow!,
      if (_incomeRow != null) _incomeRow!,
      if (_feeRow != null) _feeRow!,
    ];

    int projectedBalance = int.tryParse(fromWallet['balance'].toString()) ?? 0;
    for (final r in allGroupRows) {
      final rid = int.tryParse(r['wallet_id'].toString());
      final rAmt = int.tryParse(r['amount'].toString()) ?? 0;
      if (rid == fromId) {
        projectedBalance += (r['is_expense'] == true ? rAmt : -rAmt);
      }
    }

    if (amount + fee > projectedBalance) {
      CustomNotification.show(
        context,
        'Gagal: Saldo dompet asal tidak mencukupi (Tersedia: ${_formatCurrency(projectedBalance)})!',
        isError: true,
      );
      return;
    }

    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted || !hasConnection) return;

    setState(() => _isSaving = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final noteText = _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : 'Transfer Internal';
      String gid = widget.tx['group_id']?.toString() ?? '';
      if (gid.isEmpty) gid = DateTime.now().microsecondsSinceEpoch.toString();

      await supabase.from('transactions').update({
        'amount': amount,
        'wallet_id': fromId,
        'wallet_name': fromWallet['name'],
        'transaction_date': dateStr,
        'note': noteText,
        'group_id': gid,
      }).eq('id', _expenseRow!['id']).eq('user_id', userId);

      await supabase.from('transactions').update({
        'amount': amount,
        'wallet_id': toId,
        'wallet_name': toWallet['name'],
        'transaction_date': dateStr,
        'note': noteText,
        'group_id': gid,
      }).eq('id', _incomeRow!['id']).eq('user_id', userId);

      if (fee > 0 && _feeRow != null) {
        await supabase.from('transactions').update({
          'amount': fee,
          'wallet_id': fromId,
          'wallet_name': fromWallet['name'],
          'transaction_date': dateStr,
          'note': 'Biaya admin transfer ke ${toWallet['name']}',
          'group_id': gid,
        }).eq('id', _feeRow!['id']).eq('user_id', userId);
      } else if (fee > 0 && _feeRow == null) {
        await supabase.from('transactions').insert({
          'amount': fee,
          'is_expense': true,
          'category': 'Biaya Admin',
          'wallet_id': fromId,
          'wallet_name': fromWallet['name'],
          'transaction_date': dateStr,
          'note': 'Biaya admin transfer ke ${toWallet['name']}',
          'group_id': gid,
          'user_id': userId,
        });
      } else if (fee == 0 && _feeRow != null) {
        await supabase.from('transactions').delete().eq('id', _feeRow!['id']).eq('user_id', userId);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal menyimpan perubahan');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    final otherWalletsFrom = _wallets.where((w) => int.tryParse(w['id'].toString()) != toId).toList();
    final otherWalletsTo = _wallets.where((w) => int.tryParse(w['id'].toString()) != fromId).toList();

    void openWalletPicker({
      required String title,
      required List<Map<String, dynamic>> items,
      required int? currentSelectedId,
      required void Function(int) onSelected,
    }) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).cardColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          String searchQuery = '';
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final filteredItems = items.where((w) {
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
                            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sheetTextColor)),
                            IconButton(
                              icon: Icon(Icons.close, size: 20, color: sheetTextColor),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      if (items.length > 5) ...[
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
                      Flexible(
                        child: filteredItems.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Dompet tidak ditemukan', style: TextStyle(color: Colors.grey)),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                                itemBuilder: (context, index) {
                                  final w = filteredItems[index];
                                  final wId = int.tryParse(w['id'].toString());
                                  final isSelected = wId == currentSelectedId;
                                  final wName = w['name'].toString();
                                  final wColor = WalletHelper.getColor(wName);
                                  final int balance = int.tryParse(w['balance']?.toString() ?? '0') ?? 0;

                                  return ListTile(
                                    dense: true,
                                    onTap: () {
                                      if (wId != null) onSelected(wId);
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
                                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(balance),
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

    Widget buildWalletSelectorTile({
      required String label,
      required List<Map<String, dynamic>> items,
      required int? value,
      required void Function(int) onSelected,
    }) {
      final selectedWallet = _wallets.firstWhere(
        (w) => int.tryParse(w['id'].toString()) == value,
        orElse: () => <String, dynamic>{},
      );
      final wName = selectedWallet['name']?.toString() ?? 'Pilih Dompet';
      final wColor = selectedWallet.isNotEmpty ? WalletHelper.getColor(wName) : Colors.grey;

      return InkWell(
        onTap: () {
          openWalletPicker(
            title: label,
            items: items,
            currentSelectedId: value,
            onSelected: onSelected,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              if (selectedWallet.isNotEmpty) ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: WalletHelper.getIcon(selectedWallet['icon_name']?.toString(), wName, color: wColor, size: 12),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  wName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selectedWallet.isNotEmpty ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    Widget buildFormLabel(String text) => Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
        );

    Widget buildAmountField(TextEditingController controller, {required ValueChanged<String> onChanged}) {
      return TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [LengthLimitingTextInputFormatter(18)],
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: '0',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
        ),
        onChanged: onChanged,
      );
    }

    void formatAmount(String val, TextEditingController controller, VoidCallback after) {
      if (val.isNotEmpty) {
        String clean = val.replaceAll('.', '');
        if (clean.startsWith('0') && clean.length > 1) {
          clean = clean.replaceFirst(RegExp(r'^0+'), '');
          if (clean.isEmpty) clean = '0';
        }
        String formatted = NumberFormat.decimalPattern('id').format(int.tryParse(clean) ?? 0);
        controller.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
      }
      after();
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? MediaQuery.of(context).viewInsets.bottom + 16 : 20,
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
                  'Edit Transfer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            buildFormLabel('DOMPET ASAL'),
            const SizedBox(height: 8),
            buildWalletSelectorTile(
              label: 'Pilih Dompet Asal',
              items: otherWalletsFrom,
              value: fromId,
              onSelected: (val) => setState(() => fromId = val),
            ),
            const SizedBox(height: 16),
            buildFormLabel('DOMPET TUJUAN'),
            const SizedBox(height: 8),
            buildWalletSelectorTile(
              label: 'Pilih Dompet Tujuan',
              items: otherWalletsTo,
              value: toId,
              onSelected: (val) => setState(() => toId = val),
            ),
            const SizedBox(height: 16),
            buildFormLabel('NOMINAL TRANSFER'),
            const SizedBox(height: 8),
            buildAmountField(_amountController, onChanged: (val) => formatAmount(val, _amountController, () {})),
            const SizedBox(height: 16),
            buildFormLabel('BIAYA ADMIN (OPSIONAL)'),
            const SizedBox(height: 8),
            buildAmountField(_adminFeeController, onChanged: (val) => formatAmount(val, _adminFeeController, () {})),
            const SizedBox(height: 16),
            buildFormLabel('TANGGAL TRANSFER'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.calendarDays, size: 14, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMM yyyy', 'id').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            buildFormLabel('CATATAN'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
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
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const FaIcon(FontAwesomeIcons.floppyDisk, color: Colors.white, size: 16),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
