import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'custom_notification.dart';

class NetworkHelper {
  /// Fungsi global untuk memeriksa apakah perangkat terhubung ke internet.
  /// Jika internet mati, fungsi akan otomatis menampilkan CustomNotification dan mengembalikan nilai 'false'.
  static Future<bool> checkConnection(BuildContext context) async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

    // Jika tidak ada koneksi sama sekali (Wifi maupun Mobile Data mati)
    if (connectivityResult.contains(ConnectivityResult.none) || connectivityResult.isEmpty) {
      if (context.mounted) {
        CustomNotification.show(
          context,
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
          isError: true,
        );
      }
      return false; // Internet mati
    }

    return true; // Internet aktif
  }

  /// Tambahkan ini di dalam class NetworkHelper
  static void handleSupabaseError(BuildContext context, Object error, {String prefix = 'Terjadi kesalahan'}) {
    String errorMsg = error.toString();
    if (errorMsg.contains('ClientException') || errorMsg.contains('Failed to fetch') || errorMsg.contains('SocketException')) {
      CustomNotification.show(
        context,
        '$prefix: Koneksi ke server terputus. Silakan periksa jaringan Anda.',
        isError: true,
      );
    } else {
      CustomNotification.show(context, '$prefix: $errorMsg', isError: true);
    }
  }
}