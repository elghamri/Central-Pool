import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/ops_models.dart';
import '../state/ops_controller.dart';
import '../state/ops_state.dart';

/// Screen 30: Maker Approval Queue & Intent Review View.
class OpsMakerQueueView extends StatelessWidget {
  final OpsController controller;
  final ValueChanged<OpsMakerQueueItem> onSelectMakerItem;

  const OpsMakerQueueView({
    super.key,
    required this.controller,
    required this.onSelectMakerItem,
  });

  Future<void> _handleApproveIntent(
      BuildContext context, OpsMakerQueueItem item) async {
    final notesController = TextEditingController(
        text: 'Underwriting KYC verified; allocation milestone confirmed.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Confirm Maker Sign-Off Intent',
            style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are signing off on disbursement allocation for ${item.memberName} in "${item.cycleName}" (Slot #${item.slotNumber}).',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Disbursement Amount: \$${(item.amountMinor / 100).toStringAsFixed(2)} USD',
              style: AppTypography.titleMedium.copyWith(
                  color: AppColors.emeraldGreen, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            StandardTextField(
              label: 'Maker Verification Notes',
              controller: notesController,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Note: This action moves the disbursement to the Checker Queue (MakerID: ${controller.session.userId}). You cannot act as Checker on this item (Invariant INV-15).',
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
            label: 'Submit Maker Approval',
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.submitMakerApproval(item.fundingId,
          notes: notesController.text);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Maker approval submitted for ${item.memberName}. Moved to Checker Queue.'),
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
            title: 'Failed to Load Maker Queue',
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
    final filteredQueue = state.filteredMakerQueue;

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
                      const Text('Treasury Maker Queue',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'First-line review for rotating disbursements. Verifies member KYC & signs off funding intent.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                    label: '${filteredQueue.length} PENDING MAKER',
                    type: StatusBadgeType.warning),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Maker Role Identity Banner
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.borderMd,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined,
                      color: AppColors.sovereignGold, size: 22.0),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Authenticated Maker: ${controller.session.fullName} (${controller.session.userId})',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textPrimary),
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
                _buildMakerCard(context, item),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildMakerCard(BuildContext context, OpsMakerQueueItem item) {
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
                StatusBadge(
                    label: 'KYC ${item.kycStatus}',
                    type: StatusBadgeType.success),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.borderSubtle, height: 1.0),
            const SizedBox(height: AppSpacing.md),

            // Pool & Slot info
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                _buildField('Cycle Name', item.cycleName),
                _buildField('Slot #', 'Slot #${item.slotNumber}'),
                _buildField('AML Risk', item.amlRiskScore),
                _buildAmountField('Disbursement Amount', item.amountMinor),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Notes: ${item.notes}',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: 'View Dossier',
                  isFullWidth: false,
                  onPressed: () => onSelectMakerItem(item),
                ),
                const SizedBox(width: AppSpacing.sm),
                PrimaryButton(
                  label: 'Approve Intent (Maker)',
                  icon: Icons.check_circle_outline,
                  isFullWidth: false,
                  onPressed: () => _handleApproveIntent(context, item),
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
          const Icon(Icons.done_all, size: 48.0, color: AppColors.emeraldGreen),
          const SizedBox(height: AppSpacing.md),
          const Text('Maker Queue is Clear', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'All pending rotation disbursements have been reviewed and staged for Checker release.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
