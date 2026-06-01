import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../main.dart';
import '../../../../widgets/custom_notification.dart';
import '../../transaction/presentation/add_transaction_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await NotificationHelper.loadHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _isLoadingHistory = false;
    });
  }

  Future<void> _clearCurrentAccountHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hapus Riwayat?',
                        style: TextStyle(
                          color: Theme.of(dialogContext).textTheme.bodyLarge?.color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Riwayat notifikasi berhasil di hapus.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(dialogContext).textTheme.bodyLarge?.color,
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Hapus'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    await NotificationHelper.clearHistory();
    if (!mounted) return;

    setState(() {
      _history = [];
    });

    CustomNotification.show(context, 'Riwayat notifikasi berhasil dihapus.');
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
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (value) {
              if (value == 'clear') {
                _clearCurrentAccountHistory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clear',
                child: Text('Hapus Riwayat'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const ClampingScrollPhysics(),
        children: [
          _buildFeaturedNotifItem(
            context,
            Icons.celebration,
            AppColors.primaryGreen,
            'Selamat Datang di Spendly!',
            'Terima kasih telah menggunakan aplikasi pencatatan keuangan ini.',
            'Pada saat pembuatan akun',
            isDark,
          ),
          _buildFeaturedNotifItem(
            context,
            Icons.account_balance_wallet,
            Colors.blue,
            'Waktu untuk Mencatat',
            'Jangan lupa mencatat pengeluaran dan pemasukan harian Anda.',
            'Pada saat aplikasi dibuka',
            isDark,
            isClickable: true,
          ),
          if (_isLoadingHistory)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
            )
          else if (_history.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Text(
                'Belum ada riwayat notifikasi. Saat pengingat dijadwalkan atau dibuka, aktivitasnya akan muncul di sini.',
                style: TextStyle(color: Colors.grey.shade400, height: 1.4),
              ),
            )
          else
            ..._history.take(8).map((item) => _buildHistoryItem(context, item, isDark, textColor)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> item, bool isDark, Color textColor) {
    final type = (item['type'] as String?) ?? 'opened';
    final timestamp = DateTime.tryParse((item['timestamp'] as String?) ?? '') ?? DateTime.now();
    final formattedTime = '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')} • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    Color iconColor;
    IconData iconData;
    switch (type) {
      case 'scheduled_daily':
        iconColor = AppColors.primaryGreen;
        iconData = Icons.schedule;
        break;
      case 'scheduled_bill':
        iconColor = Colors.orange;
        iconData = Icons.receipt_long;
        break;
      case 'opened':
        iconColor = Colors.blue;
        iconData = Icons.notifications_active;
        break;
      default:
        iconColor = Colors.grey;
        iconData = Icons.notifications;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(iconData, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['title'] as String?) ?? '-',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (item['body'] as String?) ?? '-',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedTime,
                    style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedNotifItem(
    BuildContext context,
    IconData icon,
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
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
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