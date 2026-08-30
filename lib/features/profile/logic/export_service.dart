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
  static String getPeriodLabel({
    required int filterMode,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    final now = DateTime.now();
    switch (filterMode) {
      case 0:
        return 'Bulan Ini (${DateFormat('MMMM yyyy', 'id').format(now)})';
      case 1:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return 'Bulan Lalu (${DateFormat('MMMM yyyy', 'id').format(lastMonth)})';
      case 2:
        final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
        return '3 Bulan Terakhir (${DateFormat('MMM', 'id').format(threeMonthsAgo)} - ${DateFormat('MMM yyyy', 'id').format(now)})';
      case 3:
        return 'Tahun Ini (${now.year})';
      case 4:
        return 'Semua Waktu';
      case 5:
        if (customStartDate != null && customEndDate != null) {
          return '${DateFormat('dd MMM yyyy', 'id').format(customStartDate)} - ${DateFormat('dd MMM yyyy', 'id').format(customEndDate)}';
        }
        return 'Rentang Kustom';
      default:
        return 'Semua Waktu';
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchDataFromSupabase({
    required int filterMode,
    DateTime? customStartDate,
    DateTime? customEndDate,
    int typeFilter = 0, // 0: Semua, 1: Pengeluaran, 2: Pemasukan
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = supabase.from('transactions').select().eq('user_id', userId);

    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (filterMode) {
      case 0: // Bulan Ini
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 1: // Bulan Lalu
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 2: // 3 Bulan Terakhir
        start = DateTime(now.year, now.month - 2, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 3: // Tahun Ini
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 4: // Semua Waktu
        break;
      case 5: // Kustom
        if (customStartDate != null && customEndDate != null) {
          start = customStartDate;
          end = DateTime(customEndDate.year, customEndDate.month,
              customEndDate.day, 23, 59, 59);
        }
        break;
    }

    if (start != null) {
      query =
          query.gte('transaction_date', start.toIso8601String().split('T')[0]);
    }
    if (end != null) {
      query =
          query.lte('transaction_date', end.toIso8601String().split('T')[0]);
    }

    if (typeFilter == 1) {
      query = query.eq('is_expense', true);
    } else if (typeFilter == 2) {
      query = query.eq('is_expense', false);
    }

    final response = await query.order('transaction_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static String _formatCurrency(int amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  static Future<void> exportTransactionsToCSV(
    BuildContext context, {
    required int filterMode,
    DateTime? customStartDate,
    DateTime? customEndDate,
    int typeFilter = 0,
  }) async {
    if (context.mounted) {
      CustomNotification.show(context, 'Mempersiapkan berkas CSV...',
          isWarning: true);
    }

    try {
      final rawData = await _fetchDataFromSupabase(
        filterMode: filterMode,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
        typeFilter: typeFilter,
      );

      if (rawData.isEmpty) {
        if (context.mounted) {
          CustomNotification.show(
              context, 'Tidak ada transaksi pada periode ini',
              isError: true);
        }
        return;
      }

      int totalIncome = 0;
      int totalExpense = 0;

      List<List<dynamic>> rows = [
        ["No", "Tanggal", "Kategori", "Tipe", "Nominal (Rp)", "Catatan"],
      ];

      for (int i = 0; i < rawData.length; i++) {
        final item = rawData[i];
        bool isExpense = item['is_expense'] == true;
        int amount = item['amount'] as int? ?? 0;

        if (isExpense) {
          totalExpense += amount;
        } else {
          totalIncome += amount;
        }

        rows.add([
          i + 1,
          _formatDate(item['transaction_date']?.toString()),
          item['category']?.toString() ?? '-',
          isExpense ? 'Pengeluaran' : 'Pemasukan',
          amount,
          item['note']?.toString() ?? '-',
        ]);
      }

      rows.add([]);
      rows.add(["RINGKASAN"]);
      rows.add(["Total Pemasukan", "", "", "", totalIncome, ""]);
      rows.add(["Total Pengeluaran", "", "", "", totalExpense, ""]);
      rows.add([
        "Selisih / Arus Kas Bersih",
        "",
        "",
        "",
        totalIncome - totalExpense,
        ""
      ]);

      String csvData = const ListToCsvConverter().convert(rows);
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          "Spendly_Transaksi_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv";
      final String tempPath = "${tempDir.path}/$fileName";
      final File tempFile = File(tempPath);
      await tempFile.writeAsString(csvData);

      final params = SaveFileDialogParams(
          sourceFilePath: tempFile.path, fileName: fileName);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (context.mounted) {
        if (finalPath != null) {
          CustomNotification.show(context, 'Berkas CSV berhasil disimpan!');
        } else {
          CustomNotification.show(context, 'Penyimpanan CSV dibatalkan',
              isWarning: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        NetworkHelper.handleSupabaseError(context, e,
            prefix: 'Gagal mengekspor CSV');
      }
    }
  }

  static Future<void> exportTransactionsToPDF(
    BuildContext context, {
    required int filterMode,
    DateTime? customStartDate,
    DateTime? customEndDate,
    int typeFilter = 0,
  }) async {
    if (context.mounted) {
      CustomNotification.show(context, 'Menyusun laporan PDF profesional...',
          isWarning: true);
    }

    try {
      final rawData = await _fetchDataFromSupabase(
        filterMode: filterMode,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
        typeFilter: typeFilter,
      );

      if (rawData.isEmpty) {
        if (context.mounted) {
          CustomNotification.show(
              context, 'Tidak ada transaksi pada periode ini',
              isError: true);
        }
        return;
      }

      int totalIncome = 0;
      int totalExpense = 0;

      final List<List<String>> tableData = [
        ['No', 'Tanggal', 'Kategori', 'Tipe', 'Nominal', 'Catatan'],
      ];

      for (int i = 0; i < rawData.length; i++) {
        final item = rawData[i];
        bool isExpense = item['is_expense'] == true;
        int amount = item['amount'] as int? ?? 0;

        if (isExpense) {
          totalExpense += amount;
        } else {
          totalIncome += amount;
        }

        tableData.add([
          '${i + 1}',
          _formatDate(item['transaction_date']?.toString()),
          item['category']?.toString() ?? '-',
          isExpense ? 'Pengeluaran' : 'Pemasukan',
          _formatCurrency(amount),
          item['note']?.toString() ?? '-',
        ]);
      }

      final String periodLabel = getPeriodLabel(
        filterMode: filterMode,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
      );

      final pdf = pw.Document();
      const primaryGreen = PdfColor.fromInt(0xFF00A86B);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SPENDLY',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryGreen,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Laporan Transaksi Keuangan',
                        style: pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Periode: $periodLabel',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800),
                      ),
                      pw.Text(
                        'Dicetak: ${DateFormat('dd MMMM yyyy, HH:mm', 'id').format(DateTime.now())} WIB',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: primaryGreen, thickness: 1.5),
              pw.SizedBox(height: 12),

              // Summary Box Cards
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Pemasukan',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _formatCurrency(totalIncome),
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryGreen),
                        ),
                      ],
                    ),
                    pw.Container(
                        width: 1, height: 28, color: PdfColors.grey400),
                    pw.Column(
                      children: [
                        pw.Text('Total Pengeluaran',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _formatCurrency(totalExpense),
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.redAccent),
                        ),
                      ],
                    ),
                    pw.Container(
                        width: 1, height: 28, color: PdfColors.grey400),
                    pw.Column(
                      children: [
                        pw.Text('Arus Kas Bersih',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _formatCurrency(totalIncome - totalExpense),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: (totalIncome - totalExpense) >= 0
                                ? primaryGreen
                                : PdfColors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Data Table
              pw.Text(
                'Rincian Transaksi (${rawData.length} Catatan)',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                context: ctx,
                data: tableData,
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: primaryGreen),
                headerHeight: 24,
                cellHeight: 22,
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerLeft,
                },
                oddRowDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey100),
                rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey300, width: 0.5))),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Spendly - Aplikasi Pengelola Keuangan Pribadi',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ];
          },
        ),
      );

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          "Spendly_Laporan_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf";
      final String tempPath = "${tempDir.path}/$fileName";
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(await pdf.save());

      final params = SaveFileDialogParams(
          sourceFilePath: tempFile.path, fileName: fileName);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (context.mounted) {
        if (finalPath != null) {
          CustomNotification.show(context, 'Berkas PDF berhasil disimpan!');
        } else {
          CustomNotification.show(context, 'Penyimpanan PDF dibatalkan',
              isWarning: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        NetworkHelper.handleSupabaseError(context, e,
            prefix: 'Gagal menyusun PDF');
      }
    }
  }
}
