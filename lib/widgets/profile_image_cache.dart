import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageCache {
  static const String legacyKey = 'profile_image_path';

  static String keyForUser(String userId) => 'profile_image_path_$userId';

  static Future<void> clearLegacyKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyKey);
  }
}