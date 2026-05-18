import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main_layout/presentation/main_navigation.dart';
import 'login_screen.dart';

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
    final prefs = await SharedPreferences.getInstance();
    bool bioEnabled = prefs.getBool('is_biometric_enabled') ?? false;
    setState(() => _isBiometricEnabled = bioEnabled);

    if (bioEnabled) {
      _authenticateWithBiometric();
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
      // Abaikan jika error / batal
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
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('user_pin');

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN Salah! Silakan coba lagi.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleForgotPin() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Lupa PIN?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Untuk mereset PIN, Anda akan dikeluarkan dari aplikasi. Semua pengaturan keamanan akan dihapus. Anda harus masuk kembali dengan email dan kata sandi Anda."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_pin');
                await prefs.setBool('is_pin_enabled', false);
                await prefs.setBool('is_biometric_enabled', false);

                await Supabase.instance.client.auth.signOut();

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Reset & Keluar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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

                Text(
                  _isError ? 'PIN Tidak Valid' : 'Masukkan Passcode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isError ? Colors.red : Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text('Gunakan 6 digit kode keamanan Anda', style: TextStyle(color: Colors.grey)),
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
                            ? Theme.of(context).colorScheme.primary
                            : (_isError ? Colors.red.shade100 : Colors.grey.shade300),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                if (_isBiometricEnabled)
                  TextButton.icon(
                    onPressed: _authenticateWithBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Gunakan Fingerprint'),
                    style: TextButton.styleFrom(backgroundColor: Colors.green.shade50),
                  )
                else
                  const SizedBox(height: 48),

                const SizedBox(height: 32),
                _buildNumpad(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
              TextButton(onPressed: _handleForgotPin, child: const Text('Lupa?', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold))),
              _numButton('0'),
              IconButton(onPressed: _onDeletePressed, icon: const Icon(Icons.backspace_outlined, color: Colors.black54), iconSize: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numButton(String number) {
    return InkWell(
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