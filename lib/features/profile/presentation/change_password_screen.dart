import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- IMPORT MEMORI LOKAL
import '../../../theme/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // GlobalKey ini ibarat "Remote Control" untuk memvalidasi form serentak
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  // Status sensor mata (untuk menyembunyikan/menampilkan angka)
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _savedPin; // Menyimpan PIN asli yang ditarik dari memori HP
  bool _isFirstTimeSetup = false; // Penanda apakah user baru pertama kali bikin PIN

  @override
  void initState() {
    super.initState();
    // Langsung cek memori HP saat halaman ini dibuka
    _loadExistingPin();
  }

  // --- FUNGSI MENGAMBIL PIN LAMA ---
  Future<void> _loadExistingPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Tarik PIN yang tersimpan
      _savedPin = prefs.getString('user_pin');
      // Jika _savedPin bernilai null (kosong), berarti user belum pernah bikin PIN
      _isFirstTimeSetup = _savedPin == null;
    });
  }

  // --- FUNGSI MENYIMPAN PIN BARU ---
  Future<void> _processChangePin() async {
    // Jalankan validator yang ada di setiap TextFormField
    if (_formKey.currentState!.validate()) {

      // Jika ini bukan pertama kali (user mau ganti PIN),
      // Kita harus memastikan PIN LAMA yang dia ketik itu COCOK dengan PIN di memori HP!
      if (!_isFirstTimeSetup && _oldPinController.text != _savedPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN Lama yang Anda masukkan salah!'), backgroundColor: Colors.red),
        );
        return; // Hentikan proses, jangan simpan!
      }

      // Jika validasi sukses, buka memori HP
      final prefs = await SharedPreferences.getInstance();
      // Simpan PIN baru ke brankas memori
      await prefs.setString('user_pin', _newPinController.text);
      // Otomatis aktifkan sakelar keamanan PIN
      await prefs.setBool('is_pin_enabled', true);

      if (mounted) {
        // Berikan notifikasi sukses sesuai kondisi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isFirstTimeSetup ? 'PIN berhasil dibuat!' : 'PIN berhasil diperbarui!'),
              backgroundColor: AppColors.primaryGreen
          ),
        );
        // Keluar dari halaman (kembali ke profil)
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    // Wajib menghapus controller agar tidak terjadi memory leak (HP lemot)
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
        // Judul berubah dinamis: "Buat" atau "Ubah"
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
          key: _formKey, // Pasang remote control form di sini
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat PIN 6 digit yang kuat untuk melindungi akun Spendly Anda.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // LOGIKA UI: Sembunyikan field "PIN Lama" jika ini pertama kalinya buat PIN.
              // Logikanya: Masa baru mau bikin PIN, disuruh masukin PIN lama? Kan gak masuk akal!
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
                  // Cek agar tidak boleh kosong dan harus genap 6 digit
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
                  // Cek apakah PIN ketikan kedua ini cocok dengan ketikan pertama
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

  // Widget pemanis untuk tulisan judul form di atas kolom input
  Widget _buildFormLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  // Widget cetakan (template) untuk menggambar kotak input PIN
  // Kita buat function ini agar tidak perlu menulis kode yang sama 3x
  Widget _buildPinField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText, // Menentukan apakah teks disensor (titik-titik)
      validator: validator, // Memasukkan aturan validasi
      keyboardType: TextInputType.number, // Paksa keyboard yang muncul adalah numpad HP
      maxLength: 6, // Maksimal 6 karakter
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: 8, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        counterText: "", // Menyembunyikan tulisan "0/6" di pojok kanan bawah
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, letterSpacing: 0, fontWeight: FontWeight.normal),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
        // Tombol mata untuk melihat/menyembunyikan sandi
        suffixIcon: IconButton(icon: FaIcon(obscureText ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye, color: Colors.grey, size: 18), onPressed: onToggleVisibility),
      ),
    );
  }
}