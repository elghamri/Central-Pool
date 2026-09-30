import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/member_dashboard_models.dart';
import '../state/dashboard_controller.dart';
import '../state/dashboard_state.dart';

/// Screen 6: Cooperative Member Home Dashboard.
class MemberHomeView extends StatelessWidget {
  final DashboardController controller;
  final ValueChanged<int>? onNavigateTab;

  const MemberHomeView({
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
            title: 'Unable to Load Dashboard',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => controller.loadDashboardData(forceRefresh: true),
          );
        }

        if (state is DashboardEmpty) {
          return EmptyStateWidget(
            title: state.title,
            description: state.message,
            icon: Icons.account_balance_wallet_outlined,
            actionLabel: 'Browse Cooperative Pools',
            onAction: () {},
          );
        }

        if (state is DashboardLoaded) {
          return _buildLoadedDashboard(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedDashboard(BuildContext context, DashboardLoaded state) {
    final summary = state.summary;
    final progressFraction = summary.totalSlots > 0
        ? (summary.payoutPosition / summary.totalSlots).clamp(0.0, 1.0)
        : 0.1;

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
            // Top Welcome Hero Banner
            _buildHeroHeader(summary),
            const SizedBox(height: AppSpacing.lg),

            // Actionable Dashboard Alerts
            for (final alert in state.alerts) ...[
              _buildAlertBanner(alert),
              const SizedBox(height: AppSpacing.md),
            ],

            // Core 4 Metric Summary Cards Grid
            _buildMetricsGrid(summary),
            const SizedBox(height: AppSpacing.xl),

            // Active Cycle Progress & Rotation Status Card
            _buildCycleProgressCard(summary, progressFraction),
            const SizedBox(height: AppSpacing.xl),

            // Quick Navigation Shortcuts
            _buildQuickActionCards(context),
            const SizedBox(height: AppSpacing.xl),

            // Recent Financial Activity Timeline
            _buildRecentActivitySection(state.financialSummary.recentActivity),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(MemberSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.5),
                  width: 1.5),
            ),
            child: const Icon(Icons.person,
                color: AppColors.emeraldGreen, size: 26.0),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        summary.fullName,
                        style: AppTypography.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const StatusBadge(
                        label: 'KYC VERIFIED', type: StatusBadgeType.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Cooperative: ${summary.currentCycleName} • Good Standing',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(DashboardAlert alert) {
    Color alertColor = AppColors.skyInfo;
    IconData alertIcon = Icons.info_outline;

    switch (alert.severity) {
      case AlertSeverity.warning:
        alertColor = AppColors.sovereignGold;
        alertIcon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.critical:
        alertColor = AppColors.crimsonRed;
        alertIcon = Icons.error_outline;
        break;
      case AlertSeverity.success:
        alertColor = AppColors.emeraldGreen;
        alertIcon = Icons.check_circle_outline;
        break;
      case AlertSeverity.info:
        alertColor = AppColors.skyInfo;
        alertIcon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderMd,
        border:
            Border.all(color: alertColor.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(alertIcon, color: alertColor, size: 22.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: alertColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  alert.message,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textPrimary),
                ),
                if (alert.actionLabel != null &&
                    onNavigateTab != null &&
                    alert.targetTabIndex != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => onNavigateTab!(alert.targetTabIndex!),
                    child: Text(
                      '${alert.actionLabel!} →',
                      style: AppTypography.labelSmall.copyWith(
                        color: alertColor,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(MemberSummary summary) {
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
                title: 'Available Pool Liquidity',
                valueWidget: FinancialAmountText(
                    amountMinor: summary.availablePoolLiquidityMinor),
                subtitle: '15% Protected Reserve Guard',
                icon: Icons.account_balance,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'My Expected Payout',
                valueWidget: FinancialAmountText(
                  amountMinor: summary.expectedPayoutMinor,
                  color: AppColors.sovereignGold,
                ),
                subtitle:
                    'Assigned to Slot #${summary.payoutPosition} of ${summary.totalSlots}',
                icon: Icons.stars_outlined,
                iconColor: AppColors.sovereignGold,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Next Contribution Due',
                valueWidget: FinancialAmountText(
                  amountMinor: summary.nextContributionDueMinor,
                  color: AppColors.emeraldGreen,
                ),
                subtitle: 'Due within 5 business days',
                icon: Icons.calendar_month_outlined,
                iconColor: AppColors.emeraldGreen,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Total Contributed',
                valueWidget: FinancialAmountText(
                    amountMinor: summary.totalContributedMinor),
                subtitle: 'Cycle Obligation: In Good Standing',
                icon: Icons.savings_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCycleProgressCard(
      MemberSummary summary, double progressFraction) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Active Cooperative Rotation',
                  style: AppTypography.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              StatusBadge(
                  label: 'CYCLE-2026-LIVE-01', type: StatusBadgeType.success),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '10-member peer-to-peer liquidity pool with deterministic FedNow clearing and instant settlement.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          LinearProgressIndicator(
            value: progressFraction,
            backgroundColor: AppColors.surfaceElevated,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
            minHeight: 8.0,
            borderRadius: AppRadii.borderFull,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Period ${summary.payoutPosition} of ${summary.totalSlots} (Current Month)',
                  style: AppTypography.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('${(progressFraction * 100).toInt()}% Progress',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.emeraldGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 600
            ? (constraints.maxWidth - 32) / 3
            : double.infinity;

        return Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildActionTile(
                icon: Icons.pie_chart_outline,
                title: 'Live Pool State',
                subtitle: 'View slot roster & pool capital',
                onTap: () => onNavigateTab?.call(2),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildActionTile(
                icon: Icons.calendar_today_outlined,
                title: 'Contribution Schedule',
                subtitle: 'Manage monthly dues & payments',
                onTap: () => onNavigateTab?.call(1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildActionTile(
                icon: Icons.receipt_long_outlined,
                title: 'Cycle Statements',
                subtitle: 'Download verified WORM statements',
                onTap: () => onNavigateTab?.call(3),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.borderMd,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: AppRadii.borderMd,
          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.borderSm,
              ),
              child: Icon(icon, color: AppColors.sovereignGold, size: 22.0),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  const SizedBox(height: 2.0),
                  Text(subtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20.0),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(List<FinancialActivityItem> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Recent Financial Activity',
                style: AppTypography.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            GhostButton(
              label: 'View All Dues',
              onPressed: () => onNavigateTab?.call(1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (activities.isEmpty)
          const SurfaceCard(
            child: Text(
                'No recent financial movements recorded in this period.',
                style: AppTypography.bodyMedium),
          )
        else
          SurfaceCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.borderSubtle, height: 1.0),
              itemBuilder: (context, index) {
                final act = activities[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: act.isDebit
                              ? AppColors.crimsonRed.withValues(alpha: 0.15)
                              : AppColors.emeraldGreen.withValues(alpha: 0.15),
                          borderRadius: AppRadii.borderSm,
                        ),
                        child: Icon(
                          act.isDebit
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: act.isDebit
                              ? AppColors.crimsonRed
                              : AppColors.emeraldGreen,
                          size: 18.0,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.title,
                              style: AppTypography.labelMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              act.subtitle,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FinancialAmountText(
                            amountMinor: act.amountMinor,
                            style: AppTypography.titleMedium,
                            color: act.isDebit
                                ? AppColors.textPrimary
                                : AppColors.emeraldGreen,
                            showSign: true,
                          ),
                          const SizedBox(height: 2.0),
                          StatusBadge(
                            label: act.status,
                            type: act.status == 'SETTLED' ||
                                    act.status == 'APPROVED'
                                ? StatusBadgeType.success
                                : StatusBadgeType.info,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return const SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 80.0),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: [
              SizedBox(width: 300.0, child: SkeletonLoader(height: 110.0)),
              SizedBox(width: 300.0, child: SkeletonLoader(height: 110.0)),
              SizedBox(width: 300.0, child: SkeletonLoader(height: 110.0)),
              SizedBox(width: 300.0, child: SkeletonLoader(height: 110.0)),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          SkeletonLoader(height: 160.0),
          SizedBox(height: AppSpacing.xl),
          SkeletonLoader(height: 240.0),
        ],
      ),
    );
  }
}
