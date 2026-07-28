# Perbaikan Arsitektur Mapo — Implementation Plan

> **For agentic workers — mode penuh:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Mode per-task (default untuk plan ini):** kalau prompt yang masuk hanya menyebut satu task, jangan pakai kedua skill di atas — keduanya mengeksekusi seluruh plan tanpa berhenti. Kerjakan **hanya** task yang diminta, centang checkbox step-nya di file ini sambil jalan, perbarui tabel Status di bawah, lalu berhenti. Enam dari sembilan task diakhiri verifikasi manual di device yang hanya bisa dilakukan manusia — di situ tempat berhentinya.

## Status

Perbarui kolom ini setiap kali sebuah task selesai dan sudah diverifikasi.

| # | Task | Status | Butuh device? |
|---|------|--------|---------------|
| 1 | Analyzer & test harness | ✅ selesai | tidak (kecuali Step 7: cek model id — diverifikasi via docs Firebase AI Logic) |
| 2 | `WeatherContext` cast `num` | ✅ selesai | tidak |
| 3 | Pisahkan `LocationService` | 🟡 kode selesai, **Step 12 (verifikasi device) belum** | **ya** — Step 12 |
| 4 | Seam `MapoChat` | ⬜ belum | tidak |
| 5 | Multi-turn `ChatSession` | ⬜ belum | **ya** — Step 9 |
| 6 | Loop tulis `meal_history` | ⬜ belum | **ya** — Step 8 |
| 7 | Loop tulis `UserPrefs` | ⬜ belum | **ya** — Step 12 |
| 8 | `firestore.rules` | ⬜ belum | **ya** — Step 5 |
| 9 | Cloud Function cuaca | ⬜ belum | **ya** — Step 11 |

**Goal:** Menutup tiga celah arsitektural di Mapo — percakapan yang tidak punya riwayat, loop data yang hanya bisa membaca tanpa pernah menulis, dan kunci API cuaca yang tertanam di binary klien — tanpa mengubah susunan folder yang sudah benar.

**Architecture:** Struktur layer saat ini (`data/` → `domain/` → `providers/` → `ui/`) dipertahankan. Yang berubah: (1) `MapoRecommender` bicara ke model lewat satu abstraksi `MapoChat` yang menyimpan `ChatSession`, sehingga percakapan punya riwayat dan domain bisa diuji tanpa Firebase; (2) `ChatNotifier` menyimpan `List<ChatTurn>` (sealed class) alih-alih satu response, sehingga status loading/error tidak lagi menghapus isi layar; (3) geolokasi dipindah ke `LocationService` sendiri, keluar dari `WeatherService`; (4) jalur tulis Firestore (`saveMeal`, `savePreferences`) disambungkan ke UI; (5) fetch cuaca dipindah ke Cloud Function di task terakhir.

**Tech Stack:** Flutter (Dart SDK ^3.12.2), flutter_riverpod ^3.3.2, firebase_ai ^3.14.1, cloud_firestore ^6.7.1, firebase_auth ^6.5.6, geolocator ^14.0.3, http ^1.6.0, flutter_test.

## Global Constraints

- Jangan mengubah susunan folder `lib/data`, `lib/domain`, `lib/models`, `lib/providers`, `lib/ui`. Struktur ini sudah proporsional untuk ~900 LOC.
- Jangan menambahkan interface abstrak untuk `WeatherService`, `MealHistoryService`, atau `LocationService`. Ketiganya sudah bisa dipalsukan dengan `implements` karena field-nya privat. Satu-satunya interface baru yang dibenarkan adalah `MapoChat` (Task 4) — `GenerativeModel` adalah `final class` di firebase_ai 3.14.1 sehingga tidak bisa disubclass atau di-mock.
- Semua string yang dilihat pengguna dalam bahasa Indonesia, gaya santai, konsisten dengan `_systemInstruction` di `lib/domain/mapo_recommender.dart:103-107`.
- Setiap cast dari JSON/Firestore ke angka harus lewat `num` lalu `.toDouble()`/`.toInt()`. Firestore dan OpenWeather mengirim `28` (int) untuk nilai bulat; `as double` akan throw.
- Nama field Firestore memakai `snake_case` (`eaten_at`, `budget_range`, `fetched_at`, `price_estimate`) — sudah dipakai di kode yang ada, jangan diubah.
- Semua enum value di `lib/domain/mapo_schema.dart` harus tetap cocok dengan default di `Recommendation.fromJson` (`lib/models/mapo_response.dart:67-77`).
- `flutter analyze` harus bersih untuk `lib/` dan `test/` sebelum setiap commit.
- Commit per task, format Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `chore:`).

**Urutan task ini berbasis dependensi, bukan prioritas bisnis.** Task 1 harus lebih dulu karena tanpanya perintah verifikasi di semua task lain tenggelam di ~397 error palsu. Task 4 harus sebelum Task 5. Task 6–7 butuh UI dari Task 5.

---

### Task 1: Bikin `flutter analyze` dan `flutter test` bisa dipakai

Saat ini `flutter analyze` melaporkan **399 issue**, dan 397 di antaranya berasal dari `build/ios/SourcePackages/` — source SwiftPM vendored yang ikut dipindai. Selama ini masih begitu, tidak ada task berikutnya yang punya sinyal verifikasi yang bisa dipercaya. Task ini juga memverifikasi model id yang masih ditandai `[VERIFIKASI]` di kode.

**Files:**
- Modify: `analysis_options.yaml:11` (tambah blok `analyzer:` sebelum blok `linter:`)
- Create: `test/models/weather_context_test.dart`

**Interfaces:**
- Consumes: —
- Produces: `flutter analyze` yang hanya melaporkan `lib/` + `test/`; direktori `test/` yang sudah terbukti jalan.

- [x] **Step 1: Catat baseline jumlah issue**

Run: `flutter analyze 2>&1 | tail -1`
Catat angkanya (saat plan ini ditulis: `399 issues found.`).

- [x] **Step 2: Kecualikan `build/` dari analyzer**

Di `analysis_options.yaml`, sisipkan blok ini tepat setelah baris `include: package:flutter_lints/flutter.yaml` dan sebelum `linter:`:

```yaml
analyzer:
  exclude:
    - build/**
```

- [x] **Step 3: Jalankan analyze, pastikan tinggal issue milik `lib/`** (hasil: 7 sebelum Step 5, bukan ~6 — App Check deprecated warning ternyata 2 baris bukan 1; sudah cocok setelah Step 5)

Run: `flutter analyze 2>&1 | tail -12`

Expected: jumlah issue turun drastis (dari 399 ke sekitar 6). Yang tersisa harus hanya ini, dan semuanya akan dibereskan di task-task berikut:
- `lib/data/weather_service.dart:11` — `BASE_URL` bukan lowerCamelCase (Task 3)
- `lib/data/weather_service.dart:53` dan `:65` — `desiredAccuracy` deprecated (Task 3)
- `lib/main.dart:16` dan `:19` — `androidProvider`/`appleProvider` deprecated (Step 5 di task ini)
- `lib/models/weather_context.dart:23` — `invalid_null_aware_operator` (Task 2)
- `lib/ui/chat_screen.dart:23` — `_getLocation` tidak dipakai (Task 3)

- [x] **Step 4: Buat test pertama untuk membuktikan `test/` berfungsi**

Buat `test/models/weather_context_test.dart`:

```dart
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
```

- [x] **Step 5: Ganti parameter App Check yang deprecated**

**Koreksi terhadap plan tertulis:** `providerAndroid`/`providerApple` di firebase_app_check 0.4.5+2 menerima tipe `AndroidAppCheckProvider`/`AppleAppCheckProvider` (class), **bukan** enum `AndroidProvider`/`AppleProvider` — kode contoh di plan ini tidak kompak dengan versi package yang terpasang. Implementasi sebenarnya:

```dart
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? AppleDebugProvider() : AppleAppAttestProvider(),
  );
```

- [x] **Step 6: Jalankan test dan analyze** (1 test PASS, 5 issues tersisa — persis daftar yang diharapkan untuk Task 2 & 3)

- [x] **Step 7: Verifikasi model id `gemini-3.5-flash-lite`**

`lib/domain/mapo_recommender.dart:18-20` masih menyimpan penanda `[VERIFIKASI]` dan dua kandidat model id. **Jangan mengarang id.** Buka daftar model Firebase AI Logic yang berlaku (Firebase Console → AI Logic, atau dokumentasi resmi Gemini API), lalu:
- Kalau `gemini-3.5-flash-lite` ada di daftar → hapus baris komentar `// [VERIFIKASI]` dan `// model: 'gemini-flash-latest',` di baris 18-19.
- Kalau tidak ada → ganti ke id yang ada di daftar, lalu hapus kedua baris komentar itu.

Diverifikasi via dokumentasi resmi Firebase AI Logic (firebase.google.com/docs/ai-logic/models): `gemini-3.5-flash-lite` ada di daftar model stabil ("latest stable Flash-Lite model"). Kedua baris komentar `[VERIFIKASI]` dihapus dari `lib/domain/mapo_recommender.dart`.

- [x] **Step 8: Commit**

```bash
git add analysis_options.yaml lib/main.dart test/models/weather_context_test.dart lib/domain/mapo_recommender.dart
git commit -m "chore: exclude build/ from analyzer, add test harness, verify model id"
```

---

### Task 2: `WeatherContext` gagal parsing suhu bulat

`WeatherContext.fromApi` (`lib/models/weather_context.dart:23`) melakukan `json['main']['temp'] as double`, dan `fromCache` (`:30`) melakukan `data['temperature'] as double`. Ketika OpenWeather atau Firestore mengirim suhu bulat, JSON-nya `28` (int), bukan `28.0` — cast itu throw. Throw-nya tertangkap `catch` di `WeatherService.getWeather` (`lib/data/weather_service.dart:40-44`) yang mengembalikan `WeatherContext.unknown()`, jadi cuaca hilang tanpa jejak dan seluruh nilai jual "context-aware" mati diam-diam.

**Files:**
- Modify: `lib/models/weather_context.dart:20-33`
- Test: `test/models/weather_context_test.dart`

