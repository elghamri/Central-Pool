import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/ops_models.dart';

/// Screen 32: Operational Action Detail & Audit Dossier View.
class OpsActionDossierView extends StatelessWidget {
  final OpsPaymentItem? payment;
  final OpsMakerQueueItem? makerItem;
  final OpsCheckerQueueItem? checkerItem;
  final VoidCallback onBack;

  const OpsActionDossierView({
    super.key,
    this.payment,
    this.makerItem,
    this.checkerItem,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final title = payment != null
        ? 'Payment Instruction Dossier'
        : (makerItem != null
            ? 'Maker Review Dossier'
            : 'Checker Authorization Dossier');

    final amountMinor = payment?.amountMinor ??
        makerItem?.amountMinor ??
        checkerItem?.amountMinor ??
        500000;
    final status = payment?.status ??
        makerItem?.status ??
        checkerItem?.status ??
        'UNKNOWN';
    final recipientName = payment?.recipientName ??
        makerItem?.memberName ??
        checkerItem?.memberName ??
        'Member';
    final recipientId = payment?.recipientMemberId ??
        makerItem?.memberId ??
        checkerItem?.memberId ??
        'usr-member-001';
    final referenceId = payment?.paymentId ??
        makerItem?.queueId ??
        checkerItem?.queueId ??
        'REF-001';
    final correlationId = payment?.correlationId ?? 'CORR-WORM-$referenceId';

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
                tooltip: 'Return to Queue',
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.headlineMedium,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      'Reference: $referenceId • Recipient: $recipientName',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(label: status, type: StatusBadgeType.success),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary Financial Summary Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Disbursement Financial Value',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                FinancialAmountText(
                  amountMinor: amountMinor,
                  style: AppTypography.financialDisplay
                      .copyWith(color: AppColors.emeraldGreen),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 20.0,
                  runSpacing: 10.0,
                  children: [
                    _buildDetailItem(
                        'Recipient Member', '$recipientName ($recipientId)'),
                    _buildDetailItem(
                        'Clearing Rail',
                        payment?.paymentRail.displayName ??
                            'FedNow Instant Clearing'),
                    _buildDetailItem('Currency', 'USD (United States Dollar)'),
                    _buildDetailItem(
                        'Security Status', 'Maker-Checker Dual Signed'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Multi-Domain Provenance & Cryptographic Audit
          const Text('WORM Audit Provenance & Correlation',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cryptographically sealed audit records persisted in Write-Once-Read-Many storage.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          SurfaceCard(
            child: Column(
              children: [
                _buildAuditRow('Correlation ID', correlationId, isCode: true),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                _buildAuditRow('Idempotency Key',
                    payment?.idempotencyKey ?? 'IDEM-$referenceId',
                    isCode: true),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                _buildAuditRow('SHA-256 Ledger Hash',
                    'SHA256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
                    isCode: true),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                _buildAuditRow('Execution Mode',
                    'SANDBOX_SIMULATION (Real-Money Movement Disabled)',
                    color: AppColors.sovereignGold),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SecondaryButton(
            label: 'Return to Operations Queue',
            icon: Icons.arrow_back,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2.0),
        Text(value, style: AppTypography.titleSmall),
      ],
    );
  }

  Widget _buildAuditRow(String label, String value,
      {bool isCode = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: isCode
                  ? AppTypography.bodySmall.copyWith(
                      color: color ?? AppColors.sovereignGold,
                      fontFamily: 'monospace')
                  : AppTypography.bodyMedium
                      .copyWith(color: color ?? AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
