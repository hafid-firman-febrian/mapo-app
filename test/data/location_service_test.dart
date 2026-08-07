import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
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

  test('GPS mati mengalahkan izin yang sudah diberikan', () {
    expect(
      resolvePermissionStatus(
        serviceEnabled: false,
        permission: LocationPermission.always,
      ),
      LocationPermissionStatus.serviceDisabled,
    );
  });

  test('whileInUse dianggap granted', () {
    expect(
      resolvePermissionStatus(
        serviceEnabled: true,
        permission: LocationPermission.whileInUse,
      ),
      LocationPermissionStatus.granted,
    );
  });

  test('deniedForever tetap denied', () {
    expect(
      resolvePermissionStatus(
        serviceEnabled: true,
        permission: LocationPermission.deniedForever,
      ),
      LocationPermissionStatus.denied,
    );
  });

  test('unableToDetermine dianggap denied, bukan granted', () {
    expect(
      resolvePermissionStatus(
        serviceEnabled: true,
        permission: LocationPermission.unableToDetermine,
      ),
      LocationPermissionStatus.denied,
    );
  });
}
