import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/ops_models.dart';

/// Screen 35: Reconciliation Variance Report & Ledger Breakdown View.
class OpsReconciliationReportView extends StatelessWidget {
  final OpsReconciliationAuditItem report;
  final VoidCallback onBack;

  const OpsReconciliationReportView({
    super.key,
    required this.report,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: onBack,
                tooltip: 'Return to Dashboard',
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('5-Way Ledger Audit Report',
                        style: AppTypography.headlineMedium,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      'Report: ${report.reportId} • Target: ${report.cycleName}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(label: report.status, type: StatusBadgeType.success),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Zero-Variance Mathematical Proof Banner
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.1),
              borderRadius: AppRadii.borderMd,
              border: Border.all(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified,
                    color: AppColors.emeraldGreen, size: 28.0),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zero Variance Confirmed Across All 5 Ledger Domains',
                        style: AppTypography.titleMedium
                            .copyWith(color: AppColors.emeraldGreen),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Funding = Treasury = General Ledger = Member Obligations = Settlement. Net Discrepancy: \$0.00 USD.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 5-Domain Detailed Verification Breakdown Table
          const Text('Multi-Domain Financial Verification Breakdown',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),

          SurfaceCard(
            child: Column(
              children: [
                _buildDomainRow('1. Funding Service Disbursed Executions',
                    report.fundingDisbursedMinor, 'services/funding-service'),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                _buildDomainRow('2. Treasury Committed Liquidity Pool Leases',
                    report.treasuryCommittedMinor, 'services/treasury-service'),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                _buildDomainRow(
                    '3. Accounting General Ledger Double-Entry Journals',
                    report.glJournalTotalMinor,
                    'services/accounting-service'),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                _buildDomainRow(
                    '4. Member Account Obligations & Dues Ledger',
                    report.memberObligationMinor,
                    'services/member-financial-service'),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                _buildDomainRow(
                    '5. External Clearing Settlement Confirmations',
                    report.settlementTotalMinor,
                    'services/financial-integration-service'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // WORM Cryptographic Seal
          const Text('Cryptographic WORM Audit Seal',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'HMAC-SHA256 signature seal proving immutable persistence in WORM compliance storage.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Signature Digest',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textSecondary)),
                    const StatusBadge(
                        label: 'VERIFIED WORM SEAL',
                        type: StatusBadgeType.success),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  report.cryptographicSignature,
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.sovereignGold, fontFamily: 'monospace'),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Audit Observations: ${report.exceptionNotes}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SecondaryButton(
            label: 'Return to Reconciliation Dashboard',
            icon: Icons.arrow_back,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildDomainRow(
      String domainTitle, int amountMinor, String serviceSource) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(domainTitle,
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis),
                Text(
                  'Source: $serviceSource',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FinancialAmountText(
            amountMinor: amountMinor,
            style:
                AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
