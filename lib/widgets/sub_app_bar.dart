import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SubAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SubAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 110,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryGreen, size: 20),
            SizedBox(width: 6),
            Text('Spendly', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
      centerTitle: true,
      title: Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal)
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}