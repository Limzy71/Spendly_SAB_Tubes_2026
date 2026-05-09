import 'package:flutter/material.dart';

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  String enteredPin = '';

  void _onNumButtonPressed(String number) {
    if (enteredPin.length < 6) {
      setState(() {
        enteredPin += number;
      });
    }
  }

  void _onDeletePressed() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      });
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

                // Ikon dan Judul Aplikasi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Spendly',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Masukkan Passcode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan 6 digit kode keamanan Anda',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Indikator Titik (Dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < enteredPin.length
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),
                // Tombol Fingerprint
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Gunakan Fingerprint'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                  ),
                ),

                const SizedBox(height: 32),

                // Numpad (Keyboard Angka)
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

  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _numButton('1'), _numButton('2'), _numButton('3'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _numButton('4'), _numButton('5'), _numButton('6'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _numButton('7'), _numButton('8'), _numButton('9'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Lupa?', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
              _numButton('0'),
              IconButton(
                onPressed: _onDeletePressed,
                icon: const Icon(Icons.backspace_outlined, color: Colors.black54),
                iconSize: 28,
              ),
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
        child: Text(
          number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}