import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/admin_models.dart';
import '../state/admin_controller.dart';
import '../state/admin_state.dart';

/// Screen 28: Treasury Liquidity & Reserve Guardrail Monitor View.
class AdminTreasuryReserveView extends StatelessWidget {
  final AdminController controller;

  const AdminTreasuryReserveView({
    super.key,
    required this.controller,
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
          return _buildLoadedView(context, state.treasury);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedView(
      BuildContext context, AdminTreasuryOverview treasury) {
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
                    const Text('Treasury & Reserve Guard',
                        style: AppTypography.headlineMedium,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2.0),
                    Text(
                      'Real-time regulatory liquidity monitoring and 15% reserve buffer enforcement.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(
                  label: treasury.reserveStatus, type: StatusBadgeType.success),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary Reserve Gauge Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: AppRadii.borderLg,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    const Text('Regulatory Reserve Ratio (INV-12)',
                        style: AppTypography.titleMedium),
                    Text(
                      '${treasury.reserveRatioPercent.toStringAsFixed(1)}% / 15.0% Required',
                      style: AppTypography.labelMedium.copyWith(
                          color: AppColors.emeraldGreen,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const ClipRRect(
                  borderRadius: AppRadii.borderFull,
                  child: LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 10.0,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Unified Treasury maintains a mandatory 15.0% uncommitted liquid buffer prior to any rotation payout execution.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Liquidity Positions Breakdown
          const Text('Liquidity Position Balances',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),

          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth > 800
                  ? (constraints.maxWidth - 48) / 4
                  : (constraints.maxWidth > 500
                      ? (constraints.maxWidth - 16) / 2
                      : double.infinity);

              return Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: SummaryMetricCard(
                      title: 'Total Treasury Liquidity',
                      valueWidget: FinancialAmountText(
                          amountMinor: treasury.totalLiquidityMinor,
                          color: AppColors.emeraldGreen),
                      subtitle: 'Unified Pool Balance',
                      icon: Icons.account_balance,
                      iconColor: AppColors.emeraldGreen,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryMetricCard(
                      title: 'Free Available Liquidity',
                      valueWidget: FinancialAmountText(
                          amountMinor: treasury.freeLiquidityMinor,
                          color: AppColors.emeraldGreen),
                      subtitle: 'Disbursement Capacity',
                      icon: Icons.check_circle_outline,
                      iconColor: AppColors.emeraldGreen,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryMetricCard(
                      title: '15% Guardrail Reserve',
                      valueWidget: FinancialAmountText(
                          amountMinor: treasury.requiredReserveMinor,
                          color: AppColors.sovereignGold),
                      subtitle: 'Locked Regulatory Buffer',
                      icon: Icons.lock_outline,
                      iconColor: AppColors.sovereignGold,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryMetricCard(
                      title: 'Committed Rotation Pool',
                      valueWidget: FinancialAmountText(
                          amountMinor: treasury.committedLiquidityMinor,
                          color: AppColors.sovereignGold),
                      subtitle: 'Active Cycle Obligations',
                      icon: Icons.pie_chart_outline,
                      iconColor: AppColors.sovereignGold,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Operational Rebalance Action Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Treasury Rebalance & Liquidity Lock',
                    style: AppTypography.titleMedium),
                const SizedBox(height: 4.0),
                Text(
                  'Trigger automated double-entry rebalance to replenish the 15% reserve buffer across pool sub-accounts.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Execute 15% Reserve Rebalance',
                  icon: Icons.sync,
                  onPressed: () async {
                    final success = await controller.triggerTreasuryRebalance();
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Treasury reserve rebalance confirmed clean (zero-variance).'),
                          backgroundColor: AppColors.emeraldGreen,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Rebalance History Audit Trail
          const Text('Treasury Event Audit Trail',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),

          for (final event in treasury.rebalanceHistory) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(event.eventId, style: AppTypography.titleSmall),
                      StatusBadge(
                          label: event.status, type: StatusBadgeType.success),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    event.eventType,
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.emeraldGreen,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4.0),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      Text(
                        'Timestamp: ${event.timestamp.toIso8601String().substring(0, 19)}Z',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      FinancialAmountText(
                          amountMinor: event.rebalancedAmountMinor,
                          color: AppColors.sovereignGold),
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Correlation ID: ${event.correlationId}',
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary, fontSize: 11.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
