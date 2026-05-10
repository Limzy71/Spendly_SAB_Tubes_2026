import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../report/presentation/report_screen.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ReportScreen(),
    const BudgetScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,

        // Memaksa background mengikuti tema (Hitam saat gelap)
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,

        // MEMAKSA warna ikon saat aktif menjadi Hijau Spendly
        selectedItemColor: const Color(0xFF05A660),

        // MEMAKSA warna ikon saat tidak aktif menjadi Abu-abu terang (agar tidak mati di hitam)
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white54
            : Colors.grey,

        // Tambahkan ini untuk memastikan label juga ikut berubah warna
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),

        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Laporan'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined),
              activeIcon: Icon(Icons.account_balance),
              label: 'Anggaran'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Dompet'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil'
          ),
        ],
      ),
    );
  }
}