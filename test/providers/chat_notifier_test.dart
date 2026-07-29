import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/domain/mapo_chat.dart';
import 'package:mapo_app/models/chat_turn.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/providers/mapo_providers.dart';

import '../domain/mapo_recommender_test.dart'
    show FakeMapoChat, FakeMealHistory, FakeWeatherService, jsonReply;

void main() {
  ProviderContainer makeContainer({
    required MapoChat chat,
    String? userId = 'u1',
    FakeMealHistory? history,
  }) {
    return ProviderContainer(
      overrides: [
        mapoChatProvider.overrideWithValue(chat),
        currentUserIdProvider.overrideWithValue(userId),
        weatherServiceProvider.overrideWithValue(FakeWeatherService()),
        mealHistoryProvider.overrideWithValue(history ?? FakeMealHistory()),
      ],
    );
  }

  // Catatan: sejak `ask` yang membaca `coordsProvider` (bukan lagi
  // `ChatScreen`), provider itu ikut jalan di test ini. Tetap tidak perlu
  // di-override: `LocationService` memanggil Geolocator lewat platform channel
  // yang tidak ada di lingkungan unit test, dan `coordsProvider` sendiri sudah
  // membungkus semuanya dengan `catch (_) => null`. Jadi resolusinya `null`,
  // cepat, dan deterministik — persis keadaan "lokasi tidak tersedia" yang
  // memang ingin diuji.

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

  test('PendingTurn muncul sinkron, sebelum await apa pun', () async {
    final container = makeContainer(chat: FakeMapoChat(jsonReply()));
    addTearDown(container.dispose);

    // Sengaja tidak di-await: yang diuji adalah state SEBELUM `ask` sempat
    // menyentuh coords/model. Kalau fetch koordinat balik ke pemanggil, di
    // titik ini state masih kosong dan field chat masih aktif berdetik-detik.
    final pending = container.read(chatProvider.notifier).ask('laper');

    final turns = container.read(chatProvider);
    expect(turns, hasLength(2));
    expect((turns[0] as UserTurn).text, 'laper');
    expect(turns[1], isA<PendingTurn>());

    await pending;
  });

  test('ask kedua selagi yang pertama jalan diabaikan, bukan menimpa', () async {
    final chat = FakeMapoChat(jsonReply());
    final container = makeContainer(chat: chat);
    addTearDown(container.dispose);
    final notifier = container.read(chatProvider.notifier);

    final first = notifier.ask('laper');
    await notifier.ask('yang lain');
    await first;

    final turns = container.read(chatProvider);
    expect(turns, hasLength(2), reason: 'turn pertama tidak boleh hilang tertimpa');
    expect((turns[0] as UserTurn).text, 'laper');
    expect(turns[1], isA<MapoTurn>());
    expect(chat.prompts, hasLength(1));
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

  test('pickMeal menyimpan menu ke riwayat', () async {
    final history = FakeMealHistory();
    final container = makeContainer(
      chat: FakeMapoChat(jsonReply(name: 'Bakso')),
      history: history,
    );
    addTearDown(container.dispose);

    await container.read(chatProvider.notifier).ask('laper');
    final picked = (container.read(chatProvider).last as MapoTurn)
        .response
        .recommendations
        .single;
    await container.read(chatProvider.notifier).pickMeal(picked);

    expect(history.saved, hasLength(1));
    expect(history.saved.single['name'], 'Bakso');
    expect(history.saved.single['category'], 'berkuah');
  });

  test('pickMeal tanpa userId tidak menyimpan apa pun', () async {
    final history = FakeMealHistory();
    final container = makeContainer(
      chat: FakeMapoChat(jsonReply()),
      userId: null,
      history: history,
    );
    addTearDown(container.dispose);

    await container.read(chatProvider.notifier).pickMeal(
      const Recommendation(
        name: 'Bakso',
        reason: 'anget',
        category: 'berkuah',
        priceEstimate: 15000,
        spiceLevel: 'sedang',
        prepTime: 'cepat',
      ),
    );

    expect(history.saved, isEmpty);
  });

  test('pickMeal menyegarkan mealHistoryEntriesProvider, bukan cuma menyimpan', () async {
    final history = FakeMealHistory();
    final container = makeContainer(
      chat: FakeMapoChat(jsonReply(name: 'Bakso')),
      history: history,
    );
    addTearDown(container.dispose);

    final before = await container.read(mealHistoryEntriesProvider.future);
    expect(before, isEmpty, reason: 'belum ada yang dipilih');

    await container.read(chatProvider.notifier).ask('laper');
    final picked = (container.read(chatProvider).last as MapoTurn)
        .response
        .recommendations
        .single;
    await container.read(chatProvider.notifier).pickMeal(picked);

    final after = await container.read(mealHistoryEntriesProvider.future);
    expect(
      after,
      hasLength(1),
      reason:
          'mealHistoryEntriesProvider cuma di-watch, tidak pernah di-invalidate '
          'setelah pickMeal — tanpa perbaikan, ini tetap kosong sampai container '
          'baru (di device: sampai hot restart)',
    );
    expect(after.single.name, 'Bakso');
  });
}
