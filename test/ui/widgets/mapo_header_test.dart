import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mapo_app/themes/app_colors.dart';
import 'package:mapo_app/ui/widgets/mapo_header.dart';

void main() {
  testWidgets('menampilkan judul dan subjudul', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: MapoHeader(
            title: 'Mangan opo hari ini?',
            subtitle: 'Halo! Bingung mau makan apa?',
          ),
        ),
      ),
    );

    expect(find.text('Mangan opo hari ini?'), findsOneWidget);
    expect(find.text('Halo! Bingung mau makan apa?'), findsOneWidget);
  });

  testWidgets('judul dipakai warna ink, bukan putih, di atas warna apa pun', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: MapoHeader(title: 'Riwayat makan', color: AppColors.green),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Riwayat makan'));
    expect(text.style?.color, AppColors.ink);
  });

  testWidgets('leading dan actions dirender kalau diisi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: MapoHeader(
            title: 'Cari makan',
            leading: MapoHeaderIconButton(
              icon: HugeIcons.strokeRoundedMenu01,
              label: 'Buka menu',
              onTap: () {},
            ),
            actions: [
              MapoHeaderIconButton(
                icon: HugeIcons.strokeRoundedUserCircle,
                label: 'Profil',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Buka menu'), findsOneWidget);
    expect(find.bySemanticsLabel('Profil'), findsOneWidget);
  });

  testWidgets('MapoHeaderIconButton memanggil onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapoHeaderIconButton(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            label: 'Kembali',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Kembali'));
    expect(tapped, isTrue);
  });
}
