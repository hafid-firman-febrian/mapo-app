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
import '../models/chat_turn.dart';
import '../models/meal_history_entry.dart';
import '../models/user_prefs.dart';

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

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

/// Dibaca sinkron dari `currentUser` (main() sudah `await signInAnonymously()`
/// sebelum runApp), tapi ikut invalidasi kalau auth state berubah.
/// Test meng-override provider ini langsung dengan sebuah String.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(firebaseAuthProvider).currentUser?.uid;
});

final mealHistoryEntriesProvider = FutureProvider<List<MealHistoryEntry>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(mealHistoryProvider).getMealHistory(userId);
});

final prefsProvider = FutureProvider<UserPrefs>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const UserPrefs();
  return ref.watch(mealHistoryProvider).getPreferences(userId);
});

/// Seam yang sama seperti currentUserIdProvider: widget tak pernah menyentuh
/// FirebaseAuth.instance langsung, jadi test bisa override tanpa Firebase asli.
/// `authStateProvider` diwatch supaya provider ini benar-benar ikut invalidasi
/// saat auth berubah — tanpa itu klaim "sama seperti currentUserIdProvider"
/// bohong, dan nama user bakal ketinggalan begitu Google Sign-In asli masuk.
final currentUserDisplayProvider = Provider<({String displayName, bool isAnonymous})>((ref) {
  ref.watch(authStateProvider);
  final user = ref.watch(firebaseAuthProvider).currentUser;
  return (displayName: user?.displayName ?? 'Kamu', isAnonymous: user?.isAnonymous ?? true);
});

final chatProvider = NotifierProvider<ChatNotifier, List<ChatTurn>>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<List<ChatTurn>> {
  @override
  List<ChatTurn> build() => const [];

  bool get _isFirstTurn => state.whereType<MapoTurn>().isEmpty;

  /// True selama satu `ask` masih jalan. Chip quick-reply, kartu Options, dan
  /// contoh di Home tidak mengecek flag "sedang kirim" apa pun, jadi tanpa
  /// penjaga ini dua `ask` bisa saling tindih: masing-masing memotret `state`
  /// sendiri lalu menimpanya, dan satu percakapan penuh hilang.
  bool _inFlight = false;

  /// Koordinat diambil di dalam sini, bukan oleh pemanggil. Mengambilnya di
  /// `ChatScreen._send` berarti ada jeda beberapa detik (dialog izin lokasi +
  /// timeout GPS 15 detik) sebelum ada satu pun turn masuk ke state — layar
  /// diam, field chat tetap aktif, dan window buat request tumpang tindih
  /// terbuka lebar. Sekarang `PendingTurn` muncul sinkron begitu `ask`
  /// dipanggil, dan fetch koordinat jadi detail internal sesudahnya.
  Future<void> ask(String message) async {
    if (_inFlight) return;

    final userId = ref.read(currentUserIdProvider);
    final history = [...state, UserTurn(message)];

    if (userId == null) {
      state = [...history, const ErrorTurn('Belum login, coba buka ulang app')];
      return;
    }

    final withContext = _isFirstTurn;
    state = [...history, const PendingTurn()];
    _inFlight = true;

    try {
      final coords = await ref.read(coordsProvider.future);
      final response = await ref
          .read(recommenderProvider)
          .reply(
            userId: userId,
            userMessage: message,
            withContext: withContext,
            lat: coords?.lat,
            lng: coords?.lng,
          );
      state = [...history, MapoTurn(response)];
    } on MapoException catch (e) {
      state = [...history, ErrorTurn(e.message)];
    } catch (_) {
      state = [...history, const ErrorTurn('Mapo lagi bingung, coba lagi ya')];
    } finally {
      _inFlight = false;
    }
  }

  /// Menutup loop data: tanpa ini `meal_history` selamanya kosong dan
  /// `getRecentMeals` tidak punya apa pun untuk dikembalikan.
  Future<void> pickMeal(Recommendation recommendation) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await ref
        .read(mealHistoryProvider)
        .saveMeal(userId, recommendation.name, recommendation.category);

    // `mealHistoryEntriesProvider` sudah punya listener aktif (drawer, layar
    // Riwayat) sejak sebelum tulisan ini terjadi, jadi Riverpod tidak pernah
    // menganggap cache-nya basi dengan sendirinya — tanpa invalidate ini,
    // keduanya tetap menampilkan data lama sampai seluruh container di-reset
    // (hot restart).
    ref.invalidate(mealHistoryEntriesProvider);
  }
}
