import 'package:shared_preferences/shared_preferences.dart';

class PinHelper {
  static const String legacyPinKey = 'user_pin';
  static const String legacyPinEnabledKey = 'is_pin_enabled';
  static const String legacyBiometricEnabledKey = 'is_biometric_enabled';

  static String userPinKey(String userId) => 'user_pin_$userId';
  static String pinEnabledKey(String userId) => 'is_pin_enabled_$userId';
  static String biometricEnabledKey(String userId) => 'is_biometric_enabled_$userId';

  static Future<void> migrateLegacyPinIfNeeded(String userId) async {
    if (userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final perUserPin = prefs.getString(userPinKey(userId));

    if (perUserPin != null && perUserPin.isNotEmpty) {
      return;
    }

    final legacyPin = prefs.getString(legacyPinKey);
    if (legacyPin == null || legacyPin.isEmpty) {
      return;
    }

    await prefs.setString(userPinKey(userId), legacyPin);

    final legacyPinEnabled = prefs.getBool(legacyPinEnabledKey) ?? false;
    await prefs.setBool(pinEnabledKey(userId), legacyPinEnabled || legacyPin.isNotEmpty);

    final legacyBiometricEnabled = prefs.getBool(legacyBiometricEnabledKey) ?? false;
    if (legacyBiometricEnabled) {
      await prefs.setBool(biometricEnabledKey(userId), true);
    }

    await prefs.remove(legacyPinKey);
    await prefs.remove(legacyPinEnabledKey);
    await prefs.remove(legacyBiometricEnabledKey);
  }
}
