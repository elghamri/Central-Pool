import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'app_buttons.dart';

/// Modal dialog for confirming critical financial or administrative actions.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final bool isLoading;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.isDestructive = false,
    this.isLoading = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmationDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.borderLg,
        side: BorderSide(color: AppColors.borderSubtle, width: 1.0),
      ),
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(content, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: cancelLabel,
                  isFullWidth: false,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: AppSpacing.sm),
                isDestructive
                    ? DangerButton(
                        label: confirmLabel,
                        isFullWidth: false,
                        isLoading: isLoading,
                        onPressed: onConfirm,
                      )
                    : PrimaryButton(
                        label: confirmLabel,
                        isFullWidth: false,
                        isLoading: isLoading,
                        onPressed: onConfirm,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
