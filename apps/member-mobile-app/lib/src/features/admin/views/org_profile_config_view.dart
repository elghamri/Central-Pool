import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/admin_models.dart';

/// Screen 23: Organization Profile & Operational Configuration View.
class OrgProfileConfigView extends StatelessWidget {
  final AdminOrgProfile profile;
  final AdminOrgOverview overview;
  final VoidCallback onBack;

  const OrgProfileConfigView({
    super.key,
    required this.profile,
    required this.overview,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
                  'Organization Profile & Settings',
                  style: AppTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Primary Organization Identification Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Legal Entity & Charter Registration',
                          style: AppTypography.titleMedium,
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    StatusBadge(
                        label: 'NCUA VERIFIED', type: StatusBadgeType.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.md),
                _buildRow('Cooperative Name', profile.orgName),
                _buildRow('Legal Entity Name', profile.legalEntityName),
                _buildRow('Federal Charter ID', overview.charterId),
                _buildRow('Tenant Identifier', overview.tenantId),
                _buildRow('Tax Identification (EIN)', profile.taxId),
                _buildRow('Base Operating Currency', profile.baseCurrency),
                _buildRow('Primary Headquarters', profile.primaryAddress),
                _buildRow('Contact Email', profile.primaryContactEmail),
                _buildRow('Contact Phone', profile.primaryContactPhone),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Underwriting & Fiduciary Operating Rules Card
          const Text('Operational Underwriting Parameters',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Invariants enforced across all cooperative cycles and liquidity pools.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow('Required Treasury Reserve Ratio',
                    '${profile.reserveRequirementPercent.toStringAsFixed(1)}% (Enforced)'),
                _buildRow(
                    'Maker-Checker Dual Authorization',
                    overview.makerCheckerEnabled
                        ? 'ENABLED (Strict Dual Sign-Off)'
                        : 'DISABLED'),
                _buildRow('Maximum Cycle Duration',
                    '${profile.maxCycleDurationMonths} Months'),
                _buildRow('Maximum Slot Capacity / Pool',
                    '${profile.maxMemberSlots} Members'),
                _buildRow('Delinquency Tolerance Limit',
                    '0 Days (Automatic Watchlist at +1 Day)'),
                _buildRow('Automated 5-Way Reconciliation',
                    'ACTIVE (Zero-Variance Invariant)'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Branch Locations Roster
          const Text('Authorized Branch Network',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),

          for (final branch in profile.branches) ...[
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadii.borderSm,
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        color: AppColors.emeraldGreen, size: 20.0),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(branch,
                        style: AppTypography.titleSmall,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const StatusBadge(
                      label: 'ACTIVE', type: StatusBadgeType.success),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Back CTA
          SecondaryButton(
            label: 'Back to Admin Overview',
            onPressed: onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTypography.labelMedium
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
