import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart'; // <-- IMPORT SHARE_PLUS DITAMBAHKAN KEMBALI

class ExportService {

  // Fungsi Cerdas untuk Meminta Izin Penyimpanan
  static Future<bool> _requestPermission(BuildContext context) async {
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }

    if (await Permission.manageExternalStorage.isGranted || await Permission.storage.isGranted) {
      return true;
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin penyimpanan ditolak!'), backgroundColor: Colors.red)
        );
      }
      return false;
    }
  }

  // =====================================================================
  // FUNGSI MENGAMBIL DATA DARI SUPABASE (SESUAI DATABASE-MU)
  // =====================================================================
  static Future<List<Map<String, dynamic>>> _fetchDataFromSupabase() async {
    final supabase = Supabase.instance.client;

    // Mengambil dari tabel 'transactions', diurutkan berdasarkan 'transaction_date' terbaru
    final response = await supabase
        .from('transactions')
        .select()
        .order('transaction_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // --- EKSPOR KE CSV ---
  static Future<void> exportTransactionsToCSV(BuildContext context) async {
    bool hasPermission = await _requestPermission(context);
    if (!hasPermission) return;

    try {
      // 1. Ambil data asli dari Supabase
      final rawData = await _fetchDataFromSupabase();

      // 2. Siapkan baris pertama (Header / Judul Kolom)
      List<List<dynamic>> rows = [
        ["Tanggal", "Kategori", "Tipe", "Nominal", "Catatan"],
      ];

      // 3. Masukkan data dari Supabase ke dalam baris-baris CSV
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

      final Directory downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) await downloadDir.create(recursive: true);

      final String path = "${downloadDir.path}/Spendly_Report_${DateTime.now().millisecondsSinceEpoch}.csv";

      final File file = File(path);
      await file.writeAsString(csvData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ CSV tersimpan di folder Download! (${rawData.length} data)'), backgroundColor: Colors.green, duration: const Duration(seconds: 3))
        );
      }

      // 4. MEMUNCULKAN MENU SHARE
      await Share.shareXFiles([XFile(path)], text: 'Laporan Keuangan Spendly (CSV)');

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal CSV: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- EKSPOR KE PDF ---
  static Future<void> exportTransactionsToPDF(BuildContext context) async {
    bool hasPermission = await _requestPermission(context);
    if (!hasPermission) return;

    try {
      // 1. Ambil data asli dari Supabase
      final rawData = await _fetchDataFromSupabase();

      final pdf = pw.Document();

      // 2. Siapkan baris pertama (Header / Judul Kolom)
      final List<List<String>> tableData = [
        ['Tanggal', 'Kategori', 'Tipe', 'Nominal', 'Catatan'],
      ];

      // 3. Masukkan data dari Supabase ke dalam tabel PDF
      for (var item in rawData) {
        String tipeTransaksi = (item['is_expense'] == true) ? 'Pengeluaran' : 'Pemasukan';

        tableData.add([
          item['transaction_date']?.toString() ?? '-',
          item['category']?.toString() ?? '-',
          tipeTransaksi,
          'Rp ${item['amount']?.toString() ?? '0'}',
          item['note']?.toString() ?? '-',
        ]);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return [
              pw.Text('Laporan Transaksi Spendly', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Dicetak pada: ${DateTime.now().toString().split(' ')[0]}'),
              pw.Text('Total Transaksi: ${rawData.length}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: ctx,
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 0.5)),
                ),
              ),
            ];
          },
        ),
      );

      final Directory downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) await downloadDir.create(recursive: true);

      final String path = "${downloadDir.path}/Spendly_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";

      final File file = File(path);
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ PDF tersimpan di folder Download! (${rawData.length} data)'), backgroundColor: Colors.green, duration: const Duration(seconds: 3))
        );
      }

      // 4. MEMUNCULKAN MENU SHARE
      await Share.shareXFiles([XFile(path)], text: 'Laporan Keuangan Spendly (PDF)');

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal PDF: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
