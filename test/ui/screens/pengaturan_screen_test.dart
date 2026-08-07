import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/location_service.dart';
import 'package:mapo_app/ui/screens/pengaturan_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  PengaturanBody body({
    LocationPermissionStatus? permission = LocationPermissionStatus.granted,
    String? appVersion = '1.0.0 (1)',
    VoidCallback? onPrivacyTap,
    VoidCallback? onDeleteAccountTap,
  }) => PengaturanBody(
    permission: permission,
    appVersion: appVersion,
    onLocationTap: () {},
    onDeleteHistoryTap: () {},
    onDeleteAccountTap: onDeleteAccountTap ?? () {},
    onPrivacyTap: onPrivacyTap,
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
}
