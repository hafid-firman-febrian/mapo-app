import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/meal_history_service.dart';
import 'package:mapo_app/data/weather_service.dart';
import 'package:mapo_app/domain/mapo_chat.dart';
import 'package:mapo_app/domain/mapo_recommender.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/models/meal_history_entry.dart';
import 'package:mapo_app/models/user_prefs.dart';
import 'package:mapo_app/models/weather_context.dart';

/// `implements` cukup: field `_db` privat, jadi bukan bagian dari interface publik.
///
/// PENTING: `implements` mewajibkan SEMUA member publik diimplementasikan.
/// Setiap kali kamu menambah method publik ke service aslinya, fake ini harus
/// ikut ditambah atau seluruh file test gagal compile. Task 7 melakukan ini.
class FakeWeatherService implements WeatherService {
  final WeatherContext result;
  final calls = <String>[];

  FakeWeatherService([WeatherContext? result])
    : result = result ?? WeatherContext.unknown();

  @override
  Future<WeatherContext> getWeather(double lat, double lng) async {
    calls.add('$lat,$lng');
    return result;
  }
}

class FakeMealHistory implements MealHistoryService {
  final List<String> recent;
  final UserPrefs prefs;
  final saved = <Map<String, String>>[];

  FakeMealHistory({this.recent = const [], UserPrefs? prefs})
    : prefs = prefs ?? const UserPrefs();

  @override
  Future<List<String>> getRecentMeals(String userId, {int limit = 3}) async =>
      recent;

  @override
  Future<UserPrefs> getPreferences(String userId) async => prefs;

  @override
  Future<void> saveMeal(String userId, String name, String category) async {
    saved.add({'name': name, 'category': category});
  }

  @override
  Future<List<MealHistoryEntry>> getMealHistory(String userId, {int limit = 20}) async =>
      [];
}

class FakeMapoChat implements MapoChat {
  final String? reply;
  final prompts = <String>[];

  FakeMapoChat(this.reply);

  @override
  Future<String?> send(String text) async {
    prompts.add(text);
    return reply;
  }
}

String jsonReply({String name = 'Soto Ayam'}) => jsonEncode({
  'response_type': 'single',
  'message': 'Cuaca dingin nih, cocok yang berkuah.',
  'recommendations': [
    {
      'name': name,
      'reason': 'Anget, pas buat hujan',
      'category': 'berkuah',
      'price_estimate': 18000,
      'spice_level': 'sedang',
      'prep_time': 'cepat',
      'tags': ['hangat'],
    },
  ],
});

void main() {
  test('konteks cuaca dan riwayat masuk ke prompt', () async {
    final chat = FakeMapoChat(jsonReply());
    final recommender = MapoRecommender(
      FakeWeatherService(
        WeatherContext(description: 'hujan ringan', temperature: 24),
      ),
      FakeMealHistory(recent: ['Nasi Goreng', 'Mie Ayam']),
      chat,
    );

    await recommender.reply(
      userId: 'u1',
      userMessage: 'laper',
      withContext: true,
      lat: -6.2,
      lng: 106.8,
    );

    expect(chat.prompts.single, contains('hujan ringan'));
    expect(chat.prompts.single, contains('24°C'));
    expect(chat.prompts.single, contains('Nasi Goreng, Mie Ayam'));
    expect(chat.prompts.single, contains('laper'));
  });

  test('lat/lng null melewatkan panggilan cuaca', () async {
    final weather = FakeWeatherService();
    final recommender = MapoRecommender(
      weather,
      FakeMealHistory(),
      FakeMapoChat(jsonReply()),
    );

    await recommender.reply(
      userId: 'u1',
      userMessage: 'laper',
      withContext: true,
    );

    expect(weather.calls, isEmpty);
  });

  test('respons diparsing jadi MapoResponse', () async {
    final recommender = MapoRecommender(
      FakeWeatherService(),
      FakeMealHistory(),
      FakeMapoChat(jsonReply(name: 'Bakso')),
    );

    final result = await recommender.reply(
      userId: 'u1',
      userMessage: 'laper',
      withContext: true,
    );

    expect(result.responseType, ResponseType.single);
    expect(result.recommendations.single.name, 'Bakso');
    expect(result.recommendations.single.priceEstimate, 18000);
  });

  test('respons kosong melempar MapoException', () async {
    final recommender = MapoRecommender(
      FakeWeatherService(),
      FakeMealHistory(),
      FakeMapoChat(null),
    );

    expect(
      () => recommender.reply(
        userId: 'u1',
        userMessage: 'laper',
        withContext: true,
      ),
      throwsA(isA<MapoException>()),
    );
  });

  test('JSON rusak melempar MapoException', () async {
    final recommender = MapoRecommender(
      FakeWeatherService(),
      FakeMealHistory(),
      FakeMapoChat('{ ini bukan json'),
    );

    expect(
      () => recommender.reply(
        userId: 'u1',
        userMessage: 'laper',
        withContext: true,
      ),
      throwsA(isA<MapoException>()),
    );
  });

  test('withContext false mengirim pesan mentah tanpa blok konteks', () async {
    final chat = FakeMapoChat(jsonReply());
    final recommender = MapoRecommender(
      FakeWeatherService(),
      FakeMealHistory(),
      chat,
    );

    await recommender.reply(
      userId: 'u1',
      userMessage: 'berkuah',
      withContext: false,
    );

    expect(chat.prompts.single, 'berkuah');
  });
}
