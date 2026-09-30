import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/funding_models.dart';

/// Screen 20: Post-Funding Obligation & Repayment Position View.
class PostFundingObligationView extends StatelessWidget {
  final PostFundingObligation obligation;
  final VoidCallback onInspectAuditStatement;
  final VoidCallback onBack;

  const PostFundingObligationView({
    super.key,
    required this.obligation,
    required this.onInspectAuditStatement,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Header
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: onBack,
                tooltip: 'Back to Settlement',
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Post-Funding Obligation',
                  style: AppTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Primary Obligation Summary Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Capital Obligation Balance',
                        style: AppTypography.titleMedium),
                    StatusBadge(
                        label: obligation.riskStatus,
                        type: StatusBadgeType.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.md),

                // Amount Showcase
                Center(
                  child: Column(
                    children: [
                      Text('Remaining Obligation Due',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4.0),
                      FinancialAmountText(
                        amountMinor: obligation.remainingObligationMinor,
                        style: AppTypography.financialDisplay.copyWith(
                          fontSize: 36.0,
                          color: AppColors.sovereignGold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '9 Monthly Periods Remaining @ \$500.00 / mo',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Progress Bar
                LinearProgressIndicator(
                  value: obligation.totalObligationMinor > 0
                      ? (obligation.repaidAmountMinor /
                              obligation.totalObligationMinor)
                          .clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.emeraldGreen),
                  minHeight: 8.0,
                ),
                const SizedBox(height: AppSpacing.md),

                // Breakdown Rows
                _buildRow('Original Disbursed Capital',
                    '\$${(obligation.originalPayoutMinor / 100).toStringAsFixed(2)} USD'),
                _buildRow('Total Repaid to Date',
                    '\$${(obligation.repaidAmountMinor / 100).toStringAsFixed(2)} USD'),
                _buildRow('Overdue / Delinquent Amount',
                    '\$${(obligation.overdueAmountMinor / 100).toStringAsFixed(2)} USD (Zero Delinquency)'),
                _buildRow('Next Contribution Due',
                    '${obligation.nextDueDate.year}-${obligation.nextDueDate.month.toString().padLeft(2, '0')}-${obligation.nextDueDate.day.toString().padLeft(2, '0')} (Period #2)'),
                _buildRow('Obligation Identifier', obligation.obligationId),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 10-Period Contribution Repayment Schedule
          const Text('Cycle Repayment Schedule',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Each monthly contribution directly reduces your outstanding cycle obligation.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          SurfaceCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: obligation.repaymentSchedule.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.borderSubtle, height: 1.0),
              itemBuilder: (context, index) {
                final item = obligation.repaymentSchedule[index];
                final isPaid = item.status == 'PAID';
                final isDue = item.status == 'DUE';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                              : (isDue
                                  ? AppColors.sovereignGold
                                      .withValues(alpha: 0.15)
                                  : AppColors.surfaceElevated),
                          borderRadius: AppRadii.borderSm,
                        ),
                        child: Icon(
                          isPaid
                              ? Icons.check_circle
                              : (isDue ? Icons.schedule : Icons.event),
                          color: isPaid
                              ? AppColors.emeraldGreen
                              : (isDue
                                  ? AppColors.sovereignGold
                                  : AppColors.textSecondary),
                          size: 18.0,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: AppTypography.labelMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2.0),
                            Text(
                              isPaid
                                  ? 'Settled • Ref: ${item.paymentReference ?? 'PAY-001'}'
                                  : (isDue
                                      ? 'Due in 5 days'
                                      : 'Scheduled period'),
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FinancialAmountText(
                            amountMinor: item.amountMinor,
                            style: AppTypography.titleMedium,
                            color: isPaid
                                ? AppColors.emeraldGreen
                                : AppColors.textPrimary,
                          ),
                          const SizedBox(height: 2.0),
                          StatusBadge(
                            label: item.status,
                            type: isPaid
                                ? StatusBadgeType.success
                                : (isDue
                                    ? StatusBadgeType.warning
                                    : StatusBadgeType.neutral),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Actions
          PrimaryButton(
            label: 'View Cryptographic Audit Statement',
            icon: Icons.lock_clock,
            onPressed: onInspectAuditStatement,
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Back to Funding Overview',
            onPressed: onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
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
