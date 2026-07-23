import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import '../data/weather_service.dart';
import '../data/meal_history_service.dart';
import '../models/mapo_response.dart';
import '../models/weather_context.dart';
import '../models/user_prefs.dart';
import 'mapo_schema.dart';

class MapoRecommender {
  final WeatherService _weather;
  final MealHistoryService _history;
  final GenerativeModel _model;

  MapoRecommender(this._weather, this._history)
    : _model = FirebaseAI.googleAI().generativeModel(
        // [VERIFIKASI] model string terkini
        // model: 'gemini-flash-latest',
        model: 'gemini-3.5-flash-lite',
        systemInstruction: Content.text(_systemInstruction),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: mapoResponseSchema,
          temperature: 0.7,
          // maxOutputTokens: 800,
        ),
      );

  Future<MapoResponse> getRecommendation({
    required String userId,
    required String userMessage,
    required double lat,
    required double lng,
  }) async {
    // Kumpulkan konteks PARALEL — bukan berurutan
    final results = await Future.wait([
      _weather.getWeather(lat, lng),
      _history.getRecentMeals(userId),
      _history.getPreferences(userId),
    ]);

    final weather = results[0] as WeatherContext;
    debugPrint('WEATHER: ${weather.description}, ${weather.temperature}°C');
    final recentMeals = results[1] as List<String>;
    debugPrint('RECENT MEALS: $recentMeals');
    final prefs = results[2] as UserPrefs;
    debugPrint('PREFS: ${prefs.budgetRange}, ${prefs.restrictions}');

    final contextBlock = _buildContextBlock(
      weather: weather,
      recentMeals: recentMeals,
      prefs: prefs,
    );

    final response = await _model.generateContent([
      Content.text('$contextBlock\n\nPesan user: "$userMessage"'),
    ]);

    final raw = response.text;
    if (raw == null || raw.isEmpty) {
      throw MapoException('Respons kosong dari model');
    }

    try {
      return MapoResponse.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      throw MapoException('Format respons tidak valid');
    }
  }

  String _buildContextBlock({
    required WeatherContext weather,
    required List<String> recentMeals,
    required UserPrefs prefs,
  }) {
    final now = DateTime.now();
    final timeOfDay = _resolveTimeOfDay(now.hour);
    final weatherLine = weather.isKnown
        ? '${weather.description}, ${weather.temperature.toStringAsFixed(0)}°C'
        : 'tidak diketahui';

    return '''
[Konteks saat ini]
Cuaca: $weatherLine
Waktu: ${now.hour}:${now.minute.toString().padLeft(2, '0')} ($timeOfDay)
Riwayat terakhir: ${recentMeals.isEmpty ? 'belum ada' : recentMeals.join(', ')}
Budget biasa: ${prefs.budgetRange}
Pantangan: ${prefs.restrictions.isEmpty ? 'tidak ada' : prefs.restrictions.join(', ')}

Gunakan konteks di atas. Hindari menyarankan menu yang sama persis dengan
riwayat terakhir. Isi field context_used sesuai konteks yang benar-benar
kamu pakai untuk memutuskan.''';
  }

  String _resolveTimeOfDay(int hour) {
    if (hour < 10) return 'sarapan';
    if (hour < 15) return 'makan_siang';
    if (hour < 21) return 'makan_malam';
    return 'ngemil';
  }

  static const _systemInstruction =
      'Kamu Mapo, asisten yang membantu orang Indonesia memutuskan mau makan '
      'apa. Bicara santai, ramah, dan singkat. Kalau informasi dari user '
      'kurang, gunakan response_type "clarify" dengan quick_replies yang '
      'membantu. Selalu balas sesuai skema JSON.';
}
