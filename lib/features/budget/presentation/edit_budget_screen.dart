import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';

class EditBudgetScreen extends StatefulWidget {
  final String category;
  final int currentLimit;
  final dynamic icon; // PERBAIKAN: Diubah ke dynamic untuk menerima FaIconData
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
  // State untuk riwayat anggaran
  List<Map<String, dynamic>> _budgetHistory = [];
  bool _isLoadingHistory = true;
  late TextEditingController _limitController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.category);
    String formattedInitial = _formatNumber(widget.currentLimit.toString());
    _limitController = TextEditingController(text: formattedInitial);
    _fetchBudgetHistory();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  String _formatNumber(String s) {
    String formatted = '';
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) formatted = '.$formatted';
      formatted = s[i] + formatted;
      count++;
    }
    return formatted;
  }

  // Fungsi mengambil riwayat limit anggaran berdasarkan periode bulan
  Future<void> _fetchBudgetHistory() async {
    try {
      final response = await supabase
          .from('budgets')
          .select()
          .ilike('category', widget.category.trim())
          .order('period_month', ascending: false); // Urutkan dari bulan terbaru

      if (mounted) {
        setState(() {
          _budgetHistory = List<Map<String, dynamic>>.from(response);
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
    setState(() => _isLoading = true);

    try {
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
          .ilike('category', widget.category.trim())
          .eq('period_month', periodMonth);

      if (widget.category.trim().toLowerCase() != newCategoryName.toLowerCase()) {
        await supabase
            .from('transactions')
            .update({'category': newCategoryName})
            .ilike('category', widget.category.trim());
      }

      if (mounted) {
        // 1. Hapus atau beri komentar pada Navigator.pop agar tetap di halaman ini
        // Navigator.pop(context, true);

        // 2. Panggil fungsi fetch untuk me-refresh list riwayat secara real-time
        _fetchBudgetHistory();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anggaran berhasil diperbarui!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e')),
        );
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

    setState(() => _isLoading = true);
    try {
      final periodMonth = DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String().split('T')[0];

      await supabase
          .from('budgets')
          .delete()
          .eq('category', widget.category)
          .eq('period_month', periodMonth);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anggaran berhasil dihapus!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
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
          onPressed: () => Navigator.pop(context),
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

            // --- KODE TOMBOL SIMPAN KAMU BERADA DI ATAS SINI ---

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text('Riwayat Anggaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),

            // Menampilkan loading, teks kosong, atau list transaksi
            _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _budgetHistory.isEmpty
                ? Center(child: Text('Belum ada riwayat anggaran.', style: TextStyle(color: Colors.grey[600])))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _budgetHistory.length,
              itemBuilder: (context, index) {
                final budget = _budgetHistory[index];

                // Format nominal limit anggaran
                final limit = budget['limit_amount'] as int;
                String formattedLimit = '';
                int count = 0;
                String s = limit.toString();
                for (int i = s.length - 1; i >= 0; i--) {
                  if (count != 0 && count % 3 == 0) formattedLimit = '.$formattedLimit';
                  formattedLimit = s[i] + formattedLimit;
                  count++;
                }

                // Ambil periode bulan (Misal: 2026-05-01)
                final periodStr = budget['period_month'].toString().split('T')[0];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      // ===================================================================
                      // PERBAIKAN 1 & 2: Menggunakan icon kategori yang sesuai & konsisten
                      // ===================================================================
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          // Gunakan parameter warna dan ikon dari widget utama (makanan)
                            color: widget.iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)
                        ),
                        // Gunakan FaIcon untuk menampilkan widget.icon (utensils)
                        child: FaIcon(widget.icon, color: widget.iconColor, size: 24),
                      ),
                      // ===================================================================

                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(budget['category']?.toString() ?? widget.category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                            const SizedBox(height: 4),
                            Text('Periode: $periodStr', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('Rp $formattedLimit', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 14)),
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