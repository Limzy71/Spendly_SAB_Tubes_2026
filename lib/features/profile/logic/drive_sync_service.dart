import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

// Helper class untuk menghubungkan GoogleSignIn dengan Google APIs
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
  // Minta akses (scope) khusus untuk membuat dan mengelola file di Drive
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  Future<void> backupDataToDrive(File databaseFile) async {
    try {
      // 1. Login menggunakan akun Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return; // User membatalkan login

      // 2. Dapatkan token autentikasi
      final GoogleSignInAuthentication googleAuth = await account.authentication;
      final headers = await account.authHeaders;

      // 3. Inisialisasi Google Drive API Client
      final authenticateClient = GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(authenticateClient);

      // 4. Siapkan metadata file untuk Google Drive
      final driveFile = drive.File();
      driveFile.name = "Spendly_Backup_${DateTime.now().toIso8601String()}.db";
      // Kamu bisa menentukan folder spesifik jika mau, defaultnya di root My Drive

      // 5. Proses Upload
      final media = drive.Media(databaseFile.openRead(), databaseFile.lengthSync());
      await driveApi.files.create(driveFile, uploadMedia: media);

      print("Backup ke Google Drive Berhasil!");
    } catch (e) {
      print("Gagal melakukan backup: $e");
    }
  }
}