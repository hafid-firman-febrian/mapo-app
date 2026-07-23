import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_prefs.dart';

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

  Future<UserPrefs> getPreferences(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return UserPrefs.fromDoc(doc.data() ?? {});
  }

  Future<void> saveMeal(String userId, String name, String category) async {
    await _db.collection('users').doc(userId).collection('meal_history').add({
      'name': name,
      'category': category,
      'eaten_at': Timestamp.now(),
    });
  }
}
