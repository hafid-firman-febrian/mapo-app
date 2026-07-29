import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_prefs.dart';
import '../../providers/mapo_providers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import 'quick_reply_chip.dart';

class PrefsEditSheet extends ConsumerStatefulWidget {
  final UserPrefs initial;

  const PrefsEditSheet({super.key, required this.initial});

  static Future<void> show(BuildContext context, UserPrefs initial) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge)),
    ),
    builder: (_) => PrefsEditSheet(initial: initial),
  );

  @override
  ConsumerState<PrefsEditSheet> createState() => _PrefsEditSheetState();
}

class _PrefsEditSheetState extends ConsumerState<PrefsEditSheet> {
  late UserPrefs _draft = widget.initial;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(chatProvider.notifier).savePrefs(_draft);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _toggleRestriction(String r) {
    final selected = _draft.restrictions.contains(r);
    final next = [..._draft.restrictions];
    selected ? next.remove(r) : next.add(r);
    setState(() => _draft = _draft.copyWith(restrictions: next));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selera kamu', style: AppText.section),
          const SizedBox(height: AppSpacing.lg),
          Text('Budget biasanya', style: AppText.bodyLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: UserPrefs.budgetOptions
                .map(
                  (b) => QuickReplyChip(
                    label: b,
                    selected: _draft.budgetRange == b,
                    onTap: () => setState(() => _draft = _draft.copyWith(budgetRange: b)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Pantangan', style: AppText.bodyLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: UserPrefs.restrictionOptions
                .map(
                  (r) => QuickReplyChip(
                    label: r,
                    selected: _draft.restrictions.contains(r),
                    onTap: () => _toggleRestriction(r),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.ink,
                padding: AppSpacing.buttonPad,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}
