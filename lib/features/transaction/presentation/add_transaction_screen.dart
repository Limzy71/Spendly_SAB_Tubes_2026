import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;
  String selectedCategory = "Makan";
  String selectedAccount = "Uang Tunai";
  DateTime selectedDate = DateTime.now();
  File? _imageFile;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const SubAppBar(title: 'Tambah Transaksi'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1FAF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTabItem("Pengeluaran", isExpense),
                        _buildTabItem("Pemasukan", !isExpense),
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
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none, hintText: "0"),
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
                  _buildCatItem(Icons.restaurant, "Makan", Colors.redAccent),
                  _buildCatItem(Icons.directions_car, "Transport", Colors.blue),
                  _buildCatItem(Icons.shopping_bag, "Belanja", Colors.purple),
                  _buildCatItem(Icons.money, "Gaji", AppColors.primaryGreen),
                  _buildCatItem(Icons.add, "Baru", Colors.grey, isNew: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
                              items: ["Uang Tunai", "BCA", "GoPay", "OVO"].map((String val) {
                                return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (val) => setState(() => selectedAccount = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.primaryGreen),
                          const SizedBox(width: 15),
                          Text(DateFormat('EEEE, dd MMMM yyyy', 'id').format(selectedDate), style: const TextStyle(fontSize: 14)),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CATATAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: "Beli apa hari ini?",
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(height: 20),
                    InkWell(
                      onTap: _pickImage,
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
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Simpan Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isExpense = (title == "Pengeluaran")),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: active ? AppColors.primaryGreen : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildCatItem(IconData icon, String label, Color color, {bool isNew = false}) {
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
                color: isNew ? Colors.white : (isSelected ? color.withOpacity(0.2) : Colors.white),
                shape: BoxShape.circle,
                border: isNew ? Border.all(color: Colors.grey.shade300) : (isSelected ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black87 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}