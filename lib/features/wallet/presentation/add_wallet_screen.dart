import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/sub_app_bar.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/wallet_helper.dart';
import '../../../../widgets/network_helper.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController _balanceController = TextEditingController();
  final FocusNode _balanceFocusNode = FocusNode();
  bool _isLoading = false;

  String selectedWalletName = 'Uang Tunai';
  String selectedIconId = 'money';

  List<String> _existingWallets = [];

  List<Map<String, String>> visibleGrid = [];
  List<Map<String, String>> hiddenGrid = [];

  final List<Map<String, String>> allTemplatesData = [
    {'name': 'Uang Tunai', 'icon_id': 'money'},
    {'name': 'Bank BCA', 'icon_id': 'bank'},
    {'name': 'Bank Mandiri', 'icon_id': 'bank'},
    {'name': 'Bank BRI', 'icon_id': 'bank'},
    {'name': 'Bank BNI', 'icon_id': 'bank'},
    {'name': 'GoPay', 'icon_id': 'wallet'},
    {'name': 'OVO', 'icon_id': 'wallet'},
    {'name': 'DANA', 'icon_id': 'wallet'},
    {'name': 'ShopeePay', 'icon_id': 'wallet'},
    {'name': 'LinkAja', 'icon_id': 'wallet'},
    {'name': 'Bank Jago', 'icon_id': 'bank'},
    {'name': 'SeaBank', 'icon_id': 'bank'},
    {'name': 'blu', 'icon_id': 'bank'},
    {'name': 'Jenius', 'icon_id': 'bank'},
    {'name': 'Allo Bank', 'icon_id': 'bank'},
    {'name': 'Bank Neo', 'icon_id': 'bank'},
    {'name': 'Flip', 'icon_id': 'wallet'},
    {'name': 'iSaku', 'icon_id': 'wallet'},
    {'name': 'Krom', 'icon_id': 'bank'},
    {'name': 'Skrill', 'icon_id': 'wallet'},
    {'name': 'Superbank', 'icon_id': 'bank'},
    {'name': 'PayPal', 'icon_id': 'paypal'},
    {'name': 'Maybank', 'icon_id': 'bank'},
    {'name': 'Bank Sinarmas', 'icon_id': 'bank'},
    {'name': 'Bank Permata', 'icon_id': 'bank'},
    {'name': 'Bank Panin', 'icon_id': 'bank'},
    {'name': 'Bank OCBC', 'icon_id': 'bank'},
    {'name': 'Bank Mega', 'icon_id': 'bank'},
    {'name': 'Bank Danamon', 'icon_id': 'bank'},
    {'name': 'Bank CIMB Niaga', 'icon_id': 'bank'},
    {'name': 'Bank BTN', 'icon_id': 'bank'},
    {'name': 'Bank BSI', 'icon_id': 'bank'}
  ];

  final List<String> defaultVisible = [
    'Uang Tunai', 'Bank BCA', 'Bank Mandiri', 'Bank BRI', 'Bank BNI', 'GoPay',
    'OVO', 'DANA', 'ShopeePay', 'LinkAja', 'Bank Jago', 'SeaBank'
  ];

  @override
  void initState() {
    super.initState();
    _fetchExistingWallets();
    _loadTemplates();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _balanceFocusNode.dispose();
    super.dispose();
  }

  String _getVisiblePrefsKey() {
    final userId = supabase.auth.currentUser?.id ?? 'guest';
    return 'visible_template_names_v3_$userId';
  }

  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> visibleNames = prefs.getStringList(_getVisiblePrefsKey()) ?? defaultVisible;

    setState(() {
      visibleGrid = visibleNames
          .map((name) => allTemplatesData.firstWhere((t) => t['name'] == name, orElse: () => {'name': name, 'icon_id': 'wallet'}))
          .where((t) => allTemplatesData.any((a) => a['name'] == t['name']))
          .toList();

      hiddenGrid = allTemplatesData.where((t) => !visibleNames.contains(t['name'])).toList();
    });
  }

  Future<void> _hideTemplate(String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> visibleNames = prefs.getStringList(_getVisiblePrefsKey()) ?? defaultVisible;

    visibleNames.remove(name);
    await prefs.setStringList(_getVisiblePrefsKey(), visibleNames);

    if (selectedWalletName == name) {
      selectedWalletName = '';
      selectedIconId = '';
    }
    _loadTemplates();
  }

  Future<void> _restoreTemplate(String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> visibleNames = prefs.getStringList(_getVisiblePrefsKey()) ?? defaultVisible;

    if (!visibleNames.contains(name)) {
      visibleNames.add(name);
    }
    await prefs.setStringList(_getVisiblePrefsKey(), visibleNames);
    _loadTemplates();
  }

  Future<void> _fetchExistingWallets() async {
    bool hasConnection = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!hasConnection) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase.from('wallets').select('name').eq('user_id', userId);
      if (!mounted) return;
      setState(() {
        _existingWallets = (response as List).map((e) => e['name'].toString().toLowerCase()).toList();
      });
    } catch (e) {
      debugPrint('Gagal mengambil data dompet: $e');
      if (mounted) {
        CustomNotification.show(context, 'Gagal memuat data dompet. Pastikan koneksi internet stabil.', isError: true);
      }
    }
  }

  void _showHideDialog(String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sembunyikan Ikon?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Anda bisa memunculkan "$label" kembali melalui tombol Baru (+).', style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(ctx);
              _hideTemplate(label);
            },
            child: const Text('Sembunyikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddWalletDialog() {
    String tempSelectedName = '';
    String tempIconId = '';
    bool isDarkDialog = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Pilih Dompet Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (hiddenGrid.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text('Semua pilihan dompet sudah ditampilkan di halaman utama.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                        )
                      else ...[
                        const Text('Daftar Dompet Tersedia:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 16,
                          children: hiddenGrid.map((template) {
                            bool isSelected = tempSelectedName == template['name'];
                            Color brandColor = WalletHelper.getColor(template['name']!);

                            return GestureDetector(
                              onTap: () {
                                setStateDialog(() {
                                  tempSelectedName = template['name']!;
                                  tempIconId = template['icon_id']!;
                                });
                              },
                              child: SizedBox(
                                width: 70,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? brandColor.withValues(alpha: 0.15) : (isDarkDialog ? Colors.white10 : Colors.grey.shade100),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? brandColor : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: WalletHelper.getIcon(template['icon_id'], template['name']!, size: 16, color: isSelected ? brandColor : null),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      template['name']!,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? brandColor : (isDarkDialog ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
                if (hiddenGrid.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      if (tempSelectedName.isNotEmpty) {
                        await _restoreTemplate(tempSelectedName);
                        setState(() {
                          selectedWalletName = tempSelectedName;
                          selectedIconId = tempIconId;
                        });
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      } else {
                        CustomNotification.show(ctx, 'Silakan pilih salah satu dompet', isWarning: true);
                      }
                    },
                    child: const Text('Pilih', style: TextStyle(color: Colors.white)),
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
        initialBalance = int.tryParse(cleanAmount) ?? 0;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PILIH DOMPET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const Text('Tahan untuk sembunyikan', style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.start,
              children: [
                ...visibleGrid.map((template) {
                  Color colorData = WalletHelper.getColor(template['name']!);
                  dynamic iconData = WalletHelper.getIcon(template['icon_id'], template['name']!, color: colorData, size: 18);
                  return _buildWalletItem(iconData, template['name']!, colorData, template['icon_id']!, isDark, cardColor, itemWidth);
                }),
                _buildWalletItem(
                  const FaIcon(FontAwesomeIcons.plus, color: Colors.grey, size: 18),
                  'Baru',
                  Colors.grey,
                  'add',
                  isDark,
                  cardColor,
                  itemWidth,
                  isNew: true,
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text('SALDO AWAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(_balanceFocusNode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Rp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: IntrinsicWidth(
                            child: TextField(
                              controller: _balanceController,
                              focusNode: _balanceFocusNode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [LengthLimitingTextInputFormatter(18)],
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
                                  clean = clean.replaceFirst(RegExp(r'^0+'), '');
                                  if (clean.isEmpty) {
                                    _balanceController.value = const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
                                    return;
                                  }
                                  String formatted = NumberFormat.decimalPattern('id').format(int.tryParse(clean) ?? 0);
                                  _balanceController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
      onLongPress: isNew ? null : () => _showHideDialog(label),
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
              child: icon,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}