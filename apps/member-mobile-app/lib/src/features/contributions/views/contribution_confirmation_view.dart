import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/contribution_models.dart';

/// Screen 12: Contribution Confirmation View.
class ContributionConfirmationView extends StatelessWidget {
  final ContributionDetail detail;
  final PaymentMethodItem paymentMethod;
  final bool isSubmitting;
  final VoidCallback onConfirmPayment;
  final VoidCallback onBack;

  const ContributionConfirmationView({
    super.key,
    required this.detail,
    required this.paymentMethod,
    required this.isSubmitting,
    required this.onConfirmPayment,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: isSubmitting ? null : onBack,
                tooltip: 'Back to Payment Method',
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Confirm Contribution',
                  style: AppTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Please review your transaction details before authorizing payment dispatch.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary Confirmation Summary Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Authorization Summary',
                        style: AppTypography.titleMedium),
                    StatusBadge(
                        label: 'READY TO DISPATCH', type: StatusBadgeType.info),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.md),

                // Amount Showcase
                Center(
                  child: Column(
                    children: [
                      Text('Total Authorization Amount',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4.0),
                      FinancialAmountText(
                        amountMinor: detail.amountMinor,
                        style: AppTypography.financialDisplay.copyWith(
                          fontSize: 34.0,
                          color: AppColors.emeraldGreen,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text('USD • Zero Transaction Fee',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Details Rows
                _buildSummaryRow('Contribution Obligation', detail.title),
                _buildSummaryRow('Cycle Identifier', detail.cycleId),
                _buildSummaryRow('Cooperative Name', detail.cycleName),
                _buildSummaryRow('Member / Debtor',
                    '${detail.memberName} (${detail.memberId})'),
                _buildSummaryRow('Clearing Rail', paymentMethod.title),
                _buildSummaryRow('Settlement Account', paymentMethod.subtitle),
                _buildSummaryRow('New Contributed Total',
                    '\$${((detail.totalContributedMinor + detail.amountMinor) / 100).toStringAsFixed(2)} USD'),
                _buildSummaryRow('New Remaining Obligation',
                    '\$${((detail.remainingCycleObligationMinor - detail.amountMinor) / 100).toStringAsFixed(2)} USD'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Legal & Double-Entry Notice
          _buildLegalNotice(),
          const SizedBox(height: AppSpacing.xl),

          // Confirmation Buttons
          PrimaryButton(
            label: isSubmitting
                ? 'Dispatching Payment...'
                : 'Authorize & Pay (\$500.00)',
            icon: Icons.lock_outline,
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : onConfirmPayment,
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Modify Details / Back',
            onPressed: isSubmitting ? null : onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTypography.labelMedium
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalNotice() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: AppColors.emeraldGreen, size: 20.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'By authorizing this contribution, an immutable double-entry journal entry will be recorded in the cooperative general ledger and reconciled against your cycle position.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
