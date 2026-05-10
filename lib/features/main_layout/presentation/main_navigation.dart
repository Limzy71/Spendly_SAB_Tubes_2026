import 'package:flutter/material.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../report/presentation/report_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../transaction/presentation/add_transaction_screen.dart';
import '../../../theme/app_colors.dart';
import 'custom_app_bar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Sekarang cuma ada 4 halaman, karena posisi tengah adalah FAB
  final List<Widget> _pages = [
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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const CustomAppBar(),

      body: _pages[_selectedIndex],

      // TOMBOL "+" SEKARANG ADA DI SINI (TERPUSAT)
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

      // MEMBUAT TOMBOL MENEMPEL DI TENGAH
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildNavItem(0, Icons.home_filled, "Beranda"),
                _buildNavItem(1, Icons.bar_chart_rounded, "Laporan"),
              ],
            ),
            Row(
              children: [
                _buildNavItem(2, Icons.account_balance_wallet_rounded, "Dompet"),
                _buildNavItem(3, Icons.person_rounded, "Profil"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk membuat item menu yang rapi
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return MaterialButton(
      minWidth: 40,
      onPressed: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryGreen : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primaryGreen : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}