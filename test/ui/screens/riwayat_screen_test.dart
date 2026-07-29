import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/meal_history_entry.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import 'package:mapo_app/ui/screens/riwayat_screen.dart';

void main() {
  group('RiwayatBody', () {
    testWidgets('daftar kosong menampilkan pesan ramah', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RiwayatBody(entries: []))),
      );

      expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
    });

    testWidgets('mengelompokkan entri per hari dan menampilkan statistik', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiwayatBody(
              entries: [
                MealHistoryEntry(name: 'Soto Ayam', category: 'berkuah', eatenAt: now, price: 13000),
                MealHistoryEntry(
                  name: 'Ayam Bakar',
                  category: 'bakar',
                  eatenAt: now.subtract(const Duration(days: 1)),
                  price: 20000,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('HARI INI'), findsOneWidget);
      expect(find.text('KEMARIN'), findsOneWidget);
      expect(find.text('Soto Ayam'), findsOneWidget);
      expect(find.text('Ayam Bakar'), findsOneWidget);
      expect(find.textContaining('berkuah'), findsWidgets);
    });
  });

  group('RiwayatScreen', () {
    testWidgets('data dari provider dirender lewat RiwayatBody', (tester) async {
      final entry = MealHistoryEntry(
        name: 'Bakso',
        category: 'berkuah',
        eatenAt: DateTime.now(),
        price: 15000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [mealHistoryEntriesProvider.overrideWith((ref) async => [entry])],
          child: const MaterialApp(home: RiwayatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bakso'), findsOneWidget);
      expect(find.text('Riwayat makan'), findsOneWidget);
    });

    testWidgets('error dari provider menampilkan pesan ramah', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealHistoryEntriesProvider.overrideWith((ref) async => throw Exception('boom')),
          ],
          child: const MaterialApp(home: RiwayatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Mapo lagi bingung'), findsOneWidget);
    });
  });
}
