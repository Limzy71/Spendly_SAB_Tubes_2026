import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

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
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
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
        _showTopNotification(context, 'Izin penyimpanan ditolak!', isError: true);
      }
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchDataFromSupabase() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('transactions').select().order('transaction_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> exportTransactionsToCSV(BuildContext context) async {
    bool hasPermission = await _requestPermission(context);
    if (!hasPermission) return;

    if (context.mounted) {
      _showTopNotification(context, 'Menyiapkan file CSV...', isInfo: true);
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

      final Directory downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) await downloadDir.create(recursive: true);

      final String path = "${downloadDir.path}/Spendly_Report_${DateTime.now().millisecondsSinceEpoch}.csv";
      final File file = File(path);
      await file.writeAsString(csvData);

      if (context.mounted) {
        _showTopNotification(context, 'CSV tersimpan di folder Download! (${rawData.length} data)');
      }

      await Share.shareXFiles([XFile(path)], text: 'Laporan Keuangan Spendly (CSV)');

    } catch (e) {
      if (context.mounted) {
        _showTopNotification(context, 'Gagal CSV: $e', isError: true);
      }
    }
  }

  static Future<void> exportTransactionsToPDF(BuildContext context) async {
    bool hasPermission = await _requestPermission(context);
    if (!hasPermission) return;

    if (context.mounted) {
      _showTopNotification(context, 'Menyiapkan file PDF...', isInfo: true);
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

      final Directory downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) await downloadDir.create(recursive: true);

      final String path = "${downloadDir.path}/Spendly_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final File file = File(path);
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        _showTopNotification(context, 'PDF tersimpan di folder Download! (${rawData.length} data)');
      }

      await Share.shareXFiles([XFile(path)], text: 'Laporan Keuangan Spendly (PDF)');

    } catch (e) {
      if (context.mounted) {
        _showTopNotification(context, 'Gagal PDF: $e', isError: true);
      }
    }
  }
}