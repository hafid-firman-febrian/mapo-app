import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_prefs.dart';
import '../models/meal_history_entry.dart';

class MealHistoryService {
  final FirebaseFirestore _db;
  MealHistoryService(this._db);

  Future<List<String>> getRecentMeals(String userId, {int limit = 3}) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('meal_history')
        .orderBy('eaten_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d['name'] as String).toList();
  }

  /// Read-only, dipakai layar Riwayat. Berbeda dari getRecentMeals (yang
  /// dipakai MapoRecommender dan cuma butuh nama) — ini butuh kategori,
  /// waktu, dan harga per entri.
  Future<List<MealHistoryEntry>> getMealHistory(String userId, {int limit = 20}) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('meal_history')
        .orderBy('eaten_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => MealHistoryEntry.fromDoc(d.data())).toList();
  }

  Future<UserPrefs> getPreferences(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return UserPrefs.fromDoc(doc.data() ?? {});
  }

  Future<void> savePreferences(String userId, UserPrefs prefs) async {
    await _db
        .collection('users')
        .doc(userId)
        .set(prefs.toDoc(), SetOptions(merge: true));
  }

  Future<void> saveMeal(String userId, String name, String category) async {
    await _db.collection('users').doc(userId).collection('meal_history').add({
      'name': name,
      'category': category,
      'eaten_at': Timestamp.now(),
    });
  }

  /// Firestore tidak punya "hapus koleksi", dan satu [WriteBatch] maksimal 500
  /// operasi — jadi harus berulang sampai koleksinya habis. Bukan kehati-hatian
  /// teoretis: user yang memakai Mapo setahun akan melewati 500 entri.
  ///
  /// Sengaja tidak menyentuh dokumen `users/{userId}` supaya preferensi
  /// (budget & pantangan) bertahan.
  Future<void> deleteMealHistory(String userId) async {
    final col = _db
        .collection('users')
        .doc(userId)
        .collection('meal_history');

    while (true) {
      final snap = await col.limit(500).get();
      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> deleteUserDoc(String userId) =>
      _db.collection('users').doc(userId).delete();
}
