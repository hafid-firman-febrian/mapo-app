import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/ui/widgets/grounding_badge.dart';

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
}
