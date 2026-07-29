import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/weather_context.dart';

void main() {
  test('unknown() menandai cuaca sebagai tidak diketahui', () {
    final w = WeatherContext.unknown();

    expect(w.isKnown, isFalse);
    expect(w.description, 'unknown');
    expect(w.temperature, 0);
  });

  test('fromApi menerima suhu bulat (int) dari API', () {
    final w = WeatherContext.fromApi({
      'weather': [
        {'description': 'hujan ringan'},
      ],
      'main': {'temp': 28},
    });

    expect(w.temperature, 28.0);
    expect(w.description, 'hujan ringan');
    expect(w.isKnown, isTrue);
  });

  test('fromApi menerima suhu desimal', () {
    final w = WeatherContext.fromApi({
      'weather': [
        {'description': 'cerah berawan'},
      ],
      'main': {'temp': 31.4},
    });

    expect(w.temperature, 31.4);
  });

  test('fromApi tidak throw saat field hilang', () {
    final w = WeatherContext.fromApi({});

    expect(w.description, 'unknown');
    expect(w.temperature, 0);
  });

  test('fromApi menandai payload rusak sebagai tidak diketahui', () {
    expect(WeatherContext.fromApi({}).isKnown, isFalse);

    // Suhu ada, deskripsi hilang — tetap tidak diketahui.
    expect(
      WeatherContext.fromApi({
        'main': {'temp': 28},
      }).isKnown,
      isFalse,
    );

    // Deskripsi ada, suhu hilang — tetap tidak diketahui.
    expect(
      WeatherContext.fromApi({
        'weather': [
          {'description': 'hujan ringan'},
        ],
      }).isKnown,
      isFalse,
    );
  });

  test('fromCache menandai data tidak lengkap sebagai tidak diketahui', () {
    expect(WeatherContext.fromCache({}).isKnown, isFalse);
    expect(
      WeatherContext.fromCache({'description': 'hujan lebat'}).isKnown,
      isFalse,
    );
    expect(WeatherContext.fromCache({'temperature': 26}).isKnown, isFalse);
  });

  test('fromCache menerima suhu bulat dari Firestore', () {
    final w = WeatherContext.fromCache({
      'description': 'hujan lebat',
      'temperature': 26,
    });

    expect(w.temperature, 26.0);
    expect(w.description, 'hujan lebat');
    expect(w.isKnown, isTrue);
  });
}
