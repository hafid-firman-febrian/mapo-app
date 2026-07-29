import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class QuickReplyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const QuickReplyChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  /// Quick reply dari Gemini adalah teks bebas, bukan salah satu dari 10
  /// category enum di mapo_schema.dart — tone di sini cuma tebakan kata
  /// kunci untuk variasi visual, bukan pemetaan kategori yang tegas.
  CategoryTone get _tone {
    final lower = label.toLowerCase();
    if (lower.contains('pedas') || lower.contains('bakar')) return CategoryTone.red;
    if (lower.contains('sehat')) return CategoryTone.green;
    if (lower.contains('murah') || lower.contains('budget') || lower.contains('hemat')) {
      return CategoryTone.amber;
    }
    return CategoryTone.blue;
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: AppSpacing.chipPad,
          decoration: BoxDecoration(
            color: selected ? tone.fill : Colors.transparent,
            border: Border.all(color: tone.dark, width: 1.5),
            borderRadius: AppRadius.rChip,
          ),
          child: Text(label, style: AppText.chip.copyWith(color: tone.dark)),
        ),
      ),
    );
  }
}
