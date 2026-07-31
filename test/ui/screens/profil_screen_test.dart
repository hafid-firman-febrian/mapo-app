import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/auth_service.dart';
import 'package:mapo_app/models/user_prefs.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import 'package:mapo_app/ui/screens/profil_screen.dart';

class FakeAuthService implements AuthService {
  final Object? linkError;
  final Object? signOutError;
  var linkCalls = 0;
  var signOutCalls = 0;

  FakeAuthService({this.linkError, this.signOutError});

  @override
  Future<void> linkOrSignInWithGoogle() async {
    linkCalls++;
    if (linkError != null) throw linkError!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) throw signOutError!;
  }
}

void main() {
  group('ProfilBody', () {
    testWidgets('anonim menampilkan banner simpan histori', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: true,
              prefs: const UserPrefs(budgetRange: '15.000-25.000', restrictions: []),
              onGoogleSignInTap: () {},
              onSignOutTap: () {},
              onEditPrefs: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ammar'), findsOneWidget);
      expect(find.textContaining('Anonim'), findsOneWidget);
      expect(find.text('Simpan histori kamu'), findsOneWidget);
      expect(find.text('tidak ada'), findsOneWidget);
      expect(find.text('15.000-25.000'), findsOneWidget);
    });

    testWidgets('bukan anonim menyembunyikan banner dan menampilkan tombol Keluar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: false,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () {},
              onSignOutTap: () {},
              onEditPrefs: () {},
            ),
          ),
        ),
      );

      expect(find.text('Simpan histori kamu'), findsNothing);
      expect(find.text('Masuk'), findsNothing);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('anonim tidak menampilkan tombol Keluar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: true,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () {},
              onSignOutTap: () {},
              onEditPrefs: () {},
            ),
          ),
        ),
      );

      expect(find.text('Keluar'), findsNothing);
    });

    testWidgets('pantangan yang terisi ditampilkan gabungan koma', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: true,
              prefs: const UserPrefs(restrictions: ['halal', 'tidak pedas']),
              onGoogleSignInTap: () {},
              onSignOutTap: () {},
              onEditPrefs: () {},
            ),
          ),
        ),
      );

      expect(find.text('halal, tidak pedas'), findsOneWidget);
    });

    testWidgets('tap Masuk memanggil onGoogleSignInTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: true,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () => tapped = true,
              onSignOutTap: () {},
              onEditPrefs: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Masuk'));
      expect(tapped, isTrue);
    });

    testWidgets('busy true menonaktifkan tombol Masuk', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: true,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () {},
              onSignOutTap: () {},
              onEditPrefs: () {},
              busy: true,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Masuk'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('busy true menonaktifkan tombol Keluar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: false,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () {},
              onSignOutTap: () {},
              onEditPrefs: () {},
              busy: true,
            ),
          ),
        ),
      );

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Keluar'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('tap Keluar memanggil onSignOutTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: false,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () {},
              onSignOutTap: () => tapped = true,
              onEditPrefs: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Keluar'));
      expect(tapped, isTrue);
    });

    testWidgets('tap ikon ubah memanggil onEditPrefs', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: true,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () {},
              onSignOutTap: () {},
              onEditPrefs: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Ubah preferensi'));
      expect(tapped, isTrue);
    });
  });

  group('ProfilScreen', () {
    testWidgets('prefs dari provider dirender lewat ProfilBody', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith(
              (ref) async => const UserPrefs(budgetRange: '> 50.000', restrictions: ['halal']),
            ),
            currentUserDisplayProvider.overrideWithValue(
              (displayName: 'Ammar', isAnonymous: true, email: null),
            ),
            authServiceProvider.overrideWithValue(FakeAuthService()),
          ],
          child: const MaterialApp(home: ProfilScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ammar'), findsOneWidget);
      expect(find.text('> 50.000'), findsOneWidget);
      expect(find.text('halal'), findsOneWidget);
    });

    testWidgets('tap Masuk memanggil AuthService.linkOrSignInWithGoogle', (tester) async {
      final fake = FakeAuthService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith((ref) async => const UserPrefs()),
            currentUserDisplayProvider.overrideWithValue(
              (displayName: 'Ammar', isAnonymous: true, email: null),
            ),
            authServiceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(home: ProfilScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(fake.linkCalls, 1);
    });

    testWidgets('error saat Masuk menampilkan SnackBar', (tester) async {
      final fake = FakeAuthService(linkError: Exception('boom'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith((ref) async => const UserPrefs()),
            currentUserDisplayProvider.overrideWithValue(
              (displayName: 'Ammar', isAnonymous: true, email: null),
            ),
            authServiceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(home: ProfilScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal masuk, coba lagi ya'), findsOneWidget);
    });

    testWidgets('cancel saat Masuk tidak menampilkan SnackBar', (tester) async {
      final fake = FakeAuthService(linkError: GoogleSignInCancelledException());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith((ref) async => const UserPrefs()),
            currentUserDisplayProvider.overrideWithValue(
              (displayName: 'Ammar', isAnonymous: true, email: null),
            ),
            authServiceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(home: ProfilScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('tap Keluar memanggil AuthService.signOut', (tester) async {
      final fake = FakeAuthService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith((ref) async => const UserPrefs()),
            currentUserDisplayProvider.overrideWithValue(
              (displayName: 'Ammar', isAnonymous: false, email: null),
            ),
            authServiceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(home: ProfilScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(fake.signOutCalls, 1);
    });

    testWidgets('error saat Keluar menampilkan pesan berbeda dari error Masuk', (tester) async {
      final fake = FakeAuthService(signOutError: Exception('boom'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith((ref) async => const UserPrefs()),
            currentUserDisplayProvider.overrideWithValue(
              (displayName: 'Ammar', isAnonymous: false, email: null),
            ),
            authServiceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(home: ProfilScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal keluar, coba lagi ya'), findsOneWidget);
    });
  });
}
