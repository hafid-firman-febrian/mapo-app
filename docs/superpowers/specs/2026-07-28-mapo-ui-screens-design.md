# Mapo — Desain 8 Layar UI

## Konteks

Mapo adalah app Flutter (Riverpod + Firebase AI Logic/Gemini + Firestore) yang menyarankan makanan berdasarkan cuaca, waktu, dan riwayat makan. Desain visual (playful, colorful, hangat, light mode) sudah ada di `mapo-screens.pdf` dan `mapo-style-guide.pdf`, dan fondasi styling sudah diimplementasikan di `lib/themes/` (`AppColors`, `CategoryTone`, `AppSpacing`, `AppRadius`, `AppSizes`, `AppText`, `AppTheme`).

Sebelum spec ini ditulis, lima task dari `docs/superpowers/plans/2026-07-25-perbaikan-arsitektur-mapo.md` sudah dieksekusi di branch `feature/mapo-ui-screens` (analyzer bersih, 19 test PASS):

1. Analyzer exclude `build/`, test harness, verifikasi model id `gemini-3.5-flash-lite`
2. `WeatherContext` cast `num` (suhu int dari API/cache tidak lagi throw)
3. `LocationService` terpisah dari `WeatherService`; lat/lng nullable; `_getLocation()` yang tadinya dead code kini tersambung ke `coordsProvider`
4. Seam `MapoChat` (domain testable, `GenerativeModel` tidak lagi dikonstruksi di dalam `MapoRecommender`)
5. Multi-turn: `ChatTurn` sealed class (`UserTurn`/`MapoTurn`/`PendingTurn`/`ErrorTurn`), `chatProvider` jadi `NotifierProvider<ChatNotifier, List<ChatTurn>>`, `ChatSession` menyimpan riwayat sehingga `clarify`+`quick_replies` benar-benar menyambung antar-turn.

Task 6–9 (loop tulis `meal_history`/`UserPrefs`, `firestore.rules`, Cloud Function cuaca) **tetap di luar scope** spec ini.

Spec ini mencakup implementasi 8 layar dari `mapo-screens.pdf`, dibangun di atas state `List<ChatTurn>` yang sudah ada.

## 1. Pemetaan layar → route

Lima dari delapan "layar" di PDF bukan route terpisah — mereka adalah render state berbeda dari **satu `ChatScreen`**, didorong oleh isi `List<ChatTurn>`:

| Layar PDF | Kondisi render |
|---|---|
| Home | `turns.isEmpty` |
| Loading | turn terakhir adalah `PendingTurn` |
| Single | turn terakhir `MapoTurn` dengan `response.responseType == single` |
| Options | turn terakhir `MapoTurn` dengan `response.responseType == options` |
| Clarify | turn terakhir `MapoTurn` dengan `response.responseType == clarify` |

Riwayat dan Profil adalah route terpisah (`Navigator.push`, tanpa field chat). Menu adalah `Drawer` yang menempel ke `Scaffold` milik `ChatScreen`.

`lib/ui/chat_screen.dart` (hasil kerja Task 4/5, masih pakai `Card`/`Chip` Material default) dipindah ke `lib/ui/screens/chat_screen.dart` dan didesain ulang total secara visual — logika `ChatTurn`/provider yang sudah ada dan teruji **tidak berubah**, hanya lapisan presentasinya.

## 2. Inventaris widget (`lib/ui/widgets/`)

Semua widget menerima model sebagai prop (dumb widget, tanpa logika bisnis), semua nilai visual dari `AppColors`/`CategoryTone`/`AppSpacing`/`AppRadius`/`AppSizes`/`AppText`.

### `MapoHeader`
AppBar kustom. Prop: `title`, `subtitle?`, `color` (default `AppColors.brand`, hijau untuk Riwayat), `leading?`, `actions?`. Sudut bawah membulat besar sesuai style guide (bukan `AppBar` standar — pakai `PreferredSizeWidget` custom agar radius bawah bisa diterapkan).

