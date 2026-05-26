import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../theme/app_colors.dart';
import '../../../../widgets/custom_notification.dart';
import '../../main_layout/presentation/main_navigation.dart';
import 'login_screen.dart';
import '../../../widgets/network_helper.dart';
import '../../../widgets/pin_helper.dart';

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  String enteredPin = '';
  bool _isError = false;
  bool _isBiometricEnabled = false;

  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometricSettings();
  }

  Future<void> _checkBiometricSettings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    await PinHelper.migrateLegacyPinIfNeeded(userId);

    final prefs = await SharedPreferences.getInstance();

    bool bioEnabled = prefs.getBool('is_biometric_enabled_$userId') ?? false;
    setState(() => _isBiometricEnabled = bioEnabled);

    if (bioEnabled) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _authenticateWithBiometric();
        }
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari / wajah Anda untuk masuk',
      );

      if (didAuthenticate && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _onNumButtonPressed(String number) {
    if (enteredPin.length < 6) {
      setState(() {
        enteredPin += number;
        _isError = false;
      });

      if (enteredPin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    await PinHelper.migrateLegacyPinIfNeeded(userId);

    final prefs = await SharedPreferences.getInstance();

    final storedPin = prefs.getString('user_pin_$userId');

    if (enteredPin == storedPin) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } else {
      setState(() {
        _isError = true;
        enteredPin = '';
      });
      if (mounted) {
        CustomNotification.show(context, 'PIN Salah! Silakan coba lagi.', isError: true);
      }
    }
  }

  void _handleForgotPin() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Lupa PIN?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          content: Text(
            "Untuk mereset PIN, Anda akan dikeluarkan dari aplikasi. Semua pengaturan keamanan akan dihapus. Anda harus masuk kembali dengan email dan kata sandi Anda.",
            style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                bool isOnline = await NetworkHelper.checkConnection(context);
                if (!isOnline) return;

                if (!context.mounted) return;
                Navigator.pop(dialogContext);

                final prefs = await SharedPreferences.getInstance();
                final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

                await prefs.remove('user_pin_$userId');
                await prefs.remove('is_pin_enabled_$userId');
                await prefs.remove('is_biometric_enabled_$userId');

                await prefs.remove('user_pin');
                await prefs.remove('is_pin_enabled');
                await prefs.remove('is_biometric_enabled');

                await Supabase.instance.client.auth.signOut();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Reset & Keluar", style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? Colors.black : const Color(0xFFF1FAF5);
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const FaIcon(FontAwesomeIcons.wallet, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text('Spendly', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                const SizedBox(height: 32),

                Text(
                  _isError ? 'PIN Tidak Valid' : 'Masukkan Passcode',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: _isError ? Colors.red : textColor),
                ),
                const SizedBox(height: 8),
                Text('Gunakan 6 digit kode keamanan Anda', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < enteredPin.length
                            ? AppColors.primaryGreen
                            : (_isError ? Colors.red.shade100 : (isDark ? Colors.white24 : Colors.grey.shade300)),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                if (_isBiometricEnabled)
                  TextButton.icon(
                    onPressed: _authenticateWithBiometric,
                    icon: const FaIcon(FontAwesomeIcons.fingerprint, size: 18),
                    label: Text('Gunakan Fingerprint', style: GoogleFonts.plusJakartaSans()),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        backgroundColor: isDark ? AppColors.primaryGreen.withValues(alpha: 0.1) : Colors.green.shade50
                    ),
                  )
                else
                  const SizedBox(height: 48),

                const SizedBox(height: 32),
                _buildNumpad(textColor),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_numButton('1', textColor), _numButton('2', textColor), _numButton('3', textColor)]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_numButton('4', textColor), _numButton('5', textColor), _numButton('6', textColor)]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_numButton('7', textColor), _numButton('8', textColor), _numButton('9', textColor)]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                  onPressed: _handleForgotPin,
                  child: Text('Lupa?', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold))
              ),
              _numButton('0', textColor),
              IconButton(
                  onPressed: _onDeletePressed,
                  icon: FaIcon(FontAwesomeIcons.deleteLeft, color: textColor.withValues(alpha: 0.7)),
                  iconSize: 24
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numButton(String number, Color textColor) {
    return InkWell(
      onTap: () => _onNumButtonPressed(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: Text(number, style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w600, color: textColor)),
      ),
    );
  }
}