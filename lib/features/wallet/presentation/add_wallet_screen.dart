import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/wallet_helper.dart';
import '../../../../widgets/network_helper.dart';

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

  // SEKARANG DRY: Hanya menyimpan info struktural, visual diserahkan ke WalletHelper
  List<Map<String, String>> walletTemplates = [
    {'name': 'Uang Tunai', 'icon_id': 'money'},
    {'name': 'BCA', 'icon_id': 'bank'},
    {'name': 'Mandiri', 'icon_id': 'bank'},
    {'name': 'GoPay', 'icon_id': 'wallet'},
    {'name': 'DANA', 'icon_id': 'wallet'},
    {'name': 'OVO', 'icon_id': 'wallet'},
    {'name': 'Baru', 'icon_id': 'add'},
  ];

  // SEKARANG DRY: Hanya butuh ID string untuk dicocokkan ke kamus pusat
  final List<String> dialogIcons = [
    'money', 'bank', 'wallet', 'card', 'savings', 'crypto', 'business'
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
    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!hasConnection) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase.from('wallets').select('name').eq('user_id', userId);
      setState(() {
        _existingWallets = (response as List).map((e) => e['name'].toString().toLowerCase()).toList();
      });
    } catch (e) {
      debugPrint('Gagal mengambil data dompet: $e');
    }
  }

  void _showAddWalletDialog() {
    TextEditingController nameController = TextEditingController();
    String tempIconId = dialogIcons[0];

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
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Cth: ShopeePay',
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Pilih Ikon:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: dialogIcons.map((iconId) {
                        bool isSelected = tempIconId == iconId;

                        // SEKARANG DRY: Meminta aset dari WalletHelper pusat
                        dynamic currentIcon = WalletHelper.getIcon(iconId, '');
                        Color currentColor = WalletHelper.getColor(nameController.text.isNotEmpty ? nameController.text : iconId);

                        return GestureDetector(
                          onTap: () => setStateDialog(() {
                            tempIconId = iconId;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? currentColor.withValues(alpha: 0.2) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? currentColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
                            ),
                            child: FaIcon(currentIcon, color: isSelected ? currentColor : Colors.grey, size: 20),
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
                    if (nameController.text.trim().isNotEmpty) {
                      setState(() {
                        walletTemplates.insert(walletTemplates.length - 1, {
                          'name': nameController.text.trim(),
                          'icon_id': tempIconId,
                        });
                        selectedWalletName = nameController.text.trim();
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
      CustomNotification.show(context, 'Silakan pilih atau buat dompet terlebih dahulu!', isWarning: true);
      return;
    }

    if (_existingWallets.contains(selectedWalletName.toLowerCase())) {
      CustomNotification.show(context, 'Dompet "$selectedWalletName" sudah ada di daftar Anda!', isWarning: true);
      return;
    }

    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!hasConnection) return;

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      int initialBalance = 0;
      if (_balanceController.text.isNotEmpty) {
        final cleanAmount = _balanceController.text.replaceAll('.', '');
        initialBalance = int.parse(cleanAmount);
      }

      await supabase.from('wallets').insert({
        'name': selectedWalletName.trim(),
        'balance': initialBalance,
        'icon_name': selectedIconId,
        'user_id': userId,
      });

      if (mounted) {
        CustomNotification.show(context, 'Dompet berhasil ditambahkan!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal menyimpan');
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

                // SEKARANG DRY: Mintakan aset visual langsung ke WalletHelper pusat
                dynamic iconData = isNew ? FontAwesomeIcons.plus : WalletHelper.getIcon(template['icon_id'], template['name']!);
                Color colorData = isNew ? Colors.grey : WalletHelper.getColor(template['name']!);

                return _buildWalletItem(iconData, template['name']!, colorData, template['icon_id']!, isDark, cardColor, itemWidth, isNew: isNew);
              }).toList(),
            ),
            const SizedBox(height: 32),

            const Text('SALDO AWAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
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

  Widget _buildWalletItem(dynamic icon, String label, Color color, String iconId, bool isDark, Color cardColor, double itemWidth, {bool isNew = false}) {
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
                color: isNew ? cardColor : (isSelected ? color.withValues(alpha: 0.2) : cardColor),
                shape: BoxShape.circle,
                border: isNew ? Border.all(color: Colors.grey.shade500) : (isSelected ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent)),
                boxShadow: (isDark || isSelected) ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: FaIcon(icon, color: color, size: 20),
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