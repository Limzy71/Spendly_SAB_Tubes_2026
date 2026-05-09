import 'package:flutter/material.dart';
import '../../report/presentation/report_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Kita set default awalnya ke angka 1 (Laporan) agar saat dibuka langsung mengarah ke hasil kerja Anda
  int _selectedIndex = 1;

  // Daftar 5 halaman yang akan dihubungkan dengan menu bawah
  final List<Widget> _screens = [
    const Center(child: Text('Halaman Beranda (Bagian Teman Anda)')), // Index 0
    const ReportScreen(), // Index 1: Ini halaman Laporan buatan Anda!
    const Center(child: Text('Halaman Anggaran')), // Index 2
    const Center(child: Text('Halaman Dompet')), // Index 3
    const Center(child: Text('Halaman Profil (Bagian Teman Anda)')), // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan menampilkan halaman sesuai dengan menu yang diklik
      body: _screens[_selectedIndex],

      // Ini adalah kode untuk Bottom Navigation Bar-nya
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Mengubah halaman saat menu diklik
          });
        },
        type: BottomNavigationBarType.fixed, // Wajib fixed agar ke-5 menu muat dan tidak goyang
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF05A660), // Warna Hijau Spendly
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        // Daftar Icon dan Label sesuai gambar desain Anda
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Laporan'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined),
              activeIcon: Icon(Icons.account_balance),
              label: 'Anggaran'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Dompet'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil'
          ),
        ],
      ),
    );
  }
}