### `ChatInputBar`
Prop: `controller`, `onSend`, `enabled` (false saat `PendingTurn` — field redup, hint berubah jadi "Tunggu sebentar..."). Tombol kirim kuning, ikon panah.

### `RecommendationCard`
Menerima `Recommendation` saja (model dari `MapoResponse`). Satu widget, dua varian lewat enum `RecommendationCardVariant { hero, row }`:
- **hero** (Single): kartu besar (radius 24, padding 22), ikon kategori di kotak putih transparan, lingkaran dekoratif, nama+alasan+tag, tombol "Makan ini" (kuning, aksi utama) + ghost "↻ lagi".
- **row** (Options): kompak (radius 16-20), ikon kiri, nama+meta kanan, harga rata kanan.

Prop: `recommendation`, `variant`, `onTap?`, `onPick?` (opsional — dipakai Task 6 nanti, bukan sekarang; parameter disiapkan tapi belum disambung ke Firestore write).

### `MealHistoryTile`
Widget terpisah untuk Riwayat — model beda (`MealHistoryEntry`, bukan `Recommendation`: tidak ada `reason`/`spiceLevel`/`prepTime`/`tags`, ada `eatenAt`). Memaksakan satu widget untuk dua model lewat union type cuma menambah kerumitan tanpa manfaat. Berbagi `CategoryBadge` dan warna/ikon kategori yang sama dengan `RecommendationCard` supaya tetap konsisten secara visual. Prop: `entry`, `onTap?`.

### `CategoryBadge`
Ikon+label pill kecil, warna dari `categoryTone(category)`. Dipakai di dalam card dan di Riwayat.

### `QuickReplyChip`
Prop: `label`, `selected`, `onTap`, `icon?`. Border warna kategori, fill saat `selected`.

### `GroundingBadge`
Pill kecil menampilkan `context_used` ("dipilih karena cuaca hujan"). Prop: `contextUsed`. Return `SizedBox.shrink()` kalau tidak ada info yang layak ditampilkan (edge case: `context_used` kosong).

### `PendingChecklist`
Widget baru (tidak disebut eksplisit di brief tapi perlu container sendiri untuk animasi bertahap Loading). Prop: `stage` (0-2, dikendalikan `TweenSequence`/`Timer` internal — lihat §6). Render tiga baris ("Cuaca ✓ / Riwayat ✓ / Menyusun saran...") yang muncul satu-satu.

### `MapoDrawer`
Prop: `userName`, `mealCount`, `onNavigate(MapoDrawerItem)`. Item: Cari makan, Riwayat, Favorit (disabled/placeholder — tidak ada data model favorit, akan ditandai "segera hadir"), Pengaturan (disabled/placeholder — sama).

## 3. Model data tambahan

`MealHistoryService.getRecentMeals()` saat ini hanya mengembalikan `List<String>` (nama saja) — tidak cukup untuk Riwayat yang butuh kategori, waktu, dan harga per entri.

Firestore subcollection `meal_history` sudah menyimpan `name`, `category`, `eaten_at` (bukan harga — itu ranah Task 6, tidak disentuh). Tambahan minimal, **read-only**, tidak menyentuh jalur tulis:

```dart
class MealHistoryEntry {
  final String name;
  final String category;
  final DateTime eatenAt;
  final int? price; // selalu null sampai Task 6 menyimpan harga

  const MealHistoryEntry({
    required this.name,
    required this.category,
    required this.eatenAt,
    this.price,
  });
}
```

`MealHistoryService.getMealHistory({int limit = 20})` — method baru di samping `getRecentMeals` yang sudah ada (tidak menggantikan, `getRecentMeals` masih dipakai `MapoRecommender`). Statistik Riwayat ("12 makan minggu ini", "berkuah paling sering") dihitung di provider/screen dari list ini (`where eatenAt` dalam 7 hari terakhir, `groupBy category`) — bukan query Firestore terpisah.

