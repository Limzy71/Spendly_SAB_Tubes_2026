import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/network_helper.dart';

class ExportService {
  static Future<List<Map<String, dynamic>>> _fetchDataFromSupabase(int filterMode) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = supabase.from('transactions').select().eq('user_id', userId);

    if (filterMode == 1) {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final lastDay = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0];
      query = query.gte('transaction_date', firstDay).lte('transaction_date', lastDay);
    }

    final response = await query.order('transaction_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  static Future<void> exportTransactionsToCSV(BuildContext context, int filterMode) async {
    if (context.mounted) CustomNotification.show(context, 'Membuka menu penyimpanan...', isWarning: true);

    try {
      final rawData = await _fetchDataFromSupabase(filterMode);
      if (rawData.isEmpty) {
        if (context.mounted) CustomNotification.show(context, 'Tidak ada data di periode ini', isError: true);
        return;
      }

      List<List<dynamic>> rows = [
        ["Tanggal", "Kategori", "Tipe", "Nominal", "Catatan"],
      ];

      for (var item in rawData) {
        String tipeTransaksi = (item['is_expense'] == true) ? 'Pengeluaran' : 'Pemasukan';
        int amount = item['amount'] as int? ?? 0;

        rows.add([
          _formatDate(item['transaction_date']),
          item['category'] ?? '-',
          tipeTransaksi,
          _formatCurrency(amount),
          item['note'] ?? '-',
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = "Spendly_Report_${DateTime.now().millisecondsSinceEpoch}.csv";
      final String tempPath = "${tempDir.path}/$fileName";
      final File tempFile = File(tempPath);
      await tempFile.writeAsString(csvData);

      final params = SaveFileDialogParams(sourceFilePath: tempFile.path, fileName: fileName);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (context.mounted) {
        if (finalPath != null) {
          CustomNotification.show(context, 'File CSV berhasil disimpan!');
        } else {
          CustomNotification.show(context, 'Penyimpanan file CSV dibatalkan', isWarning: true);
        }
      }
    } catch (e) {
      if (context.mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal memproses CSV');
    }
  }

  static Future<void> exportTransactionsToPDF(BuildContext context, int filterMode) async {
    if (context.mounted) CustomNotification.show(context, 'Membuka menu penyimpanan...', isWarning: true);

    try {
      final rawData = await _fetchDataFromSupabase(filterMode);
      if (rawData.isEmpty) {
        if (context.mounted) CustomNotification.show(context, 'Tidak ada data di periode ini', isError: true);
        return;
      }

      final pdf = pw.Document();
      final List<List<String>> tableData = [
        ['Tanggal', 'Kategori', 'Tipe', 'Nominal', 'Catatan'],
      ];

      for (var item in rawData) {
        String tipeTransaksi = (item['is_expense'] == true) ? 'Pengeluaran' : 'Pemasukan';
        int amount = item['amount'] as int? ?? 0;

        tableData.add([
          _formatDate(item['transaction_date']?.toString()),
          item['category']?.toString() ?? '-',
          tipeTransaksi,
          _formatCurrency(amount),
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
              pw.Text('Dicetak pada: ${DateFormat('dd MMMM yyyy', 'id').format(DateTime.now())}'),
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

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = "Spendly_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final String tempPath = "${tempDir.path}/$fileName";
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(await pdf.save());

      final params = SaveFileDialogParams(sourceFilePath: tempFile.path, fileName: fileName);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (context.mounted) {
        if (finalPath != null) {
          CustomNotification.show(context, 'File PDF berhasil disimpan!');
        } else {
          CustomNotification.show(context, 'Penyimpanan file PDF dibatalkan', isWarning: true);
        }
      }
    } catch (e) {
      if (context.mounted) NetworkHelper.handleSupabaseError(context, e, prefix: 'Gagal memproses PDF');
    }
  }
}