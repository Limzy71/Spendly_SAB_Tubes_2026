import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_colors.dart';
import '../../../../widgets/custom_notification.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../../widgets/pin_helper.dart';

import '../../../../widgets/network_helper.dart';

class PasscodeSettingsScreen extends StatefulWidget {
  const PasscodeSettingsScreen({super.key});

  @override
  State<PasscodeSettingsScreen> createState() => _PasscodeSettingsScreenState();
}

class _PasscodeSettingsScreenState extends State<PasscodeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _savedPin;
  bool _isFirstTimeSetup = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPin();
  }

  Future<void> _loadExistingPin() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    await PinHelper.migrateLegacyPinIfNeeded(userId);
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('user_pin_$userId');
      _isFirstTimeSetup = _savedPin == null || _savedPin!.isEmpty;
    });
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
            "Untuk mereset PIN, Anda akan dikeluarkan dari aplikasi. Semua pengaturan keamanan lokal akan dihapus. Anda harus masuk kembali menggunakan email/Google Anda.",
            style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                if (!mounted) return;
                if (!await NetworkHelper.checkConnection(context)) return;

                setState(() => _isLoading = true);

                try {
                  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                  await PinHelper.migrateLegacyPinIfNeeded(userId);

                  await Supabase.instance.client.auth.signOut();

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('user_pin_$userId');
                  await prefs.remove('is_pin_enabled_$userId');
                  await prefs.remove('is_biometric_enabled_$userId');

                  await prefs.remove('user_pin');
                  await prefs.remove('is_pin_enabled');
                  await prefs.remove('is_biometric_enabled');

                  if (!mounted) return;
                  CustomNotification.show(context, 'Sesi direset. Silakan masuk kembali untuk mengatur PIN baru.', isWarning: true);
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                } catch (e) {
                  if (mounted) {
                    CustomNotification.show(context, 'Gagal mereset sesi, coba lagi.', isError: true);
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
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

  Future<void> _processChangePin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 400));

    if (!_isFirstTimeSetup && _oldPinController.text != _savedPin) {
      setState(() => _isLoading = false);
      if (mounted) CustomNotification.show(context, 'PIN Lama yang Anda masukkan salah!', isError: true);
      return;
    }

    if (!_isFirstTimeSetup && _newPinController.text == _oldPinController.text) {
      setState(() => _isLoading = false);
      if (mounted) CustomNotification.show(context, 'PIN Baru tidak boleh sama dengan PIN Lama!', isWarning: true);
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    await PinHelper.migrateLegacyPinIfNeeded(userId);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_pin_$userId', _newPinController.text);
    await prefs.setBool('is_pin_enabled_$userId', true);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      CustomNotification.show(context, _isFirstTimeSetup ? 'PIN berhasil dibuat!' : 'PIN berhasil diperbarui!');
    }
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isFirstTimeSetup ? 'Buat PIN Keamanan' : 'Ubah PIN Keamanan',
          style: GoogleFonts.plusJakartaSans(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat PIN 6 digit yang kuat untuk melindungi akun Spendly Anda.',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),

              if (!_isFirstTimeSetup) ...[
                _buildFormLabel('PIN Lama', textColor),
                _buildPinField(
                  controller: _oldPinController,
                  hint: 'Masukkan PIN saat ini',
                  obscureText: _obscureOld,
                  onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleForgotPin,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      overlayColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                    ),
                    child: Text('Lupa PIN Saat Ini?', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              _buildFormLabel('PIN Baru', textColor),
              _buildPinField(
                controller: _newPinController,
                hint: 'Masukkan 6 Digit PIN baru',
                obscureText: _obscureNew,
                onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 20),

              _buildFormLabel('Konfirmasi PIN Baru', textColor),
              _buildPinField(
                controller: _confirmPinController,
                hint: 'Ulangi PIN baru',
                obscureText: _obscureConfirm,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                isConfirm: true,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processChangePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                    _isFirstTimeSetup ? 'Simpan PIN' : 'Simpan PIN Baru',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(label, style: GoogleFonts.plusJakartaSans(color: textColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    bool isConfirm = false,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: GoogleFonts.plusJakartaSans(color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: 8, fontWeight: FontWeight.bold),
      validator: (value) {
        if (value == null || value.isEmpty) return 'PIN wajib diisi';
        if (value.length != 6) return 'PIN wajib 6 digit angka';
        if (isConfirm && value != _newPinController.text) return 'Konfirmasi PIN tidak cocok';
        return null;
      },
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14, letterSpacing: 0, fontWeight: FontWeight.normal),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),

        prefixIcon: Padding(
          padding: const EdgeInsets.all(14.0),
          child: FaIcon(FontAwesomeIcons.lock, color: Colors.grey.shade500, size: 18),
        ),

        suffixIcon: IconButton(
            icon: FaIcon(obscureText ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye, color: Colors.grey, size: 18),
            onPressed: onToggleVisibility
        ),
      ),
    );
  }
}