import 'package:geolocator/geolocator.dart';

/// Koordinat pengguna. `null` di jalur pemanggil berarti lokasi tidak tersedia.
typedef Coords = ({double lat, double lng});

class LocationDeniedException implements Exception {
  @override
  String toString() => 'LocationDeniedException: izin lokasi tidak diberikan';
}

enum LocationPermissionStatus { granted, denied, serviceDisabled }

/// Fungsi murni (bukan method) supaya bisa diuji tanpa Geolocator asli — pola
/// yang sama dengan `isCredentialConflict` di `auth_service.dart`.
///
/// GPS yang mati di level sistem mengalahkan izin apa pun: percuma izin sudah
/// `always` kalau layanan lokasinya sendiri tidak hidup.
LocationPermissionStatus resolvePermissionStatus({
  required bool serviceEnabled,
  required LocationPermission permission,
}) {
  if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

  return switch (permission) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocationPermissionStatus.granted,
    _ => LocationPermissionStatus.denied,
  };
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

  /// Hanya membaca — tidak pernah memicu dialog izin sistem. Memunculkan
  /// prompt izin dari halaman Pengaturan (di mana user cuma ingin melihat
  /// status) akan membingungkan.
  Future<LocationPermissionStatus> permissionStatus() async {
    return resolvePermissionStatus(
      serviceEnabled: await Geolocator.isLocationServiceEnabled(),
      permission: await Geolocator.checkPermission(),
    );
  }

  /// GPS mati butuh layar setelan yang berbeda dari izin yang ditolak —
  /// `openAppSettings()` tidak menolong sama sekali kalau GPS-nya yang mati.
  Future<void> openSettings(LocationPermissionStatus status) async {
    if (status == LocationPermissionStatus.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
