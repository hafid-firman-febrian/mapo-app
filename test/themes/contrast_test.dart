import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/themes/app_colors.dart';
import 'package:mapo_app/themes/app_theme.dart';

/// Perhitungan kontras WCAG 2.x. Ini yang mengunci angka-angka di spec supaya
/// tidak bisa hilang diam-diam: sebelum test ini ada, `_ScrimText` bisa dihapus
/// dan seluruh suite tetap hijau.
///
/// Ambang yang dipakai:
/// - teks normal → 4.5:1 (WCAG 1.4.3 AA)
/// - ikon / komponen UI non-teks → 3:1 (WCAG 1.4.11)
double _linear(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) {
  // Bulatkan ke 8-bit dulu — itu yang benar-benar sampai ke layar.
  double ch(double v) => _linear((v * 255).round() / 255);
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color fg, Color bg) {
  final a = _luminance(fg);
  final b = _luminance(bg);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

Color composite(Color overlay, Color base) {
  final a = overlay.a;
  return Color.from(
    alpha: 1,
    red: overlay.r * a + base.r * (1 - a),
    green: overlay.g * a + base.g * (1 - a),
    blue: overlay.b * a + base.b * (1 - a),
  );
}

const _scrimAlpha = 0.35;

void main() {
  group('Accessibility Rule A — scrim di atas CategoryTone.base', () {
    test('teks putih di atas scrim 0.35 lolos 4.5:1 di semua kategori', () {
      for (final tone in CategoryTone.values) {
        final scrim = composite(Colors.black.withValues(alpha: _scrimAlpha), tone.base);
        expect(
          contrast(Colors.white, scrim),
          greaterThanOrEqualTo(4.5),
          reason: '${tone.name}: scrim $_scrimAlpha tidak cukup untuk teks putih',
        );
      }
    });

    test('scrim memang dibutuhkan — teks putih langsung di atas base gagal', () {
      for (final tone in CategoryTone.values) {
        expect(
          contrast(Colors.white, tone.base),
          lessThan(4.5),
          reason: '${tone.name}: kalau ini lolos, scrim boleh dipertanyakan lagi',
        );
      }
    });
  });

  group('Accessibility Rule A — kotak ikon di atas CategoryTone.base', () {
    test('overlayIcon berbasis hitam, bukan putih', () {
      expect(AppColors.overlayIcon.r, 0);
      expect(AppColors.overlayIcon.g, 0);
      expect(AppColors.overlayIcon.b, 0);
    });

    test('ikon putih di atas overlayIcon lolos 3:1 di semua kategori', () {
      for (final tone in CategoryTone.values) {
        final box = composite(AppColors.overlayIcon, tone.base);
        expect(
          contrast(Colors.white, box),
          greaterThanOrEqualTo(3.0),
          reason: '${tone.name}: kotak ikon gagal WCAG 1.4.11',
        );
      }
    });

    test('overlay putih 20% justru memperburuk — jangan kembali ke sana', () {
      final white20 = Colors.white.withValues(alpha: 0.20);
      for (final tone in CategoryTone.values) {
        final lightened = composite(white20, tone.base);
        final darkened = composite(AppColors.overlayIcon, tone.base);
        expect(
          contrast(Colors.white, darkened),
          greaterThan(contrast(Colors.white, lightened)),
          reason: '${tone.name}: overlay gelap harus lebih kontras dari overlay putih',
        );
      }
    });
  });

  group('Accessibility Rule C — tombol', () {
    // `AppTheme.light` menyentuh GoogleFonts, yang butuh binding widget —
    // makanya dua test ini `testWidgets`, bukan `test`.
    ButtonStyle elevated() => AppTheme.light.elevatedButtonTheme.style!;

    testWidgets('default ElevatedButton lolos 4.5:1', (tester) async {
      final style = elevated();
      final fg = style.foregroundColor!.resolve(<WidgetState>{})!;
      final bg = style.backgroundColor!.resolve(<WidgetState>{})!;
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
    });

    testWidgets('AppText.button tidak menyimpan putih yang gagal di atas brand', (tester) async {
      final textColor = elevated().textStyle!.resolve(<WidgetState>{})!.color!;
      expect(contrast(textColor, AppColors.brand), greaterThanOrEqualTo(4.5));
    });

    test('pasangan warna tombol "Masuk" di Profil lolos 4.5:1', () {
      expect(contrast(Colors.white, AppColors.blueDark), greaterThanOrEqualTo(4.5));
    });

    test('ikon kirim di ChatInputBar lolos 3:1 di atas brand', () {
      expect(contrast(AppColors.ink, AppColors.brand), greaterThanOrEqualTo(3.0));
    });

    test('onCard: teks tombol lolos 4.5:1 di atas isiannya, di semua tone', () {
      for (final tone in CategoryTone.values) {
        final style = AppButtonStyles.onCard(tone);
        final fg = style.foregroundColor!.resolve(<WidgetState>{})!;
        final bg = style.backgroundColor!.resolve(<WidgetState>{})!;
        expect(
          contrast(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: 'kartu ${tone.name}: teks tombol tidak terbaca di atas isiannya',
        );
      }
    });

    test('onCard: isian tombol tidak pernah sewarna kartunya', () {
      for (final tone in CategoryTone.values) {
        final bg = AppButtonStyles.onCard(tone).backgroundColor!.resolve(<WidgetState>{})!;
        expect(
          bg,
          isNot(tone.base),
          reason: 'kartu ${tone.name}: tombol menyatu dengan kartu, terlihat mati',
        );
      }
    });

    test('tombol brand di kartu amber memang tak terlihat — sebab onCard ada', () {
      // CategoryTone.amber.base == AppColors.brand, jadi tombol default
      // menyatu total dengan kartu kategori manis/cemilan.
      expect(contrast(AppColors.brand, CategoryTone.amber.base), lessThan(3.0));
    });

    test('putih di atas brand/blue memang gagal — dokumentasi kenapa ink dipakai', () {
      expect(contrast(Colors.white, AppColors.brand), lessThan(4.5));
      expect(contrast(Colors.white, AppColors.blue), lessThan(4.5));
      // ink di atas blue lebih buruk lagi — sebabnya "Masuk" pindah ke blueDark
      // alih-alih ikut mengganti foreground jadi ink.
      expect(contrast(AppColors.ink, AppColors.blue), lessThan(contrast(Colors.white, AppColors.blue)));
    });
  });
}
