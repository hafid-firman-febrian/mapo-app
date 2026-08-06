import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/ui/widgets/grounding_badge.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mapo_app/themes/app_colors.dart';

List<List<dynamic>> _iconOf(WidgetTester tester) =>
    tester.widget<HugeIcon>(find.byType(HugeIcon)).icon;

Color? _fillColorOf(WidgetTester tester) {
  final container = tester.widget<Container>(find.byType(Container));
  return (container.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('tidak render apa pun kalau contextUsed null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GroundingBadge())),
    );

    expect(find.byType(GroundingBadge), findsOneWidget);
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('tidak render apa pun kalau semua field contextUsed kosong', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed()),
        ),
      ),
    );

    expect(find.byType(Container), findsNothing);
  });

  testWidgets('menampilkan cuaca kalau ada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(
            contextUsed: ContextUsed(weather: 'hujan ringan'),
          ),
        ),
      ),
    );

    expect(find.textContaining('hujan ringan'), findsOneWidget);
  });

  testWidgets('menampilkan riwayat kalau basedOnHistory true dan cuaca kosong', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(
            contextUsed: ContextUsed(basedOnHistory: true),
          ),
        ),
      ),
    );

    expect(find.textContaining('riwayat'), findsOneWidget);
  });

  testWidgets('menampilkan waktu tanpa underscore kalau cuma timeOfDay yang ada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(
            contextUsed: ContextUsed(timeOfDay: 'makan_siang'),
          ),
        ),
      ),
    );

    expect(find.textContaining('makan siang'), findsOneWidget);
  });

  testWidgets('label dibawa lewat Semantics sebagai satu node (bukan dobel)', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed(weather: 'hujan ringan')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('dipilih karena cuaca hujan ringan'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('cuaca (belum dikenali kata kuncinya) pakai icon cloud dan tone biru', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(
            contextUsed: ContextUsed(weather: 'berawan tebal'),
          ),
        ),
      ),
    );

    expect(_iconOf(tester), HugeIcons.strokeRoundedCloud);
    expect(_fillColorOf(tester), CategoryTone.blue.fill);
  });

  testWidgets('riwayat pakai icon Clock01 dan tone amber', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed(basedOnHistory: true)),
        ),
      ),
    );

    expect(_iconOf(tester), HugeIcons.strokeRoundedClock01);
    expect(_fillColorOf(tester), CategoryTone.amber.fill);
  });

  testWidgets('timeOfDay pakai icon Time01 dan tone hijau', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed(timeOfDay: 'makan_siang')),
        ),
      ),
    );

    expect(_iconOf(tester), HugeIcons.strokeRoundedTime01);
    expect(_fillColorOf(tester), CategoryTone.green.fill);
  });

  testWidgets('cuaca cerah pakai icon Sun01 dan tone amber', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed(weather: 'cerah')),
        ),
      ),
    );

    expect(_iconOf(tester), HugeIcons.strokeRoundedSun01);
    expect(_fillColorOf(tester), CategoryTone.amber.fill);
  });

  testWidgets('cuaca hujan pakai icon CloudAngledRain dan tone biru', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed(weather: 'hujan ringan')),
        ),
      ),
    );

    expect(_iconOf(tester), HugeIcons.strokeRoundedCloudAngledRain);
    expect(_fillColorOf(tester), CategoryTone.blue.fill);
  });

  testWidgets('cuaca gerimis pakai icon CloudAngledRain dan tone biru', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed(weather: 'gerimis')),
        ),
      ),
    );

    expect(_iconOf(tester), HugeIcons.strokeRoundedCloudAngledRain);
    expect(_fillColorOf(tester), CategoryTone.blue.fill);
  });

  testWidgets('cuaca badai petir pakai icon CloudAngledRainZap dan tone merah', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed(weather: 'badai petir')),
        ),
      ),
    );

    expect(_iconOf(tester), HugeIcons.strokeRoundedCloudAngledRainZap);
    expect(_fillColorOf(tester), CategoryTone.red.fill);
  });

  testWidgets('cuaca hujan lebat disertai petir pakai icon storm, bukan rain', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(
            contextUsed: ContextUsed(weather: 'hujan lebat disertai petir'),
          ),
        ),
      ),
    );

    expect(_iconOf(tester), HugeIcons.strokeRoundedCloudAngledRainZap);
    expect(_fillColorOf(tester), CategoryTone.red.fill);
  });

  testWidgets('cuaca salju pakai icon Snow dan tone biru', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed(weather: 'salju ringan')),
        ),
      ),
    );

    expect(_iconOf(tester), HugeIcons.strokeRoundedSnow);
    expect(_fillColorOf(tester), CategoryTone.blue.fill);
  });

  testWidgets('icon dan teks selalu pakai AppColors.ink, terlepas dari tone', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed(basedOnHistory: true)),
        ),
      ),
    );

    // basedOnHistory pakai CategoryTone.amber — sebelum fix, icon/teks
    // memakai tone.dark (brandDark) yang gagal kontras 4.5:1 di atas fill-nya.
    final icon = tester.widget<HugeIcon>(find.byType(HugeIcon));
    expect(icon.color, AppColors.ink);

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.color, AppColors.ink);
  });
}
