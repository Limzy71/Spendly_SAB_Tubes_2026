import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../../widgets/custom_notification.dart';
import 'login_screen.dart';
import '../../../widgets/network_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    bool isOnline = await NetworkHelper.checkConnection(context);
    if (!isOnline) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim()},
        emailRedirectTo: 'io.supabase.spendly://login-callback',
      );

      if (mounted) {
        CustomNotification.show(context, 'Pendaftaran berhasil! Silakan cek email Anda untuk verifikasi.');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    } on AuthException catch (error) {
      if (mounted) {
        String errorMessage = 'Pendaftaran gagal. Silakan coba lagi.';
        final rawMsg = error.message.toLowerCase();

        // 1. Tangani error spesifik dengan bahasa manusia
        if (rawMsg.contains('database error saving new user') || rawMsg.contains('already registered')) {
          errorMessage = 'Email ini sudah terdaftar. Silakan gunakan email lain atau langsung Masuk.';
        } else if (rawMsg.contains('password')) {
          errorMessage = 'Kata sandi terlalu lemah. Minimal 6 karakter.';
        } else if (rawMsg.contains('invalid email')) {
          errorMessage = 'Format email tidak valid. Periksa kembali ketikan Anda.';
        } else {
          // 2. Jika pesan berupa JSON, kita saring (ekstrak) bagian "message"-nya saja
          final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(error.message);
          if (match != null) {
            errorMessage = match.group(1)!;
          } else {
            // Jika regex gagal, bersihkan karakter aneh sebagai cadangan
            errorMessage = error.message.replaceAll(RegExp(r'[\{\}"]'), '').replaceFirst('code:unexpected_failure, message:', '');
          }
        }
        CustomNotification.show(context, errorMessage, isError: true);
      }
    } catch (error) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, error, prefix: 'Pendaftaran gagal');
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
                    decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(16)),
                    child: const FaIcon(FontAwesomeIcons.wallet, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('Spendly', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(height: 40),
                  Text('Buat Akun Baru', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Kelola keuanganmu lebih rapi', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 40),

                  _buildTextField(
                      controller: _nameController,
                      hintText: 'Nama Lengkap',
                      icon: FontAwesomeIcons.user,
                      isDark: isDark,
                      textCapitalization: TextCapitalization.words
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Konfirmasi Kata Sandi',
                    icon: FontAwesomeIcons.lock,
                    isPassword: true,
                    isVisible: _isConfirmPasswordVisible,
                    onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    isDark: isDark,
                    isConfirm: true,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Daftar Sekarang', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sudah punya akun? ', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                        child: Text('Masuk', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
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
    required TextEditingController controller, required String hintText, required dynamic icon,
    bool isPassword = false, bool isVisible = false, VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text, required bool isDark, bool isConfirm = false,
    List<TextInputFormatter>? inputFormatters, TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller, obscureText: isPassword && !isVisible, keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black87),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '$hintText tidak boleh kosong';
        if (keyboardType == TextInputType.emailAddress) {
          if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) return 'Format email tidak valid';
        }
        if (isPassword && value.length < 8) return 'Minimal 8 karakter';
        if (isConfirm && value != _passwordController.text) return 'Kata sandi tidak cocok';
        return null;
      },
      decoration: InputDecoration(
        counterText: "",
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FaIcon(icon, color: Colors.grey.shade500, size: 20),
        ),
        suffixIcon: isPassword ? IconButton(icon: FaIcon(isVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash, color: Colors.grey.shade500, size: 18), onPressed: onVisibilityToggle) : null,
        hintText: hintText, hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), filled: true, fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
    );
  }
}