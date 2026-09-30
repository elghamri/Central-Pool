import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/ops_models.dart';
import '../state/ops_controller.dart';
import '../state/ops_state.dart';

/// Screen 31: Checker Authorization & Release Queue View.
class OpsCheckerQueueView extends StatelessWidget {
  final OpsController controller;
  final ValueChanged<OpsCheckerQueueItem> onSelectCheckerItem;

  const OpsCheckerQueueView({
    super.key,
    required this.controller,
    required this.onSelectCheckerItem,
  });

  Future<void> _handleAuthorizeRelease(
      BuildContext context, OpsCheckerQueueItem item) async {
    // Check self-approval upfront
    if (item.makerId == controller.session.userId) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: const Text('Self-Approval Forbidden',
              style: TextStyle(color: AppColors.crimsonRed)),
          content: Text(
            'Under Financial Invariant INV-15, Maker (${item.makerId}) cannot act as Checker on the same transaction. An independent secondary Checker officer must authorize this release.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Dismiss',
                  style: TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Confirm Checker Release Authorization',
            style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are authorizing the irrevocable clearing release for ${item.memberName} in "${item.cycleName}".',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Release Amount: \$${(item.amountMinor / 100).toStringAsFixed(2)} USD',
              style: AppTypography.titleMedium.copyWith(
                  color: AppColors.emeraldGreen, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Maker Sign-Off: ${item.makerName} (${item.makerId}) • Dual-Auth Checked.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Clearing Rail: FedNow Instant Clearing (ISO 20022 Direct Dispatch). Mode: Sandbox Simulation.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.sovereignGold),
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
            label: 'Authorize & Dispatch',
            icon: Icons.send_rounded,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.authorizeCheckerRelease(item.fundingId,
          makerId: item.makerId);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Disbursement for ${item.memberName} authorized and dispatched.'),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectIntent(
      BuildContext context, OpsCheckerQueueItem item) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Reject Disbursement Intent',
            style: TextStyle(color: AppColors.crimsonRed)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provide an audit reason for rejecting the Maker sign-off for ${item.memberName}.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            StandardTextField(
              label: 'Rejection Rationale (Required)',
              hint: 'e.g. Incomplete KYC documentation or schedule mismatch',
              controller: reasonController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.crimsonRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Rejection',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      final success = await controller.rejectCheckerRelease(item.fundingId,
          reason: reasonController.text.trim());
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disbursement rejected and returned to Maker.'),
            backgroundColor: AppColors.amberWarning,
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
            title: 'Failed to Load Checker Queue',
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
    final filteredQueue = state.filteredCheckerQueue;

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
                      const Text('Treasury Checker Queue',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Secondary authorization queue. Enforces independent sign-off (MakerID != CheckerID).',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                    label: '${filteredQueue.length} AWAITING CHECKER',
                    type: StatusBadgeType.warning),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Invariant Safety Guard Banner
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.borderMd,
                border: Border.all(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.emeraldGreen, size: 22.0),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Fiduciary Invariant INV-15 Enforced: Self-approval is strictly prevented by system policy.',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.emeraldGreen),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (filteredQueue.isEmpty)
              _buildEmptyState()
            else
              for (final item in filteredQueue) ...[
                _buildCheckerCard(context, item),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckerCard(BuildContext context, OpsCheckerQueueItem item) {
    final isSelfMaker = item.makerId == controller.session.userId;

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
                      Text(item.memberName,
                          style: AppTypography.titleMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Member ID: ${item.memberId} • Queue: ${item.queueId}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(label: item.status, type: StatusBadgeType.warning),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.borderSubtle, height: 1.0),
            const SizedBox(height: AppSpacing.md),

            // Maker provenance
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.borderSm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin,
                      color: AppColors.sovereignGold, size: 18.0),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Maker Sign-Off: ${item.makerName} (${item.makerId})',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelfMaker)
                    const StatusBadge(
                        label: 'SELF (CANNOT CHECK)',
                        type: StatusBadgeType.error),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Pool & Amount
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                _buildField('Cycle Name', item.cycleName),
                _buildField('Slot #', 'Slot #${item.slotNumber}'),
                _buildAmountField(
                    'Authorized Release Amount', item.amountMinor),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: 'Reject',
                  isFullWidth: false,
                  onPressed: () => _handleRejectIntent(context, item),
                ),
                const SizedBox(width: AppSpacing.sm),
                PrimaryButton(
                  label: 'Authorize Release',
                  icon: Icons.verified_outlined,
                  isFullWidth: false,
                  onPressed: () => _handleAuthorizeRelease(context, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
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

  Widget _buildAmountField(String label, int amountMinor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2.0),
        FinancialAmountText(
          amountMinor: amountMinor,
          style: AppTypography.titleMedium.copyWith(
              color: AppColors.emeraldGreen, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.verified, size: 48.0, color: AppColors.emeraldGreen),
          const SizedBox(height: AppSpacing.md),
          const Text('Checker Queue is Clear',
              style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'All staged Maker disbursements have been reviewed, verified, and released.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
