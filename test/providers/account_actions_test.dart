import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/auth_service.dart';
import 'package:mapo_app/data/meal_history_service.dart';
import 'package:mapo_app/models/meal_history_entry.dart';
import 'package:mapo_app/models/user_prefs.dart';
import 'package:mapo_app/providers/mapo_providers.dart';

/// Mencatat urutan pemanggilan ke satu daftar bersama dengan
/// [RecordingMealHistory], supaya urutan lintas-service bisa di-assert.
class RecordingAuth implements AuthService {
  final List<String> log;
  final Object? reauthError;
  final Object? deleteAccountError;

  RecordingAuth(this.log, {this.reauthError, this.deleteAccountError});

  @override
  Future<void> reauthenticateWithGoogle() async {
    log.add('reauth');
    if (reauthError != null) throw reauthError!;
  }

  @override
  Future<void> deleteAccount() async {
    log.add('deleteAccount');
    if (deleteAccountError != null) throw deleteAccountError!;
  }

  @override
  Future<void> linkOrSignInWithGoogle() async => log.add('link');

  @override
  Future<void> signOut() async => log.add('signOut');
}

class RecordingMealHistory implements MealHistoryService {
  final List<String> log;
  final Object? deleteHistoryError;

  /// Dihitung terpisah dari [log] karena dipakai untuk membuktikan
  /// `mealHistoryEntriesProvider` benar-benar dibangun ulang setelah
  /// invalidasi, bukan untuk mengunci urutan pemanggilan.
  var getMealHistoryCalls = 0;

  RecordingMealHistory(this.log, {this.deleteHistoryError});

  @override
  Future<void> deleteMealHistory(String userId) async {
    log.add('deleteMealHistory');
    if (deleteHistoryError != null) throw deleteHistoryError!;
  }

  @override
  Future<void> deleteUserDoc(String userId) async => log.add('deleteUserDoc');

  @override
  Future<List<String>> getRecentMeals(String userId, {int limit = 3}) async =>
      const [];

  @override
  Future<List<MealHistoryEntry>> getMealHistory(
    String userId, {
    int limit = 20,
  }) async {
    getMealHistoryCalls++;
    return const [];
  }

  @override
  Future<UserPrefs> getPreferences(String userId) async => const UserPrefs();

  @override
  Future<void> savePreferences(String userId, UserPrefs prefs) async {}

  @override
  Future<void> saveMeal(String userId, String name, String category) async {}
}

