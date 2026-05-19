import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../transaction/presentation/add_transaction_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _timeAgo = 'Baru saja';

  @override
  void initState() {
    super.initState();
    _calculateTimeAgo();
  }

  Future<void> _calculateTimeAgo() async {
    final prefs = await SharedPreferences.getInstance();
    int savedHour = prefs.getInt('reminder_hour') ?? 20;
    int savedMinute = prefs.getInt('reminder_minute') ?? 0;

    DateTime now = DateTime.now();
    DateTime alarmTime = DateTime(now.year, now.month, now.day, savedHour, savedMinute);

    if (alarmTime.isAfter(now)) {
      alarmTime = alarmTime.subtract(const Duration(days: 1));
    }

    Duration diff = now.difference(alarmTime);

    String timeText = '';
    if (diff.inMinutes < 60) {
      timeText = diff.inMinutes <= 1 ? 'Baru saja' : '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      timeText = '${diff.inHours} jam lalu';
    } else {
      timeText = '${diff.inDays} hari lalu';
    }

    setState(() {
      _timeAgo = timeText;
    });
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const ClampingScrollPhysics(),
        children: [
          _buildNotifItem(
            context,
            Icons.celebration,
            AppColors.primaryGreen,
            'Selamat Datang di Spendly!',
            'Terima kasih telah menggunakan aplikasi pencatat keuangan kami.',
            'Saat pendaftaran',
            isDark,
            isClickable: false,
          ),
          _buildNotifItem(
            context,
            Icons.account_balance_wallet,
            Colors.blue,
            'Waktunya mencatat!',
            'Jangan lupa catat pengeluaran dan pemasukan harianmu.',
            _timeAgo,
            isDark,
            isClickable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotifItem(BuildContext context, IconData icon, Color color, String title, String subtitle, String time, bool isDark, {required bool isClickable}) {
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
          onTap: isClickable ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
            );
          } : null,
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
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
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
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}