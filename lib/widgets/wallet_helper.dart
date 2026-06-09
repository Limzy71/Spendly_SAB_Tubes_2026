import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';

class WalletHelper {

  // 1. Kamus Pusat Ikon Dompet Pintar
  static dynamic getIcon(String? iconName, String walletName) {
    if (iconName != null && iconName != 'default' && iconName != 'add') {
      switch (iconName) {
        case 'money': return FontAwesomeIcons.moneyBillWave;
        case 'bank': return FontAwesomeIcons.buildingColumns;
        case 'wallet': return FontAwesomeIcons.wallet;
        case 'card': return FontAwesomeIcons.creditCard;
        case 'savings': return FontAwesomeIcons.piggyBank;
        case 'crypto': return FontAwesomeIcons.bitcoin;
        case 'business': return FontAwesomeIcons.store;
        case 'investment': return FontAwesomeIcons.arrowTrendUp;
        case 'safe': return FontAwesomeIcons.vault;
        case 'online': return FontAwesomeIcons.globe;
      }
    }

    String name = walletName.toLowerCase().trim();
    if (name.isEmpty) return FontAwesomeIcons.wallet;

    if (name.contains('gopay') || name.contains('go-pay')) {
      return FontAwesomeIcons.wallet;
    } else if (name.contains('ovo')) {
      return FontAwesomeIcons.wallet;
    } else if (name.contains('dana')) {
      return FontAwesomeIcons.wallet;
    } else if (name.contains('shopee') || name.contains('spay')) {
      return FontAwesomeIcons.wallet;
    } else if (name.contains('linkaja')) {
      return FontAwesomeIcons.wallet;
    } else if (name.contains('paypal')) {
      return FontAwesomeIcons.paypal;
    } else if (name.contains('crypto') || name.contains('kripto') || name.contains('bitcoin') || name.contains('pintu') || name.contains('indodax')) {
      return FontAwesomeIcons.bitcoin;
    }

    // -- Pencocokan Bank Konvensional & Digital Populer --
    if (name.contains('bca') || name.contains('klikbca') || name.contains('sakuku')) {
      return FontAwesomeIcons.buildingColumns;
    } else if (name.contains('mandiri') || name.contains('livin')) {
      return FontAwesomeIcons.buildingColumns;
    } else if (name.contains('bri') || name.contains('brimo')) {
      return FontAwesomeIcons.buildingColumns;
    } else if (name.contains('bni')) {
      return FontAwesomeIcons.buildingColumns;
    } else if (name.contains('jago')) {
      return FontAwesomeIcons.buildingColumns; // Bank Jago
    } else if (name.contains('seabank') || name.contains('sea bank')) {
      return FontAwesomeIcons.buildingColumns; // SeaBank
    } else if (name.contains('blu')) {
      return FontAwesomeIcons.buildingColumns; // blu by BCA Digital
    } else if (name.contains('jenius') || name.contains('btpn')) {
      return FontAwesomeIcons.creditCard;
    }

    // -- LAYER 2: Pencocokan Berdasarkan Kategori Teks (Grup Industri) --
    if (name.contains('bank') || name.contains('rekening') || name.contains('atm')) {
      return FontAwesomeIcons.buildingColumns;
    } else if (name.contains('pay') || name.contains('wallet') || name.contains('saku') || name.contains('digital')) {
      return FontAwesomeIcons.wallet;
    } else if (name.contains('tabungan') || name.contains('celengan') || name.contains('simpanan')) {
      return FontAwesomeIcons.piggyBank;
    } else if (name.contains('investasi') || name.contains('reksadana') || name.contains('saham')) {
      return FontAwesomeIcons.arrowTrendUp;
    }

    // -- LAYER 3: Ultimate Fallback jika namanya benar-benar polos --
    return FontAwesomeIcons.wallet;
  }

  // 2. Kamus Pusat Warna Dompet Pintar
  static Color getColor(String walletName) {
    String name = walletName.toLowerCase().trim();
    if (name.isEmpty) return Colors.teal.shade700;

    // Warna khas masing-masing brand fintech / bank Indonesia
    if (name.contains('tunai') || name.contains('cash')) {
      return AppColors.primaryGreen;
    } else if (name.contains('bca') || name.contains('sakuku')) {
      return const Color(0xFF0056A3); // Biru Gelap BCA
    } else if (name.contains('mandiri') || name.contains('livin')) {
      return const Color(0xFF1A3F68); // Biru Navy Mandiri
    } else if (name.contains('bri') || name.contains('brimo')) {
      return const Color(0xFF00529C); // Biru BRI
    } else if (name.contains('bni')) {
      return const Color(0xFF008491); // Tosca BNI
    } else if (name.contains('gopay') || name.contains('go-pay')) {
      return const Color(0xFF00AED6); // Biru Cerah GoPay
    } else if (name.contains('ovo')) {
      return const Color(0xFF4C2A86); // Ungu OVO
    } else if (name.contains('dana')) {
      return const Color(0xFF108EE9); // Biru DANA
    } else if (name.contains('shopee') || name.contains('spay') || name.contains('seabank') || name.contains('sea bank')) {
      return const Color(0xFFEE4D2D); // Orange Shopee / SeaBank
    } else if (name.contains('linkaja')) {
      return const Color(0xFFE02424); // Merah LinkAja
    } else if (name.contains('jago')) {
      return const Color(0xFFFF9E1B); // Amber/Kuning Oranye Bank Jago
    } else if (name.contains('blu')) {
      return const Color(0xFF00D2C4); // Tosca Muda Cerah blu
    } else if (name.contains('jenius')) {
      return const Color(0xFF25AAE1); // Biru Langit Jenius
    } else if (name.contains('paypal')) {
      return const Color(0xFF003087); // Deep Blue PayPal
    } else if (name.contains('crypto') || name.contains('kripto') || name.contains('bitcoin')) {
      return Colors.amber.shade600;
    }

    // Fallback berdasarkan industri jika namanya tidak masuk daftar brand di atas
    if (name.contains('bank') || name.contains('rekening')) {
      return Colors.indigo;
    } else if (name.contains('pay') || name.contains('wallet')) {
      return Colors.blue;
    } else if (name.contains('tabungan')) {
      return Colors.teal;
    }

    return Colors.teal.shade700; // Warna default netral
  }

  // 3. Kamus Pusat Subtitle Deskripsi Dompet
  static String getSubtitle(String walletName) {
    String name = walletName.toLowerCase().trim();
    if (name.isEmpty) return 'Bank / Rekening';

    if (name.contains('tunai') || name.contains('cash')) {
      return 'Uang Fisik';
    } else if (name.contains('gopay') || name.contains('ovo') || name.contains('dana') || name.contains('shopee') || name.contains('spay') || name.contains('linkaja') || name.contains('paypal') || name.contains('wallet') || name.contains('pay')) {
      return 'E-Wallet';
    } else if (name.contains('jago') || name.contains('seabank') || name.contains('blu') || name.contains('jenius') || name.contains('neo') || name.contains('allo') || name.contains('digital')) {
      return 'Digital Bank';
    } else if (name.contains('crypto') || name.contains('kripto') || name.contains('bitcoin')) {
      return 'Aset Kripto';
    } else if (name.contains('tabungan') || name.contains('celengan')) {
      return 'Simpanan';
    }

    return 'Bank / Rekening';
  }
}