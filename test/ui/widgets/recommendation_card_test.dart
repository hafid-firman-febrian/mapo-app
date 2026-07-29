import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/ui/widgets/recommendation_card.dart';

const _rec = Recommendation(
  name: 'Soto Ayam',
  reason: 'Kuahnya anget pas buat cuaca hujan, ringan, dan masih di bawah budget kamu.',
  category: 'berkuah',
  priceEstimate: 13000,
  spiceLevel: 'sedang',
  prepTime: 'cepat',
  tags: ['hangat'],
);

void main() {
  testWidgets('hero menampilkan nama, alasan, dan tombol Makan ini', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecommendationCard(recommendation: _rec)),
      ),
    );

    expect(find.text('Soto Ayam'), findsOneWidget);
    expect(find.textContaining('Kuahnya anget'), findsOneWidget);
    expect(find.text('Makan ini'), findsOneWidget);
  });

  testWidgets('hero menampilkan tag kategori, spice level, prep time, dan tag tambahan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecommendationCard(recommendation: _rec)),
      ),
    );

    expect(find.text('berkuah'), findsOneWidget);
    expect(find.text('sedang'), findsOneWidget);
    expect(find.text('cepat'), findsOneWidget);
    expect(find.text('hangat'), findsOneWidget);
  });

  testWidgets('tombol lagi cuma muncul kalau onRetry diisi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecommendationCard(recommendation: _rec)),
      ),
    );
    expect(find.bySemanticsLabel('Cari saran lain'), findsNothing);

    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationCard(recommendation: _rec, onRetry: () => retried = true),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Cari saran lain'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Cari saran lain'));
    expect(retried, isTrue);
  });

  testWidgets('tap Makan ini memanggil onPick', (tester) async {
    var picked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationCard(recommendation: _rec, onPick: () => picked = true),
        ),
      ),
    );

    await tester.tap(find.text('Makan ini'));
    expect(picked, isTrue);
  });

  testWidgets('tags kosong tidak merender Wrap kosong', (tester) async {
    const noTags = Recommendation(
      name: 'Nasi Putih',
      reason: 'Netral, cocok buat pendamping apa saja.',
      category: 'nasi',
      priceEstimate: 5000,
      spiceLevel: 'tidak_pedas',
      prepTime: 'cepat',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecommendationCard(recommendation: noTags)),
      ),
    );

    // spiceLevel 'tidak_pedas' sengaja tidak ditampilkan sebagai tag (lihat _tags).
    expect(find.text('tidak pedas'), findsNothing);
    expect(find.text('nasi'), findsOneWidget);
    expect(find.text('cepat'), findsOneWidget);
  });

  testWidgets('row menampilkan nama, kategori, spice level, dan harga', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecommendationCard(
            recommendation: _rec,
            variant: RecommendationCardVariant.row,
          ),
        ),
      ),
    );

    expect(find.text('Soto Ayam'), findsOneWidget);
    expect(find.text('berkuah · sedang'), findsOneWidget);
    expect(find.text('Rp13.000'), findsOneWidget);
    expect(find.text('Makan ini'), findsNothing);
  });

  testWidgets('row tidak menampilkan tombol Makan ini walau onPick diisi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationCard(
            recommendation: _rec,
            variant: RecommendationCardVariant.row,
            onPick: () {},
          ),
        ),
      ),
    );

    expect(find.text('Makan ini'), findsNothing);
  });

  testWidgets('row memanggil onTap saat kartu ditekan', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationCard(
            recommendation: _rec,
            variant: RecommendationCardVariant.row,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(RecommendationCard));
    expect(tapped, isTrue);
  });
}
