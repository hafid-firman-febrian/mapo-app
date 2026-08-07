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

  RecordingAuth(this.log, {this.reauthError});

  @override
  Future<void> reauthenticateWithGoogle() async {
    log.add('reauth');
    if (reauthError != null) throw reauthError!;
  }

  @override
  Future<void> deleteAccount() async => log.add('deleteAccount');

  @override
  Future<void> linkOrSignInWithGoogle() async => log.add('link');

  @override
  Future<void> signOut() async => log.add('signOut');
}

class RecordingMealHistory implements MealHistoryService {
  final List<String> log;

  RecordingMealHistory(this.log);

  @override
  Future<void> deleteMealHistory(String userId) async =>
      log.add('deleteMealHistory');

  @override
  Future<void> deleteUserDoc(String userId) async => log.add('deleteUserDoc');

  @override
  Future<List<String>> getRecentMeals(String userId, {int limit = 3}) async =>
      const [];

  @override
  Future<List<MealHistoryEntry>> getMealHistory(
    String userId, {
    int limit = 20,
  }) async => const [];

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
    String? userId = 'u1',
  }) {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        authServiceProvider.overrideWithValue(
          RecordingAuth(log, reauthError: reauthError),
        ),
        mealHistoryProvider.overrideWithValue(RecordingMealHistory(log)),
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

  test('deleteAccount: tanpa userId tidak melakukan apa-apa', () async {
    final log = <String>[];
    final container = makeContainer(log: log, userId: null);
    addTearDown(container.dispose);

    await container
        .read(accountActionsProvider)
        .deleteAccount(isAnonymous: false);

    expect(log, isEmpty);
  });

  test('deleteMealHistory tidak menghapus dokumen user', () async {
    final log = <String>[];
    final container = makeContainer(log: log);
    addTearDown(container.dispose);

    await container.read(accountActionsProvider).deleteMealHistory();

    expect(log, ['deleteMealHistory']);
  });
}
