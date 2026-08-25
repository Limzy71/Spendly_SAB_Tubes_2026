import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';

class CategoryHelper {
  static Color getColorForIcon(String iconId) {
    switch (iconId) {
      // PENGELUARAN (37 Icon Lengkap & Super Kontras)
      case 'utensils': return const Color(0xFFFF9800);
      case 'coffee': return const Color(0xFF795548);
      case 'car': return const Color(0xFF2196F3);
      case 'motorcycle': return const Color(0xFF009688);
      case 'gas_pump': return const Color(0xFFFF5722);
      case 'bag': return const Color(0xFF9C27B0);
      case 'cart': return const Color(0xFFE91E63);
      case 'shirt': return const Color(0xFF4DB6AC);
      case 'invoice': return const Color(0xFFF44336);
      case 'bolt': return const Color(0xFFFFC107);
      case 'droplet': return const Color(0xFF00BCD4);
      case 'wifi': return const Color(0xFF3F51B5);
      case 'mobile': return const Color(0xFF5C6BC0);
      case 'house': return const Color(0xFF8D6E63);
      case 'key': return const Color(0xFF78909C);
      case 'hospital': return const Color(0xFFE91E63);
      case 'edu': return const Color(0xFF00ACC1);
      case 'book': return const Color(0xFF26A69A);
      case 'film': return const Color(0xFF00897B);
      case 'game': return const Color(0xFF673AB7);
      case 'music': return const Color(0xFF8BC34A);
      case 'plane': return const Color(0xFF03A9F4);
      case 'hotel': return const Color(0xFF5D4037);
      case 'paw': return const Color(0xFFFF7043);
      case 'baby': return const Color(0xFFF48FB1);
      case 'heart': return const Color(0xFFE53935);
      case 'hands_praying': return const Color(0xFF43A047);
      case 'smoking': return const Color(0xFF616161);
      case 'scissors': return const Color(0xFFAB47BC);
      case 'dumbbell': return const Color(0xFFD50000);
      case 'wrench': return const Color(0xFF546E7A);
      case 'laptop': return const Color(0xFF607D8B);
      case 'shield': return const Color(0xFF1565C0);
      case 'credit_card': return const Color(0xFFC2185B);
      case 'train': return const Color(0xFFFFB300);
      case 'building': return const Color(0xFF827717);
      case 'star': return const Color(0xFFFFEA00);

      // PEMASUKAN (24 Icon Lengkap & Super Kontras)
      case 'salary': return AppColors.primaryGreen;
      case 'giftbox': return const Color(0xFFEF5350);
      case 'arrow': return const Color(0xFF448AFF);
      case 'chart': return const Color(0xFF5C6BC0);
      case 'store': return const Color(0xFFAB47BC);
      case 'truck': return const Color(0xFFFF9800);
      case 'piggy': return const Color(0xFFF06292);
      case 'coins': return const Color(0xFFFFB300);
      case 'briefcase': return const Color(0xFF8D6E63);
      case 'laptop_code': return const Color(0xFF009688);
      case 'receipt': return const Color(0xFF26A69A);
      case 'hand_holding': return const Color(0xFF66BB6A);
      case 'hand_sparkles': return const Color(0xFFFFC107);
      case 'money_check': return const Color(0xFF1565C0);
      case 'sack': return const Color(0xFFE65100);
      case 'percent': return const Color(0xFF00ACC1);
      case 'building_columns': return const Color(0xFF3F51B5);
      case 'bitcoin': return const Color(0xFFFFA000);
      case 'gem': return const Color(0xFF9C27B0);
      case 'crown': return const Color(0xFFFFD600);
      case 'arrows_rotate': return const Color(0xFF00BCD4);
      case 'house_laptop': return const Color(0xFF689F38);
      case 'vault': return const Color(0xFF795548);
      case 'user_tie': return const Color(0xFF455A64);

      default: return const Color(0xFF9E9E9E);
    }
  }

