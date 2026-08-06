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
      final (icon, tone) = _weatherVisual(ctx.weather!);
      return (
        icon: icon,
        label: 'dipilih karena cuaca ${ctx.weather}',
        tone: tone,
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

  (List<List<dynamic>>, CategoryTone) _weatherVisual(String description) {
    final d = description.toLowerCase();
    if (d.contains('petir') || d.contains('badai') || d.contains('guntur')) {
      return (HugeIcons.strokeRoundedCloudAngledRainZap, CategoryTone.red);
    }
    if (d.contains('salju')) {
      return (HugeIcons.strokeRoundedSnow, CategoryTone.blue);
    }
    if (d.contains('hujan') || d.contains('gerimis') || d.contains('rintik')) {
      return (HugeIcons.strokeRoundedCloudAngledRain, CategoryTone.blue);
    }
    if (d.contains('cerah') || d.contains('panas') || d.contains('terik')) {
      return (HugeIcons.strokeRoundedSun01, CategoryTone.amber);
    }
    return (HugeIcons.strokeRoundedCloud, CategoryTone.blue);
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
              color: AppColors.ink,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSpacing.xs / 2),
            Flexible(
              child: Text(
                visual.label,
                style: AppText.caption.copyWith(
                  color: AppColors.ink,
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
