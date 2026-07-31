import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/domain/mapo_chat.dart';
import 'package:mapo_app/models/chat_turn.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/models/user_prefs.dart';
import 'package:mapo_app/providers/mapo_providers.dart';

import '../domain/mapo_recommender_test.dart'
    show FakeMapoChat, FakeMealHistory, FakeWeatherService, jsonReply;

class _PendingMapoChat implements MapoChat {
  final Completer<String?> completer;
  _PendingMapoChat(this.completer);

  @override
  Future<String?> send(String text) => completer.future;
}

/// Mengosongkan antrean microtask/macrotask berkali-kali supaya `ask()` yang
/// sedang jalan maju sejauh mungkin — sampai ke titik dia betul-betul
/// menunggu sebuah `Completer` yang belum di-complete manual (mis. coords,
/// context block, lalu `_chat.send()`). Tidak akan pernah "menyelesaikan"
/// completer yang memang sengaja dibiarkan pending; cuma meng-flush kerja
/// async lain yang sudah bisa selesai sendiri.
Future<void> _flush() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>(() {});
  }
}

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

  test('UID berganti saat ask() masih menunggu tidak menimpa state dengan respons basi', () async {
    final completer = Completer<String?>();
    final chat = _PendingMapoChat(completer);
    final container = makeContainer(chat: chat, userId: 'u1');
    addTearDown(container.dispose);

    final askFuture = container.read(chatProvider.notifier).ask('laper');

    // Simulasikan UID berganti (sign out/switch akun) sebelum Gemini membalas.
    container.updateOverrides([
      mapoChatProvider.overrideWithValue(chat),
      currentUserIdProvider.overrideWithValue('u2'),
      weatherServiceProvider.overrideWithValue(FakeWeatherService()),
      mealHistoryProvider.overrideWithValue(FakeMealHistory()),
    ]);
    // Riverpod cuma menandai chatProvider "dirty" di sini, build() tidak
    // otomatis dijalankan ulang sampai ada yang membaca provider ini lagi.
    // Di app asli, ChatScreen yang men-watch chatProvider selalu melakukan
    // pembacaan itu dalam sekejap. Tanpa baris ini, dirty flag baru
    // ke-flush oleh `expect` di bawah — yaitu SETELAH tulisan basi terjadi —
    // sehingga build() ke-2 itu kebetulan menimpa balik korupsinya dan
    // membuat test ini lolos meski bug-nya masih ada.
    container.read(chatProvider);

    completer.complete(jsonReply());
    await askFuture;

    expect(container.read(chatProvider), isEmpty);
  });

  test('_inFlight tidak ikut ke-reset oleh respons basi dari sesi lama', () async {
    final completerA = Completer<String?>();
    final chatA = _PendingMapoChat(completerA);
    final container = makeContainer(chat: chatA, userId: 'u1');
    addTearDown(container.dispose);

    final askA = container.read(chatProvider.notifier).ask('pesan A');
    // Biarkan askA maju sampai betul-betul terhenti di chatA.send() (yaitu
    // completerA), bukan cuma sampai di await pertama. Tanpa ini,
    // recommenderProvider yang baru di-invalidate oleh override di bawah
    // bisa telanjur "ke-baca ulang" oleh kelanjutan askA sendiri dan malah
    // ikut terikat ke chatB — bukan bug yang mau diuji.
    await _flush();

    final completerB = Completer<String?>();
    final chatB = _PendingMapoChat(completerB);
    container.updateOverrides([
      mapoChatProvider.overrideWithValue(chatB),
      currentUserIdProvider.overrideWithValue('u2'),
      weatherServiceProvider.overrideWithValue(FakeWeatherService()),
      mealHistoryProvider.overrideWithValue(FakeMealHistory()),
    ]);
    container.read(chatProvider); // paksa build() rerun sebelum lanjut

    final askB = container.read(chatProvider.notifier).ask('pesan B');
    await _flush(); // biarkan askB maju sampai terhenti di chatB.send()

    // Respons basi dari sesi lama (u1) datang belakangan.
    completerA.complete(jsonReply(name: 'Basi'));
    await askA;

    // Kalau _inFlight salah ke-reset oleh selesainya A, ask ketiga ini akan
    // ikut jalan (guard _inFlight jebol) dan bisa balapan menimpa state B.
    // Seharusnya diabaikan karena B masih in-flight.
    final askC = container
        .read(chatProvider.notifier)
        .ask('pesan C, seharusnya diabaikan');
    await _flush();

    completerB.complete(jsonReply(name: 'Bakso'));
    await askB;
    await askC;

    final turns = container.read(chatProvider);
    expect(turns, hasLength(2));
    expect((turns[0] as UserTurn).text, 'pesan B');
    expect((turns[1] as MapoTurn).response.recommendations.single.name, 'Bakso');
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

  test('savePrefs meneruskan preferensi ke service dan menyegarkan prefsProvider', () async {
    final history = FakeMealHistory();
    final container = makeContainer(
      chat: FakeMapoChat(jsonReply()),
      history: history,
    );
    addTearDown(container.dispose);

    final before = await container.read(prefsProvider.future);
    expect(before.budgetRange, '15.000-25.000');

    await container.read(chatProvider.notifier).savePrefs(
      const UserPrefs(budgetRange: '> 50.000', restrictions: ['halal']),
    );

    expect(history.savedPrefs.single.budgetRange, '> 50.000');
    expect(history.savedPrefs.single.restrictions, ['halal']);

    final after = await container.read(prefsProvider.future);
    expect(after.budgetRange, '> 50.000');
    expect(after.restrictions, ['halal']);
  });
}
