import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final Color primaryGreen = const Color(0xFF05A660);

  // --- STATE (Logika Interaktif) ---
  bool isExpense = true;
  String rawAmount = "150000";
  String selectedCategory = "Makan";

  // Fungsi untuk memformat angka "150000" menjadi "150.000"
  String get formattedAmount {
    if (rawAmount.isEmpty) return "0";
    String result = "";
    int count = 0;
    for (int i = rawAmount.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) result = ".$result";
      result = rawAmount[i] + result;
      count++;
    }
    return result;
  }

  // Fungsi ketika tombol angka/hapus dipencet
  void _onNumpadTap(String value) {
    setState(() {
      if (value == "backspace") {
        if (rawAmount.isNotEmpty) {
          rawAmount = rawAmount.substring(0, rawAmount.length - 1);
        }
        if (rawAmount.isEmpty) rawAmount = "0";
      } else if (value == "000") {
        if (rawAmount != "0" && rawAmount.length < 12) rawAmount += "000";
      } else if (value == "." || value == "+" || value == "-" || value == "check") {
        print("Tombol $value ditekan");
      } else {
        if (rawAmount == "0") {
          rawAmount = value;
        } else if (rawAmount.length < 12) {
          rawAmount += value;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 110,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF05A660), size: 20),
              SizedBox(width: 6),
              Text('Spendly', style: TextStyle(color: Color(0xFF05A660), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        centerTitle: true,
        title: const Text(
            'Tambah Transaksi',
            style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // 1. TABS (Pengeluaran / Pemasukan)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
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

            const SizedBox(height: 30),
            // 2. NOMINAL DISPLAY (Interaktif)
            const Text('JUMLAH (IDR)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Rp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryGreen)),
                const SizedBox(width: 8),
                Text(formattedAmount, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)),
                Container(width: 2, height: 40, color: primaryGreen),
              ],
            ),

            const SizedBox(height: 30),
            // 3. NUMPAD (Keyboard Angka Interaktif)
            _buildNumpad(),

            const SizedBox(height: 30),
            // 4. KATEGORI (Interaktif)
            _buildCategorySection(),

            const SizedBox(height: 30),
            // 5. FORM DETAIL (Tanggal & Catatan)
            _buildDetailForm(),

            const SizedBox(height: 30),
            // 6. TOMBOL SIMPAN
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Simpan Anggaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

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
          child: Text(title, style: TextStyle(color: active ? primaryGreen : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.3,
        children: [
          _buildNumBtn("1"), _buildNumBtn("2"), _buildNumBtn("3"), _buildOpBtn(Icons.add, "+", const Color(0xFF6B7AF5)),
          _buildNumBtn("4"), _buildNumBtn("5"), _buildNumBtn("6"), _buildOpBtn(Icons.remove, "-", const Color(0xFF6B7AF5)),
          _buildNumBtn("7"), _buildNumBtn("8"), _buildNumBtn("9"), _buildOpBtn(Icons.backspace_outlined, "backspace", const Color(0xFF8F9DF8)),
          _buildNumBtn("."), _buildNumBtn("0"), _buildNumBtn("000"), _buildOpBtn(Icons.check, "check", primaryGreen),
        ],
      ),
    );
  }

  Widget _buildNumBtn(String text) {
    return GestureDetector(
      onTap: () => _onNumpadTap(text),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFF1FAF5), borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87))),
      ),
    );
  }

  Widget _buildOpBtn(IconData icon, String value, Color color) {
    return GestureDetector(
      onTap: () => _onNumpadTap(value),
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCatItem(Icons.restaurant, "Makan", Colors.redAccent),
              _buildCatItem(Icons.directions_car, "Transport", Colors.blue),
              _buildCatItem(Icons.shopping_bag, "Belanja", Colors.purple),
              _buildCatItem(Icons.money, "Gaji", primaryGreen),
              _buildCatItem(Icons.add, "Baru", Colors.grey, isNew: true),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCatItem(IconData icon, String label, Color color, {bool isNew = false}) {
    bool isSelected = selectedCategory == label;

    return GestureDetector(
      onTap: () {
        if (!isNew) setState(() => selectedCategory = label);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Efek visual jika kategori dipilih
                color: isNew ? Colors.white : (isSelected ? color.withOpacity(0.2) : color.withOpacity(0.05)),
                shape: BoxShape.circle,
                border: isNew ? Border.all(color: Colors.grey.shade300, style: BorderStyle.solid) :
                (isSelected ? Border.all(color: color, width: 2) : null),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black87 : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildFormRow(Icons.calendar_today_outlined, "Tanggal & Waktu", "Hari ini, 14:20"),
          const Divider(),
          _buildFormRow(Icons.edit_note, "Catatan/Deskripsi", "Beli makan siang di kantor..."),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.camera_alt_outlined, color: primaryGreen),
            label: Text('Lampirkan Foto Struk', style: TextStyle(color: primaryGreen)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: primaryGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFormRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}