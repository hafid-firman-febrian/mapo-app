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
}
