import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppText {
  AppText._();

  static TextStyle get _base => GoogleFonts.poppins();

  static TextStyle get display1 => _base.copyWith(
    fontSize: 42,
    fontWeight: FontWeight.w600,
    height: 1.05,
    color: AppColors.ink,
  );

  static TextStyle get display2 => _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.1,
    color: AppColors.ink,
  );

  static TextStyle get title => _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static TextStyle get section => _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static TextStyle get bodyLarge => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.ink,
  );

  static TextStyle get bodyMedium => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.inkSoft,
  );

  static TextStyle get caption => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.inkSoft,
  );

  static TextStyle get button => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get chip =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600);
}
