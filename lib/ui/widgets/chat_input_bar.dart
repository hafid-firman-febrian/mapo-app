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
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: AppText.bodyLarge,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: enabled ? 'Lagi pengen apa?' : 'Tunggu sebentar...',
                fillColor: enabled ? null : AppColors.line,
              ),
              onSubmitted: enabled ? (_) => _submit() : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: 'Kirim pesan',
            button: true,
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
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSent02,
                      color: Colors.white,
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
