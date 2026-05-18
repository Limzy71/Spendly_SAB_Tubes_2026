import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../../../widgets/custom_notification.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _savedPin;
  bool _isFirstTimeSetup = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPin();
  }

  Future<void> _loadExistingPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('user_pin');
      _isFirstTimeSetup = _savedPin == null;
    });
  }

  Future<void> _processChangePin() async {
    if (_formKey.currentState!.validate()) {

      if (!_isFirstTimeSetup && _oldPinController.text != _savedPin) {
        CustomNotification.show(context, 'PIN Lama yang Anda masukkan salah!', isError: true);
        return;
      }

      if (!_isFirstTimeSetup && _newPinController.text == _oldPinController.text) {
        CustomNotification.show(context, 'PIN Baru tidak boleh sama dengan PIN Lama!', isWarning: true);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_pin', _newPinController.text);
      await prefs.setBool('is_pin_enabled', true);

      if (mounted) {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            CustomNotification.show(context, _isFirstTimeSetup ? 'PIN berhasil dibuat!' : 'PIN berhasil diperbarui!');
          }
        });
      }
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
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isFirstTimeSetup ? 'Buat PIN Keamanan' : 'Ubah PIN Keamanan',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
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
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),

              if (!_isFirstTimeSetup) ...[
                _buildFormLabel('PIN Lama', textColor),
                _buildPinField(
                  controller: _oldPinController,
                  hint: 'Masukkan PIN saat ini',
                  obscureText: _obscureOld,
                  onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'PIN lama wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              _buildFormLabel('PIN Baru', textColor),
              _buildPinField(
                controller: _newPinController,
                hint: 'Masukkan 6 Digit PIN baru',
                obscureText: _obscureNew,
                onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'PIN baru wajib diisi';
                  if (value.length != 6) return 'PIN wajib 6 digit angka';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildFormLabel('Konfirmasi PIN Baru', textColor),
              _buildPinField(
                controller: _confirmPinController,
                hint: 'Ulangi PIN baru',
                obscureText: _obscureConfirm,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Konfirmasi PIN wajib diisi';
                  if (value != _newPinController.text) return 'Konfirmasi PIN tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processChangePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isFirstTimeSetup ? 'Simpan PIN' : 'Simpan PIN Baru',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
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
      child: Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: 8, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, letterSpacing: 0, fontWeight: FontWeight.normal),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
        suffixIcon: IconButton(icon: FaIcon(obscureText ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye, color: Colors.grey, size: 18), onPressed: onToggleVisibility),
      ),
    );
  }
}