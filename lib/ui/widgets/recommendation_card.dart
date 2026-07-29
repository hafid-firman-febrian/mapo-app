import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/mapo_response.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../../utils/currency.dart';

enum RecommendationCardVariant { hero, row }

class RecommendationCard extends StatefulWidget {
  final Recommendation recommendation;
  final RecommendationCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onPick;
  final VoidCallback? onRetry;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.variant = RecommendationCardVariant.hero,
    this.onTap,
    this.onPick,
    this.onRetry,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tone = categoryTone(widget.recommendation.category);
    final isHero = widget.variant == RecommendationCardVariant.hero;

    final card = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: tone.base,
        borderRadius: isHero ? AppRadius.rCardLarge : AppRadius.rCardSmall,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: isHero
              ? _HeroContent(
                  recommendation: widget.recommendation,
                  onPick: widget.onPick,
                  onRetry: widget.onRetry,
                )
              : _RowContent(recommendation: widget.recommendation),
        ),
      ),
    );

    // Hero adalah kartu "utama" — di layar tablet lebar penuh terasa kayak
    // banner, bukan pesan chat. Row (Options) sengaja tidak dibatasi, tetap
    // ikut lebar list seperti daftar pilihan biasa.
    if (!isHero) return card;
    return ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: card);
  }
}

/// Panel scrim rata di belakang teks — Accessibility Rule A. 0.35 dipilih
/// supaya kasus terburuk (brand/amber) masih lolos kontras AA 4.5:1 dengan
/// teks putih (lihat spec §4 untuk perhitungannya). Jangan diturunkan.
class _ScrimText extends StatelessWidget {
  final Widget child;

  const _ScrimText({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.iconBox),
      ),
      child: child,
    );
  }
}

List<String> _tags(Recommendation r) => [
      r.category,
      if (r.spiceLevel != 'tidak_pedas') r.spiceLevel.replaceAll('_', ' '),
      r.prepTime,
      ...r.tags,
    ];

class _HeroContent extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback? onPick;
  final VoidCallback? onRetry;

  const _HeroContent({required this.recommendation, this.onPick, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    final tags = _tags(r);

    return Padding(
      padding: AppSpacing.cardPadLarge,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: AppColors.overlayCircle, shape: BoxShape.circle),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.iconBoxLarge,
                height: AppSizes.iconBoxLarge,
                decoration: BoxDecoration(color: AppColors.overlayIcon, borderRadius: AppRadius.rIconBox),
                child: Center(
                  child: HugeIcon(icon: categoryIcon(r.category), color: Colors.white, size: AppSizes.iconLarge),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ScrimText(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      r.name,
                      style: AppText.title.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      r.reason,
                      style: AppText.bodyLarge.copyWith(color: Colors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: tags
                            .map(
                              (t) => Container(
                                padding: AppSpacing.badgePad,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.rBadge,
                                ),
                                child: Text(t, style: AppText.caption.copyWith(color: Colors.white)),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPick,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Makan ini'),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Semantics(
                      label: 'Cari saran lain',
                      button: true,
                      container: true,
                      excludeSemantics: true,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          onPressed: onRetry,
                          style: IconButton.styleFrom(backgroundColor: AppColors.overlayIcon),
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedRefresh,
                            color: Colors.white,
                            size: AppSizes.iconMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowContent extends StatelessWidget {
  final Recommendation recommendation;

  const _RowContent({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    return Padding(
      padding: AppSpacing.cardPadSmall,
      child: Row(
        children: [
          Container(
            width: AppSizes.iconBoxSmall,
            height: AppSizes.iconBoxSmall,
            decoration: BoxDecoration(color: AppColors.overlayIcon, borderRadius: AppRadius.rIconBox),
            child: Center(
              child: HugeIcon(icon: categoryIcon(r.category), color: Colors.white, size: AppSizes.iconMedium),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ScrimText(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    r.name,
                    style: AppText.section.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${r.category} · ${r.spiceLevel.replaceAll('_', ' ')}',
                    style: AppText.caption.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Rp${formatRupiah(r.priceEstimate)}',
            style: AppText.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
