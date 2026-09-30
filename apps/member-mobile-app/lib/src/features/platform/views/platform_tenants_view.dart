import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/platform_models.dart';
import '../state/platform_controller.dart';
import '../state/platform_state.dart';

/// Screen 37: Multi-Tenant & Organization Provisioning Console View.
class PlatformTenantsView extends StatelessWidget {
  final PlatformController controller;

  const PlatformTenantsView({
    super.key,
    required this.controller,
  });

  Future<void> _handleProvisionTenant(BuildContext context) async {
    final nameController = TextEditingController();
    final legalController = TextEditingController();
    final charterController = TextEditingController();
    int selectedReserveBps = 1500; // 15.0%

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: const Text('Provision New Cooperative Tenant',
              style: AppTypography.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Provision an isolated tenant partition with dedicated Row-Level Security (RLS) policies and double-entry chart of accounts.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                StandardTextField(
                  label: 'Cooperative Name',
                  hint: 'e.g. Delta Vanguard Mutual Credit',
                  controller: nameController,
                ),
                const SizedBox(height: AppSpacing.sm),
                StandardTextField(
                  label: 'Legal Entity Name',
                  hint: 'e.g. Delta Vanguard Federal Credit Society',
                  controller: legalController,
                ),
                const SizedBox(height: AppSpacing.sm),
                StandardTextField(
                  label: 'NCUA / Regulatory Charter #',
                  hint: 'e.g. NCUA-COOP-2026-992',
                  controller: charterController,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Liquidity Reserve Guardrail Ratio',
                    style: AppTypography.labelSmall),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<int>(
                  initialValue: selectedReserveBps,
                  dropdownColor: AppColors.cardSurface,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 1500,
                        child: Text('15.0% Regulatory Guardrail (Standard)')),
                    DropdownMenuItem(
                        value: 1750,
                        child: Text('17.5% Enhanced Liquidity Buffer')),
                    DropdownMenuItem(
                        value: 2000,
                        child: Text('20.0% Conservative Reserve Ratio')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedReserveBps = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            PrimaryButton(
              label: 'Provision Tenant',
              icon: Icons.add_business,
              isFullWidth: false,
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    charterController.text.trim().isNotEmpty) {
                  Navigator.of(ctx).pop(true);
                }
              },
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final success = await controller.provisionNewTenant(
        name: nameController.text.trim(),
        legalEntityName: legalController.text.trim().isNotEmpty
            ? legalController.text.trim()
            : nameController.text.trim(),
        charterNumber: charterController.text.trim(),
        reserveRatioBps: selectedReserveBps,
      );

      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Tenant "${nameController.text.trim()}" provisioned successfully.'),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
      }
    }
  }

  Future<void> _handleToggleStatus(
      BuildContext context, PlatformTenantItem tenant) async {
    final willSuspend = tenant.status == 'ACTIVE';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text(
          willSuspend
              ? 'Suspend Tenant Partition?'
              : 'Reactivate Tenant Partition?',
          style: TextStyle(
              color:
                  willSuspend ? AppColors.crimsonRed : AppColors.emeraldGreen),
        ),
        content: Text(
          willSuspend
              ? 'Suspending "${tenant.name}" (${tenant.tenantId}) will immediately pause new member logins, cycle creations, and clearing dispatches.'
              : 'Reactivating "${tenant.name}" (${tenant.tenantId}) will restore full member access and scheduled rotation disbursements.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  willSuspend ? AppColors.crimsonRed : AppColors.emeraldGreen,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
                willSuspend ? 'Confirm Suspension' : 'Confirm Reactivation',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.toggleTenantStatus(tenant.tenantId,
          suspend: willSuspend);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tenant ${tenant.name} status updated.'),
            backgroundColor:
                willSuspend ? AppColors.amberWarning : AppColors.emeraldGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlatformState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is PlatformLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.emeraldGreen));
        }

        if (state is PlatformError) {
          return ErrorCardWidget(
            title: 'Failed to Load Tenant Registry',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => controller.loadPlatformTelemetry(forceRefresh: true),
          );
        }

        if (state is PlatformLoaded) {
          return _buildLoadedView(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, PlatformLoaded state) {
    final tenants = state.filteredTenants;

    return RefreshIndicator(
      onRefresh: () => controller.loadPlatformTelemetry(forceRefresh: true),
      color: AppColors.emeraldGreen,
      backgroundColor: AppColors.cardSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      const Text('Multi-Tenant Registry',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Commercial cooperative tenant partitions with enforced Row-Level Security (RLS) isolation.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                PrimaryButton(
                  label: 'Provision Tenant',
                  icon: Icons.add_business,
                  isFullWidth: false,
                  onPressed: () => _handleProvisionTenant(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Search Bar
            StandardTextField(
              label: 'Search Tenants',
              hint:
                  'Search by cooperative name, tenant ID, or charter number...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              onChanged: (v) => controller.setSearchQuery(v),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (tenants.isEmpty)
              _buildEmptyState()
            else
              for (final tenant in tenants) ...[
                _buildTenantCard(context, tenant),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildTenantCard(BuildContext context, PlatformTenantItem tenant) {
    final isActive = tenant.status == 'ACTIVE';

    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                      Text(tenant.name,
                          style: AppTypography.titleLarge,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Tenant ID: ${tenant.tenantId} • Charter: ${tenant.charterNumber}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: tenant.status,
                  type: isActive
                      ? StatusBadgeType.success
                      : StatusBadgeType.error,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.borderSubtle, height: 1.0),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 20.0,
              runSpacing: 8.0,
              children: [
                _buildMetric('Active Members', '${tenant.memberCount} Members'),
                _buildMetric('Reserve Guardrail',
                    '${(tenant.reserveRatioBps / 100).toStringAsFixed(1)}%'),
                _buildAmountMetric(
                    'Total Managed Capital', tenant.totalCapitalMinor),
                _buildMetric('Isolation Layer', tenant.isolationStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: isActive
                      ? 'Suspend Tenant Access'
                      : 'Reactivate Partition',
                  icon: isActive ? Icons.block : Icons.check_circle_outline,
                  isFullWidth: false,
                  onPressed: () => _handleToggleStatus(context, tenant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2.0),
        Text(value,
            style:
                AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildAmountMetric(String label, int amountMinor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2.0),
        FinancialAmountText(
          amountMinor: amountMinor,
          style: AppTypography.titleMedium.copyWith(
              color: AppColors.emeraldGreen, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.business_outlined,
              size: 48.0, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          const Text('No matching tenant partitions found',
              style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Adjust search criteria or click "Provision Tenant" to create a new cooperative partition.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
