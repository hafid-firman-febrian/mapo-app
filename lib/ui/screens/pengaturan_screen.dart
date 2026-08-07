import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/auth_service.dart';
import '../../data/location_service.dart';
import '../../providers/mapo_providers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../widgets/mapo_header.dart';

/// Kosong selama kebijakan privasi belum ada. Barisnya tidak dirender sama
/// sekali selagi konstanta ini kosong — begitu diisi, barisnya muncul sendiri
/// tanpa menyentuh kode lain.
const _privacyPolicyUrl = '';

class PengaturanScreen extends ConsumerStatefulWidget {
  const PengaturanScreen({super.key});

  @override
  ConsumerState<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends ConsumerState<PengaturanScreen>
    with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// User pergi ke setelan sistem, mengizinkan, lalu kembali. Tanpa ini
  /// barisnya masih menulis "Ditolak" dan user mengira gagal.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(locationPermissionProvider);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleDeleteHistory() async {
    final ok = await _confirm(
      title: 'Hapus riwayat makan?',
      message:
          'Semua catatan makanmu dihapus dan percakapan dimulai ulang. '
          'Preferensi (budget & pantangan) tetap tersimpan.',
      confirmLabel: 'Hapus',
    );
    // `await _confirm` bisa berdurasi tak terbatas — user boleh berlama-lama di
    // depan dialog, dan layarnya bisa keburu di-dispose. `setState` tanpa
    // penjagaan ini akan melempar.
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(accountActionsProvider).deleteMealHistory();
      _snack('Riwayat makan dihapus');
    } catch (_) {
      _snack('Gagal hapus riwayat, coba lagi ya');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final ok = await _confirm(
      title: 'Hapus akun?',
      message:
          'Riwayat makan, preferensi, dan akunmu dihapus permanen. '
          'Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Hapus akun',
    );
    // Sama seperti _handleDeleteHistory: dialog bisa terbuka lama, layar bisa
    // keburu di-dispose sebelum ini lanjut.
    if (!ok || !mounted) return;

    final isAnonymous = ref.read(currentUserDisplayProvider).isAnonymous;

    setState(() => _busy = true);
    try {
      await ref
          .read(accountActionsProvider)
          .deleteAccount(isAnonymous: isAnonymous);
      if (mounted) {
        // Messenger diambil ke variabel lokal SEBELUM pop. `popUntil` melepas
        // route ini, jadi `ScaffoldMessenger.of(context)` sesudahnya memakai
        // context yang sudah di-deactivate. Messenger-nya sendiri milik
        // MaterialApp — ia hidup lebih lama dari route yang dilepas, dan
        // Scaffold layar awal yang muncul kembali langsung mengambil alih
        // SnackBar yang sedang antre.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).popUntil((route) => route.isFirst);
        messenger.showSnackBar(
          const SnackBar(content: Text('Akun kamu udah dihapus')),
        );
      }
    } on GoogleSignInCancelledException {
      // User menutup picker — batal total, belum ada yang terhapus.
    } catch (_) {
      _snack('Gagal hapus akun, coba lagi ya');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleLocationTap(LocationPermissionStatus? status) async {
    if (status == null) return;
    await ref.read(locationServiceProvider).openSettings(status);
  }

  /// `launchUrl` punya dua cara gagal, bukan satu. Selain mengembalikan `false`
  /// ia juga *melempar* `PlatformException` kalau tidak ada activity yang bisa
  /// menangani intent-nya (perangkat tanpa browser, atau `<queries>` di
  /// AndroidManifest tidak mendaftarkan ACTION_VIEW + skema https di API 30+).
  /// Tanpa `try`, kegagalan itu lolos jadi unhandled exception dan user tidak
  /// melihat apa pun.
  Future<void> _handlePrivacyTap() async {
    try {
      final opened = await launchUrl(
        Uri.parse(_privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) _snack('Gagal membuka tautan');
    } catch (_) {
      _snack('Gagal membuka tautan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = ref.watch(locationPermissionProvider);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: MapoHeader(
        title: 'Pengaturan',
        leading: MapoHeaderIconButton(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          label: 'Kembali',
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: PengaturanBody(
        permission: permission.value,
        appVersion: version.value,
        busy: _busy,
        onLocationTap: () => _handleLocationTap(permission.value),
        onDeleteHistoryTap: _handleDeleteHistory,
        onDeleteAccountTap: _handleDeleteAccount,
        onPrivacyTap: _privacyPolicyUrl.isEmpty ? null : _handlePrivacyTap,
      ),
    );
  }
}

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
