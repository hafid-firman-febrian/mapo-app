import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool enabled;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  void _submit() {
    final text = controller.text;
    if (text.trim().isEmpty) return;
    onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.page,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Opacity(
              opacity: enabled ? 1.0 : 0.6,
              child: TextField(
                controller: controller,
                enabled: enabled,
                style: AppText.bodyLarge,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: enabled ? 'Lagi pengen apa?' : 'Tunggu sebentar...',
                ),
                onSubmitted: enabled ? (_) => _submit() : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: 'Kirim pesan',
            button: true,
            enabled: enabled,
            container: true,
            excludeSemantics: true,
            child: SizedBox(
              width: AppSizes.sendButton,
              height: AppSizes.sendButton,
              child: Material(
                color: enabled ? AppColors.brand : AppColors.inkFaint,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enabled ? _submit : null,
                  child: Center(
                    // Ikon `ink` di atas `brand` = 6.90:1. Putih cuma 2.03:1 —
                    // di bawah minimum 3:1 WCAG 1.4.11 untuk ikon kontrol.
                    // State disabled (`inkFaint`) dikecualikan oleh 1.4.11.
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSent02,
                      color: enabled ? AppColors.ink : Colors.white,
                      size: AppSizes.iconMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