**Interfaces:**
- Consumes: `WeatherContext.unknown()` (sudah ada)
- Produces: `WeatherContext.fromApi(Map<String, dynamic>)` dan `WeatherContext.fromCache(Map<String, dynamic>)` yang tidak pernah throw dan tidak pernah mengembalikan `null`.

- [x] **Step 1: Tulis test yang gagal**

Tambahkan ke `test/models/weather_context_test.dart`, di dalam `void main() { ... }` setelah test yang sudah ada:

```dart
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

  test('fromCache menerima suhu bulat dari Firestore', () {
    final w = WeatherContext.fromCache({
      'description': 'hujan lebat',
      'temperature': 26,
    });

    expect(w.temperature, 26.0);
    expect(w.description, 'hujan lebat');
    expect(w.isKnown, isTrue);
  });
```

- [x] **Step 2: Jalankan test untuk memastikan gagal**

Run: `flutter test test/models/weather_context_test.dart`

Expected: FAIL. `fromApi menerima suhu bulat (int) dari API` dan `fromCache menerima suhu bulat dari Firestore` gagal dengan `type 'int' is not a subtype of type 'double' in type cast`. `fromApi tidak throw saat field hilang` gagal dengan `NoSuchMethodError` pada `null`.

- [x] **Step 3: Tulis implementasi minimal**

Ganti kedua factory di `lib/models/weather_context.dart` (baris 20-33) dengan:

```dart
  factory WeatherContext.fromApi(Map<String, dynamic> json) {
    final entries = json['weather'] as List?;
    final first = (entries == null || entries.isEmpty)
        ? null
        : entries.first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>?;

    return WeatherContext(
      description: first?['description'] as String? ?? 'unknown',
      temperature: (main?['temp'] as num?)?.toDouble() ?? 0,
    );
  }

  factory WeatherContext.fromCache(Map<String, dynamic> data) {
    return WeatherContext(
      description: data['description'] as String? ?? 'unknown',
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0,
    );
  }
```

- [x] **Step 4: Jalankan test dan analyze**

Run: `flutter test test/models/weather_context_test.dart && flutter analyze 2>&1 | tail -8`

Expected: 5 test PASS. Warning `invalid_null_aware_operator` di `lib/models/weather_context.dart:23` hilang.

- [x] **Step 5: Commit**

```bash
git add lib/models/weather_context.dart test/models/weather_context_test.dart
git commit -m "fix: parse suhu int dari API dan cache tanpa throw"
```

---

### Task 3: Pisahkan geolokasi dari `WeatherService`, sambungkan ke UI

Tiga masalah bertumpuk di sini. Pertama, `_getLocation()` di `lib/ui/chat_screen.dart:23` **tidak pernah dipanggil**, jadi `_lat`/`_lng` selalu `0,0` — koordinat di Teluk Guinea — di setiap request. Kedua, widget itu meng-instansiasi `WeatherService(FirebaseFirestore.instance)` langsung, melewati `weatherServiceProvider` yang sudah ada di `lib/providers/mapo_providers.dart:12`. Ketiga, geolokasi bukan tanggung jawab `WeatherService`; `getCurrentPosition()` dan `getCurrentCity()` menumpang di kelas yang salah, dan `getCurrentCity()` tidak dipakai sama sekali.

Setelah task ini, koordinat bertipe *nullable* sepanjang jalur: izin lokasi ditolak adalah keadaan normal, bukan error. Cuaca akan jadi `unknown()` dan app tetap jalan.

**Files:**
- Create: `lib/data/location_service.dart`
- Modify: `lib/data/weather_service.dart:1-14` (buang import geocoding/geolocator, ganti `BASE_URL` → `_baseUrl`) dan hapus baris 47-81
- Modify: `lib/providers/mapo_providers.dart:9-18` (tambah `locationServiceProvider`, `coordsProvider`)
- Modify: `lib/ui/chat_screen.dart:16-37` (hapus `_getLocation`, `_lat`, `_lng`; `_send` tidak lagi mengirim koordinat)
- Modify: `lib/domain/mapo_recommender.dart:30-54` (lat/lng jadi nullable)
- Modify: `pubspec.yaml:44` (hapus `geocoding`)
- Modify: `ios/Runner/Info.plist` (tambah `NSLocationWhenInUseUsageDescription`)
- Test: `test/data/location_service_test.dart`

**Interfaces:**
- Consumes: `WeatherContext.unknown()` (Task 2), `weatherServiceProvider` (sudah ada)
- Produces:
  - `class LocationDeniedException implements Exception`
  - `class LocationService { Future<Coords> current(); }`
  - `typedef Coords = ({double lat, double lng});`
  - `final locationServiceProvider = Provider<LocationService>`
  - `final coordsProvider = FutureProvider<Coords?>` — `null` berarti lokasi tidak tersedia, bukan error
  - `MapoRecommender.getRecommendation({required String userId, required String userMessage, double? lat, double? lng})`

- [x] **Step 1: Tulis test yang gagal**

Buat `test/data/location_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/location_service.dart';

void main() {
  test('LocationDeniedException punya pesan yang bisa dibaca', () {
    expect(
      LocationDeniedException().toString(),
      contains('izin lokasi'),
    );
  });

  test('Coords membawa lat dan lng', () {
    const Coords c = (lat: -6.2, lng: 106.8);

    expect(c.lat, -6.2);
    expect(c.lng, 106.8);
  });
}
```

Catatan: `LocationService.current()` memanggil `Geolocator` yang butuh platform channel, jadi tidak diuji unit di sini — hanya kontrak tipe dan exception-nya. Perilaku sebenarnya diverifikasi manual di Step 8.

- [x] **Step 2: Jalankan test untuk memastikan gagal**

Run: `flutter test test/data/location_service_test.dart`

Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/data/location_service.dart'`.

- [x] **Step 3: Buat `LocationService`**

Buat `lib/data/location_service.dart`:

```dart
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
```

- [x] **Step 4: Jalankan test untuk memastikan lulus**

Run: `flutter test test/data/location_service_test.dart`

Expected: 2 test PASS.

- [x] **Step 5: Bersihkan `WeatherService`**

Di `lib/data/weather_service.dart`:

Hapus dua import ini dari baris 4-5:

```dart
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
```

Ganti baris 11 (`BASE_URL` melanggar lint `constant_identifier_names`) dan sesuaikan pemakaiannya di baris 32:

```dart
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
```

```dart
      final uri = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=id',
      );
```

Hapus seluruh method `getCurrentPosition()` (baris 47-55) dan `getCurrentCity()` (baris 57-81). Yang tersisa di kelas itu hanya `getWeather()`.

Hapus juga baris komentar `// [VERIFIKASI] endpoint & struktur respons Weather API` di baris 30 — endpoint dan struktur respons sudah diverifikasi oleh test di Task 2.

- [x] **Step 6: Buang dependensi `geocoding`**

`geocoding` hanya dipakai oleh `getCurrentCity()` yang baru saja dihapus.

Run: `flutter pub remove geocoding`

- [x] **Step 7: Tambah provider lokasi**

Di `lib/providers/mapo_providers.dart`, tambahkan import:

```dart
import '../data/location_service.dart';
```

Lalu tambahkan di bawah blok `// ── Data layer ──` (setelah `mealHistoryProvider`, baris 18):

```dart
final locationServiceProvider = Provider((ref) => LocationService());

/// `null` = lokasi tidak tersedia (izin ditolak / GPS mati / timeout).
/// Ini keadaan normal, bukan error — cuaca tinggal jadi unknown.
final coordsProvider = FutureProvider<Coords?>((ref) async {
  try {
    return await ref.watch(locationServiceProvider).current();
  } catch (_) {
    return null;
  }
});
```

- [x] **Step 8: Bikin lat/lng nullable di recommender**

Di `lib/domain/mapo_recommender.dart`, ubah signature `getRecommendation` (baris 30-35) dan pengumpulan konteks (baris 37-48):

```dart
  Future<MapoResponse> getRecommendation({
    required String userId,
    required String userMessage,
    double? lat,
    double? lng,
  }) async {
    // Kumpulkan konteks PARALEL — bukan berurutan
    final results = await Future.wait([
      (lat == null || lng == null)
          ? Future.value(WeatherContext.unknown())
          : _weather.getWeather(lat, lng),
      _history.getRecentMeals(userId),
      _history.getPreferences(userId),
    ]);
```

Sisa method (baris 43 ke bawah) tidak berubah.

- [x] **Step 9: Sambungkan di UI dan hapus kode mati**

Di `lib/ui/chat_screen.dart`, hapus import `cloud_firestore` (baris 1) dan `weather_service` (baris 4). Ganti isi `_ChatScreenState` bagian atas (baris 16-37) dengan:

```dart
class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    final coords = await ref.read(coordsProvider.future);
    await ref
        .read(chatProvider.notifier)
        .ask(text, lat: coords?.lat, lng: coords?.lng);
  }
```

`_send` sekarang `Future<void>`, bukan `void`, jadi kedua widget yang menerimanya harus ikut berubah tipe. Di `class _ResponseView`, ganti deklarasi field-nya:

```dart
  final Future<void> Function(String) onQuickReply;
```

Dan di `class _InputBar`:

```dart
  final Future<void> Function(String) onSend;
```

Dan di `mapo_providers.dart`, `ChatNotifier.ask` sudah menerima `lat`/`lng` sebagai `required double` — ubah jadi nullable:

```dart
  Future<void> ask(
    String message, {
    double? lat,
    double? lng,
  }) async {
```

- [x] **Step 10: Jalankan analyze dan seluruh test**

Run: `flutter analyze && flutter test`

Expected: analyze bersih (`No issues found!`). Semua test PASS. Warning `_getLocation isn't referenced`, `BASE_URL isn't lowerCamelCase`, dan dua `desiredAccuracy is deprecated` semuanya hilang.

- [x] **Step 11: Deklarasikan izin lokasi iOS**

`android/app/src/main/AndroidManifest.xml:2-3` sudah punya `ACCESS_FINE_LOCATION` dan `ACCESS_COARSE_LOCATION`, tapi `ios/Runner/Info.plist` **tidak punya entri `NSLocation*` sama sekali**. Tanpa itu, `Geolocator.requestPermission()` di iOS langsung mengembalikan `denied` tanpa pernah memunculkan dialog — Step 12 akan selalu gagal di iOS dan penyebabnya tidak kelihatan dari kode Dart.

