import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/mapo_response.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class GroundingBadge extends StatelessWidget {
  final ContextUsed? contextUsed;

  const GroundingBadge({super.key, this.contextUsed});

  String? get _label {
    final ctx = contextUsed;
    if (ctx == null) return null;
    if (ctx.weather != null && ctx.weather!.isNotEmpty) {
      return 'dipilih karena cuaca ${ctx.weather}';
    }
    if (ctx.basedOnHistory) return 'dipilih berdasarkan riwayat kamu';
    if (ctx.timeOfDay != null && ctx.timeOfDay!.isNotEmpty) {
      return 'pas buat ${ctx.timeOfDay!.replaceAll('_', ' ')}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) return const SizedBox.shrink();

    return Semantics(
      label: label,
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: AppSpacing.badgePad,
        decoration: BoxDecoration(
          color: AppColors.blueFill,
          borderRadius: AppRadius.rBadge,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCloud,
              color: AppColors.blueDark,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSpacing.xs / 2),
            Flexible(
              child: Text(
                label,
                style: AppText.caption.copyWith(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
