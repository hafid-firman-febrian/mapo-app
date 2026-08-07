import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/auth_service.dart';
import '../../models/user_prefs.dart';
import '../../providers/mapo_providers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../widgets/mapo_header.dart';
import '../widgets/prefs_edit_sheet.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  bool _busy = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).linkOrSignInWithGoogle();
    } on GoogleSignInCancelledException {
      // User membatalkan picker — diam saja, bukan error.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal masuk, coba lagi ya')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleSignOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Konfirmasi'),
        content: Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              setState(() => _busy = true);
              try {
                await ref.read(authServiceProvider).signOut();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal keluar, coba lagi ya')),
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              'Mapo lagi bingung, coba lagi ya',
              style: AppText.bodyLarge,
            ),
          ),
        ),
        data: (prefs) => ProfilBody(
          displayName: userDisplay.displayName,
          isAnonymous: userDisplay.isAnonymous,
          prefs: prefs,
          busy: _busy,
          email: userDisplay.email,
          onGoogleSignInTap: _handleGoogleSignIn,
          onSignOutTap: _handleSignOut,
          onEditPrefs: () => PrefsEditSheet.show(context, prefs),
        ),
      ),
    );
  }
}

class ProfilBody extends StatelessWidget {
  final String displayName;
  final String? email;
  final bool isAnonymous;
  final UserPrefs prefs;
  final VoidCallback onGoogleSignInTap;
  final VoidCallback onSignOutTap;
  final VoidCallback onEditPrefs;
  final bool busy;

  const ProfilBody({
    super.key,
    required this.displayName,
    required this.isAnonymous,
    required this.prefs,
    required this.onGoogleSignInTap,
    required this.onSignOutTap,
    required this.onEditPrefs,
    this.busy = false,
    this.email,
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
                decoration: const BoxDecoration(
                  color: AppColors.brandFill,
                  shape: BoxShape.circle,
                ),
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
              if (email != null) Text(email ?? '', style: AppText.bodyLarge),

              Text(
                isAnonymous
                    ? 'Anonim · belum tersimpan'
                    : 'Tersimpan dengan Google',
                style: AppText.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isAnonymous)
          Container(
            padding: AppSpacing.cardPadSmall,
            decoration: BoxDecoration(
              color: AppColors.blueFill,
              borderRadius: AppRadius.rCardSmall,
            ),
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
                        style: AppText.caption.copyWith(
                          color: AppColors.blueDark,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: busy ? null : onGoogleSignInTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Masuk'),
                ),
              ],
            ),
          )
        else
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: busy ? null : onSignOutTap,
              child: const Text('Keluar'),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PREFERENSI',
              style: AppText.caption.copyWith(letterSpacing: 1),
            ),
            Semantics(
              label: 'Ubah preferensi',
              button: true,
              container: true,
              excludeSemantics: true,
              child: InkWell(
                onTap: onEditPrefs,
                borderRadius: AppRadius.rIconBox,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedEdit02,
                    color: AppColors.brandDark,
                    size: AppSizes.iconSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _PrefRow(
          icon: HugeIcons.strokeRoundedWallet01,
          label: 'Budget biasa',
          value: prefs.budgetRange,
        ),
        _PrefRow(
          icon: HugeIcons.strokeRoundedFire,
          label: 'Pantangan',
          value: prefs.restrictions.isEmpty
              ? 'tidak ada'
              : prefs.restrictions.join(', '),
        ),
      ],
    );
  }
}

class _PrefRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;

  const _PrefRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            color: AppColors.inkSoft,
            size: AppSizes.iconMedium,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppText.bodyLarge)),
          Text(
            value,
            style: AppText.bodyMedium.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