## 4. Perbaikan kontras (WCAG AA)

Rasio kontras teks putih di atas warna kategori `base` (dihitung dari nilai hex `AppColors`): biru 4.16:1, merah 3.61:1, hijau 2.79:1, brand/kuning 2.03:1. Ambang AA teks normal (16px) adalah 4.5:1 — keempatnya gagal; hijau dan kuning bahkan gagal ambang teks besar-bold (3:1, dipakai judul nama menu).

**Perbaikan:** `RecommendationCard` (varian `hero` maupun `row`) menambahkan panel scrim rata `Colors.black.withValues(alpha: 0.35)` di belakang blok teks, independen dari warna kategori. Angka 0.35 dihitung dari kasus terburuk (brand/amber, luminance dasar 0.4682): dengan blending `channel_baru = channel_asli × (1 - 0.35)` lalu dihitung ulang luminance-nya, kontras putih-di-atasnya jadi persis 4.53:1 — baru lolos ambang AA teks normal (4.5:1). Tiga kategori lain (biru, merah, hijau) jauh lebih longgar di angka yang sama (5.5–8:1), jadi satu nilai scrim yang sama aman dipakai di keempat kategori. Ini overlay warna di dalam kartu, bukan box-shadow di tepi — konsisten dengan prinsip style guide "cukup warna & radius, jangan shadow tebal". Tidak mengubah nilai `AppColors`/`CategoryTone` yang sudah didefinisikan.

`MealHistoryTile` (Riwayat) tidak kena isu ini — tile-nya pakai latar halaman putih/`AppColors.page` dengan teks `AppColors.ink`, dan kotak ikon kategori pakai `tone.fill`+`tone.dark` (pasangan yang sudah kontras tinggi, dipakai juga oleh `CategoryBadge`), bukan `tone.base`+putih.

## 5. Animasi & micro-interaction

- Transisi antar-state percakapan (Home → Loading → Single/Options/Clarify): `AnimatedSwitcher` + `SlideTransition` kombinasi fade, tanpa dependency baru.
- Kemunculan kartu rekomendasi: fade+slide-up per kartu, stagger ringan (~40ms) kalau lebih dari satu (Options).
- `PendingChecklist`: tiga baris muncul bertahap via `Timer.periodic` (~600ms/step) — **simulasi murni**, bukan progress asli dari `Future.wait` backend (dikonfirmasi user: domain layer tidak expose event granular per-step). Kalau response sudah balik sebelum animasi selesai, langsung cut ke selesai.
- Tombol "Makan ini": scale-down ringan on-tap (`GestureDetector` + `AnimatedScale`).
- Kartu Options: ripple bawaan `InkWell` + scale halus saat ditekan.
- `QuickReplyChip`: transisi warna border/fill saat `selected` berubah.

## 6. Aksesibilitas

- `Semantics(label: ...)` untuk semua icon-only button (kirim, back, menu, profil, refresh).
- Tap target minimum 48×48 (bungkus ikon kecil dengan `SizedBox`/padding kalau perlu).
- Scrim kontras (§4) di semua `RecommendationCard` varian hero.
- Kontras teks di `MapoHeader` (putih di atas `AppColors.brand`) — brand luminance 0.4682, kontras dengan putih 2.03:1, **juga gagal AA**. Header memakai judul besar (Display 1/2, 30-42px bold) yang butuh hanya 3:1 — masih gagal. Solusi sama seperti kartu: judul header pakai `AppColors.ink` bukan putih, ATAU header mendapat scrim serupa. **Rekomendasi: pakai `AppColors.ink`** untuk teks judul di header (kontras ink-on-brand jauh di atas AA), karena header tidak punya "ruang" untuk gradient scrim tanpa mengubah nuansa warna brand secara nyata.

## 7. Responsif

