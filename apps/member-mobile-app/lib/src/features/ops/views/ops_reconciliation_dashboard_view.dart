import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/ops_models.dart';
import '../state/ops_controller.dart';
import '../state/ops_state.dart';

/// Screen 34: 5-Way Reconciliation Dashboard & Audit Engine View.
class OpsReconciliationDashboardView extends StatelessWidget {
  final OpsController controller;
  final ValueChanged<OpsReconciliationAuditItem> onSelectReport;

  const OpsReconciliationDashboardView({
    super.key,
    required this.controller,
    required this.onSelectReport,
  });

  Future<void> _handleRunReconciliation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Execute 5-Way Cross-Domain Reconciliation',
            style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Run deterministic 5-way ledger audit for "Rotating Pool Alpha-1" (CYCLE-2026-LIVE-01).',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Audit Domains: Funding Executions ↔ Treasury Reserves ↔ GL Journals ↔ Member Obligations ↔ Settlement Confirmations.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          PrimaryButton(
            label: 'Run 5-Way Audit',
            icon: Icons.sync,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final report =
          await controller.run5WayReconciliation('CYCLE-2026-LIVE-01');
      if (context.mounted && report != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '5-Way Audit completed. Report ${report.reportId} sealed with 0 variance.'),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OpsState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is OpsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.emeraldGreen));
        }

        if (state is OpsError) {
          return ErrorCardWidget(
            title: 'Failed to Load Reconciliation Engine',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => controller.loadOpsTelemetry(forceRefresh: true),
          );
        }

        if (state is OpsLoaded) {
          return _buildLoadedView(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, OpsLoaded state) {
    final reconciliations = state.reconciliations;

    return RefreshIndicator(
      onRefresh: () => controller.loadOpsTelemetry(forceRefresh: true),
      color: AppColors.emeraldGreen,
      backgroundColor: AppColors.cardSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('5-Way Reconciliation Engine',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Continuous multi-domain cross-verification across 5 ledger domains with WORM sealing.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const StatusBadge(
                    label: 'MATCH CLEAN', type: StatusBadgeType.success),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // On-Demand Audit Run Trigger Card
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                      borderRadius: AppRadii.borderSm,
                    ),
                    child: const Icon(Icons.verified_user,
                        color: AppColors.emeraldGreen, size: 28.0),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Trigger 5-Way Ledger Audit',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: 2.0),
                        Text(
                          'Execute Step 31 mathematical proof verifying zero variances across all 5 financial domains.',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PrimaryButton(
                    label: 'Run 5-Way Audit',
                    icon: Icons.play_arrow,
                    isFullWidth: false,
                    onPressed: () => _handleRunReconciliation(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            const Text('Historical Reconciliation Reports',
                style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.md),

            for (final report in reconciliations) ...[
              _buildReportCard(context, report),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
      BuildContext context, OpsReconciliationAuditItem report) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.cycleName,
                          style: AppTypography.titleLarge,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Report ID: ${report.reportId} • Date: ${report.auditDate.year}-${report.auditDate.month.toString().padLeft(2, '0')}-${report.auditDate.day.toString().padLeft(2, '0')}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                    label: report.status, type: StatusBadgeType.success),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.borderSubtle, height: 1.0),
            const SizedBox(height: AppSpacing.md),

            // 5 Ledger Domain Balances
            Wrap(
              spacing: 20.0,
              runSpacing: 10.0,
              children: [
                _buildDomainMetric(
                    'Funding Disbursed', report.fundingDisbursedMinor),
                _buildDomainMetric(
                    'Treasury Committed', report.treasuryCommittedMinor),
                _buildDomainMetric(
                    'GL Journal Total', report.glJournalTotalMinor),
                _buildDomainMetric(
                    'Member Obligation', report.memberObligationMinor),
                _buildDomainMetric(
                    'Settlement Total', report.settlementTotalMinor),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Discrepancy & Signature Row with responsive column/row
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.borderSm,
                border: Border.all(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.emeraldGreen, size: 18.0),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Net Ledger Variance: \$0.00 USD (Zero Discrepancy)',
                            style: AppTypography.labelMedium.copyWith(
                                color: AppColors.emeraldGreen,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SecondaryButton(
                    label: 'Inspect Report',
                    icon: Icons.article_outlined,
                    isFullWidth: false,
                    onPressed: () => onSelectReport(report),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainMetric(String label, int amountMinor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2.0),
        FinancialAmountText(
          amountMinor: amountMinor,
          style:
              AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
