import 'package:geolocator/geolocator.dart';

/// Koordinat pengguna. `null` di jalur pemanggil berarti lokasi tidak tersedia.
typedef Coords = ({double lat, double lng});

class LocationDeniedException implements Exception {
  @override
  String toString() => 'LocationDeniedException: izin lokasi tidak diberikan';
}

class LocationService {
  /// Melempar [LocationDeniedException] kalau izin ditolak atau GPS mati.
  Future<Coords> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationDeniedException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationDeniedException();
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (lat: position.latitude, lng: position.longitude);
  }
}