Di `ios/Runner/Info.plist`, tambahkan dua entri ini di dalam `<dict>` teratas (sejajar dengan key lain seperti `CFBundleName`):

```xml
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>Mapo pakai lokasi kamu untuk tahu cuaca di sekitar, biar saran menunya nyambung.</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>Mapo pakai lokasi kamu untuk tahu cuaca di sekitar, biar saran menunya nyambung.</string>
```

Verifikasi entri terbaca dan plist masih valid:

Run: `plutil -p ios/Runner/Info.plist | grep NSLocation`

Expected: kedua key muncul beserta teksnya. Kalau `plutil` melaporkan error parsing, XML-nya rusak — perbaiki dulu sebelum lanjut.

- [ ] **Step 12: Verifikasi manual di device**

Run: `flutter run --dart-define=WEATHER_API_KEY=<kunci_openweather_kamu>`

Kirim satu pesan. Di log, cari baris `WEATHER:` dari `debugPrint` di `lib/domain/mapo_recommender.dart:44`.

Expected: deskripsi cuaca kota kamu yang sebenarnya (mis. `WEATHER: awan tersebar, 30°C`), **bukan** cuaca Teluk Guinea dan bukan `unknown`. Kalau dialog izin lokasi muncul lalu kamu tolak, app harus tetap membalas dengan `WEATHER: unknown, 0°C` tanpa crash.

- [x] **Step 13: Commit**

```bash
git add lib/data/location_service.dart lib/data/weather_service.dart lib/providers/mapo_providers.dart lib/ui/chat_screen.dart lib/domain/mapo_recommender.dart test/data/location_service_test.dart ios/Runner/Info.plist pubspec.yaml pubspec.lock
git commit -m "refactor: pisahkan LocationService dari WeatherService dan sambungkan ke UI"
```

---

### Task 4: Seam `MapoChat` supaya domain bisa diuji

`MapoRecommender` membangun `GenerativeModel` sendiri di initializer list (`lib/domain/mapo_recommender.dart:16-28`), dan `GenerativeModel` adalah `final class` di firebase_ai 3.14.1 — tidak bisa disubclass, tidak bisa di-mock. Akibatnya seluruh logika domain (perakitan konteks, parsing respons, penanganan respons kosong) tidak bisa diuji tanpa memanggil Gemini sungguhan.

Task ini memasukkan satu interface tipis yang juga menjadi tempat `ChatSession` disimpan di Task 5. **Perilaku belum berubah** — masih one-shot. Ini murni refactor dengan test sebagai jaring.

**Files:**
- Create: `lib/domain/mapo_chat.dart`
- Modify: `lib/domain/mapo_recommender.dart:1-28` (terima `MapoChat`, buang konstruksi model)
- Modify: `lib/providers/mapo_providers.dart:20-26` (pindahkan konstruksi model ke provider)
- Test: `test/domain/mapo_recommender_test.dart`

**Interfaces:**
- Consumes: `MapoRecommender.getRecommendation({required String userId, required String userMessage, double? lat, double? lng})` (Task 3), `mapoResponseSchema` (`lib/domain/mapo_schema.dart:33`)
- Produces:
  - `abstract interface class MapoChat { Future<String?> send(String text); }`
  - `class FirebaseMapoChat implements MapoChat` — membungkus `ChatSession`
  - `final generativeModelProvider = Provider<GenerativeModel>`
  - `final mapoChatProvider = Provider<MapoChat>`
  - `MapoRecommender(WeatherService, MealHistoryService, MapoChat)` — urutan argumen posisional

- [ ] **Step 1: Tulis test yang gagal**

Buat `test/domain/mapo_recommender_test.dart`:

```dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/meal_history_service.dart';
import 'package:mapo_app/data/weather_service.dart';
import 'package:mapo_app/domain/mapo_chat.dart';
import 'package:mapo_app/domain/mapo_recommender.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/models/user_prefs.dart';
import 'package:mapo_app/models/weather_context.dart';

/// `implements` cukup: field `_db` privat, jadi bukan bagian dari interface publik.
///
/// PENTING: `implements` mewajibkan SEMUA member publik diimplementasikan.
/// Setiap kali kamu menambah method publik ke service aslinya, fake ini harus
/// ikut ditambah atau seluruh file test gagal compile. Task 7 melakukan ini.
class FakeWeatherService implements WeatherService {
  final WeatherContext result;
  final calls = <String>[];

  FakeWeatherService([WeatherContext? result])
    : result = result ?? WeatherContext.unknown();

  @override
  Future<WeatherContext> getWeather(double lat, double lng) async {
    calls.add('$lat,$lng');
    return result;
  }
}

class FakeMealHistory implements MealHistoryService {
  final List<String> recent;
  final UserPrefs prefs;
  final saved = <Map<String, String>>[];

  FakeMealHistory({this.recent = const [], UserPrefs? prefs})
    : prefs = prefs ?? const UserPrefs();

  @override
  Future<List<String>> getRecentMeals(String userId, {int limit = 3}) async =>
      recent;

  @override
  Future<UserPrefs> getPreferences(String userId) async => prefs;

  @override
  Future<void> saveMeal(String userId, String name, String category) async {
    saved.add({'name': name, 'category': category});
  }
}

class FakeMapoChat implements MapoChat {
  final String? reply;
  final prompts = <String>[];

  FakeMapoChat(this.reply);

  @override
  Future<String?> send(String text) async {
    prompts.add(text);
    return reply;
  }
}

String jsonReply({String name = 'Soto Ayam'}) => jsonEncode({
  'response_type': 'single',
  'message': 'Cuaca dingin nih, cocok yang berkuah.',
  'recommendations': [
    {
      'name': name,
      'reason': 'Anget, pas buat hujan',
      'category': 'berkuah',
      'price_estimate': 18000,
      'spice_level': 'sedang',
      'prep_time': 'cepat',
      'tags': ['hangat'],
    },
  ],
});

void main() {
  test('konteks cuaca dan riwayat masuk ke prompt', () async {
    final chat = FakeMapoChat(jsonReply());
    final recommender = MapoRecommender(
      FakeWeatherService(
        WeatherContext(description: 'hujan ringan', temperature: 24),
      ),
      FakeMealHistory(recent: ['Nasi Goreng', 'Mie Ayam']),
      chat,
    );

    await recommender.getRecommendation(
      userId: 'u1',
      userMessage: 'laper',
      lat: -6.2,
      lng: 106.8,
    );

    expect(chat.prompts.single, contains('hujan ringan'));
    expect(chat.prompts.single, contains('24°C'));
    expect(chat.prompts.single, contains('Nasi Goreng, Mie Ayam'));
    expect(chat.prompts.single, contains('laper'));
  });

  test('lat/lng null melewatkan panggilan cuaca', () async {
    final weather = FakeWeatherService();
    final recommender = MapoRecommender(
      weather,
      FakeMealHistory(),
      FakeMapoChat(jsonReply()),
    );

    await recommender.getRecommendation(userId: 'u1', userMessage: 'laper');

    expect(weather.calls, isEmpty);
  });

  test('respons diparsing jadi MapoResponse', () async {
    final recommender = MapoRecommender(
      FakeWeatherService(),
      FakeMealHistory(),
      FakeMapoChat(jsonReply(name: 'Bakso')),
    );

    final result = await recommender.getRecommendation(
      userId: 'u1',
      userMessage: 'laper',
    );

    expect(result.responseType, ResponseType.single);
    expect(result.recommendations.single.name, 'Bakso');
    expect(result.recommendations.single.priceEstimate, 18000);
  });

  test('respons kosong melempar MapoException', () async {
    final recommender = MapoRecommender(
      FakeWeatherService(),
      FakeMealHistory(),
      FakeMapoChat(null),
    );

    expect(
      () => recommender.getRecommendation(userId: 'u1', userMessage: 'laper'),
      throwsA(isA<MapoException>()),
    );
  });

  test('JSON rusak melempar MapoException', () async {
    final recommender = MapoRecommender(
      FakeWeatherService(),
      FakeMealHistory(),
      FakeMapoChat('{ ini bukan json'),
    );

    expect(
      () => recommender.getRecommendation(userId: 'u1', userMessage: 'laper'),
      throwsA(isA<MapoException>()),
    );
  });
}
```

Catatan: import `cloud_firestore` dipakai secara implisit oleh tipe `WeatherService`/`MealHistoryService`; kalau `flutter analyze` melaporkannya sebagai unused, hapus import itu.

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

Run: `flutter test test/domain/mapo_recommender_test.dart`

Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/domain/mapo_chat.dart'` dan `MapoRecommender` tidak menerima 3 argumen posisional.

- [ ] **Step 3: Buat abstraksi `MapoChat`**

Buat `lib/domain/mapo_chat.dart`:

```dart
import 'package:firebase_ai/firebase_ai.dart';

/// Satu-satunya interface abstrak di proyek ini, dan alasannya spesifik:
/// [GenerativeModel] adalah `final class` sehingga tidak bisa disubclass atau
/// di-mock. Tanpa seam ini, logika domain tidak bisa diuji tanpa memanggil
/// Gemini sungguhan.
abstract interface class MapoChat {
  /// Mengirim [text] dan mengembalikan teks respons mentah, atau `null`
  /// kalau model tidak mengembalikan kandidat apa pun.
  Future<String?> send(String text);
}

class FirebaseMapoChat implements MapoChat {
  final ChatSession _session;

  FirebaseMapoChat(this._session);

  @override
  Future<String?> send(String text) async {
    final response = await _session.sendMessage(Content.text(text));
    return response.text;
  }
}
```

- [ ] **Step 4: Terima `MapoChat` di recommender**

Di `lib/domain/mapo_recommender.dart`, ganti import dan bagian atas kelas (baris 1-28) dengan:

```dart
import 'dart:convert';
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

  MapoRecommender(this._weather, this._history, this._chat);
```

Import `firebase_ai` dan `mapo_schema` dihapus dari file ini — keduanya pindah ke provider.

Lalu ganti pemanggilan model (baris 56-58) jadi:

```dart
    final raw = await _chat.send('$contextBlock\n\nPesan user: "$userMessage"');
```

Dan hapus baris 60 (`final raw = response.text;`) karena `raw` sekarang sudah terisi di atas.

