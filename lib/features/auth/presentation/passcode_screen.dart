import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main_layout/presentation/main_navigation.dart';

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  String enteredPin = ''; // Menyimpan angka yang sedang diketik user
  bool _isError = false; // Status apakah PIN yang dimasukkan salah

  // Fungsi yang dipanggil tiap kali user menekan angka di Numpad
  void _onNumButtonPressed(String number) {
    // Hanya izinkan mengetik jika panjang PIN belum sampai 6 digit
    if (enteredPin.length < 6) {
      setState(() {
        enteredPin += number; // Tambahkan angka ke dalam string
        _isError = false; // Reset pesan error setiap kali user mulai ngetik lagi
      });

      // Jika user sudah mengetik tepat 6 digit, otomatis jalankan pengecekan!
      if (enteredPin.length == 6) {
        _verifyPin();
      }
    }
  }

  // Fungsi untuk tombol hapus (backspace)
  void _onDeletePressed() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        // Potong 1 angka terakhir dari belakang
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  // --- FUNGSI INTI: VERIFIKASI PIN ---
  Future<void> _verifyPin() async {
    // 1. Buka memori lokal HP
    final prefs = await SharedPreferences.getInstance();
    // 2. Ambil PIN asli yang pernah disave user saat membuat PIN
    final storedPin = prefs.getString('user_pin');

    // 3. Cocokkan: Apakah yang diketik == PIN yang disave?
    if (enteredPin == storedPin) {
      // JIKA BENAR: Hancurkan halaman Passcode ini dan ganti dengan Dashboard (MainNavigation)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } else {
      // JIKA SALAH: Tampilkan error, kosongkan bulatan PIN agar user bisa ngetik ulang
      setState(() {
        _isError = true;
        enteredPin = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN Salah! Silakan coba lagi.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // Logo Aplikasi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text('Spendly', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 32),

                // Teks Instruksi: Jika salah PIN, teks akan berubah jadi merah
                Text(
                  _isError ? 'PIN Tidak Valid' : 'Masukkan Passcode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isError ? Colors.red : Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text('Gunakan 6 digit kode keamanan Anda', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),

                // Indikator Titik (Dots) PIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Membuat 6 buah titik
                  children: List.generate(6, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Logika warna titik:
                        // Jika index < panjang PIN yang diketik, warnai hijau (terisi)
                        // Jika error, warnai merah transparan. Jika belum diisi, abu-abu.
                        color: index < enteredPin.length
                            ? Theme.of(context).colorScheme.primary
                            : (_isError ? Colors.red.shade100 : Colors.grey.shade300),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),
                // Tombol Fingerprint (Opsional / Dummy sementara)
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Gunakan Fingerprint'),
                  style: TextButton.styleFrom(backgroundColor: Colors.green.shade50),
                ),

                const SizedBox(height: 32),
                // Panggil Widget Numpad
                _buildNumpad(),
                const SizedBox(height: 24),

                // Tombol Bantuan
                TextButton(
                  onPressed: () {},
                  child: const Text('Butuh bantuan? Hubungi Support'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget khusus untuk menggambar susunan keyboard angka
  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_numButton('1'), _numButton('2'), _numButton('3')]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_numButton('4'), _numButton('5'), _numButton('6')]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_numButton('7'), _numButton('8'), _numButton('9')]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Tombol Lupa Sandi
              TextButton(onPressed: () {}, child: const Text('Lupa?', style: TextStyle(color: Colors.grey, fontSize: 16))),
              _numButton('0'),
              // Tombol Hapus (Backspace)
              IconButton(onPressed: _onDeletePressed, icon: const Icon(Icons.backspace_outlined, color: Colors.black54), iconSize: 28),
            ],
          ),
        ],
      ),
    );
  }

  // Widget cetakan (template) untuk satu tombol angka agar kodenya tidak diulang-ulang
  Widget _numButton(String number) {
    return InkWell(
      // Saat ditekan, oper angkanya ke fungsi _onNumButtonPressed
      onTap: () => _onNumButtonPressed(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: Text(number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
      ),
    );
  }
}