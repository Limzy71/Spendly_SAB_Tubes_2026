import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class WalletHelper {
  static Widget getIcon(String? iconName, String walletName, {Color? color, double size = 20}) {
    String name = walletName.toLowerCase().trim();
    String assetPath = '';

    if (name.contains('tunai') || name.contains('cash') || name.contains('dompet')) {
      assetPath = 'assets/images/logos/tunai.svg';
    } else if (name.contains('bca') || name.contains('klikbca')) {
      assetPath = 'assets/images/logos/bca.svg';
    } else if (name.contains('mandiri')) {
      assetPath = 'assets/images/logos/mandiri.svg';
    } else if (name.contains('bri') || name.contains('brimo')) {
      assetPath = 'assets/images/logos/bri.svg';
    } else if (name.contains('bni')) {
      assetPath = 'assets/images/logos/bni.svg';
    } else if (name.contains('gopay') || name.contains('go-pay')) {
      assetPath = 'assets/images/logos/gopay.svg';
    } else if (name.contains('ovo')) {
      assetPath = 'assets/images/logos/ovo.svg';
    } else if (name.contains('dana') && !name.contains('danamon')) {
      assetPath = 'assets/images/logos/dana.svg';
    } else if (name.contains('shopee') || name.contains('spay')) {
      assetPath = 'assets/images/logos/shopeepay.svg';
    } else if (name.contains('linkaja')) {
      assetPath = 'assets/images/logos/linkaja.svg';
    } else if (name.contains('jago')) {
      assetPath = 'assets/images/logos/bank-jago.svg';
    } else if (name.contains('seabank') || name.contains('sea bank')) {
      assetPath = 'assets/images/logos/seabank-logo.svg';
    } else if (name.contains('blu')) {
      assetPath = 'assets/images/logos/blu-by-bca.svg';
    } else if (name.contains('jenius')) {
      assetPath = 'assets/images/logos/jenius.svg';
    } else if (name.contains('paypal')) {
      assetPath = 'assets/images/logos/paypal.svg';
    } else if (name.contains('allo')) {
      assetPath = 'assets/images/logos/allo-bank.svg';
    } else if (name.contains('neo')) {
      assetPath = 'assets/images/logos/bank-neo.svg';
    } else if (name.contains('flip')) {
      assetPath = 'assets/images/logos/flip.svg';
    } else if (name.contains('isaku') || name.contains('saku')) {
      assetPath = 'assets/images/logos/isaku.svg';
    } else if (name.contains('krom')) {
      assetPath = 'assets/images/logos/krom-bank.svg';
    } else if (name.contains('skrill')) {
      assetPath = 'assets/images/logos/skrill.svg';
    } else if (name.contains('super')) {
      assetPath = 'assets/images/logos/super-bank.svg';
    } else if (name.contains('maybank')) {
      assetPath = 'assets/images/logos/maybank.svg';
    } else if (name.contains('sinarmas')) {
      assetPath = 'assets/images/logos/bank-sinarmas.svg';
    } else if (name.contains('permata')) {
      assetPath = 'assets/images/logos/bank-permata.svg';
    } else if (name.contains('panin')) {
      assetPath = 'assets/images/logos/bank-panin.svg';
    } else if (name.contains('ocbc')) {
      assetPath = 'assets/images/logos/bank-ocbc.svg';
    } else if (name.contains('mega')) {
      assetPath = 'assets/images/logos/bank-mega.svg';
    } else if (name.contains('danamon')) {
      assetPath = 'assets/images/logos/bank-danamon.svg';
    } else if (name.contains('cimb') || name.contains('niaga')) {
      assetPath = 'assets/images/logos/bank-cimb-niaga.svg';
    } else if (name.contains('btn')) {
      assetPath = 'assets/images/logos/bank-btn.svg';
    } else if (name.contains('bsi')) {
      assetPath = 'assets/images/logos/bank-bsi.svg';
    }

    if (assetPath.isNotEmpty) {
      return SizedBox(
        width: size * 2.4,
        height: size * 2.4,
        child: Align(
          alignment: Alignment.center,
          child: SvgPicture.asset(
            assetPath,
            width: size * 2.4,
            height: size * 2.4,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      );
    }

    dynamic iconData = FontAwesomeIcons.wallet;

    if (iconName != null && iconName != 'default' && iconName != 'add') {
      switch (iconName) {
        case 'money': iconData = FontAwesomeIcons.moneyBillWave; break;
        case 'bank': iconData = FontAwesomeIcons.buildingColumns; break;
        case 'wallet': iconData = FontAwesomeIcons.wallet; break;
        case 'card': iconData = FontAwesomeIcons.creditCard; break;
        case 'savings': iconData = FontAwesomeIcons.piggyBank; break;
        case 'crypto': iconData = FontAwesomeIcons.bitcoin; break;
        case 'business': iconData = FontAwesomeIcons.store; break;
        case 'investment': iconData = FontAwesomeIcons.arrowTrendUp; break;
        case 'safe': iconData = FontAwesomeIcons.vault; break;
        case 'online': iconData = FontAwesomeIcons.globe; break;
      }
      return SizedBox(
        width: size * 1.4,
        height: size * 1.4,
        child: Align(
          alignment: Alignment.center,
          child: FaIcon(iconData, color: color, size: size * 1.4),
        ),
      );
    }

    if (name.isEmpty) {
      return SizedBox(
        width: size * 1.4,
        height: size * 1.4,
        child: Align(
          alignment: Alignment.center,
          child: FaIcon(FontAwesomeIcons.wallet, color: color, size: size * 1.4),
        ),
      );
    }

    if (name.contains('tunai') || name.contains('cash') || name.contains('dompet')) {
      iconData = FontAwesomeIcons.moneyBillWave;
    } else if (name.contains('gopay') || name.contains('go-pay') || name.contains('ovo') || (name.contains('dana') && !name.contains('danamon')) || name.contains('shopee') || name.contains('spay') || name.contains('linkaja') || name.contains('isaku') || name.contains('flip') || name.contains('skrill')) {
      iconData = FontAwesomeIcons.wallet;
    } else if (name.contains('paypal')) {
      iconData = FontAwesomeIcons.paypal;
    } else if (name.contains('crypto') || name.contains('kripto') || name.contains('bitcoin') || name.contains('pintu') || name.contains('indodax')) {
      iconData = FontAwesomeIcons.bitcoin;
    } else if (name.contains('bca') || name.contains('klikbca') || name.contains('sakuku') || name.contains('mandiri') || name.contains('bri') || name.contains('brimo') || name.contains('bni') || name.contains('jago') || name.contains('seabank') || name.contains('sea bank') || name.contains('blu') || name.contains('allo') || name.contains('neo') || name.contains('krom') || name.contains('super') || name.contains('maybank') || name.contains('sinarmas') || name.contains('permata') || name.contains('panin') || name.contains('ocbc') || name.contains('mega') || name.contains('danamon') || name.contains('cimb') || name.contains('btn') || name.contains('bsi')) {
      iconData = FontAwesomeIcons.buildingColumns;
    } else if (name.contains('jenius') || name.contains('btpn')) {
      iconData = FontAwesomeIcons.creditCard;
    } else if (name.contains('bank') || name.contains('rekening') || name.contains('atm')) {
      iconData = FontAwesomeIcons.buildingColumns;
    } else if (name.contains('pay') || name.contains('wallet') || name.contains('saku') || name.contains('digital')) {
      iconData = FontAwesomeIcons.wallet;
    } else if (name.contains('tabungan') || name.contains('celengan') || name.contains('simpanan')) {
      iconData = FontAwesomeIcons.piggyBank;
    } else if (name.contains('investasi') || name.contains('reksadana') || name.contains('saham')) {
      iconData = FontAwesomeIcons.arrowTrendUp;
    }

    return SizedBox(
      width: size * 1.4,
      height: size * 1.4,
      child: Align(
        alignment: Alignment.center,
        child: FaIcon(iconData, color: color, size: size * 1.4),
      ),
    );
  }

  static Color getColor(String walletName) {
    String name = walletName.toLowerCase().trim();
    if (name.isEmpty) return Colors.teal.shade700;

    if (name.contains('tunai') || name.contains('cash') || name.contains('dompet')) return AppColors.primaryGreen;
    if (name.contains('bca') || name.contains('sakuku')) return const Color(0xFF0056A3);
    if (name.contains('mandiri')) return const Color(0xFF1A3F68);
    if (name.contains('bri') || name.contains('brimo')) return const Color(0xFF00529C);
    if (name.contains('bni')) return const Color(0xFFF15A23);
    if (name.contains('gopay') || name.contains('go-pay')) return const Color(0xFF00AED6);
    if (name.contains('ovo')) return const Color(0xFF4C2A86);
    if (name.contains('dana') && !name.contains('danamon')) return const Color(0xFF108EE9);
    if (name.contains('shopee') || name.contains('spay')) return const Color(0xFFEE4D2D);
    if (name.contains('seabank') || name.contains('sea bank')) return const Color(0xFFFF6B00);
    if (name.contains('flip')) return const Color(0xFFFD6542);
    if (name.contains('linkaja')) return const Color(0xFFE02424);
    if (name.contains('super')) return const Color(0xFF00C93A);
    if (name.contains('jago')) return const Color(0xFFFF9E1B);
    if (name.contains('neo')) return const Color(0xFFFF6B59);
    if (name.contains('blu')) return const Color(0xFF00D2C4);
    if (name.contains('jenius')) return const Color(0xFF25AAE1);
    if (name.contains('allo')) return const Color(0xFFFFAA00);
    if (name.contains('krom')) return const Color(0xFF7B33FF);
    if (name.contains('skrill')) return const Color(0xFF801C41);
    if (name.contains('paypal')) return const Color(0xFF003087);
    if (name.contains('isaku') || name.contains('saku')) return const Color(0xFF005BAB);
    if (name.contains('maybank')) return const Color(0xFFFFD100);
    if (name.contains('sinarmas')) return const Color(0xFFE31837);
    if (name.contains('permata')) return const Color(0xFF007A5E);
    if (name.contains('panin')) return const Color(0xFF0033A0);
    if (name.contains('ocbc')) return const Color(0xFFED1C24);
    if (name.contains('mega')) return const Color(0xFFF8B612);
    if (name.contains('danamon')) return const Color(0xFFF37021);
    if (name.contains('cimb') || name.contains('niaga')) return const Color(0xFF9B2743);
    if (name.contains('btn')) return const Color(0xFF00509E);
    if (name.contains('bsi')) return const Color(0xFF00A39D);
    if (name.contains('crypto') || name.contains('kripto') || name.contains('bitcoin')) return Colors.amber.shade600;

    if (name.contains('bank') || name.contains('rekening')) return Colors.indigo;
    if (name.contains('pay') || name.contains('wallet')) return Colors.blue;
    if (name.contains('tabungan')) return Colors.teal;

    return Colors.teal.shade700;
  }

  static String getSubtitle(String walletName) {
    String name = walletName.toLowerCase().trim();
    if (name.isEmpty) return 'Bank / Rekening';

    if (name.contains('tunai') || name.contains('cash') || name.contains('dompet')) {
      return 'Uang Fisik';
    } else if (name.contains('gopay') || name.contains('ovo') || (name.contains('dana') && !name.contains('danamon')) || name.contains('shopee') || name.contains('spay') || name.contains('linkaja') || name.contains('paypal') || name.contains('wallet') || name.contains('pay') || name.contains('flip') || name.contains('isaku') || name.contains('skrill')) {
      return 'E-Wallet';
    } else if (name.contains('jago') || name.contains('seabank') || name.contains('sea bank') || name.contains('blu') || name.contains('jenius') || name.contains('neo') || name.contains('allo') || name.contains('digital') || name.contains('krom') || name.contains('super')) {
      return 'Digital Bank';
    } else if (name.contains('crypto') || name.contains('kripto') || name.contains('bitcoin')) {
      return 'Aset Kripto';
    } else if (name.contains('tabungan') || name.contains('celengan')) {
      return 'Simpanan';
    }

    return 'Bank / Rekening';
  }
}