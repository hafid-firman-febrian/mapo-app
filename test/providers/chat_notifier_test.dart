import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/domain/mapo_chat.dart';
import 'package:mapo_app/models/chat_turn.dart';
import 'package:mapo_app/providers/mapo_providers.dart';

import '../domain/mapo_recommender_test.dart'
    show FakeMapoChat, FakeMealHistory, FakeWeatherService, jsonReply;

void main() {
  ProviderContainer makeContainer({
    required MapoChat chat,
    String? userId = 'u1',
  }) {
    return ProviderContainer(
      overrides: [
        mapoChatProvider.overrideWithValue(chat),
        currentUserIdProvider.overrideWithValue(userId),
        weatherServiceProvider.overrideWithValue(FakeWeatherService()),
        mealHistoryProvider.overrideWithValue(FakeMealHistory()),
      ],
    );
  }

  // Catatan: `coordsProvider` tidak perlu di-override. `ChatNotifier.ask`
  // menerima lat/lng sebagai parameter — yang membaca `coordsProvider` adalah
  // `ChatScreen`, bukan notifier-nya.

  test('mulai dengan daftar turn kosong', () {
    final container = makeContainer(chat: FakeMapoChat(jsonReply()));
    addTearDown(container.dispose);

    expect(container.read(chatProvider), isEmpty);
  });

  test('ask menambahkan UserTurn lalu MapoTurn', () async {
    final container = makeContainer(chat: FakeMapoChat(jsonReply()));
    addTearDown(container.dispose);

    await container.read(chatProvider.notifier).ask('laper');

    final turns = container.read(chatProvider);
    expect(turns, hasLength(2));
    expect((turns[0] as UserTurn).text, 'laper');
    expect(
      (turns[1] as MapoTurn).response.recommendations.single.name,
      'Soto Ayam',
    );
  });

  test('riwayat turn tidak hilang saat request kedua', () async {
    final chat = FakeMapoChat(jsonReply());
    final container = makeContainer(chat: chat);
    addTearDown(container.dispose);

    await container.read(chatProvider.notifier).ask('laper');
    await container.read(chatProvider.notifier).ask('yang lain');

    expect(container.read(chatProvider), hasLength(4));
    expect(container.read(chatProvider).whereType<PendingTurn>(), isEmpty);
  });

  test('konteks hanya dikirim di turn pertama', () async {
    final chat = FakeMapoChat(jsonReply());
    final container = makeContainer(chat: chat);
    addTearDown(container.dispose);

    await container.read(chatProvider.notifier).ask('laper');
    await container.read(chatProvider.notifier).ask('yang lain');

    expect(chat.prompts, hasLength(2));
    expect(chat.prompts[0], contains('[Konteks saat ini]'));
    expect(chat.prompts[1], 'yang lain');
  });

  test('kegagalan model jadi ErrorTurn, bukan mengosongkan daftar', () async {
    final container = makeContainer(chat: FakeMapoChat(null));
    addTearDown(container.dispose);

    await container.read(chatProvider.notifier).ask('laper');

    final turns = container.read(chatProvider);
    expect(turns, hasLength(2));
    expect(turns[0], isA<UserTurn>());
    expect(turns[1], isA<ErrorTurn>());
  });

  test('tanpa userId langsung ErrorTurn', () async {
    final container = makeContainer(
      chat: FakeMapoChat(jsonReply()),
      userId: null,
    );
    addTearDown(container.dispose);

    await container.read(chatProvider.notifier).ask('laper');

    expect(container.read(chatProvider).last, isA<ErrorTurn>());
  });
}