`_systemInstruction` (baris 103-107) tetap di kelas ini untuk sekarang; Step 5 memindahkannya.

- [ ] **Step 5: Pindahkan konstruksi model ke provider**

Pindahkan `_systemInstruction` dari `lib/domain/mapo_recommender.dart` (hapus baris 103-107 dari kelas itu) ke `lib/providers/mapo_providers.dart`.

Di `lib/providers/mapo_providers.dart`, tambahkan import:

```dart
import 'package:firebase_ai/firebase_ai.dart';
import '../domain/mapo_chat.dart';
import '../domain/mapo_schema.dart';
```

Ganti blok `// ── Domain layer ──` (baris 20-26) dengan:

```dart
// ── Domain layer ──────────────────────────────────────────
const _systemInstruction =
    'Kamu Mapo, asisten yang membantu orang Indonesia memutuskan mau makan '
    'apa. Bicara santai, ramah, dan singkat. Kalau informasi dari user '
    'kurang, gunakan response_type "clarify" dengan quick_replies yang '
    'membantu. Selalu balas sesuai skema JSON.';

final generativeModelProvider = Provider<GenerativeModel>(
  (ref) => FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash-lite',
    systemInstruction: Content.text(_systemInstruction),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: mapoResponseSchema,
      temperature: 0.7,
    ),
  ),
);

final mapoChatProvider = Provider<MapoChat>(
  (ref) => FirebaseMapoChat(ref.watch(generativeModelProvider).startChat()),
);

final recommenderProvider = Provider(
  (ref) => MapoRecommender(
    ref.watch(weatherServiceProvider),
    ref.watch(mealHistoryProvider),
    ref.watch(mapoChatProvider),
  ),
);
```

**Penting:** pakai model id yang sudah kamu verifikasi di Task 1 Step 7, bukan yang tertulis di atas kalau berbeda.

`ChatSession.sendMessage` meneruskan `generationConfig` dari `startChat()` yang default `null`, dan `GenerativeModel.generateContent` melakukan `generationConfig ?? _generationConfig` — jadi `responseSchema` dari model tetap berlaku di mode chat. Tidak perlu mengulang config di `startChat()`.

- [ ] **Step 6: Jalankan test dan analyze**

Run: `flutter test && flutter analyze`

Expected: 5 test baru di `test/domain/mapo_recommender_test.dart` PASS, seluruh test lain tetap PASS, analyze bersih.

- [ ] **Step 7: Commit**

```bash
git add lib/domain/mapo_chat.dart lib/domain/mapo_recommender.dart lib/providers/mapo_providers.dart test/domain/mapo_recommender_test.dart
git commit -m "refactor: inject MapoChat ke recommender agar domain bisa diuji"
```

---

### Task 5: Percakapan multi-turn — `clarify` dan `quick_replies` akhirnya berfungsi

Ini task terbesar dan inti dari perbaikan. Tiga hal saling terkait:

1. `MapoRecommender` memakai `generateContent()` one-shot, jadi model tidak punya riwayat. Ketika model membalas `response_type: 'clarify'` dengan pertanyaan "mau berkuah atau goreng?" dan pengguna menekan quick reply "berkuah", request berikutnya terkirim **tanpa** pertanyaan itu — model tidak tahu ia baru saja bertanya apa. Fitur `clarify` yang sudah ada di skema (`lib/domain/mapo_schema.dart:35-49`) dan sudah dirender di UI (`lib/ui/chat_screen.dart:89-105`) mustahil bekerja.
2. `ChatNotifier` menyimpan satu `MapoResponse?`, jadi tidak ada riwayat yang bisa ditampilkan.
3. `state = const AsyncValue.loading()` (`lib/providers/mapo_providers.dart:58`) **mengosongkan layar** setiap kali pengguna mengirim pesan. Ini kenapa `AsyncNotifier` diganti `Notifier` di task ini: status pending dimodelkan sebagai satu turn di dalam daftar, bukan sebagai state pengganti seluruh daftar.

`authProvider` (`lib/providers/mapo_providers.dart:29-31`) juga dibereskan di sini. Sekarang ia dideklarasikan tapi tidak dipakai — `ChatNotifier` membaca `FirebaseAuth.instance` langsung di baris 48 dengan versi provider dikomentari di baris 47, yang membuat notifier tidak bisa dites.

Konteks (cuaca, riwayat, prefs) hanya dikirim di **turn pertama**. `ChatSession` sudah menyimpan riwayat di sisi klien dan mengirimnya ulang setiap request, jadi menempelkan blok konteks di setiap turn hanya menghabiskan token dan membuat model bingung soal konteks mana yang terbaru.

**Files:**
- Create: `lib/models/chat_turn.dart`
- Modify: `lib/domain/mapo_recommender.dart:30-70` (`getRecommendation` → `reply` dengan flag `withContext`)
- Modify: `lib/providers/mapo_providers.dart:28-70` (auth provider, `ChatNotifier` jadi `Notifier<List<ChatTurn>>`)
- Modify: `lib/ui/chat_screen.dart` (rewrite jadi daftar pesan)
- Test: `test/providers/chat_notifier_test.dart`, `test/domain/mapo_recommender_test.dart` (sesuaikan nama method)

**Interfaces:**
- Consumes: `MapoChat.send(String)` (Task 4), `coordsProvider` (Task 3), `mapoChatProvider`, `recommenderProvider` (Task 4)
- Produces:
  - `sealed class ChatTurn`, dengan subclass `UserTurn(String text)`, `MapoTurn(MapoResponse response)`, `PendingTurn()`, `ErrorTurn(String message)`
  - `MapoRecommender.reply({required String userId, required String userMessage, required bool withContext, double? lat, double? lng}) → Future<MapoResponse>`
  - `final firebaseAuthProvider = Provider<FirebaseAuth>`
  - `final authStateProvider = StreamProvider<User?>` (mengganti nama `authProvider`)
  - `final currentUserIdProvider = Provider<String?>`
  - `final chatProvider = NotifierProvider<ChatNotifier, List<ChatTurn>>`
  - `ChatNotifier.ask(String message, {double? lat, double? lng}) → Future<void>`

- [ ] **Step 1: Tulis test yang gagal**

Buat `test/providers/chat_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/domain/mapo_chat.dart';
import 'package:mapo_app/models/chat_turn.dart';
import 'package:mapo_app/providers/mapo_providers.dart';

import '../domain/mapo_recommender_test.dart' show FakeMapoChat, jsonReply;

void main() {
  ProviderContainer makeContainer({
    required MapoChat chat,
    String? userId = 'u1',
  }) {
    return ProviderContainer.test(
      overrides: [
        mapoChatProvider.overrideWithValue(chat),
        currentUserIdProvider.overrideWithValue(userId),
        weatherServiceProvider.overrideWithValue(FakeWeatherService()),
        mealHistoryProvider.overrideWithValue(FakeMealHistory()),
      ],
    );
  }

  // Catatan: `coordsProvider` tidak perlu di-override. `ChatNotifier.ask`
  // menerima lat/lng sebagai parameter — yang membaca `coordsProvider` adalah
  // `ChatScreen`, bukan notifier-nya.

  test('mulai dengan daftar turn kosong', () {
    final container = makeContainer(chat: FakeMapoChat(jsonReply()));

    expect(container.read(chatProvider), isEmpty);
  });

  test('ask menambahkan UserTurn lalu MapoTurn', () async {
    final container = makeContainer(chat: FakeMapoChat(jsonReply()));

    await container.read(chatProvider.notifier).ask('laper');

    final turns = container.read(chatProvider);
    expect(turns, hasLength(2));
    expect((turns[0] as UserTurn).text, 'laper');
    expect((turns[1] as MapoTurn).response.recommendations.single.name,
        'Soto Ayam');
  });

  test('riwayat turn tidak hilang saat request kedua', () async {
    final chat = FakeMapoChat(jsonReply());
    final container = makeContainer(chat: chat);

    await container.read(chatProvider.notifier).ask('laper');
    await container.read(chatProvider.notifier).ask('yang lain');

    expect(container.read(chatProvider), hasLength(4));
    expect(container.read(chatProvider).whereType<PendingTurn>(), isEmpty);
  });

  test('konteks hanya dikirim di turn pertama', () async {
    final chat = FakeMapoChat(jsonReply());
    final container = makeContainer(chat: chat);

    await container.read(chatProvider.notifier).ask('laper');
    await container.read(chatProvider.notifier).ask('yang lain');

    expect(chat.prompts, hasLength(2));
    expect(chat.prompts[0], contains('[Konteks saat ini]'));
    expect(chat.prompts[1], 'yang lain');
  });

  test('kegagalan model jadi ErrorTurn, bukan mengosongkan daftar', () async {
    final container = makeContainer(chat: FakeMapoChat(null));

    await container.read(chatProvider.notifier).ask('laper');

    final turns = container.read(chatProvider);
    expect(turns, hasLength(2));
    expect(turns[0], isA<UserTurn>());
    expect(turns[1], isA<ErrorTurn>());
  });

  test('tanpa userId langsung ErrorTurn', () async {
    final container = makeContainer(
      chat: FakeMapoChat(jsonReply()),
      userId: null,
    );

    await container.read(chatProvider.notifier).ask('laper');

    expect(container.read(chatProvider).last, isA<ErrorTurn>());
  });
}
```

Test ini memakai kembali fake dari Task 4 lewat import relatif. Perbaiki baris `import` di atas menjadi:

```dart
import '../domain/mapo_recommender_test.dart'
    show FakeMapoChat, FakeMealHistory, FakeWeatherService, jsonReply;
```

Ketiga fake itu sudah dideklarasikan di Task 4 dengan konstruktor tanpa argumen wajib, jadi tidak ada yang perlu diubah di `test/domain/mapo_recommender_test.dart` untuk keperluan import ini.

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

Run: `flutter test test/providers/chat_notifier_test.dart`

Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/models/chat_turn.dart'`, `currentUserIdProvider` tidak dikenal, `chatProvider` bukan `NotifierProvider`.

- [ ] **Step 3: Buat model `ChatTurn`**

Buat `lib/models/chat_turn.dart`:

