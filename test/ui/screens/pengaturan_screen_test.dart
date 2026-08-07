import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/auth_service.dart';
import 'package:mapo_app/data/location_service.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import 'package:mapo_app/ui/screens/pengaturan_screen.dart';

/// `implements`, bukan subclass: [AccountActions] butuh sebuah `Ref` yang tidak
/// bisa dibuat di test. Pola yang sama dipakai `FakeAuthService` di
/// `profil_screen_test.dart`.
class FakeAccountActions implements AccountActions {
  final Object? deleteHistoryError;
  final Object? deleteAccountError;

  var deleteHistoryCalls = 0;
  var deleteAccountCalls = 0;
  bool? lastIsAnonymous;

  FakeAccountActions({this.deleteHistoryError, this.deleteAccountError});

  @override
  Future<void> deleteMealHistory() async {
    deleteHistoryCalls++;
    if (deleteHistoryError != null) throw deleteHistoryError!;
  }

  @override
  Future<void> deleteAccount({required bool isAnonymous}) async {
    deleteAccountCalls++;
    lastIsAnonymous = isAnonymous;
    if (deleteAccountError != null) throw deleteAccountError!;
  }
}

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  PengaturanBody body({
    LocationPermissionStatus? permission = LocationPermissionStatus.granted,
    String? appVersion = '1.0.0 (1)',
    VoidCallback? onPrivacyTap,
    VoidCallback? onDeleteAccountTap,
    VoidCallback? onDeleteHistoryTap,
    bool busy = false,
  }) => PengaturanBody(
    permission: permission,
    appVersion: appVersion,
    onLocationTap: () {},
    onDeleteHistoryTap: onDeleteHistoryTap ?? () {},
    onDeleteAccountTap: onDeleteAccountTap ?? () {},
    onPrivacyTap: onPrivacyTap,
    busy: busy,
  );

  /// Seluruh provider yang [PengaturanScreen] sentuh di-override, supaya tidak
  /// ada satu pun panggilan ke Firebase/Geolocator asli. `isAnonymous` ikut
  /// dipalsukan karena `_handleDeleteAccount` meneruskannya ke `deleteAccount`.
  Widget scope(
    FakeAccountActions actions, {
    required Widget child,
    bool isAnonymous = true,
  }) => ProviderScope(
    overrides: [
      accountActionsProvider.overrideWithValue(actions),
      locationPermissionProvider.overrideWith(
        (ref) async => LocationPermissionStatus.granted,
      ),
      appVersionProvider.overrideWith((ref) async => '1.0.0 (1)'),
      currentUserDisplayProvider.overrideWithValue(
        (displayName: 'Ammar', isAnonymous: isAnonymous, email: null),
      ),
    ],
    child: child,
  );

  Widget screen(FakeAccountActions actions, {bool isAnonymous = true}) => scope(
    actions,
    isAnonymous: isAnonymous,
    child: const MaterialApp(home: PengaturanScreen()),
  );

  /// Label baris "Hapus akun" identik dengan label tombol konfirmasi di dalam
  /// dialognya, jadi `find.text('Hapus akun')` menemukan dua widget begitu
  /// dialognya terbuka. Sama seperti tombol "Keluar" di `profil_screen_test`,
  /// tombol dialog selalu dicari lewat descendant-nya [AlertDialog].
  Finder inDialog(String label) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text(label),
  );

  group('PengaturanBody', () {
    testWidgets('izin diberikan menampilkan Diizinkan', (tester) async {
      await tester.pumpWidget(wrap(body()));

      expect(find.text('Diizinkan'), findsOneWidget);
    });

    testWidgets('izin ditolak menampilkan Ditolak', (tester) async {
      await tester.pumpWidget(
        wrap(body(permission: LocationPermissionStatus.denied)),
      );

      expect(find.text('Ditolak'), findsOneWidget);
    });

    testWidgets('GPS mati punya teks sendiri, bukan Ditolak', (tester) async {
      await tester.pumpWidget(
        wrap(body(permission: LocationPermissionStatus.serviceDisabled)),
      );

      expect(find.text('GPS mati'), findsOneWidget);
      expect(find.text('Ditolak'), findsNothing);
    });

    testWidgets('status dan versi yang belum termuat tampil sebagai —', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(body(permission: null, appVersion: null)));

      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('baris privasi disembunyikan kalau onPrivacyTap null', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(body()));

      expect(find.text('Kebijakan privasi'), findsNothing);
    });

    testWidgets('baris privasi muncul kalau onPrivacyTap ada', (tester) async {
      await tester.pumpWidget(wrap(body(onPrivacyTap: () {})));

      expect(find.text('Kebijakan privasi'), findsOneWidget);
    });

    testWidgets('tap Hapus akun memanggil callback', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(wrap(body(onDeleteAccountTap: () => tapped++)));

      await tester.tap(find.text('Hapus akun'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('tap Hapus riwayat makan memanggil callback', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(wrap(body(onDeleteHistoryTap: () => tapped++)));

      await tester.tap(find.text('Hapus riwayat makan'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('busy true menonaktifkan kedua baris destruktif', (
      tester,
    ) async {
      var history = 0;
      var account = 0;
      await tester.pumpWidget(
        wrap(
          body(
            busy: true,
            onDeleteHistoryTap: () => history++,
            onDeleteAccountTap: () => account++,
          ),
        ),
      );

      await tester.tap(find.text('Hapus riwayat makan'));
      await tester.tap(find.text('Hapus akun'));
      await tester.pump();

      expect(history, 0);
      expect(account, 0);

      // Dua assertion di atas sendirian bisa lolos secara palsu (callback yang
      // tidak pernah terpasang sama sekali juga menghasilkan 0), jadi `onTap`
      // baris-barisnya diperiksa langsung. Pasangan sebaliknya ada di dua test
      // "tap ... memanggil callback" di atas, yang membuktikan barisnya memang
      // bisa di-tap saat `busy` false.
      InkWell rowOf(String label) => tester.widget<InkWell>(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );

      expect(rowOf('Hapus riwayat makan').onTap, isNull);
      expect(rowOf('Hapus akun').onTap, isNull);
    });

    // Dua test berikut berpasangan dan wajib bersama: yang pertama sendirian
    // akan tetap lolos meski `onTap` baris lokasi dibuat selalu `null`
    // (tap tidak pernah memanggil apa pun, `tapped` tetap 0 baik ternyata
    // salah maupun benar). Yang kedua mengunci sisi sebaliknya, membuktikan
    // baris itu memang bisa di-tap saat statusnya bukan `granted`. Jangan
    // hapus salah satunya karena mengira redundan.
    testWidgets('izin sudah diberikan membuat baris lokasi tidak bisa di-tap', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        wrap(
          PengaturanBody(
            permission: LocationPermissionStatus.granted,
            appVersion: '1.0.0 (1)',
            onLocationTap: () => tapped++,
            onDeleteHistoryTap: () {},
            onDeleteAccountTap: () {},
          ),
        ),
      );

      await tester.tap(find.text('Izin lokasi'));
      await tester.pump();

      expect(tapped, 0);
    });

    testWidgets('izin ditolak membuat baris lokasi bisa di-tap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        wrap(
          PengaturanBody(
            permission: LocationPermissionStatus.denied,
            appVersion: '1.0.0 (1)',
            onLocationTap: () => tapped++,
            onDeleteHistoryTap: () {},
            onDeleteAccountTap: () {},
          ),
        ),
      );

      await tester.tap(find.text('Izin lokasi'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('tiga judul seksi selalu tampil', (tester) async {
      await tester.pumpWidget(wrap(body()));

      expect(find.text('LOKASI'), findsOneWidget);
      expect(find.text('DATA'), findsOneWidget);
      expect(find.text('TENTANG'), findsOneWidget);
    });
  });

  /// Dialog konfirmasi adalah satu-satunya gerbang sebelum penghapusan
  /// permanen, dan sebelum group ini tidak ada satu pun test yang menyentuh
  /// `PengaturanScreen` — mengganti `await _confirm(...)` jadi `const ok = true`
  /// tidak membuat satu test pun gagal.
  group('PengaturanScreen', () {
    testWidgets('Hapus riwayat makan memunculkan dialog, Batal tidak menghapus apa pun', (
      tester,
    ) async {
      final actions = FakeAccountActions();
      await tester.pumpWidget(screen(actions));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus riwayat makan'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Hapus riwayat makan?'), findsOneWidget);

      await tester.tap(inDialog('Batal'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(actions.deleteHistoryCalls, 0);
    });

    testWidgets('konfirmasi Hapus riwayat makan benar-benar menghapus riwayat', (
      tester,
    ) async {
      final actions = FakeAccountActions();
      await tester.pumpWidget(screen(actions));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus riwayat makan'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Hapus'));
      await tester.pumpAndSettle();

      expect(actions.deleteHistoryCalls, 1);
      expect(find.text('Riwayat makan dihapus'), findsOneWidget);
    });

    testWidgets('gagal hapus riwayat menampilkan pesan gagal, bukan pesan sukses', (
      tester,
    ) async {
      final actions = FakeAccountActions(
        deleteHistoryError: StateError('currentUser null'),
      );
      await tester.pumpWidget(screen(actions));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus riwayat makan'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Riwayat makan dihapus'), findsNothing);
      expect(find.text('Gagal hapus riwayat, coba lagi ya'), findsOneWidget);
    });

    testWidgets('Hapus akun memunculkan dialog, Batal tidak menghapus apa pun', (
      tester,
    ) async {
      final actions = FakeAccountActions();
      await tester.pumpWidget(screen(actions));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus akun'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Hapus akun?'), findsOneWidget);

      await tester.tap(inDialog('Batal'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(actions.deleteAccountCalls, 0);
    });

    testWidgets('konfirmasi Hapus akun benar-benar menghapus akun', (
      tester,
    ) async {
      final actions = FakeAccountActions();
      await tester.pumpWidget(screen(actions, isAnonymous: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus akun'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Hapus akun'));
      await tester.pumpAndSettle();

      expect(actions.deleteAccountCalls, 1);
      // Diteruskan apa adanya: user Google wajib reauth, user anonim tidak —
      // dan `AccountActions` tidak bisa menebaknya sendiri.
      expect(actions.lastIsAnonymous, isFalse);
    });

    testWidgets('hapus akun yang sukses menutup layar dan tetap menampilkan SnackBar', (
      tester,
    ) async {
      final actions = FakeAccountActions();
      late BuildContext rootContext;

      await tester.pumpWidget(
        scope(
          actions,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                rootContext = context;
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );

      // Didorong sebagai route kedua supaya `popUntil((r) => r.isFirst)`
      // benar-benar melepas layarnya — kalau PengaturanScreen jadi `home`,
      // popUntil tidak melakukan apa-apa dan test ini tidak membuktikan apa pun
      // soal SnackBar yang harus selamat dari pop.
      Navigator.of(rootContext).push(
        MaterialPageRoute<void>(builder: (_) => const PengaturanScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus akun'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Hapus akun'));
      await tester.pumpAndSettle();

      expect(find.byType(PengaturanScreen), findsNothing);
      expect(find.text('Akun kamu udah dihapus'), findsOneWidget);
    });

    testWidgets('gagal hapus akun menampilkan SnackBar dan tidak menutup layar', (
      tester,
    ) async {
      final actions = FakeAccountActions(
        deleteAccountError: StateError('currentUser null'),
      );
      late BuildContext rootContext;

      await tester.pumpWidget(
        scope(
          actions,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                rootContext = context;
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );

      Navigator.of(rootContext).push(
        MaterialPageRoute<void>(builder: (_) => const PengaturanScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus akun'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Hapus akun'));
      await tester.pumpAndSettle();

      // Inti Temuan 1: gagal-diam dulu terlihat persis seperti sukses (layar
      // ditutup, tanpa pesan apa pun). Sekarang keduanya harus berbeda.
      expect(find.byType(PengaturanScreen), findsOneWidget);
      expect(find.text('Akun kamu udah dihapus'), findsNothing);
      expect(find.text('Gagal hapus akun, coba lagi ya'), findsOneWidget);
    });

    testWidgets('user membatalkan Google picker tidak memunculkan SnackBar', (
      tester,
    ) async {
      final actions = FakeAccountActions(
        deleteAccountError: GoogleSignInCancelledException(),
      );
      await tester.pumpWidget(screen(actions, isAnonymous: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus akun'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Hapus akun'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
