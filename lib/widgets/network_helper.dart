import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'custom_notification.dart';

class NetworkHelper {
  /// Fungsi global untuk memeriksa apakah perangkat terhubung ke internet.
  /// Jika internet mati, fungsi akan otomatis menampilkan CustomNotification dan mengembalikan nilai 'false'.
  static Future<bool> checkConnection(BuildContext context) async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none) || connectivityResult.isEmpty) {
      if (context.mounted) {
        CustomNotification.show(
          context,
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
          isError: true,
        );
      }
      return false;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      if (context.mounted) {
        CustomNotification.show(
          context,
          'Jaringan terhubung, namun tidak ada akses internet.',
          isError: true,
        );
      }
      return false;
    }

    return false;
  }
}