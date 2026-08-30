import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  static bool _isAuthExpiry(String errorMsg) {
    final lower = errorMsg.toLowerCase();
    return lower.contains('jwt') ||
        lower.contains('token has expired') ||
        lower.contains('token expired') ||
        lower.contains('access token') ||
        lower.contains('refresh token') ||
        lower.contains('session expired') ||
        lower.contains('session missing') ||
        lower.contains('session_not_found') ||
        lower.contains('invalid_claim') ||
        lower.contains('failed to validate token') ||
        lower.contains('invalid jwt') ||
        lower.contains('expired') && lower.contains('auth');
  }

  /// Terjemahkan pesan error teknis menjadi pesan yang mudah dipahami pengguna.
  /// Mengembalikan string kosong jika tidak ada terjemahan yang cocok.
  static String friendlyMessage(Object error) {
    return _friendlyMessage(error.toString());
  }

  static String _friendlyMessage(String errorMsg) {
    final lower = errorMsg.toLowerCase();

    if (_isAuthExpiry(errorMsg)) {
      return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    }
    if (lower.contains('clientexception') || lower.contains('failed to fetch') ||
        lower.contains('socketerror') || lower.contains('network') ||
        lower.contains('connection refused') || lower.contains('timeout')) {
      return 'Koneksi ke server terputus. Silakan periksa jaringan Anda.';
    }
    if (lower.contains('authentication failed') || lower.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (lower.contains('already registered') || lower.contains('already exists') || lower.contains('already registered')) {
      return 'Data sudah terdaftar sebelumnya.';
    }
    if (lower.contains('foreign key') || lower.contains('row level security') || lower.contains('rls')) {
      return 'Anda tidak memiliki izin untuk melakukan aksi ini.';
    }
    if (lower.contains('duplicate key') || lower.contains('unique constraint')) {
      return 'Data yang sama sudah pernah disimpan.';
    }
    if (lower.contains('permission denied')) {
      return 'Anda tidak memiliki izin untuk melakukan aksi ini.';
    }
    if (lower.contains('not found')) {
      return 'Data yang Anda cari tidak ditemukan.';
    }
    if (lower.contains('database error')) {
      return 'Terjadi masalah pada penyimpanan data. Silakan coba lagi.';
    }

    // Jika error berisi blok JSON milik Supabase/Postgrest, coba ekstrak bagian "message" yang ramah.
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(errorMsg);
    if (match != null) {
      final extracted = match.group(1)!.trim();
      if (extracted.isNotEmpty && !extracted.toLowerCase().contains('jwt') && !extracted.toLowerCase().contains('exception')) {
        return extracted;
      }
    }

    return '';
  }

  /// Menangani error dari Supabase/Postgrest dengan pesan yang mudah dipahami.
  static void handleSupabaseError(BuildContext context, Object error, {String prefix = 'Terjadi kesalahan'}) {
    String errorMsg = error.toString();

    if (_isAuthExpiry(errorMsg)) {
      CustomNotification.show(
        context,
        'Sesi Anda telah berakhir. Silakan masuk kembali.',
        isWarning: true,
      );
      _resetExpiredSession();
      return;
    }

    final friendly = _friendlyMessage(errorMsg);
    // Jangan pernah menampilkan pesan error teknis mentah (JWT, exception, kode status) ke pengguna.
    final message = friendly.isNotEmpty
        ? friendly
        : 'Terjadi kesalahan. Silakan coba lagi.';

    CustomNotification.show(context, message, isError: true);
  }

  static Future<void> _resetExpiredSession() async {
    try {
      // signOut() di gotrue sudah menangani JWT yang kedaluwarsa (401 diabaikan)
      // dan tetap membersihkan sesi lokal, sehingga AuthGate otomatis
      // mengarahkan pengguna kembali ke layar login.
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Abaikan error; onAuthStateChange tetap akan mengarahkan ke layar login.
    }
  }
}