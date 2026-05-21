import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../profile/presentation/notification_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onProfileTap;

  const CustomAppBar({super.key, this.onProfileTap});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final user = Supabase.instance.client.auth.currentUser;
    final String? supabaseAvatarUrl = user?.userMetadata?['avatar_url'];

    if (supabaseAvatarUrl != null && supabaseAvatarUrl.isNotEmpty) {
      if (mounted) setState(() => _profileImagePath = supabaseAvatarUrl);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final localPath = prefs.getString('profile_image_path');
    if (mounted) setState(() => _profileImagePath = localPath);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    ImageProvider? imageProvider;
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      if (_profileImagePath!.startsWith('http://') || _profileImagePath!.startsWith('https://')) {
        imageProvider = NetworkImage(_profileImagePath!);
      } else {
        imageProvider = FileImage(File(_profileImagePath!));
      }
    }

    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 10.0),
        child: GestureDetector(
          onTap: widget.onProfileTap,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 20, color: Colors.white)
                : null,
          ),
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
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationScreen()),
            );
          },
        ),
      ],
    );
  }
}