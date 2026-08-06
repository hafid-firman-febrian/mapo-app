import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/mapo_response.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class GroundingBadge extends StatelessWidget {
  final ContextUsed? contextUsed;

  const GroundingBadge({super.key, this.contextUsed});

  ({List<List<dynamic>> icon, String label, CategoryTone tone})? get _visual {
    final ctx = contextUsed;
    if (ctx == null) return null;
    if (ctx.weather != null && ctx.weather!.isNotEmpty) {
      return (
        icon: HugeIcons.strokeRoundedCloud,
        label: 'dipilih karena cuaca ${ctx.weather}',
        tone: CategoryTone.blue,
      );
    }
    if (ctx.basedOnHistory) {
      return (
        icon: HugeIcons.strokeRoundedClock01,
        label: 'dipilih berdasarkan riwayat kamu',
        tone: CategoryTone.amber,
      );
    }
    if (ctx.timeOfDay != null && ctx.timeOfDay!.isNotEmpty) {
      return (
        icon: HugeIcons.strokeRoundedTime01,
        label: 'pas buat ${ctx.timeOfDay!.replaceAll('_', ' ')}',
        tone: CategoryTone.green,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    if (visual == null) return const SizedBox.shrink();

    return Semantics(
      label: visual.label,
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: AppSpacing.badgePad,
        decoration: BoxDecoration(
          color: visual.tone.fill,
          borderRadius: AppRadius.rBadge,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: visual.icon,
              color: visual.tone.dark,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSpacing.xs / 2),
            Flexible(
              child: Text(
                visual.label,
                style: AppText.caption.copyWith(
                  color: visual.tone.dark,
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
