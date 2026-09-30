import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/member_dashboard_models.dart';
import '../state/dashboard_controller.dart';
import '../state/dashboard_state.dart';

/// Screen 7: Live Cooperative Pool & Cycle State View.
class LivePoolStateView extends StatelessWidget {
  final DashboardController controller;
  final ValueChanged<int>? onNavigateTab;

  const LivePoolStateView({
    super.key,
    required this.controller,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DashboardState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is DashboardLoading) {
          return _buildLoadingSkeleton();
        }

        if (state is DashboardError) {
          return ErrorCardWidget(
            title: 'Unable to Load Pool State',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => controller.loadDashboardData(forceRefresh: true),
          );
        }

        if (state is DashboardEmpty) {
          return const EmptyStateWidget(
            title: 'No Live Pool Connected',
            description:
                'There are no live liquidity pool cycles associated with your account.',
            icon: Icons.pie_chart_outline,
          );
        }

        if (state is DashboardLoaded) {
          return _buildLoadedPoolState(context, state.poolState, state.summary);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedPoolState(
      BuildContext context, LiveCyclePoolState pool, MemberSummary summary) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: AppColors.emeraldGreen,
      backgroundColor: AppColors.cardSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pool Header Banner
            _buildPoolHeader(pool),
            const SizedBox(height: AppSpacing.lg),

            // Capital Health Breakdown Cards
            _buildCapitalHealthCards(pool),
            const SizedBox(height: AppSpacing.xl),

            // Pool Reserve Guard Notice
            _buildReserveGuardNotice(pool),
            const SizedBox(height: AppSpacing.xl),

            // Slot Rotation Map Section
            _buildSlotRotationRoster(pool),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolHeader(LiveCyclePoolState pool) {
    return SurfaceCard(
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
                    Text(pool.cycleName, style: AppTypography.headlineSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Cycle ID: ${pool.cycleId} • Co-op: ${pool.cooperativeId}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const StatusBadge(
                  label: 'ACTIVE POOL', type: StatusBadgeType.success),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 24.0,
            runSpacing: 8.0,
            children: [
              _buildMetaChip(Icons.people_outline,
                  '${pool.participatingMemberCount} Members'),
              _buildMetaChip(Icons.timelapse,
                  'Period ${pool.currentPeriod}/${pool.totalPeriods} Active'),
              _buildMetaChip(Icons.verified_outlined, 'Dual-Auth Enforced'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.0, color: AppColors.emeraldGreen),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style:
              AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCapitalHealthCards(LiveCyclePoolState pool) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 700
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth > 400
                ? (constraints.maxWidth - 16) / 2
                : double.infinity);

        return Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Total Pool Capital',
                valueWidget:
                    FinancialAmountText(amountMinor: pool.totalPoolMinor),
                subtitle: '10 Periods • 10 Members',
                icon: Icons.account_balance,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Contributions Collected',
                valueWidget: FinancialAmountText(
                  amountMinor: pool.contributionsReceivedMinor,
                  color: AppColors.emeraldGreen,
                ),
                subtitle: '100% Period 1 Dues Collected',
                icon: Icons.check_circle_outline,
                iconColor: AppColors.emeraldGreen,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Remaining Pipeline',
                valueWidget: FinancialAmountText(
                    amountMinor: pool.contributionsOutstandingMinor),
                subtitle: '9 Scheduled Monthly Periods',
                icon: Icons.pending_actions,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: '15% Protected Reserve',
                valueWidget: FinancialAmountText(
                  amountMinor: pool.reserveGuardMinor,
                  color: AppColors.sovereignGold,
                ),
                subtitle: 'Invariant Guardrail Active',
                icon: Icons.shield,
                iconColor: AppColors.sovereignGold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReserveGuardNotice(LiveCyclePoolState pool) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border: Border.all(
            color: AppColors.sovereignGold.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security,
              color: AppColors.sovereignGold, size: 24.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protected Liquidity & Zero-Loss Guarantee',
                  style: AppTypography.titleSmall
                      .copyWith(color: AppColors.sovereignGold),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'The cooperative pool maintains a mandatory 15% reserve buffer (\$7,500.00) in the Unified Treasury to guarantee all disbursements without external debt.',
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

  Widget _buildSlotRotationRoster(LiveCyclePoolState pool) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Rotation Schedule & Allocation Slots',
                style: AppTypography.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            StatusBadge(
              label: '${pool.slots.length} SLOTS ASSIGNED',
              type: StatusBadgeType.info,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Each month, full pooled capital of \$5,000.00 is disbursed to the scheduled rotation slot.',
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        // Slot cards grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 650;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 2 : 1,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                mainAxisExtent: 130.0,
              ),
              itemCount: pool.slots.length,
              itemBuilder: (context, index) {
                final slot = pool.slots[index];
                return _buildSlotCard(slot);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSlotCard(CycleSlotItem slot) {
    final isCurrent = slot.isCurrentMember;
    final isCurrentAlloc = slot.status == 'CURRENT_ALLOCATION';

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.surfaceElevated : AppColors.cardSurface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(
          color: isCurrent
              ? AppColors.sovereignGold
              : (isCurrentAlloc
                  ? AppColors.emeraldGreen
                  : AppColors.borderSubtle),
          width: isCurrent ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.sovereignGold
                          : AppColors.deepSlate,
                      borderRadius: AppRadii.borderSm,
                    ),
                    child: Text(
                      'Slot #${slot.slotNumber}',
                      style: AppTypography.labelSmall.copyWith(
                        color: isCurrent
                            ? AppColors.deepSlate
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    const StatusBadge(
                        label: 'YOU', type: StatusBadgeType.warning),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(
                label: slot.status == 'CURRENT_ALLOCATION'
                    ? 'CURRENT'
                    : slot.status,
                type: slot.status == 'CURRENT_ALLOCATION' ||
                        slot.status == 'SETTLED'
                    ? StatusBadgeType.success
                    : StatusBadgeType.neutral,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.memberName,
                      style: AppTypography.titleSmall.copyWith(
                        color: isCurrent
                            ? AppColors.sovereignGold
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      slot.scheduledPeriod,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FinancialAmountText(
                amountMinor: slot.payoutAmountMinor,
                style: AppTypography.titleMedium,
                color: isCurrent
                    ? AppColors.sovereignGold
                    : AppColors.emeraldGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 120.0),
          SizedBox(height: AppSpacing.lg),
          SkeletonLoader(height: 100.0),
          SizedBox(height: AppSpacing.xl),
          SkeletonLoader(height: 350.0),
        ],
      ),
    );
  }
}
