import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class PendingChecklist extends StatefulWidget {
  final Duration stepDuration;

  const PendingChecklist({super.key, this.stepDuration = const Duration(milliseconds: 600)});

  @override
  State<PendingChecklist> createState() => _PendingChecklistState();
}

class _PendingChecklistState extends State<PendingChecklist> {
  static const _steps = ['Ngecek cuaca...', 'Ngecek riwayat makan...', 'Menyusun saran...'];

  int _stage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.stepDuration, (timer) {
      if (_stage >= _steps.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _stage++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSquareLock01,
              color: AppColors.brandDark,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('Mapo lagi mikir...', style: AppText.section),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i <= _stage && i < _steps.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) => Opacity(opacity: value, child: child),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  HugeIcon(
                    icon: i < _stage
                        ? HugeIcons.strokeRoundedCheckmarkCircle01
                        : HugeIcons.strokeRoundedClock01,
                    color: i < _stage ? AppColors.green : AppColors.inkFaint,
                    size: AppSizes.iconSmall,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_steps[i], style: AppText.bodyMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
