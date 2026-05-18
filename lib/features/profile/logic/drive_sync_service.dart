import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/custom_notification.dart';

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

  static Future<Map<String, dynamic>> _fetchAllSupabaseData() async {
    final supabase = Supabase.instance.client;

    final transactionsRes = await supabase.from('transactions').select();
    final walletsRes = await supabase.from('wallets').select();
    final budgetsRes = await supabase.from('budgets').select();

    return {
      'transactions': transactionsRes,
      'wallets': walletsRes,
      'budgets': budgetsRes,
    };
  }

  static Future<void> backupToDrive(BuildContext context) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return;

      if (context.mounted) {
        CustomNotification.show(context, 'Membaca seluruh data database...', isWarning: true);
      }

      final allData = await _fetchAllSupabaseData();
      String jsonData = jsonEncode(allData);

      final authHeaders = await account.authHeaders;
      final driveApi = drive.DriveApi(GoogleAuthClient(authHeaders));

      final Directory dir = await getTemporaryDirectory();
      final File backupFile = File('${dir.path}/Spendly_All_Backup.json');
      await backupFile.writeAsString(jsonData);

      final driveFile = drive.File();
      String tanggal = DateTime.now().toString().split(' ')[0];
      driveFile.name = "Spendly_Full_Backup_$tanggal\_${DateTime.now().millisecondsSinceEpoch}.json";
      driveFile.mimeType = "application/json";

      final media = drive.Media(backupFile.openRead(), backupFile.lengthSync());
      await driveFile.name != null ? driveApi.files.create(driveFile, uploadMedia: media) : null;

      if (context.mounted) {
        CustomNotification.show(context, 'Semua data berhasil dicadangkan ke Google Drive!');
      }
    } catch (e) {
      if (context.mounted) {
        CustomNotification.show(context, 'Gagal mencadangkan data: $e', isError: true);
      }
    }
  }

  static Future<void> restoreFromDrive(BuildContext context) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return;

      if (context.mounted) {
        CustomNotification.show(context, 'Mencari daftar cadangan di Google Drive...', isWarning: true);
      }

      final authHeaders = await account.authHeaders;
      final driveApi = drive.DriveApi(GoogleAuthClient(authHeaders));

      final fileList = await driveApi.files.list(
        q: "name contains 'Spendly_Full_Backup' and trashed = false",
        orderBy: "createdTime desc",
        pageSize: 10,
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        if (context.mounted) {
          CustomNotification.show(context, 'Tidak ditemukan file cadangan di Drive Anda.', isWarning: true);
        }
        return;
      }

      if (!context.mounted) return;

      final drive.File? selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Pilih File Pemulihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: fileList.files!.length,
                itemBuilder: (context, index) {
                  final file = fileList.files![index];
                  final date = file.createdTime?.toLocal();
                  final dateString = date != null ? "${date.day}-${date.month}-${date.year} (${date.hour}:${date.minute.toString().padLeft(2, '0')})" : "-";

                  return Card(
                    elevation: 0,
                    color: Colors.blue.withValues(alpha: 0.05),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.backup, color: Colors.blue),
                      title: Text(file.name ?? 'File Cadangan', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Dibuat: $dateString', style: const TextStyle(fontSize: 12)),
                      onTap: () => Navigator.pop(dialogContext, file),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, null),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      );

      if (selectedFile == null) return;

      final String fileId = selectedFile.id!;

      if (context.mounted) {
        CustomNotification.show(context, 'Mengunduh dan menyinkronkan data...', isWarning: true);
      }

      final drive.Media response = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      List<int> dataBytes = [];
      await response.stream.listen((data) {
        dataBytes.addAll(data);
      }).asFuture();

      String stringData = utf8.decode(dataBytes);
      Map<String, dynamic> backupData = jsonDecode(stringData);

      final supabase = Supabase.instance.client;

      if (backupData['wallets'] != null) {
        await supabase.from('wallets').upsert(List<Map<String, dynamic>>.from(backupData['wallets']));
      }
      if (backupData['budgets'] != null) {
        await supabase.from('budgets').upsert(List<Map<String, dynamic>>.from(backupData['budgets']));
      }
      if (backupData['transactions'] != null) {
        await supabase.from('transactions').upsert(List<Map<String, dynamic>>.from(backupData['transactions']));
      }

      if (context.mounted) {
        CustomNotification.show(context, 'Pemulihan & Sinkronisasi data berhasil selesai!');
      }
    } catch (e) {
      if (context.mounted) {
        CustomNotification.show(context, 'Gagal sinkronisasi data balik: $e', isError: true);
      }
    }
  }
}