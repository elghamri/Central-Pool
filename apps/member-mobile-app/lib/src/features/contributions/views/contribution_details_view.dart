import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/contribution_models.dart';

/// Screen 10: Contribution Details View.
class ContributionDetailsView extends StatelessWidget {
  final ContributionDetail detail;
  final VoidCallback onContinueToPayment;
  final VoidCallback onBack;

  const ContributionDetailsView({
    super.key,
    required this.detail,
    required this.onContinueToPayment,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Back Header
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: onBack,
                tooltip: 'Back to Overview',
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Contribution Details',
                  style: AppTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Main Detail Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        detail.title,
                        style: AppTypography.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const StatusBadge(
                        label: 'DUE NOW', type: StatusBadgeType.warning),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.md),

                // Amount Showcase
                Center(
                  child: Column(
                    children: [
                      Text('Amount Due',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4.0),
                      FinancialAmountText(
                        amountMinor: detail.amountMinor,
                        style: AppTypography.financialDisplay.copyWith(
                          fontSize: 36.0,
                          color: AppColors.emeraldGreen,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Scheduled settlement via FedNow RTGS rail',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Key Context Rows
                _buildInfoRow('Cooperative Cycle',
                    '${detail.cycleName} (${detail.cycleId})'),
                _buildInfoRow('Enrolled Member',
                    '${detail.memberName} (${detail.memberId})'),
                _buildInfoRow('Rotation Slot',
                    'Slot #${detail.slotPosition} of ${detail.totalSlots}'),
                _buildInfoRow('Due Date',
                    '${detail.dueDate.year}-${detail.dueDate.month.toString().padLeft(2, '0')}-${detail.dueDate.day.toString().padLeft(2, '0')} (5 days remaining)'),
                _buildInfoRow('Total Contributed to Date',
                    '\$${(detail.totalContributedMinor / 100).toStringAsFixed(2)} USD'),
                _buildInfoRow('Remaining Cycle Balance',
                    '\$${(detail.remainingCycleObligationMinor / 100).toStringAsFixed(2)} USD'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          PrimaryButton(
            label: 'Continue to Payment',
            icon: Icons.arrow_forward,
            onPressed: onContinueToPayment,
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Cancel & Return to Overview',
            onPressed: onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
}
