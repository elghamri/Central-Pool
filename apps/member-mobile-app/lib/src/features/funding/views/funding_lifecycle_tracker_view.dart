import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/funding_models.dart';

/// Screen 18: 14-Stage Funding Lifecycle Tracker View.
class FundingLifecycleTrackerView extends StatelessWidget {
  final List<FundingLifecycleItem> stages;
  final VoidCallback onInspectSettlement;
  final VoidCallback onBack;

  const FundingLifecycleTrackerView({
    super.key,
    required this.stages,
    required this.onInspectSettlement,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount =
        stages.where((s) => s.status == LifecycleStageStatus.completed).length;

    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: onBack,
                tooltip: 'Back to Overview',
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Funding Lifecycle Tracker',
                  style: AppTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'End-to-end audit trail tracking your \$5,000.00 disbursement across 14 deterministic stages.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Lifecycle Progress Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Disbursement Progress',
                        style: AppTypography.titleMedium),
                    StatusBadge(
                      label: '$completedCount OF ${stages.length} COMPLETE',
                      type: completedCount == stages.length
                          ? StatusBadgeType.success
                          : StatusBadgeType.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value:
                      stages.isNotEmpty ? completedCount / stages.length : 0.0,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.emeraldGreen),
                  minHeight: 8.0,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  completedCount == stages.length
                      ? 'All stages completed and cryptographically verified in 5-way reconciliation.'
                      : 'Disbursement is actively progressing through banking rails and ledger verification.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 14-Stage Visual Timeline
          const Text('Deterministic Stage Execution Log',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),

          for (int i = 0; i < stages.length; i++) ...[
            _buildStageItem(stages[i], isLast: i == stages.length - 1),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          PrimaryButton(
            label: 'View Settlement & Rail Confirmation',
            icon: Icons.receipt_long,
            onPressed: onInspectSettlement,
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

  Widget _buildStageItem(FundingLifecycleItem item, {required bool isLast}) {
    Color iconColor;
    IconData icon;
    StatusBadgeType badgeType;

    switch (item.status) {
      case LifecycleStageStatus.completed:
        iconColor = AppColors.emeraldGreen;
        icon = Icons.check_circle;
        badgeType = StatusBadgeType.success;
        break;
      case LifecycleStageStatus.pending:
        iconColor = AppColors.amberWarning;
        icon = Icons.schedule;
        badgeType = StatusBadgeType.warning;
        break;
      case LifecycleStageStatus.failed:
        iconColor = AppColors.crimsonRed;
        icon = Icons.error_outline;
        badgeType = StatusBadgeType.error;
        break;
      case LifecycleStageStatus.unknown:
        iconColor = AppColors.skyInfo;
        icon = Icons.help_outline;
        badgeType = StatusBadgeType.info;
        break;
      case LifecycleStageStatus.notStarted:
        iconColor = AppColors.textSecondary;
        icon = Icons.circle_outlined;
        badgeType = StatusBadgeType.neutral;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator & Line Column
          Column(
            children: [
              Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor, width: 1.5),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 16.0),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.0,
                    color: item.status == LifecycleStageStatus.completed
                        ? AppColors.emeraldGreen.withValues(alpha: 0.4)
                        : AppColors.borderSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),

          // Stage Details Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SurfaceCard(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.stageNumber}. ${item.title}',
                            style: AppTypography.titleSmall
                                .copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        StatusBadge(
                            label: item.status.displayName, type: badgeType),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      item.description,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    if (item.referenceId != null) ...[
                      const SizedBox(height: 6.0),
                      Row(
                        children: [
                          const Icon(Icons.tag,
                              size: 12.0, color: AppColors.sovereignGold),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              'Ref: ${item.referenceId}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.sovereignGold,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.completedAt != null) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        'Completed: ${item.completedAt!.toUtc().toString().substring(0, 19)} UTC',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
