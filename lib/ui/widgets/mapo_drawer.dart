import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

enum MapoDrawerItem { cariMakan, riwayat, pengaturan }

class MapoDrawer extends StatelessWidget {
  final String userName;
  final int? mealCount;
  final ValueChanged<MapoDrawerItem> onNavigate;

  const MapoDrawer({
    super.key,
    required this.userName,
    this.mealCount,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.paper,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: AppSpacing.screenPad,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(AppRadius.cardLarge)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: AppSizes.iconBoxSmall / 2,
                    backgroundColor: Colors.white,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserCircle,
                      color: AppColors.brand,
                      size: AppSizes.iconLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(userName, style: AppText.title.copyWith(color: AppColors.ink)),
                  Text(
                    mealCount == null
                        ? 'Ayo mulai cerita ke Mapo'
                        : 'Sudah $mealCount kali makan bareng Mapo',
                    style: AppText.bodyMedium.copyWith(color: AppColors.ink.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DrawerTile(
              icon: HugeIcons.strokeRoundedSearchArea,
              label: 'Cari makan',
              onTap: () => onNavigate(MapoDrawerItem.cariMakan),
            ),
            _DrawerTile(
              icon: HugeIcons.strokeRoundedClock01,
              label: 'Riwayat makan',
              onTap: () => onNavigate(MapoDrawerItem.riwayat),
            ),
            const _DrawerTile(icon: HugeIcons.strokeRoundedSettings01, label: 'Pengaturan'),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;

  const _DrawerTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        color: enabled ? AppColors.ink : AppColors.inkFaint,
        size: AppSizes.iconMedium,
      ),
      title: Text(
        enabled ? label : '$label (segera hadir)',
        style: AppText.bodyLarge.copyWith(color: enabled ? AppColors.ink : AppColors.inkFaint),
      ),
      enabled: enabled,
      onTap: onTap,
    );
  }
}
