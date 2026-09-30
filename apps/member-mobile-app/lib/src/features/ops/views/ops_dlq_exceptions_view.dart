import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/ops_models.dart';
import '../state/ops_controller.dart';
import '../state/ops_state.dart';

/// Screen 33: Exceptions & Dead Letter Queue (DLQ) Console View.
class OpsDlqExceptionsView extends StatelessWidget {
  final OpsController controller;

  const OpsDlqExceptionsView({
    super.key,
    required this.controller,
  });

  Future<void> _handleReplay(BuildContext context, OpsDlqRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Confirm Safe Event Replay',
            style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to re-drive event ${record.dlqId} (${record.eventType}) from the Dead Letter Queue.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error: ${record.errorMessage}',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.crimsonRed),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Safe Replay Invariant: The idempotency key ensures no duplicate payment or double-spend occurs.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.emeraldGreen),
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
            label: 'Re-Drive Event',
            icon: Icons.replay,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.replayDlqRecord(record.dlqId);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Event ${record.dlqId} safely re-driven into processing queue.'),
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
            title: 'Failed to Load DLQ Console',
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
    final records = state.filteredDlqRecords;

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
                      const Text('Dead Letter Queue (DLQ)',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Diagnostic exceptions console. Inspect failed payloads, inspect root causes, and re-drive.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                    label: '${records.length} DEAD LETTERS',
                    type: StatusBadgeType.error),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (records.isEmpty)
              _buildEmptyState()
            else
              for (final record in records) ...[
                _buildDlqCard(context, record),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildDlqCard(BuildContext context, OpsDlqRecord record) {
    final isReplayed = record.status == 'REPLAYED';

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
                      Text(record.eventType,
                          style: AppTypography.titleMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'DLQ ID: ${record.dlqId} • Topic: ${record.topic}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: record.status,
                  type: isReplayed
                      ? StatusBadgeType.success
                      : StatusBadgeType.error,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.borderSubtle, height: 1.0),
            const SizedBox(height: AppSpacing.md),

            // Error message block
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.crimsonRed.withValues(alpha: 0.1),
                borderRadius: AppRadii.borderSm,
                border: Border.all(
                    color: AppColors.crimsonRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Failure Diagnostic:',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.crimsonRed)),
                  const SizedBox(height: 2.0),
                  Text(record.errorMessage,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 4.0),
                  Text(
                    'Stack Trace: ${record.errorStackTrace}',
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                _buildField('Correlation ID', record.correlationId),
                _buildField('Retry Attempt',
                    '${record.retryCount} of ${record.maxRetries}'),
                _buildField('Source System', record.sourceSystem),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isReplayed)
                  PrimaryButton(
                    label: 'Replay Event Safely',
                    icon: Icons.replay,
                    isFullWidth: false,
                    onPressed: () => _handleReplay(context, record),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 48.0, color: AppColors.emeraldGreen),
          const SizedBox(height: AppSpacing.md),
          const Text('Dead Letter Queue is Empty',
              style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Zero unhandled exceptions or dead-letter events detected.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