```dart
import 'mapo_response.dart';

/// Satu baris di layar chat. `sealed` supaya `switch` di UI wajib lengkap.
sealed class ChatTurn {
  const ChatTurn();
}

class UserTurn extends ChatTurn {
  final String text;
  const UserTurn(this.text);
}

class MapoTurn extends ChatTurn {
  final MapoResponse response;
  const MapoTurn(this.response);
}

/// Mapo sedang mengetik. Dimodelkan sebagai turn, bukan sebagai state
/// pengganti — supaya riwayat di atasnya tetap terlihat saat menunggu.
class PendingTurn extends ChatTurn {
  const PendingTurn();
}

class ErrorTurn extends ChatTurn {
  final String message;
  const ErrorTurn(this.message);
}
```

- [ ] **Step 4: Ubah recommender jadi sadar turn**

Di `lib/domain/mapo_recommender.dart`, ganti `getRecommendation` (baris 30-70) dengan `reply`:

```dart
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

    final raw = await _chat.send(prompt);
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
    // Kumpulkan konteks PARALEL — bukan berurutan
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

    debugPrint('WEATHER: ${weather.description}, ${weather.temperature}°C');
    debugPrint('RECENT MEALS: $recentMeals');
    debugPrint('PREFS: ${prefs.budgetRange}, ${prefs.restrictions}');

    return _buildContextBlock(
      weather: weather,
      recentMeals: recentMeals,
      prefs: prefs,
    );
  }
```

`_buildContextBlock`, `_resolveTimeOfDay` (baris 72-101) tidak berubah.

Lalu di `test/domain/mapo_recommender_test.dart`, ganti semua `getRecommendation(` → `reply(` dan tambahkan `withContext: true` ke setiap pemanggilan. Untuk test `'lat/lng null melewatkan panggilan cuaca'`, tetap `withContext: true`. Tambahkan satu test baru:

```dart
  test('withContext false mengirim pesan mentah tanpa blok konteks', () async {
    final chat = FakeMapoChat(jsonReply());
    final recommender = MapoRecommender(
      FakeWeatherService(),
      FakeMealHistory(),
      chat,
    );

    await recommender.reply(
      userId: 'u1',
      userMessage: 'berkuah',
      withContext: false,
    );

    expect(chat.prompts.single, 'berkuah');
  });
```

- [ ] **Step 5: Tulis ulang provider auth dan `ChatNotifier`**

Di `lib/providers/mapo_providers.dart`, tambahkan import:

```dart
import '../models/chat_turn.dart';
```

Ganti blok `// ── Auth ──` dan `// ── Chat state ──` (baris 28-70) dengan:

```dart
// ── Auth ──────────────────────────────────────────────────
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

/// Dibaca sinkron dari `currentUser` (main() sudah `await signInAnonymously()`
/// sebelum runApp), tapi ikut invalidasi kalau auth state berubah.
/// Test meng-override provider ini langsung dengan sebuah String.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(firebaseAuthProvider).currentUser?.uid;
});

// ── Chat state ────────────────────────────────────────────
final chatProvider = NotifierProvider<ChatNotifier, List<ChatTurn>>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<List<ChatTurn>> {
  @override
  List<ChatTurn> build() => const [];

  bool get _isFirstTurn => state.whereType<MapoTurn>().isEmpty;

  Future<void> ask(String message, {double? lat, double? lng}) async {
    final userId = ref.read(currentUserIdProvider);
    final history = [...state, UserTurn(message)];

    if (userId == null) {
      state = [...history, const ErrorTurn('Belum login, coba buka ulang app')];
      return;
    }

    final withContext = _isFirstTurn;
    state = [...history, const PendingTurn()];

    try {
      final response = await ref.read(recommenderProvider).reply(
        userId: userId,
        userMessage: message,
        withContext: withContext,
        lat: lat,
        lng: lng,
      );
      state = [...history, MapoTurn(response)];
    } on MapoException catch (e) {
      state = [...history, ErrorTurn(e.message)];
    } catch (_) {
      state = [...history, const ErrorTurn('Mapo lagi bingung, coba lagi ya')];
    }
  }
}
```

Perhatikan: `state` diganti dengan `[...history, ...]`, bukan `[...state, ...]` — ini yang membuang `PendingTurn` saat request selesai.

- [ ] **Step 6: Jalankan test provider**

Run: `flutter test test/providers/chat_notifier_test.dart test/domain/mapo_recommender_test.dart`

Expected: PASS semua (6 test notifier, 6 test recommender).

- [ ] **Step 7: Tulis ulang `ChatScreen` jadi daftar pesan**

Ganti seluruh isi `lib/ui/chat_screen.dart` dengan:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import '../models/chat_turn.dart';
import '../models/mapo_response.dart';
import 'widgets/recommendation_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    final coords = await ref.read(coordsProvider.future);
    if (!mounted) return;

    await ref
        .read(chatProvider.notifier)
        .ask(text, lat: coords?.lat, lng: coords?.lng);

    if (!mounted || !_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final turns = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapo')),
      body: Column(
        children: [
          Expanded(
            child: turns.isEmpty
                ? const Center(child: Text('Bingung mau makan apa?'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: turns.length,
                    itemBuilder: (context, i) => _TurnView(
                      turn: turns[i],
                      onQuickReply: _send,
                    ),
                  ),
          ),
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _TurnView extends StatelessWidget {
  final ChatTurn turn;
  final Future<void> Function(String) onQuickReply;

  const _TurnView({required this.turn, required this.onQuickReply});

  @override
  Widget build(BuildContext context) {
    return switch (turn) {
      UserTurn(:final text) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text),
        ),
      ),
      PendingTurn() => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Mapo mikir dulu...'),
          ],
        ),
      ),
      ErrorTurn(:final message) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      MapoTurn(:final response) => _ResponseView(
        response: response,
        onQuickReply: onQuickReply,
      ),
    };
  }
}

class _ResponseView extends StatelessWidget {
  final MapoResponse response;
  final Future<void> Function(String) onQuickReply;

