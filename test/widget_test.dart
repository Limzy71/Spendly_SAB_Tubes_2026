import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:spendly/theme/app_theme.dart';
import 'package:spendly/widgets/sub_app_bar.dart';
import 'package:spendly/widgets/transaction_item.dart';

void main() {
  group('SubAppBar', () {
    testWidgets('menampilkan judul pada tema terang', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(appBar: SubAppBar(title: 'Dompet')),
        ),
      );

      expect(find.text('Dompet'), findsOneWidget);
    });

    testWidgets('menampilkan judul dan action pada tema gelap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const Scaffold(
            appBar: SubAppBar(
              title: 'Laporan',
              actions: [Icon(Icons.settings)],
            ),
          ),
        ),
      );

      expect(find.text('Laporan'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    test('memiliki tinggi sesuai standar AppBar', () {
      expect(
        const SubAppBar(title: 'Test').preferredSize.height,
        kToolbarHeight,
      );
    });
  });

  group('TransactionItem', () {
    Future<void> pumpItem(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('merender judul, keterangan, ikon, dan nominal', (tester) async {
      await pumpItem(
        tester,
        const TransactionItem(
          title: 'Makan Siang',
          subtitle: '24 Agu 2026',
          amount: '-Rp25.000',
          bgIconColor: Colors.orange,
          icon: FontAwesomeIcons.utensils,
          amountColor: Colors.red,
        ),
      );

      expect(find.text('Makan Siang'), findsOneWidget);
      expect(find.text('24 Agu 2026'), findsOneWidget);
      expect(find.text('-Rp25.000'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is FaIcon && w.icon == FontAwesomeIcons.utensils.data,
        ),
        findsOneWidget,
      );
    });

    testWidgets('merender dengan data nominal positif', (tester) async {
      await pumpItem(
        tester,
        const TransactionItem(
          title: 'Gaji',
          subtitle: '1 Agu 2026',
          amount: '+Rp5.000.000',
          bgIconColor: Colors.green,
          icon: FontAwesomeIcons.briefcase,
          amountColor: Colors.green,
        ),
      );

      expect(find.text('Gaji'), findsOneWidget);
      expect(find.text('+Rp5.000.000'), findsOneWidget);
    });
  });

  group('AppTheme', () {
    test('tema terang dan gelap dapat dibangun tanpa error', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
      expect(AppTheme.darkTheme.useMaterial3, isTrue);
    });
  });
}
