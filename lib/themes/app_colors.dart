import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AppColors {
  AppColors._();

  static const brand = Color(0xFFF5A623);
  static const brandDark = Color(0xFFB8860B);
  static const brandFill = Color(0xFFFDF0D8);

  static const blue = Color(0xFF4A78E0);
  static const blueDark = Color(0xFF2F5BC0);
  static const blueFill = Color(0xFFE7EEFB);

  static const red = Color(0xFFE8544E);
  static const redDark = Color(0xFFC0392B);
  static const redFill = Color(0xFFFBECEB);

  static const green = Color(0xFF3DAE7C);
  static const greenDark = Color(0xFF2A8560);
  static const greenFill = Color(0xFFEBF6F1);

  static const ink = Color(0xFF2C2C2A);
  static const inkSoft = Color(0xFF8A8A85);
  static const inkFaint = Color(0xFFB0A59A);
  static const line = Color(0xFFF0EDE6);
  static const lineSoft = Color(0xFFF5F2EC);
  static const paper = Color(0xFFFFFFFF);
  static const page = Color(0xFFFBFAF7);

  static final onColorSoft = Colors.white.withValues(alpha: 0.90);
  static final onColorFaint = Colors.white.withValues(alpha: 0.85);

  /// Latar kotak ikon di atas `CategoryTone.base` — Accessibility Rule A untuk
  /// ikon. Harus berbasis hitam, bukan putih: overlay putih *menerangkan*
  /// backdrop sehingga ikon putih di atasnya makin tenggelam (kasus terburuk
  /// amber = 1.76:1, jauh di bawah minimum 3:1 WCAG 1.4.11 untuk non-teks).
  /// Hitam 20% menggelapkan backdrop dan membawa kasus terburuk yang sama ke
  /// 3.13:1. Tetap transparan supaya warna kategori masih tembus (frosted),
  /// bukan kotak hitam pekat.
  static final overlayIcon = Colors.black.withValues(alpha: 0.20);

  /// Lingkaran dekoratif di kartu hero — murni ornamen, tidak ada teks/ikon di
  /// atasnya, jadi tidak terikat aturan kontras.
  static final overlayCircle = Colors.white.withValues(alpha: 0.10);
  static final overlayTag = Colors.white.withValues(alpha: 0.20);
}

enum CategoryTone {
  blue(AppColors.blue, AppColors.blueDark, AppColors.blueFill),
  red(AppColors.red, AppColors.redDark, AppColors.redFill),
  green(AppColors.green, AppColors.greenDark, AppColors.greenFill),
  amber(AppColors.brand, AppColors.brandDark, AppColors.brandFill);

  const CategoryTone(this.base, this.dark, this.fill);

  final Color base;
  final Color dark;
  final Color fill;
}

CategoryTone categoryTone(String category) {
  switch (category) {
    case 'pedas':
    case 'bakar':
    case 'goreng':
      return CategoryTone.red;
    case 'sehat':
    case 'mie':
      return CategoryTone.green;
    case 'manis':
    case 'cemilan':
      return CategoryTone.amber;
    case 'berkuah':
    case 'nasi':
    case 'cepat_saji':
    default:
      return CategoryTone.blue;
  }
}

List<List<dynamic>> categoryIcon(String category) {
  switch (category) {
    case 'berkuah':
      return HugeIcons.strokeRoundedRiceBowl01;
    case 'pedas':
      return HugeIcons.strokeRoundedFire;
    case 'bakar':
      return HugeIcons.strokeRoundedBbqGrill;
    case 'goreng':
      return HugeIcons.strokeRoundedChickenThighs;
    case 'manis':
      return HugeIcons.strokeRoundedCakeSlice;
    case 'sehat':
      return HugeIcons.strokeRoundedSalad;
    case 'mie':
      return HugeIcons.strokeRoundedNoodles;
    case 'nasi':
      return HugeIcons.strokeRoundedRiceBowl02;
    case 'cemilan':
      return HugeIcons.strokeRoundedCupcake01;
    case 'cepat_saji':
      return HugeIcons.strokeRoundedFrenchFries01;
    default:
      return HugeIcons.strokeRoundedRestaurant;
  }
}
