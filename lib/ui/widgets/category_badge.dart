import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

/// Pill kecil warna kategori — ikon+label. Selalu `tone.fill` (latar) +
/// `tone.dark` (teks/ikon), sesuai Accessibility Rule B di plan: `tone.base`
/// sebagai foreground di atas latar terang gagal kontras di semua kategori.
class CategoryBadge extends StatelessWidget {
  final String category;
  final String label;

  const CategoryBadge({super.key, required this.category, required this.label});

  @override
  Widget build(BuildContext context) {
    final tone = categoryTone(category);
    return Semantics(
      label: label,
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: AppSpacing.badgePad,
        decoration: BoxDecoration(color: tone.fill, borderRadius: AppRadius.rBadge),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: categoryIcon(category), color: tone.dark, size: AppSizes.iconSmall),
            const SizedBox(width: AppSpacing.xs / 2),
            Text(
              label,
              style: AppText.caption.copyWith(color: tone.dark, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
