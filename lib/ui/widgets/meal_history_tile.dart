import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/meal_history_entry.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../../utils/currency.dart';

class MealHistoryTile extends StatelessWidget {
  final MealHistoryEntry entry;

  const MealHistoryTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final tone = categoryTone(entry.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: AppSizes.listAvatar,
            height: AppSizes.listAvatar,
            decoration: BoxDecoration(color: tone.fill, borderRadius: AppRadius.rIconBox),
            child: Center(
              child: HugeIcon(icon: categoryIcon(entry.category), color: tone.dark, size: AppSizes.iconMedium),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: AppText.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('${entry.category} · ${_formatTime(entry.eatenAt)}', style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            entry.price == null ? 'harga belum tercatat' : 'Rp${formatRupiah(entry.price!)}',
            style: entry.price == null
                ? AppText.caption.copyWith(fontStyle: FontStyle.italic)
                : AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
