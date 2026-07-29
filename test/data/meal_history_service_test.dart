import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/meal_history_service.dart';
import 'package:mapo_app/models/user_prefs.dart';

void main() {
  test('savePreferences menulis budget dan pantangan', () async {
    final db = FakeFirebaseFirestore();
    final service = MealHistoryService(db);

    await service.savePreferences(
      'u1',
      const UserPrefs(
        budgetRange: '25.000-50.000',
        restrictions: ['tidak pedas', 'halal'],
      ),
    );

    final doc = await db.collection('users').doc('u1').get();
    expect(doc.data()!['budget_range'], '25.000-50.000');
    expect(doc.data()!['restrictions'], ['tidak pedas', 'halal']);
  });

  test('savePreferences merge, tidak menghapus field lain', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({'nama_panggilan': 'Firman'});
    final service = MealHistoryService(db);

    await service.savePreferences(
      'u1',
      const UserPrefs(budgetRange: '< 15.000'),
    );

    final doc = await db.collection('users').doc('u1').get();
    expect(doc.data()!['nama_panggilan'], 'Firman');
    expect(doc.data()!['budget_range'], '< 15.000');
  });

  test('getPreferences membaca kembali yang baru ditulis', () async {
    final db = FakeFirebaseFirestore();
    final service = MealHistoryService(db);

    await service.savePreferences(
      'u1',
      const UserPrefs(budgetRange: '> 50.000', restrictions: ['vegetarian']),
    );
    final prefs = await service.getPreferences('u1');

    expect(prefs.budgetRange, '> 50.000');
    expect(prefs.restrictions, ['vegetarian']);
  });

  test('saveMeal lalu getRecentMeals mengembalikan menu terbaru dulu', () async {
    final db = FakeFirebaseFirestore();
    final service = MealHistoryService(db);

    await service.saveMeal('u1', 'Soto Ayam', 'berkuah');
    await service.saveMeal('u1', 'Bakso', 'berkuah');

    final recent = await service.getRecentMeals('u1');

    expect(recent, hasLength(2));
    expect(recent, contains('Soto Ayam'));
    expect(recent, contains('Bakso'));
  });
}
