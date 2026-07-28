import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_context.dart';

class WeatherService {
  final FirebaseFirestore _db;
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const _apiKey = String.fromEnvironment('WEATHER_API_KEY');

  WeatherService(this._db);

  Future<WeatherContext> getWeather(double lat, double lng) async {
    final cacheKey = '${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';
    final cacheRef = _db.collection('weather_cache').doc(cacheKey);

    try {
      final cached = await cacheRef.get();
      if (cached.exists) {
        final data = cached.data()!;
        final fetchedAt = (data['fetched_at'] as Timestamp).toDate();
        if (DateTime.now().difference(fetchedAt).inMinutes < 45) {
          return WeatherContext.fromCache(data);
        }
      }

      final uri = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=id',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return WeatherContext.unknown();

      final weather = WeatherContext.fromApi(jsonDecode(res.body));
      await cacheRef.set({...weather.toCache(), 'fetched_at': Timestamp.now()});
      return weather;
    } catch (e) {
      debugPrint('Error getting weather: $e');
      // Cuaca gagal ≠ app mati
      return WeatherContext.unknown();
    }
  }
}
