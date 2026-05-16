import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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

  // =====================================================================
  // 1. FUNGSI AMBIL SEMUA TABEL DARI SUPABASE
  // =====================================================================
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

  // =====================================================================
  // 2. FUNGSI CADANGKAN (BACKUP ALL TABLES TO DRIVE)
  // =====================================================================
  static Future<void> backupToDrive(BuildContext context) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Membaca seluruh data database...'))
        );
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
      await driveApi.files.create(driveFile, uploadMedia: media);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Semua tabel berhasil dicadangkan ke Google Drive!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Gagal mencadangkan: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // =====================================================================
  // 3. FUNGSI PULIHKAN (RESTORE DATA FROM DRIVE TO SUPABASE)
  // =====================================================================
  static Future<void> restoreFromDrive(BuildContext context) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mencari daftar cadangan di Google Drive...'))
        );
      }

      final authHeaders = await account.authHeaders;
      final driveApi = drive.DriveApi(GoogleAuthClient(authHeaders));

      // Ambil hingga 10 file cadangan terbaru
      final fileList = await driveApi.files.list(
        q: "name contains 'Spendly_Full_Backup' and trashed = false",
        orderBy: "createdTime desc",
        pageSize: 10,
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('⚠️ Tidak ditemukan file cadangan di Drive Anda.'), backgroundColor: Colors.orange)
          );
        }
        return;
      }

      // --- TAMPILKAN POP-UP PILIHAN FILE KE PENGGUNA ---
      if (!context.mounted) return;

      final drive.File? selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Pilih File Pemulihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SizedBox(
              width: double.maxFinite,
              height: 300, // Dibatasi agar bisa di-scroll
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: fileList.files!.length,
                itemBuilder: (context, index) {
                  final file = fileList.files![index];

                  // Format tanggal pembuatan agar enak dibaca
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
                      onTap: () {
                        // Kirim file yang dipilih kembali ke fungsi utama
                        Navigator.pop(dialogContext, file);
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, null), // Batal
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      );

      // Jika pengguna menekan "Batal" atau tap di luar pop-up
      if (selectedFile == null) {
        return;
      }

      // --- LANJUTKAN PROSES DOWNLOAD FILE YANG DIPILIH ---
      final String fileId = selectedFile.id!;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mengunduh dan menyinkronkan data...'))
        );
      }

      // Perbaikan 'media' menjadi 'fullMedia' ada di baris ini:
      final drive.Media response = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      List<int> dataBytes = [];
      await response.stream.listen((data) {
        dataBytes.addAll(data);
      }).asFuture();

      String stringData = utf8.decode(dataBytes);
      Map<String, dynamic> backupData = jsonDecode(stringData);

      final supabase = Supabase.instance.client;

      // Masukkan kembali data ke masing-masing tabel menggunakan .upsert()
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Pemulihan & Sinkronisasi data berhasil selesai!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Gagal sinkronisasi balik: $e'), backgroundColor: Colors.red));
      }
    }
  }
}