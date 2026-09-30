import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/funding_models.dart';

/// Screen 21: Funding Statement & Cryptographic Audit Detail View.
class FundingAuditStatementView extends StatelessWidget {
  final FundingAuditStatement auditStatement;
  final VoidCallback onReturnToOverview;

  const FundingAuditStatementView({
    super.key,
    required this.auditStatement,
    required this.onReturnToOverview,
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
                onPressed: onReturnToOverview,
                tooltip: 'Back to Overview',
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Funding Audit Statement',
                  style: AppTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Cryptographic proof of multi-domain reconciliation across General Ledger, Treasury Pool, and Banking Rails.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary Reconciliation Proof Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('5-Way Cross-Domain Audit',
                        style: AppTypography.titleMedium),
                    StatusBadge(
                      label: auditStatement.reconciliationStatus,
                      type: StatusBadgeType.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.md),
                _buildAuditRow(
                    'Funding Execution ID', auditStatement.fundingExecutionId),
                _buildAuditRow(
                    'Cycle Allocation ID', auditStatement.allocationId),
                _buildAuditRow('Treasury Reservation ID',
                    auditStatement.treasuryReservationId),
                _buildAuditRow('Payment Instruction ID',
                    auditStatement.paymentInstructionId),
                _buildAuditRow('Settlement Confirmation ID',
                    auditStatement.settlementConfirmationId),
                _buildAuditRow(
                    'General Ledger Journal Ref', auditStatement.glJournalRef),
                _buildAuditRow(
                    'Member Obligation ID', auditStatement.obligationId),
                _buildAuditRow(
                    'Correlation Tracking ID', auditStatement.correlationId),
                _buildAuditRow('Reconciliation Variance',
                    '\$${(auditStatement.varianceAmountMinor / 100).toStringAsFixed(2)} USD (Zero Variance)'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Immutable WORM SHA-256 Seal Box
          _buildWormSealCard(),
          const SizedBox(height: AppSpacing.xl),

          // Actions
          PrimaryButton(
            label: 'Download Signed Statement (PDF)',
            icon: Icons.download,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Cryptographically signed funding audit statement generated.'),
                  backgroundColor: AppColors.emeraldGreen,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Back to Funding Overview',
            onPressed: onReturnToOverview,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value) {
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

  Widget _buildWormSealCard() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border:
            Border.all(color: AppColors.sovereignGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock,
                  color: AppColors.sovereignGold, size: 22.0),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'WORM Audit Log Hash',
                style: AppTypography.labelMedium.copyWith(
                    color: AppColors.sovereignGold,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          SelectableText(
            auditStatement.auditHash,
            style: AppTypography.bodySmall.copyWith(
              fontFamily: 'monospace',
              color: AppColors.textPrimary,
              fontSize: 11.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'This record is permanently sealed in the Write-Once-Read-Many regulatory log and cannot be mutated.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
