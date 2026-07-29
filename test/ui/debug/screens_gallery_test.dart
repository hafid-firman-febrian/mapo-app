import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/debug/screens_gallery.dart';

void main() {
  testWidgets('menampilkan semua entri dan membuka preview Single', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScreensGallery()));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('Single'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Clarify'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Riwayat (terisi)'), findsOneWidget);
    expect(find.text('Riwayat (kosong)'), findsOneWidget);
    expect(find.text('Profil (anonim)'), findsOneWidget);
    expect(find.text('Menu (drawer)'), findsOneWidget);

    await tester.tap(find.text('Single'));
    await tester.pumpAndSettle();

    expect(find.text('Soto Ayam'), findsOneWidget);
    expect(find.text('Makan ini'), findsOneWidget);
  });

  testWidgets('preview Riwayat kosong menampilkan pesan ramah', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScreensGallery()));

    await tester.tap(find.text('Riwayat (kosong)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
  });
}
