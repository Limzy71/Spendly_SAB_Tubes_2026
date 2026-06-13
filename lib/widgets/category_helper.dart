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
    'penjualan',
    'pencairan',
    'baru',
  };

  static Color getColorForIcon(String iconId) {
    switch (iconId) {
    // PENGELUARAN (20 Icon Super Kontras)
      case 'utensils': return const Color(0xFFFF9800);
      case 'car': return const Color(0xFF2196F3);
      case 'bag': return const Color(0xFF9C27B0);
      case 'invoice': return const Color(0xFFF44336);
      case 'film': return const Color(0xFF009688);
      case 'coffee': return const Color(0xFF795548);
      case 'plane': return const Color(0xFF03A9F4);
      case 'house': return const Color(0xFF3F51B5);
      case 'hospital': return const Color(0xFFE91E63);
      case 'edu': return const Color(0xFF00BCD4);
      case 'paw': return const Color(0xFFFF5722);
      case 'game': return const Color(0xFF673AB7);
      case 'shirt': return const Color(0xFF4DB6AC);
      case 'laptop': return const Color(0xFF607D8B);
      case 'train': return const Color(0xFFFFC107);
      case 'building': return const Color(0xFF827717);
      case 'star': return const Color(0xFFFFEA00);
      case 'music': return const Color(0xFF8BC34A);
      case 'dumbbell': return const Color(0xFFD50000);
      case 'book': return const Color(0xFF00E5FF);

    // PEMASUKAN (12 Icon Super Kontras)
      case 'coins': return const Color(0xFFFFB300);
      case 'piggy': return const Color(0xFFF06292);
      case 'salary': return AppColors.primaryGreen;
      case 'chart': return const Color(0xFF5C6BC0);
      case 'briefcase': return const Color(0xFF8D6E63);
      case 'giftbox': return const Color(0xFFEF5350);
      case 'arrow': return const Color(0xFF448AFF);
      case 'store': return const Color(0xFFAB47BC);
      case 'receipt': return const Color(0xFF26A69A);
      case 'hand_holding': return const Color(0xFF66BB6A);
      case 'money_check': return const Color(0xFF1565C0);
      case 'sack': return const Color(0xFFE65100);

      default: return const Color(0xFF9E9E9E);
    }
  }

  static Color getColor(String category, {Map<String, String>? customIcons}) {
    String cat = category.toLowerCase().trim();

    if (customIcons != null && customIcons.containsKey(cat)) {
      return getColorForIcon(customIcons[cat]!);
    }

    if (cat.contains('makan') || cat.contains('jajan') || cat.contains('minum') || cat.contains('kopi') || cat.contains('resto') || cat.contains('cafe') || cat.contains('sarapan') || cat.contains('kuliner')) {
      return getColorForIcon('utensils');
    } else if (cat.contains('transport') || cat.contains('bensin') || cat.contains('parkir') || cat.contains('mobil') || cat.contains('motor') || cat.contains('ojek') || cat.contains('grab') || cat.contains('gojek') || cat.contains('bengkel') || cat.contains('service')) {
      return getColorForIcon('car');
    } else if (cat.contains('belanja') || cat.contains('shop') || cat.contains('kebutuhan') || cat.contains('baju') || cat.contains('sepatu') || cat.contains('skincare') || cat.contains('pasar') || cat.contains('mall') || cat.contains('indomaret') || cat.contains('alfamart')) {
      return getColorForIcon('bag');
    } else if (cat.contains('tagihan') || cat.contains('listrik') || cat.contains('air') || cat.contains('pdam') || cat.contains('wifi') || cat.contains('internet') || cat.contains('pulsa') || cat.contains('kuota') || cat.contains('kos') || cat.contains('kontrakan')) {
      return getColorForIcon('invoice');
    } else if (cat.contains('hiburan') || cat.contains('nonton') || cat.contains('game') || cat.contains('bioskop') || cat.contains('netflix') || cat.contains('spotify') || cat.contains('liburan') || cat.contains('wisata') || cat.contains('healing') || cat.contains('main')) {
      return getColorForIcon('film');
    } else if (cat.contains('sehat') || cat.contains('sakit') || cat.contains('dokter') || cat.contains('obat') || cat.contains('apotek') || cat.contains('klinik') || cat.contains('rs') || cat.contains('vitamin') || cat.contains('gym')) {
      return getColorForIcon('hospital');
    } else if (cat.contains('edukasi') || cat.contains('kuliah') || cat.contains('sekolah') || cat.contains('buku') || cat.contains('kursus') || cat.contains('spp') || cat.contains('tugas') || cat.contains('ukt')) {
      return getColorForIcon('edu');
    } else if (cat.contains('musik') || cat.contains('music') || cat.contains('konser') || cat.contains('lagu') || cat.contains('band')) {
      return getColorForIcon('music');
    } else if (cat.contains('olahraga') || cat.contains('dumbbell') || cat.contains('fitness') || cat.contains('fitnes')) {
      return getColorForIcon('dumbbell');
    } else if (cat.contains('investasi') || cat.contains('saham') || cat.contains('reksadana') || cat.contains('crypto') || cat.contains('emas') || cat.contains('reksa')) {
      return getColorForIcon('arrow');
    } else if (cat.contains('gaji') || cat.contains('salary') || cat.contains('upah') || cat.contains('payday')) {
      return getColorForIcon('salary');
    } else if (cat.contains('bonus') || cat.contains('hadiah') || cat.contains('gift') || cat.contains('thr') || cat.contains('reward')) {
      return getColorForIcon('giftbox');
    } else if (cat.contains('penjualan') || cat.contains('dagang') || cat.contains('jualan') || cat.contains('toko') || cat.contains('bisnis') || cat.contains('usaha')) {
      return getColorForIcon('store');
    } else if (cat.contains('pencairan') || cat.contains('cair') || cat.contains('withdraw') || cat.contains('wd') || cat.contains('tarik')) {
      return getColorForIcon('piggy');
    } else if (cat.contains('bank') || cat.contains('bca') || cat.contains('rekening') || cat.contains('transfer')) {
      return getColorForIcon('money_check');
    } else if (cat.contains('coin') || cat.contains('koin') || cat.contains('uang') || cat.contains('tunai')) {
      return getColorForIcon('coins');
    } else if (cat.contains('dana') || cat.contains('tabungan') || cat.contains('celengan') || cat.contains('wallet') || cat.contains('darurat')) {
      return getColorForIcon('piggy');
    } else if (cat.contains('chart') || cat.contains('grafik') || cat.contains('statistik') || cat.contains('laporan')) {
      return getColorForIcon('chart');
    } else if (cat.contains('briefcase') || cat.contains('pekerjaan')) {
      return getColorForIcon('briefcase');
    }

    return const Color(0xFF607D8B);
  }

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
    } else if (cat.contains('musik') || cat.contains('music') || cat.contains('konser') || cat.contains('lagu')) {
      return FontAwesomeIcons.music;
    } else if (cat.contains('olahraga') || cat.contains('dumbbell') || cat.contains('gym') || cat.contains('fitness') || cat.contains('fitnes')) {
      return FontAwesomeIcons.dumbbell;
    } else if (cat.contains('investasi') || cat.contains('saham') || cat.contains('reksadana') || cat.contains('reksa')) {
      return FontAwesomeIcons.arrowTrendUp;
    } else if (cat.contains('crypto') || cat.contains('bitcoin')) {
      return FontAwesomeIcons.bitcoin;
    } else if (cat.contains('gaji') || cat.contains('salary') || cat.contains('upah') || cat.contains('payday')) {
      return FontAwesomeIcons.moneyBillWave;
    } else if (cat.contains('bonus') || cat.contains('hadiah') || cat.contains('gift') || cat.contains('thr') || cat.contains('reward')) {
      return FontAwesomeIcons.gift;
    } else if (cat.contains('penjualan') || cat.contains('dagang') || cat.contains('jualan') || cat.contains('toko') || cat.contains('bisnis') || cat.contains('usaha')) {
      return FontAwesomeIcons.store;
    } else if (cat.contains('pencairan') || cat.contains('cair') || cat.contains('withdraw') || cat.contains('wd') || cat.contains('tarik')) {
      return FontAwesomeIcons.piggyBank;
    } else if (cat.contains('bank') || cat.contains('bca') || cat.contains('rekening') || cat.contains('transfer')) {
      return FontAwesomeIcons.buildingColumns;
    } else if (cat.contains('coin') || cat.contains('koin') || cat.contains('uang') || cat.contains('tunai')) {
      return FontAwesomeIcons.coins;
    } else if (cat.contains('dana') || cat.contains('tabungan') || cat.contains('celengan') || cat.contains('wallet') || cat.contains('darurat')) {
      return FontAwesomeIcons.piggyBank;
    } else if (cat.contains('chart') || cat.contains('grafik') || cat.contains('statistik')) {
      return FontAwesomeIcons.chartLine;
    } else if (cat.contains('briefcase') || cat.contains('pekerjaan')) {
      return FontAwesomeIcons.briefcase;
    } else if (cat.contains('laptop') || cat.contains('komputer') || cat.contains('pc') || cat.contains('gadget') || cat.contains('hp')) {
      return FontAwesomeIcons.laptop;
    } else if (cat.contains('rumah') || cat.contains('building') || cat.contains('gedung')) {
      return FontAwesomeIcons.building;
    }

    return FontAwesomeIcons.boxArchive;
  }

  static dynamic getCustomIconById(String id) {
    switch (id) {
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
      case 'shirt': return FontAwesomeIcons.shirt;
      case 'laptop': return FontAwesomeIcons.laptop;
      case 'film': return FontAwesomeIcons.film;
      case 'train': return FontAwesomeIcons.train;
      case 'building': return FontAwesomeIcons.building;
      case 'music': return FontAwesomeIcons.music;
      case 'dumbbell': return FontAwesomeIcons.dumbbell;
      case 'safe': return FontAwesomeIcons.boxArchive;
      case 'store': return FontAwesomeIcons.store;
      case 'receipt': return FontAwesomeIcons.receipt;
      case 'hand_holding': return FontAwesomeIcons.handHoldingDollar;
      case 'money_check': return FontAwesomeIcons.moneyCheckDollar;
      case 'sack': return FontAwesomeIcons.sackDollar;
      default: return FontAwesomeIcons.star;
    }
  }
}