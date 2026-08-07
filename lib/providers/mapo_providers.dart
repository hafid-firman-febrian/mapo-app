import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/weather_service.dart';
import '../data/meal_history_service.dart';
import '../data/location_service.dart';
import '../data/auth_service.dart';
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

/// Dibaca halaman Pengaturan. Disegarkan lewat `ref.invalidate` saat app
/// kembali dari setelan sistem — tanpa itu, barisnya tetap menulis "Ditolak"
/// sesudah user baru saja mengizinkan, dan user mengira gagal.
final locationPermissionProvider = FutureProvider<LocationPermissionStatus>(
  (ref) => ref.watch(locationServiceProvider).permissionStatus(),
);

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

final mapoChatProvider = Provider<MapoChat>((ref) {
  // Watch supaya ChatSession baru dibuat (riwayat sisi-model direset) saat
  // UID berubah — login Google atau sign out.
  ref.watch(currentUserIdProvider);
  return FirebaseMapoChat(ref.watch(generativeModelProvider).startChat());
});

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

/// `userChanges()`, bukan `authStateChanges()` — yang terakhir cuma emit
/// saat sign-in/sign-out beneran, tidak emit saat akun anonim di-link ke
/// Google (UID sama, cuma provider-nya nambah). Tanpa ini,
/// currentUserDisplayProvider tidak ter-update setelah link sukses.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).userChanges(),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(firebaseAuthProvider)),
);

/// Dibaca sinkron dari `currentUser` (main() sudah `await signInAnonymously()`
/// sebelum runApp), tapi ikut invalidasi kalau auth state berubah.
/// Test meng-override provider ini langsung dengan sebuah String.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(firebaseAuthProvider).currentUser?.uid;
});

final mealHistoryEntriesProvider = FutureProvider<List<MealHistoryEntry>>((
  ref,
) async {
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
final currentUserDisplayProvider =
    Provider<({String displayName, bool isAnonymous, String? email})>((ref) {
      ref.watch(authStateProvider);
      final user = ref.watch(firebaseAuthProvider).currentUser;
      final displayName =
          user?.displayName ??
          user?.providerData
              .where((p) => p.providerId == 'google.com')
              .map((p) => p.displayName)
              .firstWhere(
                (n) => n != null && n.isNotEmpty,
                orElse: () => null,
              ) ??
          user?.email ??
          'Kamu';
      return (
        displayName: displayName,
        isAnonymous: user?.isAnonymous ?? true,
        email: user?.email,
      );
    });

final chatProvider = NotifierProvider<ChatNotifier, List<ChatTurn>>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<List<ChatTurn>> {
  Object? _session;

  @override
  List<ChatTurn> build() {
    // Watch supaya daftar turn direset saat UID berubah — login Google atau
    // sign out sebelumnya meninggalkan riwayat percakapan akun lama.
    ref.watch(currentUserIdProvider);
    // Token baru tiap kali UID berubah: request ask() yang sudah in-flight
    // dari sesi lama jadi basi dan tidak boleh lagi menulis ke state di
    // bawah ini. Reset _inFlight juga di sini (bukan cuma di finally ask())
    // supaya sesi baru tidak ikut terblokir menunggu request basi selesai.
    _session = Object();
    _inFlight = false;
    return const [];
  }

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
    final session = _session;
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
      if (session != _session) return; // sesi sudah ganti — buang respons basi
      state = [...history, MapoTurn(response)];
    } on MapoException catch (e) {
      if (session != _session) return;
      state = [...history, ErrorTurn(e.message)];
    } catch (_) {
      if (session != _session) return;
      state = [...history, const ErrorTurn('Mapo lagi bingung, coba lagi ya')];
    } finally {
      if (session == _session) _inFlight = false;
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

  Future<void> savePrefs(UserPrefs prefs) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await ref.read(mealHistoryProvider).savePreferences(userId, prefs);
    ref.invalidate(prefsProvider);
  }
}

final accountActionsProvider = Provider<AccountActions>(
  (ref) => AccountActions(ref),
);

/// Aksi akun sengaja dipisah dari [ChatNotifier]: menaruh `deleteAccount` di
/// notifier percakapan jelas salah tempat, meski `savePrefs` sudah terlanjur
/// ada di sana.
///
/// Bentuknya `Provider`, bukan `Notifier`, karena tidak ada state yang perlu
/// diekspos — status `busy` ditahan di local state layar, mengikuti pola
/// `_ProfilScreenState._busy`.
class AccountActions {
  final Ref _ref;

  AccountActions(this._ref);

  /// Menghapus riwayat tanpa menyentuh dokumen user — preferensi bertahan.
  ///
  /// [ChatSession] ikut direset karena blok konteks berisi riwayat makan
  /// dikirim di turn pertama dan tersimpan di sisi model. Tanpa reset, Mapo
  /// tetap berkata "kemarin kamu makan soto" sesudah riwayatnya dihapus.
  Future<void> deleteMealHistory() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    await _ref.read(mealHistoryProvider).deleteMealHistory(userId);

    _ref.invalidate(mealHistoryEntriesProvider);
    // Keduanya eksplisit: ChatNotifier.build() cuma watch currentUserIdProvider
    // dan mengambil recommenderProvider lewat ref.read, jadi menginvalidasi
    // mapoChatProvider saja tidak mengosongkan turn yang tampil di layar.
    _ref.invalidate(mapoChatProvider);
    _ref.invalidate(chatProvider);
  }

  /// Urutannya tidak boleh dibalik. `firestore.rules` cuma mengizinkan tulisan
  /// selagi `request.auth.uid == userId` — menghapus akun lebih dulu membuat
  /// `meal_history` yatim selamanya, dan tanpa Cloud Functions tidak ada cara
  /// membersihkannya.
  ///
  /// Tidak perlu invalidasi manual seperti [deleteMealHistory]: UID berubah,
  /// jadi `chatProvider`, `mapoChatProvider`, `mealHistoryEntriesProvider`, dan
  /// `prefsProvider` semuanya tersegarkan sendiri.
  Future<void> deleteAccount({required bool isAnonymous}) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    final auth = _ref.read(authServiceProvider);
    if (!isAnonymous) await auth.reauthenticateWithGoogle();

    final history = _ref.read(mealHistoryProvider);
    await history.deleteMealHistory(userId);
    await history.deleteUserDoc(userId);

    await auth.deleteAccount();
  }
}

/// Versi app untuk halaman Pengaturan. Dibaca dari platform, bukan ditulis
/// tangan — string versi yang di-hardcode akan basi diam-diam.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});
