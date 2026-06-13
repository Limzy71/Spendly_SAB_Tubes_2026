import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../theme/app_colors.dart';
import '../../transaction/presentation/add_transaction_screen.dart';
import '../../transaction/presentation/edit_transaction_screen.dart';
import '../../../../widgets/network_helper.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  bool _hasTransactionToday = false;
  bool _isUpdateAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAppUpdate();
    _loadActivityData();
  }

  Future<void> _checkAppUpdate() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final response = await supabase
          .from('app_settings')
          .select('value')
          .eq('key', 'latest_version')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        String latestVersion = response['value'];
        if (currentVersion != latestVersion) {
          if (mounted) {
            setState(() {
              _isUpdateAvailable = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadActivityData() async {
    bool isOnline = await NetworkHelper.checkConnection(context);
    if (!mounted) return;
    if (!isOnline) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      List<Map<String, dynamic>> tempActivities = [];
      DateTime now = DateTime.now();
      bool hasTxToday = false;

      final todayStr = now.toIso8601String().split('T')[0];
      final firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

      final txResponse = await supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('transaction_date', todayStr)
          .neq('category', 'Transfer')
          .order('created_at', ascending: false)
          .limit(10);

      if (txResponse.isNotEmpty) {
        hasTxToday = true;
      }

      for (var tx in txResponse) {
        bool isExpense = tx['is_expense'] == true;
        int amount = int.tryParse(tx['amount'].toString()) ?? 0;
        String cat = tx['category'] ?? 'Lainnya';
        String timeStr = tx['created_at'].toString();

        tempActivities.add({
          'type': isExpense ? 'expense' : 'income',
          'title': isExpense ? 'Pengeluaran Baru' : 'Pemasukan Baru',
          'body': 'Mencatat $cat sebesar ${_formatCurrency(amount)}',
          'timestamp': DateTime.parse(timeStr),
          'icon': isExpense ? FontAwesomeIcons.arrowTrendDown : FontAwesomeIcons.arrowTrendUp,
          'color': isExpense ? Colors.red : AppColors.primaryGreen,
          'transaction_data': tx,
        });
      }

      final currentMonthStr = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final budgetResponse = await supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('period_month', currentMonthStr);

      final monthTxResponse = await supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('is_expense', true)
          .neq('category', 'Transfer')
          .gte('transaction_date', firstDayOfMonth)
          .lte('transaction_date', lastDayOfMonth);

      Map<String, int> spentPerCat = {};
      for (var tx in monthTxResponse) {
        String cat = tx['category'].toString().toLowerCase();
        int amount = int.tryParse(tx['amount'].toString()) ?? 0;
        spentPerCat[cat] = (spentPerCat[cat] ?? 0) + amount;
      }

      for (var b in budgetResponse) {
        String cat = b['category'].toString();
        int limit = int.tryParse(b['limit_amount'].toString()) ?? 0;
        int spent = spentPerCat[cat.toLowerCase()] ?? 0;

        if (limit > 0) {
          double percentage = spent / limit;
          if (percentage >= 0.8) {
            tempActivities.add({
              'type': 'budget_alert',
              'title': 'Peringatan Anggaran',
              'body': 'Anggaran $cat sudah terpakai ${(percentage * 100).toInt()}%. Hati-hati overbudget!',
              'timestamp': now,
              'icon': FontAwesomeIcons.triangleExclamation,
              'color': Colors.orange,
              'transaction_data': null,
            });
          }
        }
      }

      final walletResponse = await supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .gte('created_at', '${now.toIso8601String().split('T')[0]}T00:00:00');

      for (var w in walletResponse) {
        tempActivities.add({
          'type': 'wallet_new',
          'title': 'Dompet Baru Dibuat',
          'body': 'Berhasil menambahkan dompet ${w['name']}',
          'timestamp': DateTime.parse(w['created_at'].toString()),
          'icon': FontAwesomeIcons.wallet,
          'color': Colors.blue,
          'transaction_data': null,
        });
      }

      tempActivities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      if (mounted) {
        setState(() {
          _activities = tempActivities;
          _hasTransactionToday = hasTxToday;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _getTimeAgo(DateTime date) {
    Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} hari yang lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit yang lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifikasi', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivityData,
        color: AppColors.primaryGreen,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_isUpdateAvailable)
              _buildFeaturedNotifItem(
                context,
                FontAwesomeIcons.rocket,
                AppColors.primaryGreen,
                'Update Tersedia! 🎉',
                'Versi terbaru Spendly sudah tersedia di Play Store. Segera perbarui untuk menikmati fitur baru!',
                'Pesan Sistem',
                isDark,
              ),

            _buildFeaturedNotifItem(
              context,
              FontAwesomeIcons.champagneGlasses,
              AppColors.primaryGreen,
              'Selamat Datang di Spendly!',
              'Terima kasih telah menggunakan aplikasi pencatatan keuangan ini.',
              'Awal pembuatan akun',
              isDark,
            ),

            if (!_isLoading && !_hasTransactionToday)
              _buildFeaturedNotifItem(
                context,
                FontAwesomeIcons.wallet,
                Colors.blue,
                'Waktu untuk Mencatat',
                'Anda belum mencatat pengeluaran atau pemasukan hari ini. Yuk catat sekarang!',
                'Pengingat Harian',
                isDark,
                isClickable: true,
              ),

            const SizedBox(height: 16),
            const Text('Aktivitas Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
              )
            else if (_activities.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                child: Text(
                  'Belum ada aktivitas hari ini. Tambahkan transaksi, buat dompet, atau atur anggaran untuk melihat riwayat aktivitas di sini.',
                  style: TextStyle(color: Colors.grey.shade500, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._activities.map((item) => _buildActivityItem(context, item, isDark, textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Map<String, dynamic> item, bool isDark, Color textColor) {
    Color iconColor = item['color'];
    dynamic iconData = item['icon'];
    bool isTransaction = item['type'] == 'expense' || item['type'] == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isTransaction && item['transaction_data'] != null
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditTransactionScreen(
                  transaction: item['transaction_data'],
                ),
              ),
            ).then((_) => _loadActivityData());
          }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.12),
                  child: FaIcon(iconData, color: iconColor, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['body'],
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTimeAgo(item['timestamp']),
                        style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (isTransaction)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedNotifItem(
      BuildContext context,
      dynamic icon,
      Color color,
      String title,
      String subtitle,
      String time,
      bool isDark, {
        bool isClickable = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isClickable
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
            ).then((_) => _loadActivityData());
          }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: FaIcon(icon, color: color, size: 18)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(time, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (isClickable)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}