import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/location_service.dart';

void main() {
  test('LocationDeniedException punya pesan yang bisa dibaca', () {
    expect(LocationDeniedException().toString(), contains('izin lokasi'));
  });

  test('Coords membawa lat dan lng', () {
    const Coords c = (lat: -6.2, lng: 106.8);

    expect(c.lat, -6.2);
    expect(c.lng, 106.8);
  });
}