- Kartu hero: `ConstrainedBox(maxWidth: 480)` + lebar mengikuti parent (bukan fixed width), aman dari SE (~375px) sampai tablet.
- Tag/kategori: `Wrap` bukan `Row`, supaya tidak overflow di layar sempit atau tag banyak.
- Teks panjang (nama menu, alasan): `overflow: TextOverflow.ellipsis` + `maxLines` wajar (nama 2 baris, alasan 3 baris) supaya card tidak melar tak terkendali, tapi tidak pernah crop makna inti.

## 8. Empty, error, edge states

- Kartu tanpa tag: `Wrap` kosong tidak dirender (bukan `SizedBox` kosong yang makan ruang).
- Harga null (`MealHistoryEntry.price == null`): tampil "harga belum tercatat" alih-alih "Rp0" atau crash.
- `context_used` semua null: `GroundingBadge` return `SizedBox.shrink()`.
- Error state (`ErrorTurn`): pesan ramah sesuai style guide ("Mapo lagi bingung, coba lagi ya"), tombol retry mengirim ulang pesan user terakhir.
- Riwayat kosong (belum pernah makan lewat Mapo): "Belum ada riwayat. Mulai cerita ke Mapo yuk!" dengan CTA balik ke Cari makan.

## 9. Preview standalone

`lib/ui/debug/mock_data.dart` — factory mock `MapoResponse`/`Recommendation`/`ChatTurn`/`MealHistoryEntry` untuk tiap state (single/options/clarify/error/edge-case kosong).

`lib/ui/debug/screens_gallery.dart` — route debug-only (`kDebugMode`), daftar tombol yang membuka tiap layar/state dengan data mock di atas. Tidak ikut ke build release (dibungkus `if (kDebugMode)` di `main.dart`, tidak ada di navigasi produksi).

## 10. Layout file

```
lib/ui/
  screens/
    chat_screen.dart       (pindah dari lib/ui/, redesign visual)
    riwayat_screen.dart     (baru)
    profil_screen.dart      (baru)
  widgets/
    mapo_header.dart
    chat_input_bar.dart
    recommendation_card.dart  (extend yang sudah ada — tambah variant, scrim, onPick)
    meal_history_tile.dart    (baru)
    category_badge.dart
    quick_reply_chip.dart
    grounding_badge.dart
    pending_checklist.dart
    mapo_drawer.dart
  debug/
    mock_data.dart
    screens_gallery.dart
lib/data/
  meal_history_service.dart  (tambah getMealHistory(), tidak ubah getRecentMeals)
lib/models/
  meal_history_entry.dart   (baru)
```

## 11. Ikon

Pakai `hugeicons` (sudah terpasang di `pubspec.yaml`, bukan `tabler_icons` yang disebut di style guide teks — dependency baru tidak ditambah untuk kebutuhan yang sama). Mapping bentuk mengikuti makna ikon di style guide (mangkuk/soup untuk berkuah, api untuk pedas/bakar, dsb), bukan nama ikon literalnya.

## 12. Login Google (Profil)

UI shell saja: tombol "Masuk Google biar gak hilang" dengan `onPressed` callback stub (`TODO`). Tidak menambah dependency `google_sign_in`, tidak wiring `linkWithCredential` — di luar scope UI ini (dikonfirmasi user).

## 13. Urutan implementasi

Sesuai prioritas yang ditentukan user: `RecommendationCard` (hero) → `ChatInputBar` → layar Single → layar Clarify → sisanya (Options, Home, Loading, Riwayat, Menu, Profil, debug gallery).

## Di luar scope

- Task 6–9 dari plan arsitektur (loop tulis Firestore, `firestore.rules`, Cloud Function cuaca).
- Verifikasi manual di device untuk Task 3 Step 12 dan Task 5 Step 9 (butuh device fisik + `WEATHER_API_KEY` asli).
- Wiring Google Sign-In sungguhan.
- Progress event asli dari backend untuk `PendingChecklist` (simulasi timed, bukan real progress).
