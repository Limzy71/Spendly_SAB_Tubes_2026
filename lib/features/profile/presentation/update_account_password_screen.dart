import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_colors.dart';
import '../../../../widgets/custom_notification.dart';
import '../../../../widgets/network_helper.dart'; // Import Network Helper

class UpdateAccountPasswordScreen extends StatefulWidget {
  const UpdateAccountPasswordScreen({super.key});

  @override
  State<UpdateAccountPasswordScreen> createState() => _UpdateAccountPasswordScreenState();
}

class _UpdateAccountPasswordScreenState extends State<UpdateAccountPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetPasswordEmail() async {
    // 1. INTEGRASI NETWORK HELPER
    if (!await NetworkHelper.checkConnection(context)) return;

    setState(() => _isLoading = true);

    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) throw 'Sesi pengguna tidak valid atau email tidak ditemukan.';

      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      if (mounted) {
        CustomNotification.show(context, 'Tautan reset kata sandi telah dikirim ke email Anda: $email');
      }
    } catch (e) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal mengirim email reset tautan');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // 2. INTEGRASI NETWORK HELPER
    if (!await NetworkHelper.checkConnection(context)) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final email = user?.email;

      if (email == null) throw 'Sesi pengguna tidak valid atau email tidak ditemukan.';

      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: _oldPasswordController.text,
        );
      } on AuthException catch (_) {
        throw 'Kata sandi saat ini yang Anda masukkan salah.';
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (mounted) {
        Navigator.pop(context);
        CustomNotification.show(context, 'Kata sandi akun berhasil diperbarui!');
      }
    } catch (e) {
      if (mounted) {
        NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal mengubah kata sandi');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Ubah Kata Sandi Akun',
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
                'Perbarui kata sandi untuk akun email Anda. Pastikan Anda mengingat kata sandi lama Anda.',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),

              _buildFormLabel('Kata Sandi Saat Ini', textColor),
              _buildPasswordField(
                controller: _oldPasswordController,
                hint: 'Masukkan kata sandi lama',
                obscureText: _obscureOld,
                onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Kata sandi saat ini wajib diisi';
                  return null;
                },
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _sendResetPasswordEmail,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    overlayColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                  ),
                  child: Text('Lupa Kata Sandi Saat Ini?', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),

              _buildFormLabel('Kata Sandi Baru', textColor),
              _buildPasswordField(
                controller: _passwordController,
                hint: 'Masukkan kata sandi baru',
                obscureText: _obscurePassword,
                onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Kata sandi baru wajib diisi';
                  if (value.length < 8) return 'Minimal 8 karakter';
                  if (value == _oldPasswordController.text) return 'Kata sandi baru tidak boleh sama dengan yang lama';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildFormLabel('Konfirmasi Kata Sandi Baru', textColor),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: 'Ulangi kata sandi baru',
                obscureText: _obscureConfirm,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Konfirmasi wajib diisi';
                  if (value != _passwordController.text) return 'Kata sandi tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Simpan Perubahan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
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
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}