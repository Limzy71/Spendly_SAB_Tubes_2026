import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk menangkap input teks PIN
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  // State untuk menyembunyikan/menampilkan PIN
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // FUNGSI UTAMA: Validasi & Proses Perubahan PIN
  void _processChangePin() {
    if (_formKey.currentState!.validate()) {
      // Jika semua validasi di dalam TextFormField lolos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN Keamanan berhasil diperbarui!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      // Kembali ke halaman profil setelah sukses
      Navigator.pop(context);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Ubah PIN Keamanan',
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
          key: _formKey, // Pasang key untuk validasi form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat PIN baru yang kuat untuk melindungi akun Spendly Anda.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // 1. INPUT PIN LAMA
              _buildFormLabel('PIN Lama', textColor),
              _buildPinField(
                controller: _oldPinController,
                hint: 'Masukkan PIN saat ini',
                obscureText: _obscureOld,
                onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PIN lama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. INPUT PIN BARU
              _buildFormLabel('PIN Baru', textColor),
              _buildPinField(
                controller: _newPinController,
                hint: 'Masukkan PIN baru',
                obscureText: _obscureNew,
                onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PIN baru wajib diisi';
                  }
                  if (value.length < 6) {
                    return 'PIN minimal harus 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 3. INPUT KONFIRMASI PIN BARU
              _buildFormLabel('Konfirmasi PIN Baru', textColor),
              _buildPinField(
                controller: _confirmPinController,
                hint: 'Ulangi PIN baru',
                obscureText: _obscureConfirm,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi PIN wajib diisi';
                  }
                  // Validasi mencocokkan PIN baru
                  if (value != _newPinController.text) {
                    return 'Konfirmasi PIN tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // TOMBOL KONFIRMASI
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processChangePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan PIN Baru',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk Label Form agar adaptif
  Widget _buildFormLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Widget Helper untuk Merender TextFormField PIN yang bersih
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
      keyboardType: TextInputType.number, // Mengoptimalkan keyboard khusus angka untuk input PIN
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),

        // PERBAIKAN: Ubah BoxBorderSide menjadi BorderSide
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),

        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}