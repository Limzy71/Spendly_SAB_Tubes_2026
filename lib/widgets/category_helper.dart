import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';

class CategoryHelper {
  static const Set<String> _builtInCategoryNames = {
    'makanan',
    'transportasi',
    'belanja',
    'tagihan',
    'hiburan',
    'gaji',
    'bonus',
    'investasi',
    'dana',
    'bca',
    'baru',
  };

  // 1. Fungsi Pusat untuk Warna Pintar (REVISI PRIORITAS)
  static Color getColor(String category, {Map<String, String>? customIcons}) {
    String cat = category.toLowerCase().trim();

    // LAYER 1: Smart Keyword Matching (DIPINDAH KE ATAS AGAR LEBIH PINTAR)
    if (cat.contains('makan') || cat.contains('jajan') || cat.contains('minum') || cat.contains('kopi') || cat.contains('resto') || cat.contains('cafe') || cat.contains('sarapan') || cat.contains('kuliner')) {
      return Colors.orange.shade600;
    } else if (cat.contains('transport') || cat.contains('bensin') || cat.contains('parkir') || cat.contains('mobil') || cat.contains('motor') || cat.contains('ojek') || cat.contains('grab') || cat.contains('gojek') || cat.contains('bengkel') || cat.contains('service')) {
      return Colors.blue.shade600;
    } else if (cat.contains('belanja') || cat.contains('shop') || cat.contains('kebutuhan') || cat.contains('baju') || cat.contains('sepatu') || cat.contains('skincare') || cat.contains('pasar') || cat.contains('mall') || cat.contains('indomaret') || cat.contains('alfamart')) {
      return Colors.purple.shade500;
    } else if (cat.contains('tagihan') || cat.contains('listrik') || cat.contains('air') || cat.contains('pdam') || cat.contains('wifi') || cat.contains('internet') || cat.contains('pulsa') || cat.contains('kuota') || cat.contains('kos') || cat.contains('kontrakan')) {
      return Colors.red.shade600;
    } else if (cat.contains('hiburan') || cat.contains('nonton') || cat.contains('game') || cat.contains('bioskop') || cat.contains('netflix') || cat.contains('spotify') || cat.contains('liburan') || cat.contains('wisata') || cat.contains('healing') || cat.contains('main')) {
      return Colors.teal.shade500;
    } else if (cat.contains('sehat') || cat.contains('sakit') || cat.contains('dokter') || cat.contains('obat') || cat.contains('apotek') || cat.contains('klinik') || cat.contains('rs') || cat.contains('vitamin') || cat.contains('gym')) {
      return Colors.pink.shade400;
    } else if (cat.contains('edukasi') || cat.contains('kuliah') || cat.contains('sekolah') || cat.contains('buku') || cat.contains('kursus') || cat.contains('spp') || cat.contains('tugas') || cat.contains('ukt')) {
      return Colors.indigo.shade500; // <--- KULIAH AKAN JADI WARNA INI
    } else if (cat.contains('investasi') || cat.contains('saham') || cat.contains('reksadana') || cat.contains('crypto') || cat.contains('emas') || cat.contains('reksa')) {
      return Colors.cyan.shade600;
    } else if (cat.contains('gaji') || cat.contains('salary') || cat.contains('upah') || cat.contains('payday')) {
      return AppColors.primaryGreen;
    } else if (cat.contains('bonus') || cat.contains('hadiah') || cat.contains('gift') || cat.contains('thr') || cat.contains('reward')) {
      return Colors.amber.shade600;
    } else if (cat.contains('dana') || cat.contains('tabungan') || cat.contains('celengan') || cat.contains('darurat')) {
      return Colors.blue.shade800; // <--- DANA DARURAT AKAN JADI WARNA INI
    }

    // LAYER 2: Jika kata kunci tidak ada, baru cek apakah ini kategori kustom (Baru)
    if (customIcons != null && customIcons.containsKey(cat)) {
      return AppColors.primaryGreen; // Default kustom tetap hijau jika tidak ada keyword cocok
    }

    // LAYER 3: Fallback warna abu-abu elegan
    return const Color(0xFF607D8B);
  }

