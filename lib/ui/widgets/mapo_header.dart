import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class MapoHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final Widget? leading;
  final List<Widget>? actions;

  const MapoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.color = AppColors.brand,
    this.leading,
    this.actions,
  });

  // 108 base fits the title alone. Subtitle and the leading/actions icon row
  // each add their own vertical space independently (a header can have both,
  // e.g. RiwayatScreen) — otherwise the icon row pushes the title into
  // overflow, which is exactly what a naive `subtitle == null ? 108 : 132`
  // misses.
  @override
  Size get preferredSize {
    var height = 108.0;
    if (subtitle != null) height += 24;
    if (leading != null || actions != null) height += 60;
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.cardLarge),
          bottomRight: Radius.circular(AppRadius.cardLarge),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppSpacing.screenPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null || actions != null)
                Row(children: [?leading, const Spacer(), ...?actions]),
              if (leading != null || actions != null)
                const SizedBox(height: AppSpacing.sm),
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                title,
                style: AppText.display2.copyWith(color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon bulat putih di dalam header berwarna — dipakai untuk
/// back/hamburger/profil. Selalu 48x48 dan Semantics-labeled.
class MapoHeaderIconButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  const MapoHeaderIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      container: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: AppColors.ink,
                size: AppSizes.iconMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
