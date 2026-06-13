import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../theme/app_colors.dart';
import '../../profile/presentation/notification_screen.dart';
import '../../../widgets/profile_image_cache.dart';
import '../../../../widgets/network_helper.dart';

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
  bool _hasUnreadNotifications = false;
  String _currentLatestVersion = '';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _checkUnreadNotifications();
  }

  Future<void> _loadProfileImage() async {
    final user = Supabase.instance.client.auth.currentUser;
    final String? supabaseAvatarUrl = user?.userMetadata?['avatar_url'];
    final userId = user?.id ?? '';

    if (supabaseAvatarUrl != null && supabaseAvatarUrl.isNotEmpty) {
      if (mounted) setState(() => _profileImagePath = supabaseAvatarUrl);
      return;
    }

    if (userId.isEmpty) {
      if (mounted) setState(() => _profileImagePath = null);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final localPath = prefs.getString(ProfileImageCache.keyForUser(userId));
    if (mounted) setState(() => _profileImagePath = localPath);
  }

  Future<void> _checkUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';

    bool isOnline = await NetworkHelper.checkConnection(context);
    if (!isOnline) return;

    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final txData = await Supabase.instance.client
          .from('transactions')
          .select('id')
          .eq('user_id', userId)
          .eq('transaction_date', todayStr);

      final walletData = await Supabase.instance.client
          .from('wallets')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', '${todayStr}T00:00:00');

      int latestActivityCount = (txData as List).length + (walletData as List).length;

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentAppVersion = packageInfo.version;

      final versionResponse = await Supabase.instance.client
          .from('app_settings')
          .select('value')
          .eq('key', 'latest_version')
          .maybeSingle();

      if (versionResponse != null && versionResponse['value'] != null) {
        _currentLatestVersion = versionResponse['value'];
      }

      int savedActivityCount = prefs.getInt('activity_count_$userId') ?? -1;
      bool hasNewActivity = false;
      if (savedActivityCount == -1 && latestActivityCount > 0) {
        hasNewActivity = true;
      } else if (latestActivityCount > savedActivityCount) {
        hasNewActivity = true;
      }

      String lastSeenVersion = prefs.getString('last_seen_update_$userId') ?? '';
      bool hasNewUpdate = false;
      if (_currentLatestVersion.isNotEmpty && currentAppVersion != _currentLatestVersion && lastSeenVersion != _currentLatestVersion) {
        hasNewUpdate = true;
      }

      if (mounted) {
        setState(() {
          _hasUnreadNotifications = hasNewActivity || hasNewUpdate;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
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
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              FaIcon(
                FontAwesomeIcons.bell,
                size: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
              if (_hasUnreadNotifications)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).appBarTheme.backgroundColor ?? Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () async {
            if (!mounted) return;
            final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
            final prefs = await SharedPreferences.getInstance();

            if (mounted) {
              setState(() {
                _hasUnreadNotifications = false;
              });
            }

            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationScreen()),
            );

            try {
              final todayStr = DateTime.now().toIso8601String().split('T')[0];
              final txData = await Supabase.instance.client.from('transactions').select('id').eq('user_id', userId).eq('transaction_date', todayStr);
              final walletData = await Supabase.instance.client.from('wallets').select('id').eq('user_id', userId).gte('created_at', '${todayStr}T00:00:00');

              int finalCount = (txData as List).length + (walletData as List).length;
              await prefs.setInt('activity_count_$userId', finalCount);

              if (_currentLatestVersion.isNotEmpty) {
                await prefs.setString('last_seen_update_$userId', _currentLatestVersion);
              }
            } catch (_) {}

            _checkUnreadNotifications();
          },
        ),
      ],
    );
  }
}