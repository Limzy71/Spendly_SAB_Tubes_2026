import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_auth;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/network_helper.dart';

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
  static final g_auth.GoogleSignIn _googleSignIn = g_auth.GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static Future<String?> getLastBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('last_google_drive_backup_time');
    if (timeStr == null) return null;
    try {
      final date = DateTime.parse(timeStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id').format(date);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getLastBackupEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_google_drive_backup_email');
  }

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

  static Future<bool> backupToDrive(BuildContext context) async {
    try {
      final g_auth.GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        if (context.mounted) {
          CustomNotification.show(
              context, 'Pencadangan Google Drive dibatalkan',
              isWarning: true);
        }
        return false;
      }

      if (context.mounted) {
        CustomNotification.show(context,
            'Mempersiapkan seluruh data transaksi, dompet & anggaran...',
            isWarning: true);
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
      driveFile.name =
          "Spendly_Full_Backup_${tanggal}_${DateTime.now().millisecondsSinceEpoch}.json";
      driveFile.mimeType = "application/json";

      final media = drive.Media(backupFile.openRead(), backupFile.lengthSync());
      await driveApi.files.create(driveFile, uploadMedia: media);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'last_google_drive_backup_time', DateTime.now().toIso8601String());
      await prefs.setString('last_google_drive_backup_email', account.email);

      if (context.mounted) {
        CustomNotification.show(
            context, 'Semua data berhasil dicadangkan ke Google Drive!');
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        NetworkHelper.handleSupabaseError(context, e,
            prefix: 'Gagal mencadangkan data');
      }
      return false;
    }
  }

  static Future<bool> restoreFromDrive(BuildContext context) async {
    try {
      final g_auth.GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        if (context.mounted) {
          CustomNotification.show(
              context, 'Sinkronisasi Google Drive dibatalkan',
              isWarning: true);
        }
        return false;
      }

      if (context.mounted) {
        CustomNotification.show(
            context, 'Mencari daftar cadangan di Google Drive...',
            isWarning: true);
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
          CustomNotification.show(
              context, 'Tidak ditemukan file cadangan di Google Drive Anda.',
              isWarning: true);
        }
        return false;
      }

      if (!context.mounted) return false;

      final drive.File? selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (BuildContext dialogContext) {
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Pilih Berkas Cadangan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SizedBox(
              width: double.maxFinite,
              height: 320,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: fileList.files!.length,
                itemBuilder: (context, index) {
                  final file = fileList.files![index];
                  final date = file.createdTime?.toLocal();
                  final dateString = date != null
                      ? DateFormat('dd MMM yyyy, HH:mm', 'id').format(date)
                      : '-';

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1FAF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.cloud_done_rounded,
                          color: Colors.green),
                      title: Text(
                        file.name ?? 'File Cadangan',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Dibuat: $dateString WIB',
                          style: const TextStyle(fontSize: 11)),
                      onTap: () => Navigator.pop(dialogContext, file),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, null),
                child:
                    const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      );

      if (selectedFile == null) {
        if (context.mounted) {
          CustomNotification.show(
              context, 'Pemilihan file cadangan dibatalkan.',
              isWarning: true);
        }
        return false;
      }

      final String fileId = selectedFile.id!;

      if (context.mounted) {
        CustomNotification.show(context, 'Mengunduh dan memulihkan data...',
            isWarning: true);
      }

      final drive.Media response = await driveApi.files.get(fileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      List<int> dataBytes = [];
      await response.stream.listen((data) {
        dataBytes.addAll(data);
      }).asFuture();

      String stringData = utf8.decode(dataBytes);
      Map<String, dynamic> backupData = jsonDecode(stringData);

      final supabase = Supabase.instance.client;

      if (backupData['wallets'] != null) {
        await supabase
            .from('wallets')
            .upsert(List<Map<String, dynamic>>.from(backupData['wallets']));
      }
      if (backupData['budgets'] != null) {
        await supabase
            .from('budgets')
            .upsert(List<Map<String, dynamic>>.from(backupData['budgets']));
      }
      if (backupData['transactions'] != null) {
        await supabase.from('transactions').upsert(
            List<Map<String, dynamic>>.from(backupData['transactions']));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_google_drive_backup_email', account.email);

      if (context.mounted) {
        CustomNotification.show(
            context, 'Pemulihan data dari Google Drive berhasil selesai!');
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        NetworkHelper.handleSupabaseError(context, e,
            prefix: 'Gagal memulihkan data dari Drive');
      }
      return false;
    }
  }
}