  const _ResponseView({required this.response, required this.onQuickReply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            response.message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Badge grounding — bukti konteks terpakai
          if (response.contextUsed?.weather != null)
            Chip(
              avatar: const Icon(Icons.cloud, size: 16),
              label: Text('berdasarkan ${response.contextUsed!.weather}'),
            ),
          const SizedBox(height: 12),

          // Layout ditentukan response_type
          ...switch (response.responseType) {
            ResponseType.clarify => [
              if (response.followUp != null) ...[
                Text(response.followUp!.question),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: response.followUp!.quickReplies
                      .map(
                        (r) => ActionChip(
                          label: Text(r),
                          onPressed: () => onQuickReply(r),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
            _ => response.recommendations
                .map((r) => RecommendationCard(recommendation: r))
                .toList(),
          },
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function(String) onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Lagi pengen apa? (mis. hujan, pengen anget)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => onSend(controller.text),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Jalankan seluruh test dan analyze**

Run: `flutter test && flutter analyze`

Expected: semua PASS, `No issues found!`.

- [ ] **Step 9: Verifikasi manual alur `clarify`**

Run: `flutter run --dart-define=WEATHER_API_KEY=<kunci_openweather_kamu>`

Kirim pesan yang sengaja kurang informasi: `"laper"`. Kalau model membalas dengan quick replies, tekan salah satunya.

Expected:
- Pesan kamu muncul sebagai bubble di kanan, tetap terlihat selagi "Mapo mikir dulu..." tampil di bawahnya (**layar tidak pernah kosong** — ini bug yang diperbaiki).
- Setelah menekan quick reply, balasan Mapo harus menyambung pertanyaannya, bukan mengulang dari nol.
- Seluruh riwayat percakapan tetap ada di layar.

- [ ] **Step 10: Commit**

```bash
git add lib/models/chat_turn.dart lib/domain/mapo_recommender.dart lib/providers/mapo_providers.dart lib/ui/chat_screen.dart test/providers/chat_notifier_test.dart test/domain/mapo_recommender_test.dart
git commit -m "feat: percakapan multi-turn agar clarify dan quick_replies berfungsi"
```

---

### Task 6: Tutup loop tulis riwayat makan

`MealHistoryService.saveMeal()` ada di `lib/data/meal_history_service.dart:24-30` tapi **tidak dipanggil dari mana pun** di seluruh `lib/`. Akibatnya subcollection `meal_history` selamanya kosong, `getRecentMeals()` selalu mengembalikan `[]`, dan instruksi di prompt — *"Hindari menyarankan menu yang sama persis dengan riwayat terakhir"* (`lib/domain/mapo_recommender.dart:91-93`) — tidak pernah punya data untuk dipatuhi. Pembeda utama produk ini baru terpasang sisi bacanya.

Task ini menambahkan aksi "Aku makan ini" di kartu rekomendasi.

**Files:**
- Modify: `lib/ui/widgets/recommendation_card.dart` (tambah tombol + callback opsional)
- Modify: `lib/providers/mapo_providers.dart` (tambah `ChatNotifier.pickMeal`)
- Modify: `lib/ui/chat_screen.dart` (sambungkan `onPick`)
- Test: `test/providers/chat_notifier_test.dart`

**Interfaces:**
- Consumes: `MealHistoryService.saveMeal(String userId, String name, String category)` (sudah ada), `currentUserIdProvider` (Task 5), `ChatTurn` (Task 5)
- Produces:
  - `ChatNotifier.pickMeal(Recommendation) → Future<void>`
  - `RecommendationCard({required Recommendation recommendation, VoidCallback? onPick})`

- [ ] **Step 1: Tulis test yang gagal**

Tambahkan ke `test/providers/chat_notifier_test.dart` di dalam `void main()`. Test ini butuh akses ke fake yang sama, jadi ubah `makeContainer` agar menerima fake riwayat dari luar:

```dart
  ProviderContainer makeContainer({
    required MapoChat chat,
    String? userId = 'u1',
    FakeMealHistory? history,
  }) {
    return ProviderContainer.test(
      overrides: [
        mapoChatProvider.overrideWithValue(chat),
        currentUserIdProvider.overrideWithValue(userId),
        weatherServiceProvider.overrideWithValue(FakeWeatherService()),
        mealHistoryProvider.overrideWithValue(history ?? FakeMealHistory()),
      ],
    );
  }
```

Lalu tambahkan test:

```dart
  test('pickMeal menyimpan menu ke riwayat', () async {
    final history = FakeMealHistory();
    final container = makeContainer(
      chat: FakeMapoChat(jsonReply(name: 'Bakso')),
      history: history,
    );

    await container.read(chatProvider.notifier).ask('laper');
    final picked = (container.read(chatProvider).last as MapoTurn)
        .response
        .recommendations
        .single;
    await container.read(chatProvider.notifier).pickMeal(picked);

    expect(history.saved, hasLength(1));
    expect(history.saved.single['name'], 'Bakso');
    expect(history.saved.single['category'], 'berkuah');
  });

  test('pickMeal tanpa userId tidak menyimpan apa pun', () async {
    final history = FakeMealHistory();
    final container = makeContainer(
      chat: FakeMapoChat(jsonReply()),
      userId: null,
      history: history,
    );

    await container.read(chatProvider.notifier).pickMeal(
      const Recommendation(
        name: 'Bakso',
        reason: 'anget',
        category: 'berkuah',
        priceEstimate: 15000,
        spiceLevel: 'sedang',
        prepTime: 'cepat',
      ),
    );

    expect(history.saved, isEmpty);
  });
```

Tambahkan import `mapo_response.dart` di file test itu:

```dart
import 'package:mapo_app/models/mapo_response.dart';
```

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

Run: `flutter test test/providers/chat_notifier_test.dart`

Expected: FAIL — `The method 'pickMeal' isn't defined for the class 'ChatNotifier'`.

- [ ] **Step 3: Tambahkan `pickMeal` ke `ChatNotifier`**

Di `lib/providers/mapo_providers.dart`, tambahkan method ini di dalam `class ChatNotifier`, setelah `ask`:

```dart
  /// Menutup loop data: tanpa ini `meal_history` selamanya kosong dan
  /// `getRecentMeals` tidak punya apa pun untuk dikembalikan.
  Future<void> pickMeal(Recommendation recommendation) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await ref.read(mealHistoryProvider).saveMeal(
      userId,
      recommendation.name,
      recommendation.category,
    );
  }
```

- [ ] **Step 4: Jalankan test untuk memastikan lulus**

Run: `flutter test test/providers/chat_notifier_test.dart`

Expected: 8 test PASS.

- [ ] **Step 5: Tambahkan tombol di kartu rekomendasi**

Di `lib/ui/widgets/recommendation_card.dart`, ubah deklarasi kelas (baris 4-6):

```dart
class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback? onPick;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onPick,
  });
```

Lalu tambahkan tombol setelah blok `Wrap` (setelah baris 44, sebelum penutup `children: [...]`):

```dart
            if (onPick != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aku makan ini'),
                ),
              ),
            ],
```

- [ ] **Step 6: Sambungkan di `ChatScreen`**

`_ResponseView` perlu akses ke `ref`, jadi ubah dari `StatelessWidget` ke `ConsumerWidget` di `lib/ui/chat_screen.dart`:

```dart
class _ResponseView extends ConsumerWidget {
  final MapoResponse response;
  final Future<void> Function(String) onQuickReply;

  const _ResponseView({required this.response, required this.onQuickReply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
```

Lalu di cabang `_ =>` pada `switch (response.responseType)`, sambungkan `onPick` dan beri umpan balik:

```dart
            _ => response.recommendations
                .map(
                  (r) => RecommendationCard(
                    recommendation: r,
                    onPick: () async {
                      await ref.read(chatProvider.notifier).pickMeal(r);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Oke, ${r.name} dicatat!')),
                      );
                    },
                  ),
                )
                .toList(),
```

- [ ] **Step 7: Jalankan seluruh test dan analyze**

Run: `flutter test && flutter analyze`

Expected: semua PASS, `No issues found!`.

- [ ] **Step 8: Verifikasi manual loop tulis-baca**

Run: `flutter run --dart-define=WEATHER_API_KEY=<kunci_openweather_kamu>`

1. Kirim pesan, tunggu rekomendasi, tekan "Aku makan ini". Snackbar harus muncul.
2. Buka Firebase Console → Firestore → `users/{uid}/meal_history`. Harus ada dokumen baru berisi `name`, `category`, `eaten_at`.
3. **Restart app** (bukan hot reload — `ChatSession` harus baru supaya turn pertama mengirim konteks lagi), kirim pesan lagi.
4. Di log, cari `RECENT MEALS:`.

Expected: baris log itu sekarang berisi nama menu yang kamu pilih, bukan `[]`. Inilah bukti loop-nya tertutup.

- [ ] **Step 9: Commit**

```bash
git add lib/ui/widgets/recommendation_card.dart lib/providers/mapo_providers.dart lib/ui/chat_screen.dart test/providers/chat_notifier_test.dart
git commit -m "feat: catat menu yang dipilih ke meal_history"
```

---

### Task 7: Tutup loop tulis preferensi

`MealHistoryService.getPreferences()` membaca `budget_range` dan `restrictions` dari `users/{uid}` (`lib/data/meal_history_service.dart:19-22`), tapi tidak ada satu pun jalur tulis. `UserPrefs` karena itu selalu memakai nilai default `'15.000-25.000'` dan `restrictions: []` (`lib/models/user_prefs.dart:6-8`) — pantangan yang masuk ke prompt selalu "tidak ada", untuk semua pengguna.

**Files:**
- Modify: `lib/data/meal_history_service.dart` (tambah `savePreferences`)
- Modify: `lib/models/user_prefs.dart` (tambah `toDoc`, konstanta pilihan)
- Create: `lib/ui/prefs_sheet.dart`
- Modify: `lib/providers/mapo_providers.dart` (tambah `prefsProvider`, `savePrefs`)
- Modify: `lib/ui/chat_screen.dart` (tombol settings di AppBar)
- Test: `test/data/meal_history_service_test.dart`

**Interfaces:**
- Consumes: `UserPrefs.fromDoc(Map<String, dynamic>)` (sudah ada), `currentUserIdProvider`, `mealHistoryProvider`
- Produces:
  - `UserPrefs.toDoc() → Map<String, dynamic>`
  - `UserPrefs.budgetOptions` → `List<String>`, `UserPrefs.restrictionOptions` → `List<String>`
  - `MealHistoryService.savePreferences(String userId, UserPrefs prefs) → Future<void>`
  - `final prefsProvider = FutureProvider<UserPrefs>`
  - `PrefsSheet` — `static Future<void> show(BuildContext context)`

- [ ] **Step 1: Tambah `fake_cloud_firestore` sebagai dev dependency**

Task ini butuh verifikasi penulisan Firestore yang sungguhan, jadi butuh Firestore palsu.

Run: `flutter pub add dev:fake_cloud_firestore`

Run: `flutter pub get`

**Kalau resolusi versi gagal** (`fake_cloud_firestore` belum mendukung `cloud_firestore ^6.7.1`): jangan pin versi lama dan jangan turunkan `cloud_firestore`. Batalkan dengan `flutter pub remove fake_cloud_firestore`, lalu **lewati Step 2, 3, dan 7** dan jangan buat `test/data/meal_history_service_test.dart`. Sebagai gantinya, uji lewat fake tingkat service (Step 6 tetap wajib dijalankan) dengan menambahkan test ini ke `test/providers/chat_notifier_test.dart`:

```dart
  test('savePrefs meneruskan preferensi ke service', () async {
    final history = FakeMealHistory();
    final container = makeContainer(
      chat: FakeMapoChat(jsonReply()),
      history: history,
    );

    await container.read(chatProvider.notifier).savePrefs(
      const UserPrefs(budgetRange: '> 50.000', restrictions: ['halal']),
    );

    expect(history.savedPrefs.single.budgetRange, '> 50.000');
    expect(history.savedPrefs.single.restrictions, ['halal']);
  });
```

(butuh `import 'package:mapo_app/models/user_prefs.dart';` dan parameter `history` pada `makeContainer` dari Task 6 Step 1). Penulisan Firestore yang sebenarnya lalu hanya diverifikasi manual di Step 12 — catat itu di commit message.

- [ ] **Step 2: Tulis test yang gagal**

Buat `test/data/meal_history_service_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/data/meal_history_service.dart';
import 'package:mapo_app/models/user_prefs.dart';

void main() {
  test('savePreferences menulis budget dan pantangan', () async {
    final db = FakeFirebaseFirestore();
    final service = MealHistoryService(db);

    await service.savePreferences(
      'u1',
      const UserPrefs(
        budgetRange: '25.000-50.000',
        restrictions: ['tidak pedas', 'halal'],
      ),
    );

    final doc = await db.collection('users').doc('u1').get();
    expect(doc.data()!['budget_range'], '25.000-50.000');
    expect(doc.data()!['restrictions'], ['tidak pedas', 'halal']);
  });

  test('savePreferences merge, tidak menghapus field lain', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({'nama_panggilan': 'Firman'});
    final service = MealHistoryService(db);

    await service.savePreferences(
      'u1',
      const UserPrefs(budgetRange: '< 15.000'),
    );

    final doc = await db.collection('users').doc('u1').get();
    expect(doc.data()!['nama_panggilan'], 'Firman');
    expect(doc.data()!['budget_range'], '< 15.000');
  });

  test('getPreferences membaca kembali yang baru ditulis', () async {
    final db = FakeFirebaseFirestore();
    final service = MealHistoryService(db);

    await service.savePreferences(
      'u1',
      const UserPrefs(budgetRange: '> 50.000', restrictions: ['vegetarian']),
    );
    final prefs = await service.getPreferences('u1');

    expect(prefs.budgetRange, '> 50.000');
    expect(prefs.restrictions, ['vegetarian']);
  });

  test('saveMeal lalu getRecentMeals mengembalikan menu terbaru dulu', () async {
    final db = FakeFirebaseFirestore();
    final service = MealHistoryService(db);

    await service.saveMeal('u1', 'Soto Ayam', 'berkuah');
    await service.saveMeal('u1', 'Bakso', 'berkuah');

    final recent = await service.getRecentMeals('u1');

    expect(recent, hasLength(2));
    expect(recent, contains('Soto Ayam'));
    expect(recent, contains('Bakso'));
  });
}
```

- [ ] **Step 3: Jalankan test untuk memastikan gagal**

Run: `flutter test test/data/meal_history_service_test.dart`

Expected: FAIL — `The method 'savePreferences' isn't defined for the class 'MealHistoryService'`.

- [ ] **Step 4: Tambahkan `toDoc` dan pilihan ke `UserPrefs`**

Ganti seluruh isi `lib/models/user_prefs.dart`:

```dart
class UserPrefs {
  static const budgetOptions = [
    '< 15.000',
    '15.000-25.000',
    '25.000-50.000',
    '> 50.000',
  ];

  static const restrictionOptions = [
    'tidak pedas',
    'halal',
    'vegetarian',
    'tanpa gorengan',
    'tanpa seafood',
  ];

  final String budgetRange;
  final List<String> restrictions;

  const UserPrefs({
    this.budgetRange = '15.000-25.000',
    this.restrictions = const [],
  });

  factory UserPrefs.fromDoc(Map<String, dynamic> data) => UserPrefs(
    budgetRange: data['budget_range'] as String? ?? '15.000-25.000',
    restrictions: (data['restrictions'] as List?)?.cast<String>() ?? const [],
  );

  Map<String, dynamic> toDoc() => {
    'budget_range': budgetRange,
    'restrictions': restrictions,
  };

  UserPrefs copyWith({String? budgetRange, List<String>? restrictions}) =>
      UserPrefs(
        budgetRange: budgetRange ?? this.budgetRange,
        restrictions: restrictions ?? this.restrictions,
      );
}
```

- [ ] **Step 5: Tambahkan `savePreferences` ke service**

Di `lib/data/meal_history_service.dart`, tambahkan method ini setelah `getPreferences`:

```dart
  Future<void> savePreferences(String userId, UserPrefs prefs) async {
    await _db
        .collection('users')
        .doc(userId)
        .set(prefs.toDoc(), SetOptions(merge: true));
  }
```

`SetOptions` sudah tersedia dari import `cloud_firestore` di baris 1. `merge: true` wajib — tanpanya field lain di dokumen pengguna terhapus.

- [ ] **Step 6: Lengkapi `FakeMealHistory` — kalau tidak, seluruh test rusak**

Menambah method publik ke `MealHistoryService` **memutus** `FakeMealHistory implements MealHistoryService` di `test/domain/mapo_recommender_test.dart`, karena `implements` mewajibkan seluruh interface publik diimplementasikan. Ini bukan pilihan.

Tambahkan ke `class FakeMealHistory` di `test/domain/mapo_recommender_test.dart`:

```dart
  final savedPrefs = <UserPrefs>[];

  @override
  Future<void> savePreferences(String userId, UserPrefs prefs) async {
    savedPrefs.add(prefs);
  }
```

- [ ] **Step 7: Jalankan test untuk memastikan lulus**

Run: `flutter test test/data/meal_history_service_test.dart && flutter test`

Expected: 4 test baru PASS, dan seluruh test lain tetap PASS (bukti Step 6 memang diperlukan — coba hapus Step 6 dan `flutter test` akan gagal compile).

- [ ] **Step 8: Tambahkan provider prefs**

Di `lib/providers/mapo_providers.dart`, tambahkan import:

```dart
import '../models/user_prefs.dart';
```

Tambahkan setelah blok `// ── Data layer ──`:

```dart
final prefsProvider = FutureProvider<UserPrefs>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const UserPrefs();
  return ref.watch(mealHistoryProvider).getPreferences(userId);
});
```

Catatan urutan: `prefsProvider` mengacu ke `currentUserIdProvider` yang dideklarasikan di bawahnya. Di Dart itu tidak masalah untuk variabel top-level, tapi kalau kamu lebih suka rapi, letakkan `prefsProvider` setelah blok `// ── Auth ──`.

Tambahkan method ini ke `class ChatNotifier`:

```dart
  Future<void> savePrefs(UserPrefs prefs) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await ref.read(mealHistoryProvider).savePreferences(userId, prefs);
    ref.invalidate(prefsProvider);
  }
```

- [ ] **Step 9: Buat `PrefsSheet`**

Buat `lib/ui/prefs_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_prefs.dart';
import '../providers/mapo_providers.dart';

class PrefsSheet extends ConsumerStatefulWidget {
  const PrefsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PrefsSheet(),
  );

  @override
  ConsumerState<PrefsSheet> createState() => _PrefsSheetState();
}

class _PrefsSheetState extends ConsumerState<PrefsSheet> {
  UserPrefs? _draft;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: prefs.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Text('Gagal memuat preferensi: $e'),
        data: (loaded) {
          final draft = _draft ??= loaded;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selera kamu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              const Text('Budget biasanya'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: UserPrefs.budgetOptions
                    .map(
                      (b) => ChoiceChip(
                        label: Text(b),
                        selected: draft.budgetRange == b,
                        onSelected: (_) => setState(
                          () => _draft = draft.copyWith(budgetRange: b),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),

              const Text('Pantangan'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: UserPrefs.restrictionOptions
                    .map(
                      (r) => FilterChip(
                        label: Text(r),
                        selected: draft.restrictions.contains(r),
                        onSelected: (selected) => setState(() {
                          final next = [...draft.restrictions];
                          selected ? next.add(r) : next.remove(r);
                          _draft = draft.copyWith(restrictions: next);
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(chatProvider.notifier).savePrefs(draft);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 10: Tambahkan tombol di AppBar**

Di `lib/ui/chat_screen.dart`, tambahkan import:

```dart
import 'prefs_sheet.dart';
```

Ganti `appBar:` (di dalam `Scaffold` pada `_ChatScreenState.build`):

```dart
      appBar: AppBar(
        title: const Text('Mapo'),
        actions: [
          IconButton(
            onPressed: () => PrefsSheet.show(context),
            icon: const Icon(Icons.tune),
            tooltip: 'Selera kamu',
          ),
        ],
      ),
```

- [ ] **Step 11: Jalankan seluruh test dan analyze**

Run: `flutter test && flutter analyze`

Expected: semua PASS, `No issues found!`.

- [ ] **Step 12: Verifikasi manual**

Run: `flutter run --dart-define=WEATHER_API_KEY=<kunci_openweather_kamu>`

1. Tekan ikon tune di AppBar, pilih budget `> 50.000` dan pantangan `tidak pedas`, tekan Simpan.
2. Cek Firebase Console → Firestore → `users/{uid}`: `budget_range` dan `restrictions` harus terisi.
3. **Restart app**, kirim pesan baru.
4. Di log, cari baris `PREFS:`.

Expected: `PREFS: > 50.000, [tidak pedas]` — bukan default. Rekomendasi yang datang juga harus menghormati pantangan itu.

- [ ] **Step 13: Commit**

```bash
git add lib/models/user_prefs.dart lib/data/meal_history_service.dart lib/ui/prefs_sheet.dart lib/providers/mapo_providers.dart lib/ui/chat_screen.dart test/data/meal_history_service_test.dart pubspec.yaml pubspec.lock
git commit -m "feat: layar preferensi dan jalur tulis UserPrefs"
```

---

### Task 8: Firestore security rules

Tidak ada `firestore.rules` di repo dan `firebase.json` tidak punya bagian `firestore`. Tanpa rules, Firestore memakai apa pun yang tersetel di console — kalau masih mode test, siapa pun bisa membaca dan menulis seluruh database. Dua paparan yang konkret:

1. `users/{uid}` dan subcollection `meal_history` berisi riwayat makan dan preferensi pribadi. Harus hanya bisa diakses pemiliknya.
2. `weather_cache/{key}` ditulis klien (`lib/data/weather_service.dart:38`) dan key-nya adalah koordinat yang dibulatkan 2 desimal — bisa ditebak. Klien mana pun bisa menulis data cuaca palsu ke cache lokasi orang lain. Rules bisa mempersempit ini; Task 9 menghapusnya sepenuhnya.

**Files:**
- Create: `firestore.rules`
- Modify: `firebase.json` (tambah bagian `firestore`)

**Interfaces:**
- Consumes: struktur koleksi dari `lib/data/meal_history_service.dart` dan `lib/data/weather_service.dart`
- Produces: `firestore.rules` yang ter-deploy

- [ ] **Step 1: Tulis rules**

Buat `firestore.rules`:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Riwayat makan dan preferensi: hanya pemiliknya.
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /meal_history/{docId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }
    }

    // Cache cuaca: bersama, tapi hanya untuk yang sudah login, dan tulisan
    // dibatasi ke bentuk yang memang dipakai app. Task 9 memindahkan tulisan
    // ini ke Cloud Function dan mengubah aturan ini jadi read-only.
    match /weather_cache/{cacheKey} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.data.keys().hasOnly(
                        ['description', 'temperature', 'fetched_at'])
                   && request.resource.data.description is string
                   && request.resource.data.temperature is number
                   && request.resource.data.fetched_at is timestamp;
    }

    // Tolak sisanya secara eksplisit.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

- [ ] **Step 2: Daftarkan rules di `firebase.json`**

`firebase.json` saat ini satu baris panjang berisi tepat satu kunci di level teratas: `"flutter"`. Objek `flutter` itu dihasilkan oleh FlutterFire CLI — **jangan diubah, jangan diformat ulang**.

Yang perlu dilakukan hanya menyisipkan kunci `"firestore"` sebagai saudara `"flutter"`. Artinya: ganti karakter `{` paling awal di file itu dengan:

```
{"firestore":{"rules":"firestore.rules"},
```

Hasil akhirnya berbentuk `{"firestore":{"rules":"firestore.rules"},"flutter":{...}}` dengan bagian `{...}` persis seperti sebelumnya.

Verifikasi bahwa JSON-nya masih valid dan kedua kunci ada:

Run: `python3 -c "import json;d=json.load(open('firebase.json'));print(sorted(d.keys()))"`

Expected: `['firestore', 'flutter']`

- [ ] **Step 3: Validasi sintaks rules tanpa deploy**

Run: `firebase deploy --only firestore:rules --dry-run`

Expected: kompilasi berhasil, tidak ada error sintaks. Kalau `firebase` belum ada: `npm install -g firebase-tools`, lalu `firebase login`.

- [ ] **Step 4: Deploy rules**

Run: `firebase deploy --only firestore:rules --project mapo-5681d`

Expected: `Deploy complete!`

- [ ] **Step 5: Verifikasi app masih jalan**

Run: `flutter run --dart-define=WEATHER_API_KEY=<kunci_openweather_kamu>`

Kirim pesan, pilih menu, buka layar preferensi dan simpan.

Expected: semuanya masih berfungsi. Kalau ada `PERMISSION_DENIED` di log, rules-nya terlalu ketat untuk pemakaian sebenarnya — cocokkan path yang ditolak dengan blok `match` di atas dan perbaiki sebelum lanjut. Jangan melonggarkan rules jadi `allow write: if true` sebagai jalan pintas.

- [ ] **Step 6: Commit**

```bash
git add firestore.rules firebase.json
git commit -m "chore: firestore security rules untuk users dan weather_cache"
```

---

### Task 9: Pindahkan fetch cuaca ke Cloud Function (pre-release)

> **Butuh Firebase Blaze plan (pay-as-you-go).** Cloud Functions tidak tersedia di Spark plan. Task ini boleh ditunda — Task 1-8 semuanya berdiri sendiri dan tidak memblokir. Tapi **jangan rilis ke publik tanpa ini**.

`WeatherService._apiKey` (`lib/data/weather_service.dart:12`) diisi lewat `String.fromEnvironment('WEATHER_API_KEY')`, yang berarti kuncinya di-inline ke binary saat compile. Siapa pun yang mengunduh APK bisa mengekstraknya dan memakai kuota OpenWeather kamu. Memanggil OpenWeather langsung dari device juga berarti tidak ada rate limiting yang bisa kamu kendalikan.

Setelah task ini, klien tidak lagi menyimpan kunci dan tidak lagi menulis ke `weather_cache`.

**Files:**
- Create: `functions/package.json`
- Create: `functions/index.js`
- Create: `functions/.gitignore`
- Modify: `firebase.json` (tambah bagian `functions`)
- Modify: `firestore.rules` (`weather_cache` jadi read-only bagi klien)
- Modify: `lib/data/weather_service.dart` (panggil callable, buang http + kunci)
- Modify: `lib/providers/mapo_providers.dart` (`weatherServiceProvider` pakai `FirebaseFunctions`)
- Modify: `pubspec.yaml` (tambah `cloud_functions`, hapus `http` kalau tidak dipakai lagi)

**Interfaces:**
- Consumes: `WeatherContext.fromApi(Map<String, dynamic>)` (Task 2), `WeatherService.getWeather(double, double)` (dipanggil dari `MapoRecommender._contextBlock`, Task 5)
- Produces:
  - Callable function `getWeather({lat, lng})` → `{description: string, temperature: number}`
  - `WeatherService(FirebaseFunctions functions)` — konstruktor berubah, tidak lagi butuh `FirebaseFirestore`

- [ ] **Step 1: Inisialisasi Cloud Functions**

Run: `firebase init functions --project mapo-5681d`

Pilih JavaScript, tolak ESLint kalau ditanya (opsional), setuju install dependencies. Ini membuat `functions/` dan menambahkan bagian `functions` ke `firebase.json`.

- [ ] **Step 2: Simpan kunci OpenWeather sebagai secret**

Run: `firebase functions:secrets:set WEATHER_API_KEY --project mapo-5681d`

Tempel kunci OpenWeather kamu saat diminta. Secret ini tersimpan di Secret Manager, tidak pernah masuk repo dan tidak pernah masuk binary klien.

- [ ] **Step 3: Tulis function-nya**

Ganti seluruh isi `functions/index.js`:

```javascript
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

const CACHE_MINUTES = 45;
const BASE_URL = "https://api.openweathermap.org/data/2.5/weather";

exports.getWeather = onCall(
  { secrets: ["WEATHER_API_KEY"], region: "asia-southeast2" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Harus login dulu");
    }

    const lat = Number(request.data?.lat);
    const lng = Number(request.data?.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      throw new HttpsError("invalid-argument", "lat/lng tidak valid");
    }

    const cacheKey = `${lat.toFixed(2)}_${lng.toFixed(2)}`;
    const cacheRef = db.collection("weather_cache").doc(cacheKey);

    const cached = await cacheRef.get();
    if (cached.exists) {
      const data = cached.data();
      const ageMinutes =
        (Date.now() - data.fetched_at.toDate().getTime()) / 60000;
      if (ageMinutes < CACHE_MINUTES) {
        return {
          description: data.description,
          temperature: data.temperature,
        };
      }
    }

    const url =
      `${BASE_URL}?lat=${lat}&lon=${lng}` +
      `&appid=${process.env.WEATHER_API_KEY}&units=metric&lang=id`;

    const response = await fetch(url);
    if (!response.ok) {
      throw new HttpsError("unavailable", "Gagal mengambil cuaca");
    }

    const body = await response.json();
    const result = {
      description: body.weather?.[0]?.description ?? "unknown",
      temperature: Number(body.main?.temp ?? 0),
    };

    await cacheRef.set({ ...result, fetched_at: Timestamp.now() });
    return result;
  },
);
```

Pastikan `functions/package.json` memakai Node 20 atau lebih baru (`fetch` global butuh Node 18+):

```json
  "engines": {
    "node": "20"
  }
```

- [ ] **Step 4: Deploy function**

Run: `firebase deploy --only functions:getWeather --project mapo-5681d`

Expected: `Deploy complete!` dan URL/nama function tercetak. Kalau gagal karena billing, Blaze plan belum aktif — aktifkan di Firebase Console, atau hentikan task ini di sini (Task 1-8 tetap utuh).

- [ ] **Step 5: Kunci `weather_cache` jadi read-only bagi klien**

Di `firestore.rules`, ganti seluruh blok `match /weather_cache/{cacheKey}` dengan:

```
    // Hanya Cloud Function (via Admin SDK, yang melewati rules) yang menulis.
    // Klien tidak punya alasan menulis ke sini lagi.
    match /weather_cache/{cacheKey} {
      allow read: if request.auth != null;
      allow write: if false;
    }
```

Run: `firebase deploy --only firestore:rules --project mapo-5681d`

- [ ] **Step 6: Tambahkan `cloud_functions` ke klien**

Run: `flutter pub add cloud_functions`

- [ ] **Step 7: Tulis ulang `WeatherService`**

Ganti seluruh isi `lib/data/weather_service.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/weather_context.dart';

class WeatherService {
  final FirebaseFunctions _functions;

  WeatherService(this._functions);

  Future<WeatherContext> getWeather(double lat, double lng) async {
    try {
      final result = await _functions
          .httpsCallable('getWeather')
          .call<Map<String, dynamic>>({'lat': lat, 'lng': lng})
          .timeout(const Duration(seconds: 20));

      return WeatherContext.fromCache(result.data);
    } catch (e) {
      debugPrint('Error getting weather: $e');
      // Cuaca gagal ≠ app mati
      return WeatherContext.unknown();
    }
  }
}
```

`WeatherContext.fromCache` dipakai di sini karena bentuk payload-nya sama (`description` + `temperature`) dan sudah tahan int/double sejak Task 2.

- [ ] **Step 8: Perbarui provider**

Di `lib/providers/mapo_providers.dart`, tambahkan import:

```dart
import 'package:cloud_functions/cloud_functions.dart';
```

Ganti `weatherServiceProvider` (yang tadinya memakai `firestoreProvider`):

```dart
final functionsProvider = Provider(
  (ref) => FirebaseFunctions.instanceFor(region: 'asia-southeast2'),
);

final weatherServiceProvider = Provider(
  (ref) => WeatherService(ref.watch(functionsProvider)),
);
```

Region harus sama dengan yang dipakai di `onCall` pada Step 3.

`firestoreProvider` tetap dipakai oleh `mealHistoryProvider`, jangan dihapus.

- [ ] **Step 9: Buang `http` kalau sudah tidak dipakai**

Run: `grep -rn "package:http" lib/`

Kalau tidak ada hasil: `flutter pub remove http`

- [ ] **Step 10: Sesuaikan fake di test**

`FakeWeatherService` di `test/domain/mapo_recommender_test.dart` memakai `implements WeatherService`, jadi ia tidak terpengaruh perubahan konstruktor. Tapi import `cloud_firestore` di file test itu mungkin jadi tidak terpakai.

Run: `flutter test && flutter analyze`

Expected: semua PASS, `No issues found!`. Kalau analyze mengeluh soal import yang tidak terpakai, hapus import itu.

- [ ] **Step 11: Verifikasi manual — tanpa `--dart-define`**

Run: `flutter run`

Perhatikan: **tidak ada** `--dart-define=WEATHER_API_KEY` lagi. Itulah intinya.

Kirim pesan. Di log, cari baris `WEATHER:`.

Expected: cuaca sebenarnya, tanpa kunci API di sisi klien. Verifikasi juga di Firebase Console → Firestore → `weather_cache` bahwa dokumen tetap dibuat/diperbarui (sekarang oleh function, bukan klien).

- [ ] **Step 12: Commit**

```bash
git add functions/ firebase.json firestore.rules lib/data/weather_service.dart lib/providers/mapo_providers.dart pubspec.yaml pubspec.lock test/domain/mapo_recommender_test.dart
git commit -m "feat: pindahkan fetch cuaca ke Cloud Function, keluarkan API key dari klien"
```

---

## Catatan yang sengaja tidak dijadikan task

- **`lottie` dan `skeletonizer`** ada di `pubspec.yaml:45-46` tapi belum dipakai di `lib/` mana pun. Saya tidak menghapusnya karena kelihatannya memang direncanakan untuk loading state. Kalau setelah Task 5 kamu memutuskan `PendingTurn` cukup ditangani `CircularProgressIndicator`, jalankan `flutter pub remove lottie skeletonizer`.
- **Widget test untuk `ChatScreen`** tidak dimasukkan. Untuk scope ini, test di level notifier (Task 5-6) sudah menangkap regresi logika, dan verifikasi manual menangkap masalah layout. Widget test baru layak kalau layarnya bertambah banyak.
- **Folder feature-first dan repository interface** belum relevan. Pertimbangkan ulang kalau layar bertambah banyak, ada mode offline, atau timnya bertambah.
- **`weather_cache` sebagai koleksi global** tetap dipertahankan setelah Task 9 — cache bersama antar-pengguna di kota yang sama justru menghemat kuota API, dan setelah Task 9 hanya function yang bisa menulis.