  static Color getColor(String category, {Map<String, String>? customIcons}) {
    String cat = category.toLowerCase().trim();

    if (customIcons != null && customIcons.containsKey(cat)) {
      return getColorForIcon(customIcons[cat]!);
    }

    if (cat.contains('admin') || cat.contains('biaya') || cat.contains('fee')) {
      return const Color(0xFFE53935);
    } else if (cat.contains('makan') || cat.contains('jajan') || cat.contains('resto') || cat.contains('cafe') || cat.contains('sarapan') || cat.contains('kuliner')) {
      return getColorForIcon('utensils');
    } else if (cat.contains('kopi') || cat.contains('minum') || cat.contains('coffee') || cat.contains('boba')) {
      return getColorForIcon('coffee');
    } else if (cat.contains('bensin') || cat.contains('bbm') || cat.contains('spbu') || cat.contains('pertamina') || cat.contains('shell')) {
      return getColorForIcon('gas_pump');
    } else if (cat.contains('motor') || cat.contains('ojek') || cat.contains('grab') || cat.contains('gojek')) {
      return getColorForIcon('motorcycle');
    } else if (cat.contains('mobil') || cat.contains('transport') || cat.contains('parkir') || cat.contains('tol')) {
      return getColorForIcon('car');
    } else if (cat.contains('kereta') || cat.contains('mrt') || cat.contains('krl') || cat.contains('lrt') || cat.contains('train')) {
      return getColorForIcon('train');
    } else if (cat.contains('supermarket') || cat.contains('toko') || cat.contains('mart') || cat.contains('indomaret') || cat.contains('alfamart') || cat.contains('pasar')) {
      return getColorForIcon('cart');
    } else if (cat.contains('belanja') || cat.contains('shop') || cat.contains('kebutuhan') || cat.contains('mall')) {
      return getColorForIcon('bag');
    } else if (cat.contains('baju') || cat.contains('sepatu') || cat.contains('shirt') || cat.contains('pakaian') || cat.contains('celana') || cat.contains('jaket')) {
      return getColorForIcon('shirt');
    } else if (cat.contains('listrik') || cat.contains('pln') || cat.contains('token')) {
      return getColorForIcon('bolt');
    } else if (cat.contains('air') || cat.contains('pdam')) {
      return getColorForIcon('droplet');
    } else if (cat.contains('wifi') || cat.contains('internet') || cat.contains('indihome') || cat.contains('biznet')) {
      return getColorForIcon('wifi');
    } else if (cat.contains('pulsa') || cat.contains('kuota') || cat.contains('telkomsel') || cat.contains('xl') || cat.contains('indosat') || cat.contains('tri')) {
      return getColorForIcon('mobile');
    } else if (cat.contains('tagihan') || cat.contains('invoice') || cat.contains('iuran')) {
      return getColorForIcon('invoice');
    } else if (cat.contains('kos') || cat.contains('sewa') || cat.contains('kontrakan') || cat.contains('kunci')) {
      return getColorForIcon('key');
    } else if (cat.contains('rumah') || cat.contains('hunian') || cat.contains('perabot')) {
      return getColorForIcon('house');
    } else if (cat.contains('sehat') || cat.contains('sakit') || cat.contains('dokter') || cat.contains('obat') || cat.contains('apotek') || cat.contains('klinik') || cat.contains('rs') || cat.contains('vitamin')) {
      return getColorForIcon('hospital');
    } else if (cat.contains('edukasi') || cat.contains('kuliah') || cat.contains('sekolah') || cat.contains('kursus') || cat.contains('spp') || cat.contains('ukt')) {
      return getColorForIcon('edu');
    } else if (cat.contains('buku') || cat.contains('tugas') || cat.contains('notes') || cat.contains('atk')) {
      return getColorForIcon('book');
    } else if (cat.contains('hiburan') || cat.contains('nonton') || cat.contains('bioskop') || cat.contains('netflix') || cat.contains('cinema') || cat.contains('streaming')) {
      return getColorForIcon('film');
    } else if (cat.contains('game') || cat.contains('main') || cat.contains('topup') || cat.contains('steam') || cat.contains('playstation')) {
      return getColorForIcon('game');
    } else if (cat.contains('musik') || cat.contains('music') || cat.contains('konser') || cat.contains('spotify')) {
      return getColorForIcon('music');
    } else if (cat.contains('liburan') || cat.contains('wisata') || cat.contains('pesawat') || cat.contains('travel') || cat.contains('healing')) {
      return getColorForIcon('plane');
    } else if (cat.contains('hotel') || cat.contains('villa') || cat.contains('resort') || cat.contains('penginapan')) {
      return getColorForIcon('hotel');
    } else if (cat.contains('hewan') || cat.contains('kucing') || cat.contains('anjing') || cat.contains('pet') || cat.contains('vet')) {
      return getColorForIcon('paw');
    } else if (cat.contains('bayi') || cat.contains('anak') || cat.contains('susu') || cat.contains('pampers')) {
      return getColorForIcon('baby');
    } else if (cat.contains('donasi') || cat.contains('amal') || cat.contains('zakat') || cat.contains('sedekah') || cat.contains('infaq')) {
      return getColorForIcon('heart');
    } else if (cat.contains('ibadah') || cat.contains('masjid') || cat.contains('gereja') || cat.contains('sholat') || cat.contains('religi')) {
      return getColorForIcon('hands_praying');
    } else if (cat.contains('rokok') || cat.contains('vape') || cat.contains('pod')) {
      return getColorForIcon('smoking');
    } else if (cat.contains('salon') || cat.contains('barber') || cat.contains('potong') || cat.contains('skincare') || cat.contains('facial')) {
      return getColorForIcon('scissors');
    } else if (cat.contains('olahraga') || cat.contains('dumbbell') || cat.contains('gym') || cat.contains('fitness') || cat.contains('fitnes') || cat.contains('badminton') || cat.contains('futsal')) {
      return getColorForIcon('dumbbell');
    } else if (cat.contains('bengkel') || cat.contains('servis') || cat.contains('service') || cat.contains('cuci') || cat.contains('onderdil')) {
      return getColorForIcon('wrench');
    } else if (cat.contains('gadget') || cat.contains('laptop') || cat.contains('hp') || cat.contains('komputer') || cat.contains('elektronik')) {
      return getColorForIcon('laptop');
    } else if (cat.contains('asuransi') || cat.contains('bpjs') || cat.contains('pajak') || cat.contains('proteksi')) {
      return getColorForIcon('shield');
    } else if (cat.contains('cicilan') || cat.contains('kredit') || cat.contains('hutang') || cat.contains('utang') || cat.contains('paylater')) {
      return getColorForIcon('credit_card');
    } else if (cat.contains('investasi') || cat.contains('saham') || cat.contains('reksadana') || cat.contains('emas') || cat.contains('reksa')) {
      return getColorForIcon('arrow');
    } else if (cat.contains('gaji') || cat.contains('salary') || cat.contains('upah') || cat.contains('payday')) {
      return getColorForIcon('salary');
    } else if (cat.contains('bonus') || cat.contains('hadiah') || cat.contains('gift') || cat.contains('thr') || cat.contains('reward')) {
      return getColorForIcon('giftbox');
    } else if (cat.contains('cashback') || cat.contains('diskon') || cat.contains('promo') || cat.contains('poin')) {
      return getColorForIcon('percent');
    } else if (cat.contains('penjualan') || cat.contains('dagang') || cat.contains('jualan') || cat.contains('omset')) {
      return getColorForIcon('store');
    } else if (cat.contains('olshop') || cat.contains('shopee') || cat.contains('tokopedia') || cat.contains('ekspedisi') || cat.contains('paket')) {
      return getColorForIcon('truck');
    } else if (cat.contains('pencairan') || cat.contains('cair') || cat.contains('withdraw') || cat.contains('wd') || cat.contains('tarik')) {
      return getColorForIcon('piggy');
    } else if (cat.contains('crypto') || cat.contains('bitcoin') || cat.contains('usdt') || cat.contains('eth')) {
      return getColorForIcon('bitcoin');
    } else if (cat.contains('bunga') || cat.contains('deposito') || cat.contains('bank') || cat.contains('rekening') || cat.contains('transfer')) {
      return getColorForIcon('building_columns');
    } else if (cat.contains('koin') || cat.contains('uang') || cat.contains('tunai') || cat.contains('cash') || cat.contains('kembalian')) {
      return getColorForIcon('coins');
    } else if (cat.contains('freelance') || cat.contains('proyek') || cat.contains('project') || cat.contains('sidejob') || cat.contains('kerja')) {
      return getColorForIcon('briefcase');
    } else if (cat.contains('coding') || cat.contains('desain') || cat.contains('jasa') || cat.contains('software')) {
      return getColorForIcon('laptop_code');
    } else if (cat.contains('tip') || cat.contains('komisi') || cat.contains('uang kaget')) {
      return getColorForIcon('hand_sparkles');
    } else if (cat.contains('refund') || cat.contains('pengembalian') || cat.contains('retur')) {
      return getColorForIcon('arrows_rotate');
    } else if (cat.contains('warisan') || cat.contains('hibah') || cat.contains('emas batangan') || cat.contains('permata')) {
      return getColorForIcon('gem');
    } else if (cat.contains('arisan') || cat.contains('brankas') || cat.contains('simpanan')) {
      return getColorForIcon('vault');
    } else if (cat.contains('penyesuaian') || cat.contains('koreksi') || cat.contains('adjustment') || cat.contains('saldo')) {
      return const Color(0xFF00897B);
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
    }

    if (cat.contains('admin') || cat.contains('biaya') || cat.contains('fee')) {
      return FontAwesomeIcons.receipt;
    } else if (cat.contains('makan') || cat.contains('jajan') || cat.contains('resto') || cat.contains('cafe') || cat.contains('sarapan') || cat.contains('kuliner')) {
      return FontAwesomeIcons.utensils;
    } else if (cat.contains('kopi') || cat.contains('minum') || cat.contains('coffee') || cat.contains('boba')) {
      return FontAwesomeIcons.mugHot;
    } else if (cat.contains('bensin') || cat.contains('bbm') || cat.contains('spbu') || cat.contains('pertamina') || cat.contains('shell')) {
      return FontAwesomeIcons.gasPump;
    } else if (cat.contains('motor') || cat.contains('ojek') || cat.contains('grab') || cat.contains('gojek')) {
      return FontAwesomeIcons.motorcycle;
    } else if (cat.contains('mobil') || cat.contains('transport') || cat.contains('parkir') || cat.contains('tol')) {
      return FontAwesomeIcons.car;
    } else if (cat.contains('kereta') || cat.contains('mrt') || cat.contains('krl') || cat.contains('lrt') || cat.contains('train')) {
      return FontAwesomeIcons.train;
    } else if (cat.contains('supermarket') || cat.contains('toko') || cat.contains('mart') || cat.contains('indomaret') || cat.contains('alfamart') || cat.contains('pasar')) {
      return FontAwesomeIcons.cartShopping;
    } else if (cat.contains('belanja') || cat.contains('shop') || cat.contains('kebutuhan') || cat.contains('mall')) {
      return FontAwesomeIcons.bagShopping;
    } else if (cat.contains('baju') || cat.contains('sepatu') || cat.contains('shirt') || cat.contains('pakaian') || cat.contains('celana') || cat.contains('jaket')) {
      return FontAwesomeIcons.shirt;
    } else if (cat.contains('listrik') || cat.contains('pln') || cat.contains('token')) {
      return FontAwesomeIcons.bolt;
    } else if (cat.contains('air') || cat.contains('pdam')) {
      return FontAwesomeIcons.droplet;
    } else if (cat.contains('wifi') || cat.contains('internet') || cat.contains('indihome') || cat.contains('biznet')) {
      return FontAwesomeIcons.wifi;
    } else if (cat.contains('pulsa') || cat.contains('kuota') || cat.contains('telkomsel') || cat.contains('xl') || cat.contains('indosat') || cat.contains('tri')) {
      return FontAwesomeIcons.mobileScreen;
    } else if (cat.contains('tagihan') || cat.contains('invoice') || cat.contains('iuran')) {
      return FontAwesomeIcons.fileInvoiceDollar;
    } else if (cat.contains('kos') || cat.contains('sewa') || cat.contains('kontrakan') || cat.contains('kunci')) {
      return FontAwesomeIcons.key;
    } else if (cat.contains('rumah') || cat.contains('hunian') || cat.contains('perabot')) {
      return FontAwesomeIcons.house;
    } else if (cat.contains('sehat') || cat.contains('sakit') || cat.contains('dokter') || cat.contains('obat') || cat.contains('apotek') || cat.contains('klinik') || cat.contains('rs') || cat.contains('vitamin')) {
      return FontAwesomeIcons.hospital;
    } else if (cat.contains('edukasi') || cat.contains('kuliah') || cat.contains('sekolah') || cat.contains('kursus') || cat.contains('spp') || cat.contains('ukt')) {
      return FontAwesomeIcons.graduationCap;
    } else if (cat.contains('buku') || cat.contains('tugas') || cat.contains('notes') || cat.contains('atk')) {
      return FontAwesomeIcons.book;
    } else if (cat.contains('hiburan') || cat.contains('nonton') || cat.contains('bioskop') || cat.contains('netflix') || cat.contains('cinema') || cat.contains('streaming')) {
      return FontAwesomeIcons.film;
    } else if (cat.contains('game') || cat.contains('main') || cat.contains('topup') || cat.contains('steam') || cat.contains('playstation')) {
      return FontAwesomeIcons.gamepad;
    } else if (cat.contains('musik') || cat.contains('music') || cat.contains('konser') || cat.contains('spotify')) {
      return FontAwesomeIcons.music;
    } else if (cat.contains('liburan') || cat.contains('wisata') || cat.contains('pesawat') || cat.contains('travel') || cat.contains('healing')) {
      return FontAwesomeIcons.plane;
    } else if (cat.contains('hotel') || cat.contains('villa') || cat.contains('resort') || cat.contains('penginapan')) {
      return FontAwesomeIcons.hotel;
    } else if (cat.contains('hewan') || cat.contains('kucing') || cat.contains('anjing') || cat.contains('pet') || cat.contains('vet')) {
      return FontAwesomeIcons.paw;
    } else if (cat.contains('bayi') || cat.contains('anak') || cat.contains('susu') || cat.contains('pampers')) {
      return FontAwesomeIcons.baby;
    } else if (cat.contains('donasi') || cat.contains('amal') || cat.contains('zakat') || cat.contains('sedekah') || cat.contains('infaq')) {
      return FontAwesomeIcons.heart;
    } else if (cat.contains('ibadah') || cat.contains('masjid') || cat.contains('gereja') || cat.contains('sholat') || cat.contains('religi')) {
      return FontAwesomeIcons.handsPraying;
    } else if (cat.contains('rokok') || cat.contains('vape') || cat.contains('pod')) {
      return FontAwesomeIcons.smoking;
    } else if (cat.contains('salon') || cat.contains('barber') || cat.contains('potong') || cat.contains('skincare') || cat.contains('facial')) {
      return FontAwesomeIcons.scissors;
    } else if (cat.contains('olahraga') || cat.contains('dumbbell') || cat.contains('gym') || cat.contains('fitness') || cat.contains('fitnes') || cat.contains('badminton') || cat.contains('futsal')) {
      return FontAwesomeIcons.dumbbell;
    } else if (cat.contains('bengkel') || cat.contains('servis') || cat.contains('service') || cat.contains('cuci') || cat.contains('onderdil')) {
      return FontAwesomeIcons.wrench;
    } else if (cat.contains('gadget') || cat.contains('laptop') || cat.contains('hp') || cat.contains('komputer') || cat.contains('elektronik')) {
      return FontAwesomeIcons.laptop;
    } else if (cat.contains('asuransi') || cat.contains('bpjs') || cat.contains('pajak') || cat.contains('proteksi')) {
      return FontAwesomeIcons.shieldHalved;
    } else if (cat.contains('cicilan') || cat.contains('kredit') || cat.contains('hutang') || cat.contains('utang') || cat.contains('paylater')) {
      return FontAwesomeIcons.creditCard;
    } else if (cat.contains('investasi') || cat.contains('saham') || cat.contains('reksadana') || cat.contains('emas') || cat.contains('reksa')) {
      return FontAwesomeIcons.arrowTrendUp;
    } else if (cat.contains('gaji') || cat.contains('salary') || cat.contains('upah') || cat.contains('payday')) {
      return FontAwesomeIcons.moneyBillWave;
    } else if (cat.contains('bonus') || cat.contains('hadiah') || cat.contains('gift') || cat.contains('thr') || cat.contains('reward')) {
      return FontAwesomeIcons.gift;
    } else if (cat.contains('cashback') || cat.contains('diskon') || cat.contains('promo') || cat.contains('poin')) {
      return FontAwesomeIcons.percent;
    } else if (cat.contains('penjualan') || cat.contains('dagang') || cat.contains('jualan') || cat.contains('omset')) {
      return FontAwesomeIcons.store;
    } else if (cat.contains('olshop') || cat.contains('shopee') || cat.contains('tokopedia') || cat.contains('ekspedisi') || cat.contains('paket')) {
      return FontAwesomeIcons.truckFast;
    } else if (cat.contains('pencairan') || cat.contains('cair') || cat.contains('withdraw') || cat.contains('wd') || cat.contains('tarik')) {
      return FontAwesomeIcons.piggyBank;
    } else if (cat.contains('crypto') || cat.contains('bitcoin') || cat.contains('usdt') || cat.contains('eth')) {
      return FontAwesomeIcons.bitcoin;
    } else if (cat.contains('bunga') || cat.contains('deposito') || cat.contains('bank') || cat.contains('rekening') || cat.contains('transfer')) {
      return FontAwesomeIcons.buildingColumns;
    } else if (cat.contains('koin') || cat.contains('uang') || cat.contains('tunai') || cat.contains('cash') || cat.contains('kembalian')) {
      return FontAwesomeIcons.coins;
    } else if (cat.contains('freelance') || cat.contains('proyek') || cat.contains('project') || cat.contains('sidejob') || cat.contains('kerja')) {
      return FontAwesomeIcons.briefcase;
    } else if (cat.contains('coding') || cat.contains('desain') || cat.contains('jasa') || cat.contains('software')) {
      return FontAwesomeIcons.laptopCode;
    } else if (cat.contains('tip') || cat.contains('komisi') || cat.contains('uang kaget')) {
      return FontAwesomeIcons.handSparkles;
    } else if (cat.contains('refund') || cat.contains('pengembalian') || cat.contains('retur')) {
      return FontAwesomeIcons.arrowsRotate;
    } else if (cat.contains('warisan') || cat.contains('hibah') || cat.contains('emas batangan') || cat.contains('permata')) {
      return FontAwesomeIcons.gem;
    } else if (cat.contains('arisan') || cat.contains('brankas') || cat.contains('simpanan')) {
      return FontAwesomeIcons.vault;
    } else if (cat.contains('penyesuaian') || cat.contains('koreksi') || cat.contains('adjustment') || cat.contains('saldo')) {
      return FontAwesomeIcons.scaleBalanced;
    }

    return FontAwesomeIcons.boxArchive;
  }

