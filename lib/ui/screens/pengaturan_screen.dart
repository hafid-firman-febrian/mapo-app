import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/location_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

/// Widget murni tanpa provider — semua data masuk lewat props supaya status
/// izin bisa diuji tanpa menyentuh Geolocator. Pembagian yang sama dengan
/// `ProfilScreen`/`ProfilBody`.
class PengaturanBody extends StatelessWidget {
  /// `null` berarti masih dimuat.
  final LocationPermissionStatus? permission;

  /// `null` berarti masih dimuat.
  final String? appVersion;

  final VoidCallback onLocationTap;
  final VoidCallback onDeleteHistoryTap;
  final VoidCallback onDeleteAccountTap;

  /// `null` menyembunyikan barisnya — dipakai selagi URL kebijakan privasi
  /// belum ada, supaya tidak ada tautan mati yang dirilis.
  final VoidCallback? onPrivacyTap;

  final bool busy;

  const PengaturanBody({
    super.key,
    required this.permission,
    required this.appVersion,
    required this.onLocationTap,
    required this.onDeleteHistoryTap,
    required this.onDeleteAccountTap,
    this.onPrivacyTap,
    this.busy = false,
  });

  String get _permissionLabel => switch (permission) {
    LocationPermissionStatus.granted => 'Diizinkan',
    LocationPermissionStatus.denied => 'Ditolak',
    LocationPermissionStatus.serviceDisabled => 'GPS mati',
    null => '—',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPad,
      children: [
        const _SectionTitle('LOKASI'),
        _SettingRow(
          icon: HugeIcons.strokeRoundedLocation01,
          label: 'Izin lokasi',
          trailing: _permissionLabel,
          // Sudah diizinkan berarti tidak ada yang perlu dibetulkan di setelan.
          onTap: permission == LocationPermissionStatus.granted
              ? null
              : onLocationTap,
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionTitle('DATA'),
        _SettingRow(
          icon: HugeIcons.strokeRoundedDelete02,
          label: 'Hapus riwayat makan',
          onTap: busy ? null : onDeleteHistoryTap,
        ),
        _SettingRow(
          icon: HugeIcons.strokeRoundedUserRemove01,
          label: 'Hapus akun',
          danger: true,
          onTap: busy ? null : onDeleteAccountTap,
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionTitle('TENTANG'),
        _SettingRow(
          icon: HugeIcons.strokeRoundedInformationCircle,
          label: 'Versi',
          trailing: appVersion ?? '—',
        ),
        if (onPrivacyTap != null)
          _SettingRow(
            icon: HugeIcons.strokeRoundedShield01,
            label: 'Kebijakan privasi',
            onTap: onPrivacyTap,
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: AppText.caption.copyWith(letterSpacing: 1)),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool danger;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red : AppColors.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rCardSmall,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: danger ? AppColors.red : AppColors.inkSoft,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label, style: AppText.bodyLarge.copyWith(color: color)),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppText.bodyMedium.copyWith(color: AppColors.inkSoft),
              ),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: AppColors.inkFaint,
                  size: AppSizes.iconSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
