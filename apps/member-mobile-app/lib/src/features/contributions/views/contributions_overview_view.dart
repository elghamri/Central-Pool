import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../dashboard/models/member_dashboard_models.dart';
import '../models/contribution_models.dart';
import '../state/contribution_controller.dart';
import '../state/contribution_state.dart';

/// Screen 9: Contributions Overview View.
class ContributionsOverviewView extends StatelessWidget {
  final ContributionController controller;
  final VoidCallback onMakeContribution;

  const ContributionsOverviewView({
    super.key,
    required this.controller,
    required this.onMakeContribution,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ContributionState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is ContributionOverviewLoading) {
          return _buildLoadingSkeleton();
        }

        if (state is ContributionOverviewError) {
          return ErrorCardWidget(
            title: 'Unable to Load Contributions',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => controller.loadOverview(forceRefresh: true),
          );
        }

        if (state is ContributionOverviewLoaded) {
          return _buildLoadedOverview(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedOverview(
      BuildContext context, ContributionOverviewLoaded state) {
    final due = state.activeDue;
    final summary = state.summary;

    return RefreshIndicator(
      onRefresh: () => controller.loadOverview(forceRefresh: true),
      color: AppColors.emeraldGreen,
      backgroundColor: AppColors.cardSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Banner
            _buildCyclePositionBanner(due, summary),
            const SizedBox(height: AppSpacing.lg),

            // Active Due Highlight Card with Primary CTA
            _buildActiveDueCard(due),
            const SizedBox(height: AppSpacing.xl),

            // Contribution Metrics Summary Grid
            _buildMetricsGrid(summary),
            const SizedBox(height: AppSpacing.xl),

            // 10-Period Contribution Schedule & History
            _buildHistorySection(state.history),
          ],
        ),
      ),
    );
  }

  Widget _buildCyclePositionBanner(
      ContributionDetail due, MemberSummary summary) {
    return SurfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.borderSm,
              border: Border.all(
                  color: AppColors.sovereignGold.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.stars,
                color: AppColors.sovereignGold, size: 24.0),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        due.cycleName,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(
                        label: 'SLOT #${due.slotPosition} OF ${due.totalSlots}',
                        type: StatusBadgeType.warning),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Member: ${due.memberName} • Cycle ID: ${due.cycleId}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDueCard(ContributionDetail due) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.borderLg,
        border: Border.all(
            color: AppColors.emeraldGreen.withValues(alpha: 0.5), width: 1.5),
      ),
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
                    Text('Current Contribution Due',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.emeraldGreen)),
                    const SizedBox(height: 4.0),
                    Text(due.title,
                        style: AppTypography.titleLarge,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const StatusBadge(
                  label: 'DUE NOW', type: StatusBadgeType.warning),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.0,
            runSpacing: 6.0,
            children: [
              FinancialAmountText(
                amountMinor: due.amountMinor,
                style: AppTypography.financialDisplay
                    .copyWith(color: AppColors.emeraldGreen),
              ),
              Text(
                'Due in 5 business days',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Make Contribution (\$500.00)',
            icon: Icons.payment,
            onPressed: onMakeContribution,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(MemberSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 700
            ? (constraints.maxWidth - 32) / 3
            : double.infinity;

        return Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Amount Already Contributed',
                valueWidget: FinancialAmountText(
                    amountMinor: summary.totalContributedMinor),
                subtitle: 'Period 1 Settled Clean',
                icon: Icons.savings_outlined,
                iconColor: AppColors.emeraldGreen,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Remaining Cycle Obligation',
                valueWidget: FinancialAmountText(
                  amountMinor: summary.outstandingObligationMinor,
                  color: AppColors.sovereignGold,
                ),
                subtitle: '9 Scheduled Monthly Periods',
                icon: Icons.receipt_outlined,
                iconColor: AppColors.sovereignGold,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Cycle Obligation Target',
                valueWidget: FinancialAmountText(
                    amountMinor: summary.expectedPayoutMinor),
                subtitle: '10 Periods @ \$500.00 / mo',
                icon: Icons.account_balance_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistorySection(List<ContributionRecord> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Contribution Schedule & History',
                style: AppTypography.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            StatusBadge(
                label: '${history.length} PERIODS',
                type: StatusBadgeType.neutral),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Automated double-entry accounting schedule tracking peer-to-peer liquidity dues.',
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.borderSubtle, height: 1.0),
            itemBuilder: (context, index) {
              final item = history[index];
              final isPaid = item.status == 'PAID';
              final isDue = item.status == 'DUE';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                            : (isDue
                                ? AppColors.sovereignGold
                                    .withValues(alpha: 0.15)
                                : AppColors.surfaceElevated),
                        borderRadius: AppRadii.borderSm,
                      ),
                      child: Icon(
                        isPaid
                            ? Icons.check_circle
                            : (isDue ? Icons.schedule : Icons.event),
                        color: isPaid
                            ? AppColors.emeraldGreen
                            : (isDue
                                ? AppColors.sovereignGold
                                : AppColors.textSecondary),
                        size: 18.0,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: AppTypography.labelMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2.0),
                          Text(
                            isPaid
                                ? 'Paid • Ref: ${item.paymentReference ?? 'PAY-RTGS-001'}'
                                : (isDue
                                    ? 'Due in 5 days • FedNow Instant'
                                    : 'Scheduled period'),
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
                          amountMinor: item.amountMinor,
                          style: AppTypography.titleMedium,
                          color: isPaid
                              ? AppColors.emeraldGreen
                              : AppColors.textPrimary,
                        ),
                        const SizedBox(height: 2.0),
                        StatusBadge(
                          label: item.status,
                          type: isPaid
                              ? StatusBadgeType.success
                              : (isDue
                                  ? StatusBadgeType.warning
                                  : StatusBadgeType.neutral),
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
          SkeletonLoader(height: 70.0),
          SizedBox(height: AppSpacing.lg),
          SkeletonLoader(height: 180.0),
          SizedBox(height: AppSpacing.xl),
          SkeletonLoader(height: 110.0),
          SizedBox(height: AppSpacing.xl),
          SkeletonLoader(height: 250.0),
        ],
      ),
    );
  }
}
