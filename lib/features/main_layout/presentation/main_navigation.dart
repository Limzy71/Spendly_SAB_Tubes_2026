import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../report/presentation/report_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../transaction/presentation/add_transaction_screen.dart';
import '../../../theme/app_colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Halaman Anggaran dihapus dari sini (nanti diakses via Report)
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ReportScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi tema untuk menyesuaikan warna background dan icon
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? (isDark ? Colors.black : Colors.white);
    Color unselectedColor = isDark ? Colors.white54 : Colors.grey;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: _screens[_selectedIndex],

      // FAB di tengah untuk Tambah Transaksi
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BottomAppBar melengkung untuk tempat FAB
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Menu Kiri
              Row(
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'Beranda', unselectedColor),
                  _buildNavItem(1, Icons.bar_chart_outlined, Icons.bar_chart, 'Laporan', unselectedColor),
                ],
              ),
              // Menu Kanan
              Row(
                children: [
                  _buildNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Dompet', unselectedColor),
                  _buildNavItem(3, Icons.person_outline, Icons.person, 'Profil', unselectedColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget builder untuk item menu bawah
  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, String label, Color unselectedColor) {
    bool isSelected = _selectedIndex == index;
    return MaterialButton(
      minWidth: 65,
      padding: EdgeInsets.zero,
      onPressed: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? iconFilled : iconOutlined,
            color: isSelected ? AppColors.primaryGreen : unselectedColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primaryGreen : unselectedColor,
            ),
          ),
        ],
      ),
    );
  }
}