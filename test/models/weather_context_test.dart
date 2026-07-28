import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/weather_context.dart';

void main() {
  test('unknown() menandai cuaca sebagai tidak diketahui', () {
    final w = WeatherContext.unknown();

    expect(w.isKnown, isFalse);
    expect(w.description, 'unknown');
    expect(w.temperature, 0);
  });
}