void main() {
  ProviderContainer makeContainer({
    required List<String> log,
    Object? reauthError,
    Object? deleteAccountError,
    Object? deleteHistoryError,
    MealHistoryService? history,
    String? userId = 'u1',
  }) {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        authServiceProvider.overrideWithValue(
          RecordingAuth(
            log,
            reauthError: reauthError,
            deleteAccountError: deleteAccountError,
          ),
        ),
        mealHistoryProvider.overrideWithValue(
          history ??
              RecordingMealHistory(log, deleteHistoryError: deleteHistoryError),
        ),
      ],
    );
  }

  test('deleteAccount: reauth dulu, lalu data, baru akun', () async {
    final log = <String>[];
    final container = makeContainer(log: log);
    addTearDown(container.dispose);

    await container
        .read(accountActionsProvider)
        .deleteAccount(isAnonymous: false);

    expect(log, [
      'reauth',
      'deleteMealHistory',
      'deleteUserDoc',
      'deleteAccount',
    ]);
  });

  test('deleteAccount: user anonim melewati reauth', () async {
    final log = <String>[];
    final container = makeContainer(log: log);
    addTearDown(container.dispose);

    await container
        .read(accountActionsProvider)
        .deleteAccount(isAnonymous: true);

    expect(log, ['deleteMealHistory', 'deleteUserDoc', 'deleteAccount']);
  });

  test('deleteAccount: reauth dibatalkan, tidak ada data yang dihapus', () async {
    final log = <String>[];
    final container = makeContainer(
      log: log,
      reauthError: GoogleSignInCancelledException(),
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(accountActionsProvider).deleteAccount(isAnonymous: false),
      throwsA(isA<GoogleSignInCancelledException>()),
    );

    expect(log, ['reauth']);
  });

  test('deleteAccount: penghapusan data yang gagal tidak menghapus akun', () async {
    final log = <String>[];
    final container = makeContainer(
      log: log,
      deleteHistoryError: Exception('koneksi putus'),
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(accountActionsProvider).deleteAccount(isAnonymous: false),
      throwsA(isA<Exception>()),
    );

    // Berhenti tepat setelah percobaan hapus riwayat: `deleteUserDoc` dan
    // `deleteAccount` tidak boleh ikut jalan. Menghapus akun di sini akan
    // membuat sisa `meal_history` yatim selamanya — `firestore.rules` tidak
    // lagi mengizinkan menyentuhnya dan proyek ini tidak punya Cloud Functions.
    expect(log, ['reauth', 'deleteMealHistory']);
  });

  test('deleteAccount: tanpa userId melempar StateError', () async {
    final log = <String>[];
    final container = makeContainer(log: log, userId: null);
    addTearDown(container.dispose);

    // Gagal-diam di sini terlihat persis seperti sukses dari sisi layar: dialog
    // konfirmasi ditutup, layar di-pop, dan user yakin akunnya sudah hilang.
    await expectLater(
      container.read(accountActionsProvider).deleteAccount(isAnonymous: false),
      throwsA(isA<StateError>()),
    );

    expect(log, isEmpty);
  });

  test('deleteMealHistory: tanpa userId melempar StateError', () async {
    final log = <String>[];
    final container = makeContainer(log: log, userId: null);
    addTearDown(container.dispose);

    await expectLater(
      container.read(accountActionsProvider).deleteMealHistory(),
      throwsA(isA<StateError>()),
    );

    expect(log, isEmpty);
  });

  test('deleteMealHistory tidak menghapus dokumen user', () async {
    final log = <String>[];
    final container = makeContainer(log: log);
    addTearDown(container.dispose);

    await container.read(accountActionsProvider).deleteMealHistory();

    expect(log, ['deleteMealHistory']);
  });

  /// Dua test di bawah mengunci Temuan 2: cache Riverpod tidak boleh
  /// ditinggalkan menampilkan data yang sudah tidak ada di Firestore hanya
  /// karena penghapusannya gagal di tengah jalan.
  test('deleteAccount yang gagal tetap menyegarkan riwayat di cache', () async {
    final log = <String>[];
    final history = RecordingMealHistory(log);
    final container = makeContainer(
      log: log,
      history: history,
      deleteAccountError: Exception('koneksi putus'),
    );
    addTearDown(container.dispose);

    // Listener aktif meniru drawer/layar Riwayat yang sudah menonton sejak
    // sebelum penghapusan — persis keadaan yang membuat Riverpod tidak pernah
    // menganggap cache-nya basi dengan sendirinya.
    container.listen(mealHistoryEntriesProvider, (_, _) {});
    await container.read(mealHistoryEntriesProvider.future);
    expect(history.getMealHistoryCalls, 1);

    await expectLater(
      container.read(accountActionsProvider).deleteAccount(isAnonymous: true),
      throwsA(isA<Exception>()),
    );
    await container.read(mealHistoryEntriesProvider.future);

    expect(history.getMealHistoryCalls, 2);
  });

  test('deleteMealHistory yang gagal tetap menyegarkan riwayat di cache', () async {
    final log = <String>[];
    final history = RecordingMealHistory(
      log,
      deleteHistoryError: Exception('koneksi putus'),
    );
    final container = makeContainer(log: log, history: history);
    addTearDown(container.dispose);

    container.listen(mealHistoryEntriesProvider, (_, _) {});
    await container.read(mealHistoryEntriesProvider.future);
    expect(history.getMealHistoryCalls, 1);

    await expectLater(
      container.read(accountActionsProvider).deleteMealHistory(),
      throwsA(isA<Exception>()),
    );
    await container.read(mealHistoryEntriesProvider.future);

    expect(history.getMealHistoryCalls, 2);
  });
}
