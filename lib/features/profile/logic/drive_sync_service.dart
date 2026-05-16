import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static void _showTopNotification(BuildContext context, String message, {bool isError = false, bool isWarning = false, bool isInfo = false}) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    Color bgColor = const Color(0xFF00AA5B);
    IconData icon = Icons.check;

    if (isError) {
      bgColor = const Color(0xFFE63946);
      icon = Icons.close;
    } else if (isWarning) {
      bgColor = Colors.orange.shade600;
      icon = Icons.warning_amber_rounded;
    } else if (isInfo) {
      bgColor = Colors.blue.shade500;
      icon = Icons.info_outline;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: -100, end: 0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(offset: Offset(0, value), child: child);
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: bgColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry != null && overlayEntry!.mounted) overlayEntry!.remove();
    });
  }

  static Future<List<Map<String, dynamic>>> _fetchDataFromSupabase() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return [];

    final response = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('transaction_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<File> _createBackupCsvFile() async {
    final rawData = await _fetchDataFromSupabase();

    List<List<dynamic>> rows = [
      ["Tanggal", "Kategori", "Tipe", "Nominal", "Catatan"],
    ];

    for (var item in rawData) {
      String tipeTransaksi = (item['is_expense'] == true) ? 'Pengeluaran' : 'Pemasukan';
      rows.add([
        item['transaction_date'] ?? '-',
        item['category'] ?? '-',
        tipeTransaksi,
        item['amount'] ?? 0,
        item['note'] ?? '-',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final Directory dir = await getApplicationDocumentsDirectory();
    final String filePath = '${dir.path}/Spendly_Backup_${DateTime.now().millisecondsSinceEpoch}.csv';

    // TYPO DIPERBAIKI DI SINI: File(filePath) bukan File(path)
    final File file = File(filePath);
    await file.writeAsString(csvData);

    return file;
  }

  static Future<void> backupToDrive(BuildContext context) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        if (context.mounted) {
          _showTopNotification(context, 'Proses backup dibatalkan.', isWarning: true);
        }
        return;
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      if (context.mounted) {
        _showTopNotification(context, 'Menyiapkan & Mengunggah data ke Google Drive...', isInfo: true);
      }

      final File backupFile = await _createBackupCsvFile();
      final driveFile = drive.File();
      driveFile.name = backupFile.path.split('/').last;

      final media = drive.Media(backupFile.openRead(), backupFile.lengthSync());
      await driveApi.files.create(driveFile, uploadMedia: media);

      if (context.mounted) {
        _showTopNotification(context, 'Backup ke Google Drive berhasil!');
      }

    } catch (e) {
      if (context.mounted) {
        _showTopNotification(context, 'Gagal backup: $e', isError: true);
      }
    }
  }

  static Future<void> disconnectGoogle() async {
    await _googleSignIn.disconnect();
  }
}