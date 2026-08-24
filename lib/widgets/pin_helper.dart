import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String legacyPinKey = 'user_pin';
  static const String legacyPinEnabledKey = 'is_pin_enabled';
  static const String legacyBiometricEnabledKey = 'is_biometric_enabled';

  static const String _securePinKeyPrefix = 'spendly_secure_pin_';
  static const String _legacyPrefsPinKeyPrefix = 'user_pin_';

  static String userPinKey(String userId) => '$_legacyPrefsPinKeyPrefix$userId';
  static String pinEnabledKey(String userId) => 'is_pin_enabled_$userId';
  static String biometricEnabledKey(String userId) =>
      'is_biometric_enabled_$userId';

  static String _secureKey(String userId) => '$_securePinKeyPrefix$userId';

  static Future<void> migrateLegacyPinIfNeeded(String userId) async {
    if (userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final legacyGlobalPin = prefs.getString(legacyPinKey);
    if (legacyGlobalPin != null && legacyGlobalPin.isNotEmpty) {
      final perUserPin = prefs.getString(userPinKey(userId));
      if (perUserPin == null || perUserPin.isEmpty) {
        await prefs.setString(userPinKey(userId), legacyGlobalPin);

        final legacyPinEnabled = prefs.getBool(legacyPinEnabledKey) ?? false;
        await prefs.setBool(
          pinEnabledKey(userId),
          legacyPinEnabled || legacyGlobalPin.isNotEmpty,
        );

        final legacyBiometricEnabled =
            prefs.getBool(legacyBiometricEnabledKey) ?? false;
        if (legacyBiometricEnabled) {
          await prefs.setBool(biometricEnabledKey(userId), true);
        }
      }

      await prefs.remove(legacyPinKey);
      await prefs.remove(legacyPinEnabledKey);
      await prefs.remove(legacyBiometricEnabledKey);
    }

    final plainPin = prefs.getString(userPinKey(userId));
    if (plainPin != null && plainPin.isNotEmpty) {
      try {
        final securePin = await _storage.read(key: _secureKey(userId));
        if (securePin == null || securePin.isEmpty) {
          await _storage.write(key: _secureKey(userId), value: plainPin);
        }
        await prefs.remove(userPinKey(userId));
      } catch (_) {
        return;
      }
    }
  }

  static Future<String?> getPin(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final securePin = await _storage.read(key: _secureKey(userId));
      if (securePin != null && securePin.isNotEmpty) return securePin;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userPinKey(userId));
  }

  static Future<bool> hasPin(String userId) async {
    final pin = await getPin(userId);
    return pin != null && pin.isNotEmpty;
  }

  static Future<bool> verifyPin(String userId, String inputPin) async {
    final storedPin = await getPin(userId);
    if (storedPin == null) return false;
    return _constantTimeEquals(storedPin, inputPin);
  }

  static Future<void> savePin(String userId, String pin) async {
    await _storage.write(key: _secureKey(userId), value: pin);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userPinKey(userId));
    await prefs.setBool(pinEnabledKey(userId), true);
  }

  static Future<void> deletePin(String userId) async {
    await _storage.delete(key: _secureKey(userId));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userPinKey(userId));
  }

  static Future<void> setPinEnabled(String userId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pinEnabledKey(userId), enabled);
  }

  static Future<bool> isPinEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final perUser = prefs.getBool(pinEnabledKey(userId));
    if (perUser != null) return perUser;
    return prefs.getBool(legacyPinEnabledKey) ?? false;
  }

  static Future<bool> isActive(String userId) async {
    if (userId.isEmpty) return false;
    final enabled = await isPinEnabled(userId);
    if (!enabled) return false;
    return hasPin(userId);
  }

  static Future<void> setBiometricEnabled(String userId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(biometricEnabledKey(userId), enabled);
  }

  static Future<bool> isBiometricEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final perUser = prefs.getBool(biometricEnabledKey(userId));
    if (perUser != null) return perUser;
    return prefs.getBool(legacyBiometricEnabledKey) ?? false;
  }

  static Future<void> resetSecurityData(String userId) async {
    await deletePin(userId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pinEnabledKey(userId));
    await prefs.remove(biometricEnabledKey(userId));
    await prefs.remove(legacyPinKey);
    await prefs.remove(legacyPinEnabledKey);
    await prefs.remove(legacyBiometricEnabledKey);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
