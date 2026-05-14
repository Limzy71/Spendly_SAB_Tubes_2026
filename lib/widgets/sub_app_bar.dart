import 'package:flutter/material.dart';

class SubAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SubAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      // Latar belakang disamakan dengan warna Scaffold (layar utama)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}