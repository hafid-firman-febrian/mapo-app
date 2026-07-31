import 'dart:convert';
import 'dart:developer';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import '../data/weather_service.dart';
import '../data/meal_history_service.dart';
import '../models/mapo_response.dart';
import '../models/weather_context.dart';
import '../models/user_prefs.dart';
import 'mapo_chat.dart';

class MapoRecommender {
  final WeatherService _weather;
  final MealHistoryService _history;
  final MapoChat _chat;
  final Duration _replyTimeout;

  MapoRecommender(
    this._weather,
    this._history,
    this._chat, {
    Duration replyTimeout = const Duration(seconds: 25),
    // ignore: prefer_initializing_formals
  }) : _replyTimeout = replyTimeout;

  /// [withContext] hanya `true` di turn pertama. [MapoChat] menyimpan riwayat
  /// sendiri, jadi mengirim ulang blok konteks tiap turn cuma buang token dan
  /// bikin model ragu konteks mana yang terbaru.
  Future<MapoResponse> reply({
    required String userId,
    required String userMessage,
    required bool withContext,
    double? lat,
    double? lng,
  }) async {
    final prompt = withContext
        ? '${await _contextBlock(userId: userId, lat: lat, lng: lng)}'
              '\n\nPesan user: "$userMessage"'
        : userMessage;

    final String? raw;
    try {
      raw = await _chat
          .send(prompt)
          .timeout(
            _replyTimeout,
            onTimeout: () =>
                throw MapoException('Mapo kelamaan mikir, coba lagi ya'),
          );
    } on QuotaExceeded {
      throw MapoException(
        'Mapo lagi kebanjiran request, coba lagi beberapa saat lagi ya',
      );
    }
    if (raw == null || raw.isEmpty) {
      throw MapoException('Respons kosong dari model');
    }

    try {
      return MapoResponse.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      throw MapoException('Format respons tidak valid');
    }
  }

  Future<String> _contextBlock({
    required String userId,
    double? lat,
    double? lng,
  }) async {
    final results = await Future.wait([
      (lat == null || lng == null)
          ? Future.value(WeatherContext.unknown())
          : _weather.getWeather(lat, lng),
      _history.getRecentMeals(userId),
      _history.getPreferences(userId),
    ]);

    final weather = results[0] as WeatherContext;
    final recentMeals = results[1] as List<String>;
    final prefs = results[2] as UserPrefs;
    log('WEATHER: ${results[0]}, ${weather.temperature}°C');
    debugPrint('WEATHER: ${weather.description}, ${weather.temperature}°C');
    debugPrint('RECENT MEALS: $recentMeals');
    debugPrint('PREFS: ${prefs.budgetRange}, ${prefs.restrictions}');

    return _buildContextBlock(
      weather: weather,
      recentMeals: recentMeals,
      prefs: prefs,
    );
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
}
