import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.paper,
      onSurface: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.page,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      // `ink` di atas `brand` = 6.90:1; putih cuma 2.03:1. Pasangan
      // putih-di-atas-brand ini sudah ditolak Accessibility Rule C waktu
      // menentukan warna judul MapoHeader — default tombol ikut aturan sama.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.ink,
          elevation: 0,
          padding: AppSpacing.buttonPad,
          textStyle: AppText.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rButton),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkSoft,
          side: const BorderSide(color: AppColors.line, width: 1.5),
          padding: AppSpacing.buttonPad,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rButton),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lineSoft,
        contentPadding: AppSpacing.inputPad,
        hintStyle: AppText.bodyMedium.copyWith(color: AppColors.inkFaint),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.rInput,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rInput,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rInput,
          borderSide: BorderSide(color: AppColors.brand, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lineSoft,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
