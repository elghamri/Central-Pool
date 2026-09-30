import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/admin_models.dart';
import '../state/admin_controller.dart';
import '../state/admin_state.dart';

/// Screen 26: Cooperative Cycles Management & Rotation Roster View.
class AdminCyclesManagementView extends StatelessWidget {
  final AdminController controller;
  final VoidCallback onLaunchNewCycleWizard;

  const AdminCyclesManagementView({
    super.key,
    required this.controller,
    required this.onLaunchNewCycleWizard,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is AdminLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.emeraldGreen));
        }

        if (state is AdminLoaded) {
          return _buildLoadedView(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, AdminLoaded state) {
    final cycles = state.cycles;

    return SingleChildScrollView(
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
                    const Text('Cooperative Cycles',
                        style: AppTypography.headlineMedium,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2.0),
                    Text(
                      'Manage rotating capital pools, assign rotation slots, and track pool health.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(
                  label: '${cycles.length} POOLS',
                  type: StatusBadgeType.success),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary Launch Cycle CTA Card
          SurfaceCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: AppRadii.borderSm,
                  ),
                  child: const Icon(Icons.add_chart,
                      color: AppColors.emeraldGreen, size: 28.0),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Launch New Cooperative Pool',
                          style: AppTypography.titleMedium),
                      const SizedBox(height: 2.0),
                      Text(
                        'Create rotating schedules, define member obligations, and initialize ledger.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PrimaryButton(
                  label: 'New Cycle',
                  icon: Icons.add,
                  isFullWidth: false,
                  onPressed: onLaunchNewCycleWizard,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text('Active Rotating Pools', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),

          for (final cycle in cycles) ...[
            _buildCycleCard(cycle),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  Widget _buildCycleCard(AdminCycleSummary cycle) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(18.0),
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
                    Text(cycle.cycleName,
                        style: AppTypography.titleLarge,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2.0),
                    Text(
                      'Cycle ID: ${cycle.cycleId} • Started: ${cycle.startDate.year}-${cycle.startDate.month.toString().padLeft(2, '0')}-${cycle.startDate.day.toString().padLeft(2, '0')}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(label: cycle.status, type: StatusBadgeType.success),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.md),

          // Metrics row
          Wrap(
            spacing: 20.0,
            runSpacing: 10.0,
            children: [
              _buildMetric('Total Pool Capital', cycle.totalPoolCapitalMinor,
                  color: AppColors.emeraldGreen),
              _buildMetric(
                  'Monthly Due / Slot', cycle.contributionPerPeriodMinor),
              _buildMetric('Payout / Recipient', cycle.payoutPerSlotMinor,
                  color: AppColors.sovereignGold),
              _buildMetricText('Duration',
                  '${cycle.durationMonths} Months (${cycle.totalSlots} Slots)'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Rotation Slot Assignment Roster',
              style: AppTypography.labelMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),

          // 10-Slot Roster
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.borderMd,
            ),
            child: Column(
              children: [
                for (int index = 0; index < cycle.slots.length; index++) ...[
                  if (index > 0)
                    const Divider(color: AppColors.borderSubtle, height: 1.0),
                  _buildSlotRow(cycle.slots[index]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotRow(AdminCycleSlotItem slot) {
    final isDisbursed = slot.status == 'DISBURSED';
    final isCurrent = slot.status == 'CURRENT';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: const BoxDecoration(
              color: AppColors.deepSlate,
              borderRadius: AppRadii.borderSm,
            ),
            child: Text(
              'Slot #${slot.slotNumber}',
              style: AppTypography.labelSmall
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.memberName,
                    style: AppTypography.titleSmall,
                    overflow: TextOverflow.ellipsis),
                Text(
                  'Recipient ID: ${slot.memberId}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FinancialAmountText(
                    amountMinor: slot.payoutAmountMinor,
                    style: AppTypography.labelMedium),
                const SizedBox(height: 2.0),
                StatusBadge(
                  label: slot.status,
                  type: isDisbursed
                      ? StatusBadgeType.success
                      : (isCurrent
                          ? StatusBadgeType.warning
                          : StatusBadgeType.neutral),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, int amountMinor, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2.0),
        FinancialAmountText(
            amountMinor: amountMinor,
            style: AppTypography.titleMedium,
            color: color),
      ],
    );
  }

  Widget _buildMetricText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2.0),
        Text(value, style: AppTypography.titleMedium),
      ],
    );
  }
}
