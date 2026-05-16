import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart'; // <-- Package baru kita

class ExportService {
  static void _showTopNotification(BuildContext context, String message, {bool isError = false, bool isInfo = false}) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    Color bgColor = const Color(0xFF00AA5B);
    IconData icon = Icons.check;

    if (isError) {
      bgColor = const Color(0xFFE63946);
      icon = Icons.close;
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

    final response = await supabase.from('transactions').select().eq('user_id', userId).order('transaction_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> exportTransactionsToCSV(BuildContext context) async {
    if (context.mounted) {
      _showTopNotification(context, 'Membuka menu penyimpanan...', isInfo: true);
    }

    try {
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

      // 1. Simpan sementara di Cache aplikasi
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = "Spendly_Report_${DateTime.now().millisecondsSinceEpoch}.csv";
      final String tempPath = "${tempDir.path}/$fileName";
      final File tempFile = File(tempPath);
      await tempFile.writeAsString(csvData);

      // 2. Munculkan dialog "Save As" bawaan HP
      final params = SaveFileDialogParams(sourceFilePath: tempFile.path, fileName: fileName);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      // 3. Tampilkan notifikasi jika sukses
      if (finalPath != null && context.mounted) {
        _showTopNotification(context, '✅ File CSV berhasil disimpan!');
      }

    } catch (e) {
      if (context.mounted) {
        _showTopNotification(context, 'Gagal CSV: $e', isError: true);
      }
    }
  }

  static Future<void> exportTransactionsToPDF(BuildContext context) async {
    if (context.mounted) {
      _showTopNotification(context, 'Membuka menu penyimpanan...', isInfo: true);
    }

    try {
      final rawData = await _fetchDataFromSupabase();
      final pdf = pw.Document();

      final List<List<String>> tableData = [
        ['Tanggal', 'Kategori', 'Tipe', 'Nominal', 'Catatan'],
      ];

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
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 0.5))),
              ),
            ];
          },
        ),
      );

      // 1. Simpan sementara di Cache aplikasi
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = "Spendly_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final String tempPath = "${tempDir.path}/$fileName";
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(await pdf.save());

      // 2. Munculkan dialog "Save As" bawaan HP
      final params = SaveFileDialogParams(sourceFilePath: tempFile.path, fileName: fileName);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      // 3. Tampilkan notifikasi jika sukses
      if (finalPath != null && context.mounted) {
        _showTopNotification(context, '✅ File PDF berhasil disimpan!');
      }

    } catch (e) {
      if (context.mounted) {
        _showTopNotification(context, 'Gagal PDF: $e', isError: true);
      }
    }
  }
}