import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/user_prefs.dart';
import '../../providers/mapo_providers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../widgets/mapo_header.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(prefsProvider);
    final userDisplay = ref.watch(currentUserDisplayProvider);

    return Scaffold(
      appBar: MapoHeader(
        title: 'Profil',
        leading: MapoHeaderIconButton(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          label: 'Kembali',
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: AppSpacing.screenPad,
            child: Text('Mapo lagi bingung, coba lagi ya', style: AppText.bodyLarge),
          ),
        ),
        data: (prefs) => ProfilBody(
          displayName: userDisplay.displayName,
          isAnonymous: userDisplay.isAnonymous,
          prefs: prefs,
          onGoogleSignInTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Masuk Google belum tersambung — segera hadir')),
            );
          },
        ),
      ),
    );
  }
}

class ProfilBody extends StatelessWidget {
  final String displayName;
  final bool isAnonymous;
  final UserPrefs prefs;
  final VoidCallback onGoogleSignInTap;

  const ProfilBody({
    super.key,
    required this.displayName,
    required this.isAnonymous,
    required this.prefs,
    required this.onGoogleSignInTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPad,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: AppSizes.iconBoxLarge,
                height: AppSizes.iconBoxLarge,
                decoration: const BoxDecoration(color: AppColors.brandFill, shape: BoxShape.circle),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedUserCircle,
                    color: AppColors.brand,
                    size: AppSizes.iconLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(displayName, style: AppText.title),
              Text(
                isAnonymous ? 'Anonim · belum tersimpan' : 'Tersimpan dengan Google',
                style: AppText.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isAnonymous)
          Container(
            padding: AppSpacing.cardPadSmall,
            decoration: BoxDecoration(color: AppColors.blueFill, borderRadius: AppRadius.rCardSmall),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Simpan histori kamu',
                        style: AppText.bodyLarge.copyWith(
                          color: AppColors.blueDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Masuk Google biar gak hilang',
                        style: AppText.caption.copyWith(color: AppColors.blueDark),
                      ),
                    ],
                  ),
                ),
                // Latar `blueDark`, bukan `blue`: putih di atas `blue` cuma
                // 4.16:1 (di bawah AA 4.5:1) dan `ink` di atas `blue` malah
                // lebih buruk (3.37:1). `blueDark` + putih = 6.22:1, dan tetap
                // biru — sama seperti Rule B yang memakai `tone.dark` sebagai
                // varian yang lolos kontras.
                ElevatedButton(
                  onPressed: onGoogleSignInTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Masuk'),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text('PREFERENSI', style: AppText.caption.copyWith(letterSpacing: 1)),
        const SizedBox(height: AppSpacing.xs),
        _PrefRow(icon: HugeIcons.strokeRoundedWallet01, label: 'Budget biasa', value: prefs.budgetRange),
        _PrefRow(
          icon: HugeIcons.strokeRoundedFire,
          label: 'Pantangan',
          value: prefs.restrictions.isEmpty ? 'tidak ada' : prefs.restrictions.join(', '),
        ),
      ],
    );
  }
}

class _PrefRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;

  const _PrefRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: AppColors.inkSoft, size: AppSizes.iconMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppText.bodyLarge)),
          Text(value, style: AppText.bodyMedium.copyWith(color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}
