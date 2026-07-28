import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/weather_service.dart';
import '../data/meal_history_service.dart';
import '../data/location_service.dart';
import '../domain/mapo_recommender.dart';
import '../models/mapo_response.dart';

// ── Data layer ────────────────────────────────────────────
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final weatherServiceProvider = Provider(
  (ref) => WeatherService(ref.watch(firestoreProvider)),
);

final mealHistoryProvider = Provider(
  (ref) => MealHistoryService(ref.watch(firestoreProvider)),
);

final locationServiceProvider = Provider((ref) => LocationService());

/// `null` = lokasi tidak tersedia (izin ditolak / GPS mati / timeout).
/// Ini keadaan normal, bukan error — cuaca tinggal jadi unknown.
final coordsProvider = FutureProvider<Coords?>((ref) async {
  try {
    return await ref.watch(locationServiceProvider).current();
  } catch (_) {
    return null;
  }
});

// ── Domain layer ──────────────────────────────────────────
final recommenderProvider = Provider(
  (ref) => MapoRecommender(
    ref.watch(weatherServiceProvider),
    ref.watch(mealHistoryProvider),
  ),
);

// ── Auth ──────────────────────────────────────────────────
final authProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

// ── Chat state ────────────────────────────────────────────
final chatProvider = AsyncNotifierProvider<ChatNotifier, MapoResponse?>(
  ChatNotifier.new,
);

class ChatNotifier extends AsyncNotifier<MapoResponse?> {
  @override
  Future<MapoResponse?> build() async => null;

  Future<void> ask(String message, {double? lat, double? lng}) async {
    // final user = ref.read(authProvider).value;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      state = AsyncValue.error(
        MapoException('Belum login'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref
          .read(recommenderProvider)
          .getRecommendation(
            userId: user.uid,
            userMessage: message,
            lat: lat,
            lng: lng,
          );
    });
  }
}
