import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/funding_models.dart';

/// Screen 19: Payout Settlement & Banking Rail Status View.
class PayoutSettlementView extends StatelessWidget {
  final PayoutSettlementDetail settlement;
  final VoidCallback onInspectObligation;
  final VoidCallback onBack;

  const PayoutSettlementView({
    super.key,
    required this.settlement,
    required this.onInspectObligation,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isSettled = settlement.settlementStatus == 'SETTLED';

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
                tooltip: 'Back to Tracker',
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Payout Status & Settlement',
                  style: AppTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Primary Settlement Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Banking Rail Execution Receipt',
                        style: AppTypography.titleMedium),
                    StatusBadge(
                      label: settlement.settlementStatus,
                      type: isSettled
                          ? StatusBadgeType.success
                          : StatusBadgeType.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.md),

                // Amount Showcase
                Center(
                  child: Column(
                    children: [
                      Text('Irrevocable Settled Liquidity',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4.0),
                      FinancialAmountText(
                        amountMinor: settlement.amountMinor,
                        style: AppTypography.financialDisplay.copyWith(
                          fontSize: 36.0,
                          color: isSettled
                              ? AppColors.emeraldGreen
                              : AppColors.amberWarning,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text('USD • Instant Gross Settlement',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Detailed Verification Rows
                _buildRow('Funding Execution ID', settlement.fundingId),
                _buildRow(
                    'Payment Instruction Status', settlement.instructionStatus),
                _buildRow('Provider Gateway Status', settlement.providerStatus),
                _buildRow(
                    'Final Settlement Status', settlement.settlementStatus),
                _buildRow('Clearing Rail', settlement.clearingRail),
                _buildRow('Transaction Reference', settlement.transactionRef),
                _buildRow('Settlement Timestamp',
                    '${settlement.settledAt.toUtc().toString().substring(0, 19)} UTC'),
                _buildRow('Correlation Identifier', settlement.correlationId),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Invariant Rule Advisory: DISPATCHED != SETTLED
          _buildDispatchVsSettlementCard(),
          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          PrimaryButton(
            label: 'View Post-Funding Obligation',
            icon: Icons.receipt_long_outlined,
            onPressed: onInspectObligation,
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Back to Lifecycle Tracker',
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

  Widget _buildDispatchVsSettlementCard() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              color: AppColors.emeraldGreen, size: 22.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guaranteed Irrevocability Invariant',
                  style: AppTypography.labelMedium.copyWith(
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'In accordance with financial invariant INV-14, DISPATCHED != SETTLED. A disbursement is only recognized as settled upon receiving Federal Reserve RTGS clearing acknowledgment.',
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
}