  static dynamic getCustomIconById(String id) {
    switch (id) {
      // PENGELUARAN
      case 'utensils': return FontAwesomeIcons.utensils;
      case 'coffee': return FontAwesomeIcons.mugHot;
      case 'car': return FontAwesomeIcons.car;
      case 'motorcycle': return FontAwesomeIcons.motorcycle;
      case 'gas_pump': return FontAwesomeIcons.gasPump;
      case 'bag': return FontAwesomeIcons.bagShopping;
      case 'cart': return FontAwesomeIcons.cartShopping;
      case 'shirt': return FontAwesomeIcons.shirt;
      case 'invoice': return FontAwesomeIcons.fileInvoiceDollar;
      case 'bolt': return FontAwesomeIcons.bolt;
      case 'droplet': return FontAwesomeIcons.droplet;
      case 'wifi': return FontAwesomeIcons.wifi;
      case 'mobile': return FontAwesomeIcons.mobileScreen;
      case 'house': return FontAwesomeIcons.house;
      case 'key': return FontAwesomeIcons.key;
      case 'hospital': return FontAwesomeIcons.hospital;
      case 'edu': return FontAwesomeIcons.graduationCap;
      case 'book': return FontAwesomeIcons.book;
      case 'film': return FontAwesomeIcons.film;
      case 'game': return FontAwesomeIcons.gamepad;
      case 'music': return FontAwesomeIcons.music;
      case 'plane': return FontAwesomeIcons.plane;
      case 'hotel': return FontAwesomeIcons.hotel;
      case 'paw': return FontAwesomeIcons.paw;
      case 'baby': return FontAwesomeIcons.baby;
      case 'heart': return FontAwesomeIcons.heart;
      case 'hands_praying': return FontAwesomeIcons.handsPraying;
      case 'smoking': return FontAwesomeIcons.smoking;
      case 'scissors': return FontAwesomeIcons.scissors;
      case 'dumbbell': return FontAwesomeIcons.dumbbell;
      case 'wrench': return FontAwesomeIcons.wrench;
      case 'laptop': return FontAwesomeIcons.laptop;
      case 'shield': return FontAwesomeIcons.shieldHalved;
      case 'credit_card': return FontAwesomeIcons.creditCard;
      case 'train': return FontAwesomeIcons.train;
      case 'building': return FontAwesomeIcons.building;
      case 'star': return FontAwesomeIcons.star;

      // PEMASUKAN
      case 'salary': return FontAwesomeIcons.moneyBillWave;
      case 'giftbox': return FontAwesomeIcons.gift;
      case 'arrow': return FontAwesomeIcons.arrowTrendUp;
      case 'chart': return FontAwesomeIcons.chartLine;
      case 'store': return FontAwesomeIcons.store;
      case 'truck': return FontAwesomeIcons.truckFast;
      case 'piggy': return FontAwesomeIcons.piggyBank;
      case 'coins': return FontAwesomeIcons.coins;
      case 'briefcase': return FontAwesomeIcons.briefcase;
      case 'laptop_code': return FontAwesomeIcons.laptopCode;
      case 'receipt': return FontAwesomeIcons.receipt;
      case 'hand_holding': return FontAwesomeIcons.handHoldingDollar;
      case 'hand_sparkles': return FontAwesomeIcons.handSparkles;
      case 'money_check': return FontAwesomeIcons.moneyCheckDollar;
      case 'sack': return FontAwesomeIcons.sackDollar;
      case 'percent': return FontAwesomeIcons.percent;
      case 'building_columns': return FontAwesomeIcons.buildingColumns;
      case 'bitcoin': return FontAwesomeIcons.bitcoin;
      case 'gem': return FontAwesomeIcons.gem;
      case 'crown': return FontAwesomeIcons.crown;
      case 'arrows_rotate': return FontAwesomeIcons.arrowsRotate;
      case 'house_laptop': return FontAwesomeIcons.houseLaptop;
      case 'vault': return FontAwesomeIcons.vault;
      case 'user_tie': return FontAwesomeIcons.userTie;

      // Legacy fallback
      case 'safe': return FontAwesomeIcons.vault;

      default: return FontAwesomeIcons.star;
    }
  }
}