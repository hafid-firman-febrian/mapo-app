import 'package:cloud_firestore/cloud_firestore.dart';

class MealHistoryEntry {
  final String name;
  final String category;
  final DateTime eatenAt;
  final int? price;

  const MealHistoryEntry({
    required this.name,
    required this.category,
    required this.eatenAt,
    this.price,
  });

  factory MealHistoryEntry.fromDoc(Map<String, dynamic> data) => MealHistoryEntry(
        name: data['name'] as String? ?? '',
        category: data['category'] as String? ?? 'nasi',
        eatenAt: (data['eaten_at'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        price: (data['price'] as num?)?.toInt(),
      );
}

class MealHistoryStats {
  final int countThisWeek;
  final String? mostCommonCategory;

  const MealHistoryStats({required this.countThisWeek, this.mostCommonCategory});

  factory MealHistoryStats.fromEntries(List<MealHistoryEntry> entries) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final thisWeek = entries.where((e) => e.eatenAt.isAfter(weekAgo)).toList();

    if (thisWeek.isEmpty) {
      return const MealHistoryStats(countThisWeek: 0, mostCommonCategory: null);
    }

    final counts = <String, int>{};
    for (final e in thisWeek) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final mostCommon = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return MealHistoryStats(countThisWeek: thisWeek.length, mostCommonCategory: mostCommon);
  }
}
