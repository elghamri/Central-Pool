import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/funding_models.dart';
import '../state/funding_controller.dart';
import '../state/funding_state.dart';

/// Screen 15: Funding & Payout Overview View.
class FundingOverviewView extends StatelessWidget {
  final FundingController controller;
  final ValueChanged<int> onSelectSubView;

  const FundingOverviewView({
    super.key,
    required this.controller,
    required this.onSelectSubView,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FundingState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is FundingLoading) {
          return _buildLoadingSkeleton();
        }

        if (state is FundingError) {
          return ErrorCardWidget(
            title: 'Unable to Load Funding Lifecycle',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => controller.loadFundingData(forceRefresh: true),
          );
        }

        if (state is FundingEmpty) {
          return EmptyStateWidget(
            title: 'No Active Funding Cycle',
            description: state.message,
            icon: Icons.account_balance_wallet_outlined,
          );
        }

        if (state is FundingLoaded) {
          return _buildLoadedView(context, state.overview);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, FundingOverview overview) {
    final alloc = overview.allocation;
    final settle = overview.settlement;
    final oblig = overview.obligation;

    return RefreshIndicator(
      onRefresh: () => controller.loadFundingData(forceRefresh: true),
      color: AppColors.emeraldGreen,
      backgroundColor: AppColors.cardSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cycle & Member Position Banner
            _buildCycleHeader(alloc, overview.eligibility),
            const SizedBox(height: AppSpacing.lg),

            // Primary Hero Allocation / Payout Card
            _buildHeroPayoutCard(alloc, settle),
            const SizedBox(height: AppSpacing.xl),

            // Summary Metric Grid
            _buildSummaryMetrics(alloc, oblig),
            const SizedBox(height: AppSpacing.xl),

            // Quick Navigation Modules (Screens 16–21)
            const Text('Funding Lifecycle Navigation',
                style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Select a stage below to inspect verified cryptographic records and banking logs.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildModuleCard(
              title: 'Funding Eligibility Gate',
              subtitle:
                  'Tier 2 KYC • Delinquency = 0 • 15% Reserve Guardrail Verified',
              icon: Icons.verified_outlined,
              badgeLabel: 'ELIGIBLE',
              badgeType: StatusBadgeType.success,
              onTap: () => onSelectSubView(1), // Screen 16
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildModuleCard(
              title: 'Allocation & Rotation Position',
              subtitle:
                  'Slot #${alloc.slotNumber} of ${alloc.totalSlots} • Expected Payout \$5,000.00 USD',
              icon: Icons.pie_chart_outline,
              badgeLabel: alloc.status,
              badgeType: StatusBadgeType.success,
              onTap: () => onSelectSubView(2), // Screen 17
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildModuleCard(
              title: '14-Stage Funding Lifecycle Tracker',
              subtitle:
                  'Maker/Checker -> Treasury -> FedNow -> GL -> 5-Way Reconciliation',
              icon: Icons.timeline,
              badgeLabel: '14/14 COMPLETED',
              badgeType: StatusBadgeType.success,
              onTap: () => onSelectSubView(3), // Screen 18
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildModuleCard(
              title: 'Payout Settlement & Rail Status',
              subtitle: 'Instant RTGS Cleared • Ref: ${settle.transactionRef}',
              icon: Icons.payments_outlined,
              badgeLabel: settle.settlementStatus,
              badgeType: StatusBadgeType.success,
              onTap: () => onSelectSubView(4), // Screen 19
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildModuleCard(
              title: 'Post-Funding Obligation & Dues',
              subtitle: '\$4,500.00 Remaining Obligation • 9 Scheduled Periods',
              icon: Icons.receipt_long_outlined,
              badgeLabel: oblig.riskStatus,
              badgeType: StatusBadgeType.success,
              onTap: () => onSelectSubView(5), // Screen 20
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildModuleCard(
              title: 'Cryptographic Audit Statement',
              subtitle: 'Zero-Variance 5-Way Match • WORM SHA-256 Ledger Stamp',
              icon: Icons.lock_clock_outlined,
              badgeLabel: 'MATCH_CLEAN',
              badgeType: StatusBadgeType.success,
              onTap: () => onSelectSubView(6), // Screen 21
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleHeader(
      AllocationPosition alloc, FundingEligibility eligibility) {
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
                        alloc.cycleName,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(
                        label:
                            'SLOT #${alloc.slotNumber} OF ${alloc.totalSlots}',
                        type: StatusBadgeType.warning),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Member: ${alloc.recipientMemberName} • Cycle ID: ${alloc.cycleId}',
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

  Widget _buildHeroPayoutCard(
      AllocationPosition alloc, PayoutSettlementDetail settle) {
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
                    Text('Cooperative Rotation Payout',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.emeraldGreen)),
                    const SizedBox(height: 4.0),
                    const Text('Period #1 Active Recipient',
                        style: AppTypography.titleLarge,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(
                  label: settle.settlementStatus,
                  type: StatusBadgeType.success),
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
                amountMinor: alloc.expectedPayoutMinor,
                style: AppTypography.financialDisplay.copyWith(
                  fontSize: 34.0,
                  color: AppColors.emeraldGreen,
                ),
              ),
              Text(
                'Settled via FedNow RTGS rail',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Track Payout Lifecycle (14 Stages)',
            icon: Icons.timeline,
            onPressed: () => onSelectSubView(3), // Screen 18
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(
      AllocationPosition alloc, PostFundingObligation oblig) {
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
                title: 'Total Disbursed Payout',
                valueWidget:
                    FinancialAmountText(amountMinor: alloc.expectedPayoutMinor),
                subtitle: 'Period 1 Recipient',
                icon: Icons.check_circle_outline,
                iconColor: AppColors.emeraldGreen,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Repaid to Date',
                valueWidget: FinancialAmountText(
                    amountMinor: oblig.repaidAmountMinor,
                    color: AppColors.emeraldGreen),
                subtitle: 'Period 1 Settled Clean',
                icon: Icons.savings_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Remaining Net Obligation',
                valueWidget: FinancialAmountText(
                    amountMinor: oblig.remainingObligationMinor,
                    color: AppColors.sovereignGold),
                subtitle: '9 Scheduled Monthly Dues',
                icon: Icons.receipt_outlined,
                iconColor: AppColors.sovereignGold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeLabel,
    required StatusBadgeType badgeType,
    required VoidCallback onTap,
  }) {
    return SurfaceCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadii.borderSm,
                ),
                child: Icon(icon, color: AppColors.emeraldGreen, size: 22.0),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        StatusBadge(label: badgeLabel, type: badgeType),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
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
          SkeletonLoader(height: 350.0),
        ],
      ),
    );
  }
}
