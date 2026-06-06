import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_auth;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';
import 'register_screen.dart';
import 'passcode_screen.dart';
import '../../main_layout/presentation/main_navigation.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/network_helper.dart';
import '../../../widgets/pin_helper.dart';
import '../../../widgets/profile_image_cache.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handlePostLoginNavigation() async {
    if (!mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    await PinHelper.migrateLegacyPinIfNeeded(userId);
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final bool isPinEnabled = prefs.getBool('is_pin_enabled_$userId') ?? false;
    final String? storedPin = prefs.getString('user_pin_$userId');

    if (isPinEnabled && storedPin != null && storedPin.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PasscodeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    bool isOnline = await NetworkHelper.checkConnection(context);

    if (!isOnline) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await ProfileImageCache.clearLegacyKey();

      if (mounted) {
        CustomNotification.show(context, 'Berhasil masuk!');
        await _handlePostLoginNavigation();
      }
    } on AuthException catch (error) {
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan saat masuk.';
        final msg = error.message.toLowerCase();

        if (msg.contains('invalid login credentials')) {
          errorMessage = 'Email atau kata sandi yang Anda masukkan salah.';
        } else if (msg.contains('email not confirmed')) {
          errorMessage = 'Email belum diverifikasi. Silakan cek kotak masuk email Anda.';
        } else if (msg.contains('rate limit')) {
          errorMessage = 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
        } else {
          final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(error.message);
          if (match != null) {
            errorMessage = match.group(1)!;
          } else {
            errorMessage = error.message.replaceAll(RegExp(r'[\{\}"]'), '').replaceFirst('code:unexpected_failure, message:', '');
          }
        }

        CustomNotification.show(context, errorMessage, isError: true);
      }
    } catch (error) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, error, prefix: 'Gagal masuk');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("=== PROSES LOGIN SELESAI ===");
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    if (email.isEmpty) {
      CustomNotification.show(context, 'Masukkan alamat email Anda terlebih dahulu.', isWarning: true);
      return;
    }

    bool isOnline = await NetworkHelper.checkConnection(context);
    if (!isOnline) {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        CustomNotification.show(context, 'Tautan pemulihan kata sandi telah dikirim ke email Anda.');
      }
    } catch (error) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, error, prefix: 'Gagal mengirim tautan pemulihan');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    bool isOnline = await NetworkHelper.checkConnection(context);
    if (!isOnline) {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      const webClientId = '426102305894-du5esrcekmtabv211lefl2sipt1r2jpk.apps.googleusercontent.com';

      final g_auth.GoogleSignIn googleSignIn = g_auth.GoogleSignIn(serverClientId: webClientId);
      await googleSignIn.signOut();
      final g_auth.GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        throw 'Proses masuk dibatalkan.';
      }

      final g_auth.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Gagal mendapatkan akses dari Google.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      await ProfileImageCache.clearLegacyKey();

      if (mounted) {
        CustomNotification.show(context, 'Berhasil masuk dengan Google!');
        await _handlePostLoginNavigation();
      }
    } catch (error) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, error, prefix: 'Gagal masuk dengan Google');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const FaIcon(FontAwesomeIcons.wallet, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('Spendly', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(height: 40),
                  Text('Selamat Datang', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Masuk untuk melanjutkan pencatatan', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 40),

                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Alamat Email',
                    icon: FontAwesomeIcons.envelope,
                    keyboardType: TextInputType.emailAddress,
                    isDark: isDark,
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return TextEditingValue(
                          text: newValue.text.toLowerCase(),
                          selection: newValue.selection,
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Kata Sandi',
                    icon: FontAwesomeIcons.lock,
                    isPassword: true,
                    isVisible: _isPasswordVisible,
                    onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    isDark: isDark,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: TextButton.styleFrom(
                        overlayColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                      ),
                      child: Text('Lupa Kata Sandi?', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Masuk', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('ATAU', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) return isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100;
                          if (states.contains(WidgetState.pressed)) return isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200;
                          return null;
                        }),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.google, size: 20, color: isDark ? Colors.white : Colors.black87),
                          const SizedBox(width: 12),
                          Text('Masuk dengan Google', style: GoogleFonts.plusJakartaSans(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Belum punya akun? ', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: Text('Daftar', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required dynamic icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bagian ini tidak boleh kosong';
        }
        if (hintText.contains('Email') && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Format email tidak valid';
        }
        return null;
      },
      style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        counterText: "",
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FaIcon(icon, color: Colors.grey.shade500, size: 20),
        ),
        suffixIcon: isPassword
            ? IconButton(icon: FaIcon(isVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash, color: Colors.grey.shade500, size: 18), onPressed: onVisibilityToggle)
            : null,
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}