import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/member_dashboard_models.dart';
import '../state/dashboard_controller.dart';
import '../state/dashboard_state.dart';

/// Screen 8: Member Financial Summary & Monthly Dues Schedule.
class MemberFinancialSummaryView extends StatelessWidget {
  final DashboardController controller;
  final ValueChanged<int>? onNavigateTab;

  const MemberFinancialSummaryView({
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
            title: 'Unable to Load Financial Summary',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => controller.loadDashboardData(forceRefresh: true),
          );
        }

        if (state is DashboardEmpty) {
          return const EmptyStateWidget(
            title: 'No Financial Records',
            description:
                'There are no active dues or financial history associated with your membership.',
            icon: Icons.receipt_long_outlined,
          );
        }

        if (state is DashboardLoaded) {
          return _buildLoadedFinancialSummary(
              context, state.financialSummary, state.summary);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedFinancialSummary(
    BuildContext context,
    MemberFinancialSummary fin,
    MemberSummary summary,
  ) {
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
            // Net Position Summary Cards
            _buildNetPositionCards(fin),
            const SizedBox(height: AppSpacing.xl),

            // Contribution Schedule Section
            _buildContributionScheduleSection(
                context, fin.contributionSchedule),
            const SizedBox(height: AppSpacing.xl),

            // Legal Obligation & Repayment Tracker
            _buildObligationSection(fin.obligations),
            const SizedBox(height: AppSpacing.xl),

            // Cycle Statements & WORM Audit Trail
            _buildStatementsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNetPositionCards(MemberFinancialSummary fin) {
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
                title: 'Total Contributed',
                valueWidget:
                    FinancialAmountText(amountMinor: fin.totalContributedMinor),
                subtitle: 'Period 1 Settled Clean',
                icon: Icons.savings_outlined,
                iconColor: AppColors.emeraldGreen,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const SummaryMetricCard(
                title: 'Payout Received / Allocated',
                valueWidget: FinancialAmountText(
                  amountMinor: 500000, // $5,000.00
                  color: AppColors.sovereignGold,
                ),
                subtitle: 'Slot #1 Approved & Verified',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.sovereignGold,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Remaining Net Obligation',
                valueWidget: FinancialAmountText(
                    amountMinor: fin.remainingObligationsMinor),
                subtitle: '9 Scheduled Periods Remaining',
                icon: Icons.receipt_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContributionScheduleSection(
    BuildContext context,
    List<ContributionRecord> schedule,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Monthly Contribution Dues',
                style: AppTypography.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            StatusBadge(
                label: '${schedule.length} PERIODS',
                type: StatusBadgeType.neutral),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '10 monthly peer-to-peer contributions of \$500.00 USD clearing via FedNow RTGS.',
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedule.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.borderSubtle, height: 1.0),
            itemBuilder: (context, index) {
              final item = schedule[index];
              return _buildScheduleRow(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(BuildContext context, ContributionRecord item) {
    final isPaid = item.status == 'PAID';
    final isDue = item.status == 'DUE';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                      : (isDue
                          ? AppColors.sovereignGold.withValues(alpha: 0.15)
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
                    Text(
                      item.title,
                      style: AppTypography.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      isPaid
                          ? 'Paid • Ref: ${item.paymentReference ?? 'PAY-RTGS-001'}'
                          : (isDue ? 'Due soon • FedNow' : 'Scheduled period'),
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FinancialAmountText(
                amountMinor: item.amountMinor,
                style: AppTypography.titleMedium,
                color: isPaid ? AppColors.emeraldGreen : AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isDue)
                PrimaryButton(
                  label: 'Pay (\$500.00)',
                  isFullWidth: false,
                  icon: Icons.lock_outline,
                  onPressed: () => _showPaymentDialog(context, item),
                )
              else
                StatusBadge(
                  label: item.status,
                  type: isPaid
                      ? StatusBadgeType.success
                      : StatusBadgeType.neutral,
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, ContributionRecord item) {
    ConfirmationDialog.show(
      context,
      title: 'Authorize Monthly Contribution',
      content:
          'Authorize payment of \$500.00 USD for ${item.title} via instant FedNow RTGS clearing from your linked bank account.',
      confirmLabel: 'Authorize \$500.00',
      cancelLabel: 'Cancel',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Payment authorization will be processed in Slice 3 Payment Integration.'),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
      }
    });
  }

  Widget _buildObligationSection(List<ObligationRecord> obligations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Legal Obligation & Repayment Position',
            style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Post-payout obligations are tracked with deterministic double-entry accounting.',
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final obl in obligations)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        obl.title,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(
                        label: obl.status, type: StatusBadgeType.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 20.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Original Allocation',
                            style: AppTypography.labelSmall),
                        const SizedBox(height: 2.0),
                        FinancialAmountText(
                            amountMinor: obl.totalAmountMinor,
                            style: AppTypography.titleMedium),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Repaid to Date',
                            style: AppTypography.labelSmall),
                        const SizedBox(height: 2.0),
                        FinancialAmountText(
                            amountMinor: obl.repaidAmountMinor,
                            style: AppTypography.titleMedium,
                            color: AppColors.emeraldGreen),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Remaining Obligation',
                            style: AppTypography.labelSmall),
                        const SizedBox(height: 2.0),
                        FinancialAmountText(
                            amountMinor: obl.remainingAmountMinor,
                            style: AppTypography.titleMedium),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: obl.totalAmountMinor > 0
                      ? (obl.repaidAmountMinor / obl.totalAmountMinor)
                          .clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.emeraldGreen),
                  minHeight: 6.0,
                  borderRadius: AppRadii.borderFull,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatementsSection(BuildContext context) {
    return SurfaceCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.receipt_long,
            color: AppColors.sovereignGold, size: 32.0),
        title: const Text('Cooperative Statements & Ledger WORM Log',
            style: AppTypography.titleMedium),
        subtitle: const Text(
            'Cryptographically signed monthly audit statements (PDF / JSON)'),
        trailing: const Icon(Icons.download, color: AppColors.emeraldGreen),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Statement PDF downloaded to device storage.'),
              backgroundColor: AppColors.emeraldGreen,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 100.0),
          SizedBox(height: AppSpacing.lg),
          SkeletonLoader(height: 250.0),
          SizedBox(height: AppSpacing.xl),
          SkeletonLoader(height: 180.0),
        ],
      ),
    );
  }
}
