import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/weather_context.dart';

class WeatherService {
  final FirebaseFirestore _db;
  static const BASE_URL = 'https://api.openweathermap.org/data/2.5/weather';
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

      // [VERIFIKASI] endpoint & struktur respons Weather API
      final uri = Uri.parse(
        '$BASE_URL?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=id',
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

  Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> getCurrentCity() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    debugPrint(
      'latitude: ${position.latitude}, longitude: ${position.longitude}',
    );

    debugPrint(placemarks[0].toString());

    String? city = placemarks[0].locality;
    return city ?? '';
  }
}
