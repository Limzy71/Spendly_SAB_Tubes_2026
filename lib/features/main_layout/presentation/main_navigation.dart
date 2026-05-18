import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'custom_app_bar.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../report/presentation/report_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../transaction/presentation/add_transaction_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/custom_notification.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  Key _dashboardKey = UniqueKey();
  Key _reportKey = UniqueKey();
  Key _walletKey = UniqueKey();

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0 && _selectedIndex != 0) _dashboardKey = UniqueKey();
      if (index == 1 && _selectedIndex != 1) _reportKey = UniqueKey();
      if (index == 2 && _selectedIndex != 2) _walletKey = UniqueKey();
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
      appBar: CustomAppBar(
        onProfileTap: () => _onItemTapped(3),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(key: _dashboardKey),
          ReportScreen(key: _reportKey),
          WalletScreen(key: _walletKey),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );

          if (result is String) {
            setState(() {
              _selectedIndex = 0;
              _dashboardKey = UniqueKey();
              _reportKey = UniqueKey();
              _walletKey = UniqueKey();
            });

            if (context.mounted) {
              CustomNotification.show(context, result);
            }
          }
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
              const SizedBox(width: 56),
              _buildNavItem(2, FontAwesomeIcons.wallet, 'Dompet', unselectedColor),
              _buildNavItem(3, FontAwesomeIcons.user, 'Profil', unselectedColor),
            ],
          ),
        ),
      ),
    );
  }

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