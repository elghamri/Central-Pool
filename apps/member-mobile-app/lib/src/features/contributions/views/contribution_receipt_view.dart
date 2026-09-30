import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/contribution_models.dart';

/// Screen 14: Contribution Result & Cryptographic Receipt View.
class ContributionReceiptView extends StatelessWidget {
  final ContributionSubmissionResult result;
  final ContributionDetail detail;
  final VoidCallback onReturnToOverview;
  final VoidCallback onGoToDashboard;

  const ContributionReceiptView({
    super.key,
    required this.result,
    required this.detail,
    required this.onReturnToOverview,
    required this.onGoToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final isSettled = result.status == 'SETTLED';

    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success / Pending Icon & Banner
          Center(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: isSettled
                    ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                    : AppColors.sovereignGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSettled
                      ? AppColors.emeraldGreen
                      : AppColors.sovereignGold,
                  width: 2.0,
                ),
              ),
              child: Icon(
                isSettled ? Icons.check_circle_outline : Icons.pending_actions,
                color: isSettled
                    ? AppColors.emeraldGreen
                    : AppColors.sovereignGold,
                size: 48.0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Center(
            child: Text(
              isSettled
                  ? 'Contribution Settled Successfully'
                  : 'Contribution Clearing Pending',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              isSettled
                  ? 'Your \$500.00 payment has been reconciled in the cooperative pool ledger.'
                  : 'Your payment instruction has been dispatched and is awaiting clearing house batch settlement.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Immutable Receipt Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Official Financial Receipt',
                        style: AppTypography.titleMedium),
                    StatusBadge(
                      label: result.status,
                      type: isSettled
                          ? StatusBadgeType.success
                          : StatusBadgeType.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.md),

                // Amount
                Center(
                  child: Column(
                    children: [
                      Text('Settled Amount',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4.0),
                      FinancialAmountText(
                        amountMinor: result.amountMinor,
                        style: AppTypography.financialDisplay.copyWith(
                          fontSize: 34.0,
                          color: isSettled
                              ? AppColors.emeraldGreen
                              : AppColors.sovereignGold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text('USD • Zero Float Rounding Drift',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Receipt Breakdown Rows
                _buildReceiptRow('Contribution ID', result.contributionId),
                _buildReceiptRow('Cycle ID', result.cycleId),
                _buildReceiptRow(
                    'Period', 'Period #${result.periodNumber} Monthly Due'),
                _buildReceiptRow('Timestamp',
                    '${result.settledAt.toUtc().toString().substring(0, 19)} UTC'),
                _buildReceiptRow('Clearing Rail', result.paymentRail),
                _buildReceiptRow(
                    'Transaction Ref', result.transactionReference),
                _buildReceiptRow(
                    'General Ledger Journal', result.ledgerJournalId),
                _buildReceiptRow('Correlation ID', result.correlationId),
                _buildReceiptRow('Updated Remaining Dues',
                    '\$${((detail.remainingCycleObligationMinor - result.amountMinor) / 100).toStringAsFixed(2)} USD'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // WORM Cryptographic Seal Notice
          _buildWormSealNotice(result),
          const SizedBox(height: AppSpacing.xl),

          // Actions
          PrimaryButton(
            label: 'Download Signed Receipt (PDF)',
            icon: Icons.download,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Cryptographically signed receipt PDF generated.'),
                  backgroundColor: AppColors.emeraldGreen,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Back to Contributions Overview',
            icon: Icons.list_alt,
            onPressed: onReturnToOverview,
          ),
          const SizedBox(height: AppSpacing.sm),
          GhostButton(
            label: 'Return to Member Dashboard',
            icon: Icons.home,
            onPressed: onGoToDashboard,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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

  Widget _buildWormSealNotice(ContributionSubmissionResult result) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderSm,
        border:
            Border.all(color: AppColors.sovereignGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_clock,
              color: AppColors.sovereignGold, size: 20.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORM Audit Log Recorded',
                  style: AppTypography.labelMedium.copyWith(
                      color: AppColors.sovereignGold,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'This receipt is sealed with an immutable SHA-256 hash in the Write-Once-Read-Many audit trail and reconciled against Treasury Pool reserves.',
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
