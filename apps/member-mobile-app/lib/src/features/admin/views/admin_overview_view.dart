import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/admin_models.dart';
import '../state/admin_controller.dart';
import '../state/admin_state.dart';

/// Screen 22: Business Admin Overview & Dashboard View.
class AdminOverviewView extends StatelessWidget {
  final AdminController controller;
  final ValueChanged<int> onNavigateTab;

  const AdminOverviewView({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is AdminLoading) {
          return _buildLoadingSkeleton();
        }

        if (state is AdminError) {
          return ErrorCardWidget(
            title: 'Failed to Load Business Overview',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => controller.loadAdminDashboard(forceRefresh: true),
          );
        }

        if (state is AdminLoaded) {
          return _buildLoadedView(context, state.overview, state.treasury);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, AdminOrgOverview overview,
      AdminTreasuryOverview treasury) {
    return RefreshIndicator(
      onRefresh: () => controller.loadAdminDashboard(forceRefresh: true),
      color: AppColors.emeraldGreen,
      backgroundColor: AppColors.cardSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Organization Header
            _buildOrgHeader(overview),
            const SizedBox(height: AppSpacing.lg),

            // Executive Metric Cards
            _buildExecutiveMetrics(overview),
            const SizedBox(height: AppSpacing.xl),

            // Secondary Invariant & Regulatory Status Row
            _buildGovernanceBar(overview),
            const SizedBox(height: AppSpacing.xl),

            // Quick Operational Action Buttons
            const Text('Administrative Quick Actions',
                style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Execute verified operational workflows across member accounts, cycles, and treasury liquidity.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildActionCard(
              title: 'Cooperative Cycle Configuration & Activation',
              subtitle:
                  'Configure new rotating pool, assign member slots, and launch rotation cycle.',
              icon: Icons.published_with_changes_outlined,
              badgeLabel: '${overview.activeCyclesCount} CYCLES',
              badgeType: StatusBadgeType.success,
              onTap: () => onNavigateTab(2), // Tab 2: Cycles
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildActionCard(
              title: 'Member Directory & KYC Verification',
              subtitle:
                  'Inspect 248 member accounts, manage KYC documentation, and review standing.',
              icon: Icons.people_outline,
              badgeLabel: '${overview.totalMembersCount} MEMBERS',
              badgeType: StatusBadgeType.info,
              onTap: () => onNavigateTab(1), // Tab 1: Members
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildActionCard(
              title: 'Treasury Liquidity & 15% Reserve Guardrail',
              subtitle:
                  'Monitor Free Liquidity (\$450,000.00) vs Required Reserve (\$75,000.00).',
              icon: Icons.account_balance_outlined,
              badgeLabel: '15.0% GUARD',
              badgeType: StatusBadgeType.warning,
              onTap: () => onNavigateTab(3), // Tab 3: Treasury
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildActionCard(
              title: 'Organization Operating Configuration',
              subtitle:
                  'View charter ID, legal entity records, branch network, and underwriting policies.',
              icon: Icons.admin_panel_settings_outlined,
              badgeLabel: 'CHARTER VERIFIED',
              badgeType: StatusBadgeType.neutral,
              onTap: () => onNavigateTab(4), // Tab 4: Profile
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgHeader(AdminOrgOverview overview) {
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.borderSm,
              border: Border.all(
                  color: AppColors.sovereignGold.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.business,
                color: AppColors.sovereignGold, size: 28.0),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    Text(
                      overview.orgName,
                      style: AppTypography.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const StatusBadge(
                        label: 'GOOD STANDING', type: StatusBadgeType.success),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Charter: ${overview.charterId} • Tenant: ${overview.tenantId}',
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

  Widget _buildExecutiveMetrics(AdminOrgOverview overview) {
    return LayoutBuilder(
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
                title: 'Total Cooperative Capital',
                valueWidget: FinancialAmountText(
                  amountMinor: overview.totalCapitalMinor,
                  style: AppTypography.financialDisplay
                      .copyWith(color: AppColors.emeraldGreen),
                ),
                subtitle: 'Unified Treasury Pool',
                icon: Icons.account_balance_wallet,
                iconColor: AppColors.emeraldGreen,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Committed Rotation Capital',
                valueWidget: FinancialAmountText(
                  amountMinor: overview.committedCapitalMinor,
                  style: AppTypography.financialDisplay
                      .copyWith(color: AppColors.sovereignGold),
                ),
                subtitle:
                    '${overview.activeCyclesCount} Active Rotation Cycles',
                icon: Icons.pie_chart,
                iconColor: AppColors.sovereignGold,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: 'Active Enrolled Members',
                valueWidget: Text(
                  '${overview.totalMembersCount}',
                  style: AppTypography.financialDisplay,
                ),
                subtitle: '100% Tier 2 KYC Verified',
                icon: Icons.people_alt_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SummaryMetricCard(
                title: '15% Reserve Requirement',
                valueWidget: FinancialAmountText(
                  amountMinor: overview.reserveGuardMinor,
                  style: AppTypography.financialDisplay
                      .copyWith(color: AppColors.sovereignGold),
                ),
                subtitle: 'Regulatory Liquidity Buffer',
                icon: Icons.security,
                iconColor: AppColors.sovereignGold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGovernanceBar(AdminOrgOverview overview) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: AppColors.emeraldGreen, size: 22.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiduciary Governance & Safety Controls Active',
                  style: AppTypography.labelMedium.copyWith(
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Dual-Authorization (Maker-Checker): ENABLED • Delinquency Rate: ${overview.delinquencyRate.toStringAsFixed(1)}% • Real-Money Movement: DISABLED (Sandbox Simulation Mode).',
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

  Widget _buildActionCard({
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
                    Text(
                      title,
                      style: AppTypography.titleSmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4.0),
                    StatusBadge(label: badgeLabel, type: badgeType),
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
          SkeletonLoader(height: 140.0),
          SizedBox(height: AppSpacing.xl),
          SkeletonLoader(height: 60.0),
          SizedBox(height: AppSpacing.xl),
          SkeletonLoader(height: 300.0),
        ],
      ),
    );
  }
}
