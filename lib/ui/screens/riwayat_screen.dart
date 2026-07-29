import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/meal_history_entry.dart';
import '../../providers/mapo_providers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../widgets/mapo_header.dart';
import '../widgets/meal_history_tile.dart';

class RiwayatScreen extends ConsumerWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(mealHistoryEntriesProvider);

    return Scaffold(
      appBar: MapoHeader(
        title: 'Riwayat makan',
        subtitle: 'Mapo pakai ini biar gak nyaranin yang sama',
        color: AppColors.green,
        leading: MapoHeaderIconButton(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          label: 'Kembali',
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: AppSpacing.screenPad,
            child: Text('Mapo lagi bingung, coba lagi ya', style: AppText.bodyLarge),
          ),
        ),
        data: (entries) => RiwayatBody(entries: entries),
      ),
    );
  }
}

class RiwayatBody extends StatelessWidget {
  final List<MealHistoryEntry> entries;

  const RiwayatBody({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.screenPad,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Belum ada riwayat.', style: AppText.section, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Mulai cerita ke Mapo yuk, biar riwayat makanmu kecatat di sini.',
                style: AppText.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final stats = MealHistoryStats.fromEntries(entries);
    final grouped = _groupByDay(entries);

    return ListView(
      padding: AppSpacing.screenPad,
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(value: '${stats.countThisWeek}', label: 'makan minggu ini')),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(value: stats.mostCommonCategory ?? '—', label: 'paling sering'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final group in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(group.key, style: AppText.caption.copyWith(letterSpacing: 1)),
          ),
          for (final entry in group.value) MealHistoryTile(entry: entry),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Map<String, List<MealHistoryEntry>> _groupByDay(List<MealHistoryEntry> entries) {
    final grouped = <String, List<MealHistoryEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(_dayLabel(e.eatenAt), () => []).add(e);
    }
    return grouped;
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadSmall,
      decoration: BoxDecoration(color: AppColors.brandFill, borderRadius: AppRadius.rCardSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppText.title.copyWith(color: AppColors.brandDark)),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}
