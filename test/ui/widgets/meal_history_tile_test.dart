import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/meal_history_entry.dart';
import 'package:mapo_app/ui/widgets/meal_history_tile.dart';

void main() {
  testWidgets('menampilkan nama, kategori, waktu, dan harga', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealHistoryTile(
            entry: MealHistoryEntry(
              name: 'Soto Ayam',
              category: 'berkuah',
              eatenAt: DateTime(2026, 7, 28, 13, 20),
              price: 13000,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Soto Ayam'), findsOneWidget);
    expect(find.textContaining('berkuah'), findsOneWidget);
    expect(find.textContaining('13:20'), findsOneWidget);
    expect(find.text('Rp13.000'), findsOneWidget);
  });

  testWidgets('harga null menampilkan pesan, bukan Rp0 atau crash', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealHistoryTile(
            entry: MealHistoryEntry(
              name: 'Ayam Bakar',
              category: 'bakar',
              eatenAt: DateTime(2026, 7, 27, 19, 5),
            ),
          ),
        ),
      ),
    );

    expect(find.text('harga belum tercatat'), findsOneWidget);
    expect(find.textContaining('Rp'), findsNothing);
  });
}
