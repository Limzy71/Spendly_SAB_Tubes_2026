import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  Key _dashboardKey = UniqueKey();

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0 && _selectedIndex != 0) {
        _dashboardKey = UniqueKey();
      }
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? (isDark ? Colors.black : Colors.white);
    Color unselectedColor = isDark ? Colors.white54 : Colors.grey;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const CustomAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(key: _dashboardKey),
          const ReportScreen(),
          const WalletScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
          setState(() {
            _dashboardKey = UniqueKey();
          });
        },
        backgroundColor: AppColors.primaryGreen,
        shape: const CircleBorder(),
        elevation: 4,
        child: const FaIcon(FontAwesomeIcons.plus, size: 24, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: bgColor,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, FontAwesomeIcons.house, 'Beranda', unselectedColor),
              _buildNavItem(1, FontAwesomeIcons.chartSimple, 'Laporan', unselectedColor),
              const SizedBox(width: 56), // Spasi untuk Floating Action Button
              _buildNavItem(2, FontAwesomeIcons.wallet, 'Dompet', unselectedColor),
              _buildNavItem(3, FontAwesomeIcons.user, 'Profil', unselectedColor),
            ],
          ),
        ),
      ),
    );
  }

  // Mengubah parameter icon menjadi tipe dinamis (dynamic) untuk menampung FontAwesome
  Widget _buildNavItem(int index, dynamic icon, String label, Color unselectedColor) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: MaterialButton(
        padding: EdgeInsets.zero,
        onPressed: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              color: isSelected ? AppColors.primaryGreen : unselectedColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryGreen : unselectedColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}