import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({Key? key}) : super(key: key);

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController _balanceController = TextEditingController();
  bool _isLoading = false;

  String selectedWalletName = 'Uang Tunai';
  String selectedIconId = 'money';

  List<String> _existingWallets = [];

  List<Map<String, dynamic>> walletTemplates = [
    {'name': 'Uang Tunai', 'icon': Icons.money, 'icon_id': 'money', 'color': AppColors.primaryGreen},
    {'name': 'BCA', 'icon': Icons.account_balance, 'icon_id': 'bank', 'color': Colors.indigo},
    {'name': 'Mandiri', 'icon': Icons.account_balance, 'icon_id': 'bank', 'color': Colors.blue.shade800},
    {'name': 'GoPay', 'icon': Icons.account_balance_wallet, 'icon_id': 'wallet', 'color': Colors.blue},
    {'name': 'DANA', 'icon': Icons.account_balance_wallet, 'icon_id': 'wallet', 'color': Colors.orange},
    {'name': 'OVO', 'icon': Icons.account_balance_wallet, 'icon_id': 'wallet', 'color': Colors.purple},
    {'name': 'Baru', 'icon': Icons.add, 'icon_id': 'add', 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> dialogIcons = [
    {'id': 'money', 'icon': Icons.money, 'color': AppColors.primaryGreen},
    {'id': 'bank', 'icon': Icons.account_balance, 'color': Colors.indigo},
    {'id': 'wallet', 'icon': Icons.account_balance_wallet, 'color': Colors.orange},
    {'id': 'card', 'icon': Icons.credit_card, 'color': Colors.purple},
    {'id': 'savings', 'icon': Icons.savings, 'color': Colors.teal},
    {'id': 'crypto', 'icon': Icons.currency_bitcoin, 'color': Colors.amber.shade600},
    {'id': 'business', 'icon': Icons.storefront, 'color': Colors.blue},
  ];

  @override
  void initState() {
    super.initState();
    _fetchExistingWallets();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingWallets() async {
    try {
      final response = await supabase.from('wallets').select('name');
      setState(() {
        _existingWallets = (response as List).map((e) => e['name'].toString().toLowerCase()).toList();
      });
    } catch (e) {
      debugPrint('Gagal mengambil data dompet: $e');
    }
  }

  void _showAddWalletDialog() {
    TextEditingController nameController = TextEditingController();
    String tempIconId = dialogIcons[0]['id'];
    IconData tempIcon = dialogIcons[0]['icon'];
    Color tempColor = dialogIcons[0]['color'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Dompet Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Cth: ShopeePay',
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Pilih Ikon:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: dialogIcons.map((item) {
                        bool isSelected = tempIconId == item['id'];
                        return GestureDetector(
                          onTap: () => setStateDialog(() {
                            tempIconId = item['id'];
                            tempIcon = item['icon'];
                            tempColor = item['color'];
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? item['color'].withOpacity(0.2) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? item['color'] : Colors.grey.shade300, width: isSelected ? 2 : 1),
                            ),
                            child: Icon(item['icon'], color: isSelected ? item['color'] : Colors.grey),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        walletTemplates.insert(walletTemplates.length - 1, {
                          'name': nameController.text,
                          'icon': tempIcon,
                          'icon_id': tempIconId,
                          'color': tempColor,
                        });
                        selectedWalletName = nameController.text;
                        selectedIconId = tempIconId;
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveWallet() async {
    if (selectedWalletName.isEmpty || selectedWalletName == 'Baru') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih atau buat dompet terlebih dahulu!')));
      return;
    }

    if (_existingWallets.contains(selectedWalletName.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dompet "$selectedWalletName" sudah ada di daftar Anda!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      int initialBalance = 0;
      if (_balanceController.text.isNotEmpty) {
        final cleanAmount = _balanceController.text.replaceAll('.', '');
        initialBalance = int.parse(cleanAmount);
      }

      await supabase.from('wallets').insert({
        'name': selectedWalletName.trim(),
        'balance': initialBalance,
        'icon_name': selectedIconId,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dompet berhasil ditambahkan!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = (screenWidth - 40 - 24) / 4;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SubAppBar(title: 'Tambah Dompet Baru'),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PILIH DOMPET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.start,
              children: walletTemplates.map((template) {
                bool isNew = template['name'] == 'Baru';
                return _buildWalletItem(template['icon'], template['name'], template['color'], template['icon_id'], isDark, cardColor, itemWidth, isNew: isNew);
              }).toList(),
            ),
            const SizedBox(height: 32),

            const Text('SALDO AWAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Rp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _balanceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "0",
                        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          String clean = value.replaceAll('.', '');
                          String formatted = NumberFormat.decimalPattern('id').format(int.parse(clean));
                          _balanceController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                        }
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
                onPressed: _isLoading ? null : _saveWallet,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Dompet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletItem(IconData icon, String label, Color color, String iconId, bool isDark, Color cardColor, double itemWidth, {bool isNew = false}) {
    bool isSelected = selectedWalletName == label;
    return GestureDetector(
      onTap: () {
        if (isNew) {
          _showAddWalletDialog();
        } else {
          setState(() {
            selectedWalletName = label;
            selectedIconId = iconId;
          });
        }
      },
      child: SizedBox(
        width: itemWidth,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isNew ? cardColor : (isSelected ? color.withOpacity(0.2) : cardColor),
                shape: BoxShape.circle,
                border: isNew ? Border.all(color: Colors.grey.shade500) : (isSelected ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent)),
                boxShadow: (isDark || isSelected) ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}