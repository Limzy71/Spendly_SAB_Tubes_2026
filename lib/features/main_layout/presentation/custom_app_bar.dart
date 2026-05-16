import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- Tambahkan import Supabase
import 'package:shared_preferences/shared_preferences.dart'; // <-- Tambahkan import SharedPreferences
import '../../../theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  // Fungsi pembantu untuk mengambil data path/url foto profil terbaru
  Future<String?> _getProfileImage() async {
    // 1. Coba cek dari metadata Supabase terlebih dahulu
    final user = Supabase.instance.client.auth.currentUser;
    final String? supabaseAvatarUrl = user?.userMetadata?['avatar_url'];
    if (supabaseAvatarUrl != null && supabaseAvatarUrl.isNotEmpty) {
      return supabaseAvatarUrl;
    }

    // 2. Jika di Supabase belum ada (offline/gagal load), ambil dari lokal cache HP
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image_path');
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 10.0),
        child: FutureBuilder<String?>(
          future: _getProfileImage(),
          builder: (context, snapshot) {
            final imagePath = snapshot.data;

            // Variabel penampung provider gambar
            ImageProvider? imageProvider;

            if (imagePath != null && imagePath.isNotEmpty) {
              if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
                // Jika dari database berupa link URL internet
                imageProvider = NetworkImage(imagePath);
              } else {
                // Jika dari local cache berupa path file HP
                imageProvider = FileImage(File(imagePath));
              }
            }

            return CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                  : null,
            );
          },
        ),
      ),
      title: const Text(
        'Spendly',
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          padding: const EdgeInsets.only(right: 16),
          icon: FaIcon(
            FontAwesomeIcons.bell,
            size: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}