  // 2. Fungsi Pusat untuk Ikon Pintar (SAMA, PRIORITAS KEYWORD DI ATAS)
  static dynamic getIcon(String category, {Map<String, String>? customIcons}) {
    String cat = category.toLowerCase().trim();

    if (customIcons != null) {
      final customIconId = customIcons[cat];
      if (customIconId != null) {
        return getCustomIconById(customIconId);
      }

      if (!_builtInCategoryNames.contains(cat)) {
        return FontAwesomeIcons.boxArchive;
      }
    }

    if (cat == 'bca') {
      return FontAwesomeIcons.buildingColumns;
    }

    // Prioritaskan Smart Keyword Matching agar ikon otomatis muncul meskipun kategori kustom
    if (cat.contains('makan') || cat.contains('jajan') || cat.contains('kuliner') || cat.contains('sarapan') || cat.contains('resto')) {
      return FontAwesomeIcons.utensils;
    } else if (cat.contains('minum') || cat.contains('kopi') || cat.contains('cafe') || cat.contains('boba')) {
      return FontAwesomeIcons.mugHot;
    } else if (cat.contains('transport') || cat.contains('mobil') || cat.contains('bengkel') || cat.contains('service')) {
      return FontAwesomeIcons.car;
    } else if (cat.contains('motor') || cat.contains('bensin') || cat.contains('parkir') || cat.contains('ojek') || cat.contains('grab') || cat.contains('gojek')) {
      return FontAwesomeIcons.motorcycle;
    } else if (cat.contains('belanja') || cat.contains('shop') || cat.contains('mall') || cat.contains('indomaret') || cat.contains('alfamart') || cat.contains('pasar')) {
      return FontAwesomeIcons.bagShopping;
    } else if (cat.contains('baju') || cat.contains('sepatu') || cat.contains('shirt') || cat.contains('skincare') || cat.contains('pakaian')) {
      return FontAwesomeIcons.shirt;
    } else if (cat.contains('tagihan') || cat.contains('listrik') || cat.contains('air') || cat.contains('pdam') || cat.contains('kos') || cat.contains('kontrakan')) {
      return FontAwesomeIcons.fileInvoiceDollar;
    } else if (cat.contains('wifi') || cat.contains('internet') || cat.contains('pulsa') || cat.contains('kuota')) {
      return FontAwesomeIcons.wifi;
    } else if (cat.contains('hiburan') || cat.contains('bioskop') || cat.contains('nonton') || cat.contains('netflix')) {
      return FontAwesomeIcons.film;
    } else if (cat.contains('game') || cat.contains('main') || cat.contains('topup')) {
      return FontAwesomeIcons.gamepad;
    } else if (cat.contains('liburan') || cat.contains('wisata') || cat.contains('healing') || cat.contains('pesawat') || cat.contains('hotel')) {
      return FontAwesomeIcons.plane;
    } else if (cat.contains('sehat') || cat.contains('sakit') || cat.contains('dokter') || cat.contains('obat') || cat.contains('apotek') || cat.contains('rs') || cat.contains('klinik')) {
      return FontAwesomeIcons.hospital;
    } else if (cat.contains('edukasi') || cat.contains('kuliah') || cat.contains('sekolah') || cat.contains('spp') || cat.contains('kursus') || cat.contains('ukt')) {
      return FontAwesomeIcons.graduationCap;
    } else if (cat.contains('buku') || cat.contains('tugas') || cat.contains('notes')) {
      return FontAwesomeIcons.book;
    } else if (cat.contains('investasi') || cat.contains('saham') || cat.contains('reksadana') || cat.contains('reksa')) {
      return FontAwesomeIcons.arrowTrendUp;
    } else if (cat.contains('crypto') || cat.contains('bitcoin')) {
      return FontAwesomeIcons.bitcoin;
    } else if (cat.contains('gaji') || cat.contains('salary') || cat.contains('upah') || cat.contains('payday')) {
      return FontAwesomeIcons.moneyBillWave;
    } else if (cat.contains('bonus') || cat.contains('hadiah') || cat.contains('gift') || cat.contains('thr') || cat.contains('reward')) {
      return FontAwesomeIcons.gift;
    } else if (cat.contains('dana') || cat.contains('tabungan') || cat.contains('celengan') || cat.contains('wallet') || cat.contains('darurat')) {
      return FontAwesomeIcons.piggyBank;
    } else if (cat.contains('laptop') || cat.contains('komputer') || cat.contains('pc') || cat.contains('gadget') || cat.contains('hp')) {
      return FontAwesomeIcons.laptop;
    } else if (cat.contains('rumah') || cat.contains('building') || cat.contains('gedung')) {
      return FontAwesomeIcons.building;
    }

    return FontAwesomeIcons.boxArchive;
  }

  // 3. Pustaka Penerjemah ID Ikon Kustom
  static dynamic getCustomIconById(String id) {
    switch (id) {
      case 'bank': return FontAwesomeIcons.buildingColumns;
      case 'wallet': return FontAwesomeIcons.wallet;
      case 'coins': return FontAwesomeIcons.coins;
      case 'piggy': return FontAwesomeIcons.piggyBank;
      case 'salary': return FontAwesomeIcons.moneyBillWave;
      case 'chart': return FontAwesomeIcons.chartLine;
      case 'briefcase': return FontAwesomeIcons.briefcase;
      case 'giftbox': return FontAwesomeIcons.gift;
      case 'arrow': return FontAwesomeIcons.arrowTrendUp;
      case 'bag': return FontAwesomeIcons.bagShopping;
      case 'utensils': return FontAwesomeIcons.utensils;
      case 'car': return FontAwesomeIcons.car;
      case 'invoice': return FontAwesomeIcons.fileInvoiceDollar;
      case 'cart': return FontAwesomeIcons.cartShopping;
      case 'wifi': return FontAwesomeIcons.wifi;
      case 'game': return FontAwesomeIcons.gamepad;
      case 'book': return FontAwesomeIcons.book;
      case 'star': return FontAwesomeIcons.star;
      case 'coffee': return FontAwesomeIcons.mugHot;
      case 'plane': return FontAwesomeIcons.plane;
      case 'house': return FontAwesomeIcons.house;
      case 'hospital': return FontAwesomeIcons.hospital;
      case 'edu': return FontAwesomeIcons.graduationCap;
      case 'paw': return FontAwesomeIcons.paw;
      case 'game': return FontAwesomeIcons.gamepad;
      case 'shirt': return FontAwesomeIcons.shirt;
      case 'laptop': return FontAwesomeIcons.laptop;
      case 'film': return FontAwesomeIcons.film;
      case 'train': return FontAwesomeIcons.train;
      case 'building': return FontAwesomeIcons.building;
      case 'card': return FontAwesomeIcons.creditCard;
      case 'savings': return FontAwesomeIcons.piggyBank;
      case 'business': return FontAwesomeIcons.briefcase;
      case 'coins2': return FontAwesomeIcons.coins;
      case 'safe': return FontAwesomeIcons.boxArchive;
      default: return FontAwesomeIcons.star;
    }
  }
}