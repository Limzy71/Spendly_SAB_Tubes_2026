import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final supabase = Supabase.instance.client;

  bool isExpense = true;
  // Kategori default disesuaikan
  String selectedCategory = "Makanan";
  String selectedAccount = "Uang Tunai";
  DateTime selectedDate = DateTime.now();
  File? _imageFile;
  bool _isLoading = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Center(child: Text('Pilih Sumber Gambar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.primaryGreen),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen)),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || _amountController.text == '0') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal wajib diisi')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cleanAmount = _amountController.text.replaceAll('.', '');
      final amount = int.parse(cleanAmount);

      await supabase.from('transactions').insert({
        'amount': amount,
        'is_expense': isExpense,
        'category': selectedCategory,
        'wallet_id': 1,
        'transaction_date': selectedDate.toIso8601String().split('T')[0],
        'note': _noteController.text.isEmpty ? null : _noteController.text,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Berhasil Disimpan!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
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
    Color dividerColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SubAppBar(title: 'Tambah Transaksi'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(_amountFocusNode),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1FAF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem("Pengeluaran", isExpense, isDark, cardColor),
                          _buildTabItem("Pemasukan", !isExpense, isDark, cardColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text('NOMINAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Rp', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                        const SizedBox(width: 10),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor),
                            cursorColor: AppColors.primaryGreen,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "0",
                                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38)
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                String clean = value.replaceAll('.', '');
                                String formatted = NumberFormat.decimalPattern('id').format(int.parse(clean));
                                _amountController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('KATEGORI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 95,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Penyeragaman Kategori di Sini
                  _buildCatItem(Icons.restaurant, "Makanan", Colors.redAccent, isDark, cardColor),
                  _buildCatItem(Icons.directions_car, "Transportasi", Colors.blue, isDark, cardColor),
                  _buildCatItem(Icons.shopping_bag, "Belanja", Colors.purple, isDark, cardColor),
                  _buildCatItem(Icons.money, "Gaji", AppColors.primaryGreen, isDark, cardColor),
                  _buildCatItem(Icons.add, "Baru", Colors.grey, isDark, cardColor, isNew: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryGreen),
                        const SizedBox(width: 15),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedAccount,
                              isExpanded: true,
                              dropdownColor: cardColor,
                              iconEnabledColor: textColor,
                              items: ["Uang Tunai", "BCA", "GoPay", "OVO"].map((String val) {
                                return DropdownMenuItem<String>(value: val, child: Text(val, style: TextStyle(fontSize: 14, color: textColor)));
                              }).toList(),
                              onChanged: (val) => setState(() => selectedAccount = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 30, color: dividerColor, thickness: 1),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.primaryGreen),
                          const SizedBox(width: 15),
                          Text(DateFormat('EEEE, dd MMMM yyyy', 'id').format(selectedDate), style: TextStyle(fontSize: 14, color: textColor)),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CATATAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Beli apa hari ini?",
                        hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white30 : Colors.grey),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    Divider(height: 20, color: dividerColor, thickness: 1),
                    InkWell(
                      onTap: _showImagePickerBottomSheet,
                      child: Column(
                        children: [
                          if (_imageFile != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_imageFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
                              ),
                            ),
                          Row(
                            children: [
                              const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen),
                              const SizedBox(width: 15),
                              Text(_imageFile == null ? "Lampirkan Foto Struk" : "Ubah Foto Struk", style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, bool active, bool isDark, Color cardColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isExpense = (title == "Pengeluaran")),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? (isDark ? Colors.white24 : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: active ? AppColors.primaryGreen : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildCatItem(IconData icon, String label, Color color, bool isDark, Color cardColor, {bool isNew = false}) {
    bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () { if (!isNew) setState(() => selectedCategory = label); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isNew ? cardColor : (isSelected ? color.withOpacity(0.2) : cardColor),
                shape: BoxShape.circle,
                border: isNew ? Border.all(color: Colors.grey.shade500) : (isSelected ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey)),
          ],
        ),
      ),
    );
  }
}