import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// --- KELAS BANTUAN UNTUK AUTENTIKASI HTTP ---
// Google Drive API membutuhkan header autentikasi yang valid.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class DriveSyncService {
  // Meminta akses khusus (Scope) agar aplikasi diizinkan membaca & menulis file di Drive
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  static Future<void> backupToDrive(BuildContext context) async {
    try {
      // 1. Meminta pengguna untuk Login menggunakan Akun Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // Jika pengguna menekan tombol "Batal" saat pop-up akun Google muncul
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proses backup dibatalkan.'), backgroundColor: Colors.orange)
          );
        }
        return;
      }

      // 2. Mendapatkan Token Autentikasi
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mengunggah data ke Google Drive...'))
        );
      }

      // 3. Menyiapkan File Data yang akan di-backup
      // CATATAN: Ini adalah contoh membuat file teks sementara untuk diunggah.
      // Nantinya, arahkan 'File' ini ke file SQLite lokal (jika ada) atau file CSV dari ExportService.
      final Directory dir = await getApplicationDocumentsDirectory();
      final String filePath = '${dir.path}/Spendly_Backup_${DateTime.now().millisecondsSinceEpoch}.txt';
      final File backupFile = File(filePath);

      // Mengisi file dengan data (Bisa diganti dengan logika ekspor database sesungguhnya)
      await backupFile.writeAsString("Ini adalah data backup Spendly pada tanggal ${DateTime.now().toString()}");

      // 4. Konfigurasi Metadata File di Google Drive
      final driveFile = drive.File();
      driveFile.name = backupFile.path.split('/').last; // Mengambil nama file

      // 5. Proses Unggah (Upload) File ke Drive
      final media = drive.Media(backupFile.openRead(), backupFile.lengthSync());
      await driveApi.files.create(driveFile, uploadMedia: media);

      // 6. Beri Notifikasi Sukses
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup ke Google Drive berhasil!'), backgroundColor: Colors.green)
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal backup: $e'), backgroundColor: Colors.red)
        );
      }
      print("Error Drive Sync: $e");
    }
  }

  // Opsi Logout dari Google (Bisa disambungkan ke tombol Logout aplikasi)
  static Future<void> disconnectGoogle() async {
    await _googleSignIn.disconnect();
  }
}