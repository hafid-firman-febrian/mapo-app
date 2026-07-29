import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/chat_turn.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import 'package:mapo_app/ui/screens/chat_screen.dart';
import 'package:mapo_app/ui/screens/riwayat_screen.dart';

MapoResponse _singleResponse({List<Recommendation>? recommendations}) => MapoResponse(
      responseType: ResponseType.single,
      message: 'Buat kamu yang lagi pengen anget',
      recommendations: recommendations ??
          const [
            Recommendation(
              name: 'Soto Ayam',
              reason: 'Kuahnya anget pas buat cuaca hujan.',
              category: 'berkuah',
              priceEstimate: 13000,
              spiceLevel: 'sedang',
              prepTime: 'cepat',
            ),
          ],
      contextUsed: const ContextUsed(weather: 'hujan ringan'),
    );

const _optionsResponse = MapoResponse(
  responseType: ResponseType.options,
  message: 'Ada 3 pilihan yang cocok buat cuaca hujan hari ini:',
  recommendations: [
    Recommendation(
      name: 'Soto Ayam',
      reason: 'anget',
      category: 'berkuah',
      priceEstimate: 13000,
      spiceLevel: 'sedang',
      prepTime: 'cepat',
    ),
    Recommendation(
      name: 'Bakso',
      reason: 'pedas',
      category: 'pedas',
      priceEstimate: 15000,
      spiceLevel: 'pedas',
      prepTime: 'cepat',
    ),
  ],
);

const _clarifyResponse = MapoResponse(
  responseType: ResponseType.clarify,
  message: 'Siap bantu!',
  followUp: FollowUp(
    question: 'Biar pas, kamu lagi pengen yang gimana nih?',
    quickReplies: ['yang murah', 'yang pedas', 'yang cepet', 'yang sehat'],
  ),
);

class _FixedChatNotifier extends ChatNotifier {
  final List<ChatTurn> initial;
  _FixedChatNotifier(this.initial);

  @override
  List<ChatTurn> build() => initial;
}

void main() {
  group('ChatConversationBody', () {
    testWidgets('turns kosong menampilkan Home dengan contoh pertanyaan tappable', (tester) async {
      String? sent;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [],
              controller: TextEditingController(),
              onSend: (t) async => sent = t,
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.text('Cerita aja ke Mapo'), findsOneWidget);
      expect(find.text('lagi hujan, pengen anget'), findsOneWidget);

      await tester.tap(find.text('lagi hujan, pengen anget'));
      expect(sent, 'lagi hujan, pengen anget');
    });

    testWidgets('UserTurn dirender sebagai bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('lagi hujan, pengen anget')],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.text('lagi hujan, pengen anget'), findsOneWidget);
    });

    testWidgets('PendingTurn menampilkan PendingChecklist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('laper'), PendingTurn()],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
              inputEnabled: false,
            ),
          ),
        ),
      );

      expect(find.text('Mapo lagi mikir...'), findsOneWidget);
      // Bereskan Timer PendingChecklist yang masih jalan sebelum test selesai.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('ErrorTurn menampilkan pesan dan tombol coba lagi', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('laper'), ErrorTurn('Mapo lagi bingung, coba lagi ya')],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
              onRetryLast: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Mapo lagi bingung, coba lagi ya'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      expect(retried, isTrue);
    });

    testWidgets('MapoTurn single menampilkan RecommendationCard hero dan badge cuaca', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: [const UserTurn('laper'), MapoTurn(_singleResponse())],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.text('Soto Ayam'), findsOneWidget);
      expect(find.text('Makan ini'), findsOneWidget);
      expect(find.textContaining('hujan ringan'), findsOneWidget);
    });

    testWidgets('tap Makan ini memanggil onPick dengan rekomendasi yang benar', (tester) async {
      Recommendation? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: [const UserTurn('laper'), MapoTurn(_singleResponse())],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
              onPick: (r) => picked = r,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Makan ini'));
      expect(picked?.name, 'Soto Ayam');
    });

    testWidgets('MapoTurn single dengan recommendations kosong menampilkan notice', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: [
                const UserTurn('laper'),
                MapoTurn(_singleResponse(recommendations: const [])),
              ],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.textContaining('belum nemu saran'), findsOneWidget);
    });

    testWidgets('MapoTurn options menampilkan beberapa row dan tap mengirim pesan pilih', (tester) async {
      String? sent;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('bingung'), MapoTurn(_optionsResponse)],
              controller: TextEditingController(),
              onSend: (t) async => sent = t,
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.text('Soto Ayam'), findsOneWidget);
      expect(find.text('Bakso'), findsOneWidget);

      await tester.tap(find.text('Bakso'));
      expect(sent, 'pilih Bakso');
    });

    testWidgets('MapoTurn clarify menampilkan pertanyaan dan quick reply', (tester) async {
      String? sent;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('aku laper'), MapoTurn(_clarifyResponse)],
              controller: TextEditingController(),
              onSend: (t) async => sent = t,
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.textContaining('gimana nih'), findsOneWidget);
      expect(find.text('yang murah'), findsOneWidget);

      await tester.tap(find.text('yang pedas'));
      expect(sent, 'yang pedas');
    });
  });

  group('ChatScreen', () {
    testWidgets('membuka drawer dan navigasi ke Riwayat', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatProvider.overrideWith(() => _FixedChatNotifier(const [])),
            coordsProvider.overrideWith((ref) async => null),
            currentUserDisplayProvider.overrideWithValue((displayName: 'Ammar', isAnonymous: true)),
            mealHistoryEntriesProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Buka menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Riwayat makan'));
      await tester.pumpAndSettle();

      expect(find.byType(RiwayatScreen), findsOneWidget);
    });
  });
}
