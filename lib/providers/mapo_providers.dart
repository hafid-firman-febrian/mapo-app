import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../data/weather_service.dart';
import '../data/meal_history_service.dart';
import '../data/location_service.dart';
import '../domain/mapo_chat.dart';
import '../domain/mapo_recommender.dart';
import '../domain/mapo_schema.dart';
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
const _systemInstruction =
    'Kamu Mapo, asisten yang membantu orang Indonesia memutuskan mau makan '
    'apa. Bicara santai, ramah, dan singkat. Kalau informasi dari user '
    'kurang, gunakan response_type "clarify" dengan quick_replies yang '
    'membantu. Selalu balas sesuai skema JSON.';

final generativeModelProvider = Provider<GenerativeModel>(
  (ref) => FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash-lite',
    systemInstruction: Content.text(_systemInstruction),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: mapoResponseSchema,
      temperature: 0.7,
    ),
  ),
);

final mapoChatProvider = Provider<MapoChat>(
  (ref) => FirebaseMapoChat(ref.watch(generativeModelProvider).startChat()),
);

final recommenderProvider = Provider(
  (ref) => MapoRecommender(
    ref.watch(weatherServiceProvider),
    ref.watch(mealHistoryProvider),
    ref.watch(mapoChatProvider),
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
