import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/meal_history_entry.dart';

void main() {
  group('MealHistoryEntry.fromDoc', () {
    test('parsing lengkap dengan harga', () {
      final entry = MealHistoryEntry.fromDoc({
        'name': 'Soto Ayam',
        'category': 'berkuah',
        'eaten_at': Timestamp.fromDate(DateTime(2026, 7, 28, 13, 20)),
        'price': 13000,
      });

      expect(entry.name, 'Soto Ayam');
      expect(entry.category, 'berkuah');
      expect(entry.eatenAt, DateTime(2026, 7, 28, 13, 20));
      expect(entry.price, 13000);
    });

    test('tanpa harga (belum tersimpan sampai Task 6 arsitektur)', () {
      final entry = MealHistoryEntry.fromDoc({
        'name': 'Ayam Bakar',
        'category': 'bakar',
        'eaten_at': Timestamp.fromDate(DateTime(2026, 7, 27, 19, 5)),
      });

      expect(entry.price, isNull);
    });

    test('field hilang tidak throw', () {
      final entry = MealHistoryEntry.fromDoc({
        'eaten_at': Timestamp.fromDate(DateTime(2026, 7, 27, 19, 5)),
      });

      expect(entry.name, '');
      expect(entry.category, 'nasi');
    });
  });

  group('MealHistoryStats.fromEntries', () {
    test('daftar kosong menghasilkan stats kosong', () {
      final stats = MealHistoryStats.fromEntries([]);

      expect(stats.countThisWeek, 0);
      expect(stats.mostCommonCategory, isNull);
    });

    test('menghitung entri minggu ini dan kategori paling sering', () {
      final now = DateTime.now();
      final entries = [
        MealHistoryEntry(name: 'Soto Ayam', category: 'berkuah', eatenAt: now),
        MealHistoryEntry(
          name: 'Bakso',
          category: 'berkuah',
          eatenAt: now.subtract(const Duration(days: 1)),
        ),
        MealHistoryEntry(
          name: 'Ayam Bakar',
          category: 'bakar',
          eatenAt: now.subtract(const Duration(days: 2)),
        ),
        MealHistoryEntry(
          name: 'Menu Lama',
          category: 'nasi',
          eatenAt: now.subtract(const Duration(days: 30)),
        ),
      ];

      final stats = MealHistoryStats.fromEntries(entries);

      expect(stats.countThisWeek, 3);
      expect(stats.mostCommonCategory, 'berkuah');
    });
  });
}
