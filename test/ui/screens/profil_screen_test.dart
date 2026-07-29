import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/user_prefs.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import 'package:mapo_app/ui/screens/profil_screen.dart';

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

    testWidgets('bukan anonim menyembunyikan banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: false,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Simpan histori kamu'), findsNothing);
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
            ),
          ),
        ),
      );

      await tester.tap(find.text('Masuk'));
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
              (displayName: 'Ammar', isAnonymous: true),
            ),
          ],
          child: const MaterialApp(home: ProfilScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ammar'), findsOneWidget);
      expect(find.text('> 50.000'), findsOneWidget);
      expect(find.text('halal'), findsOneWidget);
    });
  });
}
