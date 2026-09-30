import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/contribution_models.dart';

/// Screen 11: Payment Method Selection View.
class PaymentMethodView extends StatelessWidget {
  final List<PaymentMethodItem> methods;
  final PaymentMethodItem selectedMethod;
  final ValueChanged<PaymentMethodItem> onSelectMethod;
  final VoidCallback onProceedToReview;
  final VoidCallback onBack;

  const PaymentMethodView({
    super.key,
    required this.methods,
    required this.selectedMethod,
    required this.onSelectMethod,
    required this.onProceedToReview,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: onBack,
                tooltip: 'Back to Details',
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Select Payment Method',
                  style: AppTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Choose your preferred institutional clearing rail for your \$500.00 contribution.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Security & Sandbox Advisory
          _buildSecurityAdvisory(),
          const SizedBox(height: AppSpacing.lg),

          // Payment Methods List
          for (final method in methods) ...[
            _buildMethodCard(method),
            const SizedBox(height: AppSpacing.md),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Action Buttons
          PrimaryButton(
            label: 'Proceed to Review (${selectedMethod.title})',
            icon: Icons.check_circle_outline,
            onPressed: selectedMethod.isAvailable ? onProceedToReview : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Back to Contribution Details',
            onPressed: onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAdvisory() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border:
            Border.all(color: AppColors.sovereignGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              color: AppColors.sovereignGold, size: 22.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Clearing Rail Guard',
                  style: AppTypography.labelMedium.copyWith(
                      color: AppColors.sovereignGold,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'All transactions are processed through authenticated double-entry accounting. Real-money movement is disabled; test execution operates via simulated RTGS settlement.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethodItem method) {
    final isSelected = method.id == selectedMethod.id;
    final isAvailable = method.isAvailable;

    return InkWell(
      onTap: isAvailable ? () => onSelectMethod(method) : null,
      borderRadius: AppRadii.borderMd,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : AppColors.cardSurface,
          borderRadius: AppRadii.borderMd,
          border: Border.all(
            color: isSelected
                ? AppColors.emeraldGreen
                : (isAvailable
                    ? AppColors.borderSubtle
                    : AppColors.borderSubtle.withValues(alpha: 0.3)),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.emeraldGreen.withValues(alpha: 0.2)
                    : AppColors.surfaceElevated,
                borderRadius: AppRadii.borderSm,
              ),
              child: Icon(
                method.icon,
                color: isSelected
                    ? AppColors.emeraldGreen
                    : (isAvailable
                        ? AppColors.textPrimary
                        : AppColors.textMuted),
                size: 24.0,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          method.title,
                          style: AppTypography.titleSmall.copyWith(
                            color: isAvailable
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (method.badgeLabel != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        StatusBadge(
                          label: method.badgeLabel!,
                          type: method.isSandbox
                              ? StatusBadgeType.warning
                              : StatusBadgeType.success,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    isAvailable
                        ? method.subtitle
                        : (method.disabledReason ?? method.subtitle),
                    style: AppTypography.bodySmall.copyWith(
                      color: isAvailable
                          ? AppColors.textSecondary
                          : AppColors.crimsonRed,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // ignore: deprecated_member_use
            Radio<String>(
              value: method.id,
              // ignore: deprecated_member_use
              groupValue: selectedMethod.id,
              // ignore: deprecated_member_use
              onChanged: isAvailable ? (_) => onSelectMethod(method) : null,
              activeColor: AppColors.emeraldGreen,
            ),
          ],
        ),
      ),
    );
  }
}
