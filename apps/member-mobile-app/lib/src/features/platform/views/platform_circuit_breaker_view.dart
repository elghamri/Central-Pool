import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../state/platform_controller.dart';
import '../state/platform_state.dart';

/// Screen 40: Emergency Circuit Breaker & Platform Controls View.
class PlatformCircuitBreakerView extends StatelessWidget {
  final PlatformController controller;

  const PlatformCircuitBreakerView({
    super.key,
    required this.controller,
  });

  Future<void> _handleToggleBreaker(
    BuildContext context, {
    required String breakerType,
    required String title,
    required String description,
    required bool currentStatus,
  }) async {
    final willEnable = !currentStatus;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Row(
          children: [
            Icon(
              willEnable
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: willEnable ? AppColors.crimsonRed : AppColors.emeraldGreen,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                willEnable ? 'Engage $title?' : 'Disengage $title?',
                style: TextStyle(
                    color: willEnable
                        ? AppColors.crimsonRed
                        : AppColors.emeraldGreen),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              willEnable
                  ? 'CRITICAL OPERATION: Engaging this circuit breaker will $description.'
                  : 'You are disengaging the emergency safeguard and restoring normal operational throughput.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            StandardTextField(
              label: 'Emergency Incident Rationale (Required)',
              hint:
                  'e.g. Upstream clearing gateway anomaly observed in Kafka topic',
              controller: reasonController,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Audit Logging: This action will be cryptographically signed by ${controller.session.fullName} (${controller.session.userId}) and logged to WORM compliance storage.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.sovereignGold),
            ),
          ],
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
                  willEnable ? AppColors.crimsonRed : AppColors.emeraldGreen,
            ),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(
              willEnable
                  ? 'Confirm Emergency Engagement'
                  : 'Confirm Disengagement',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.toggleCircuitBreaker(
        breakerType: breakerType,
        enable: willEnable,
        reason: reasonController.text.trim(),
      );

      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$title is now ${willEnable ? "ACTIVE (ENGAGED)" : "DISENGAGED"}.'),
            backgroundColor:
                willEnable ? AppColors.crimsonRed : AppColors.emeraldGreen,
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
            title: 'Failed to Load Circuit Breaker State',
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
    final breaker = state.circuitBreaker;

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
                      const Text('Emergency Circuit Breakers',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'High-risk platform controls to instantly halt money movement, pause writes, or engage maintenance.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: breaker.isGlobalFreezeActive
                      ? 'SYSTEM FROZEN'
                      : 'NORMAL OPERATIONS',
                  type: breaker.isGlobalFreezeActive
                      ? StatusBadgeType.error
                      : StatusBadgeType.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // High-Risk Security Banner
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.crimsonRed.withValues(alpha: 0.1),
                borderRadius: AppRadii.borderMd,
                border: Border.all(
                    color: AppColors.crimsonRed.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_rounded,
                      color: AppColors.crimsonRed, size: 30.0),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('High-Risk Operational Safety Boundary',
                            style: AppTypography.titleMedium
                                .copyWith(color: AppColors.crimsonRed)),
                        const SizedBox(height: 2.0),
                        Text(
                          'Actions on this screen immediately impact all cooperative tenants and payment rails. Dual-confirmation is strictly required.',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 1. Global Platform Freeze
            _buildControlCard(
              context,
              title: 'Global Platform Write Freeze',
              description:
                  'immediately lock database writes across all services and pause member contribution & payout cycles',
              isActive: breaker.isGlobalFreezeActive,
              icon: Icons.pause_circle_filled,
              activeLabel: 'GLOBAL FREEZE ENGAGED',
              inactiveLabel: 'WRITES ENABLED (NORMAL)',
              actionLabel: breaker.isGlobalFreezeActive
                  ? 'Lift Global Freeze'
                  : 'Trigger Global Freeze',
              isCritical: true,
              onToggle: () => _handleToggleBreaker(
                context,
                breakerType: 'GLOBAL_FREEZE',
                title: 'Global Platform Freeze',
                description:
                    'immediately lock database writes across all microservices and halt all scheduled cycle transitions',
                currentStatus: breaker.isGlobalFreezeActive,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Payment Clearing Rails Cutoff
            _buildControlCard(
              context,
              title: 'Payment Clearing Rails Cutoff',
              description:
                  'immediately halt outbound ISO 20022 and NACHA dispatches across FedNow, RTP, ACH, and Card gateways',
              isActive: breaker.isPaymentClearingHalted,
              icon: Icons.money_off,
              activeLabel: 'CLEARING RAILS HALTED',
              inactiveLabel: 'CLEARING RAILS ACTIVE',
              actionLabel: breaker.isPaymentClearingHalted
                  ? 'Resume Clearing Rails'
                  : 'Halt Clearing Gateways',
              isCritical: true,
              onToggle: () => _handleToggleBreaker(
                context,
                breakerType: 'CLEARING_HALT',
                title: 'Payment Clearing Rails Cutoff',
                description:
                    'immediately halt all outbound clearing dispatches to external payment networks',
                currentStatus: breaker.isPaymentClearingHalted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Platform Maintenance Mode
            _buildControlCard(
              context,
              title: 'Platform Maintenance Mode',
              description:
                  'restrict public and member ingress access for planned infrastructure maintenance',
              isActive: breaker.isMaintenanceModeActive,
              icon: Icons.build_circle_outlined,
              activeLabel: 'MAINTENANCE MODE ACTIVE',
              inactiveLabel: 'PUBLIC INGRESS ONLINE',
              actionLabel: breaker.isMaintenanceModeActive
                  ? 'Disable Maintenance'
                  : 'Enable Maintenance Mode',
              isCritical: false,
              onToggle: () => _handleToggleBreaker(
                context,
                breakerType: 'MAINTENANCE_MODE',
                title: 'Platform Maintenance Mode',
                description:
                    'restrict ingress access to Platform Admins for scheduled maintenance',
                currentStatus: breaker.isMaintenanceModeActive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard(
    BuildContext context, {
    required String title,
    required String description,
    required bool isActive,
    required IconData icon,
    required String activeLabel,
    required String inactiveLabel,
    required String actionLabel,
    required bool isCritical,
    required VoidCallback onToggle,
  }) {
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.crimsonRed.withValues(alpha: 0.15)
                              : AppColors.surfaceElevated,
                          borderRadius: AppRadii.borderSm,
                        ),
                        child: Icon(icon,
                            color: isActive
                                ? AppColors.crimsonRed
                                : AppColors.emeraldGreen,
                            size: 22.0),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(title,
                            style: AppTypography.titleLarge,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: isActive ? activeLabel : inactiveLabel,
                  type: isActive
                      ? StatusBadgeType.error
                      : StatusBadgeType.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.borderSubtle, height: 1.0),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Impact Summary: Engaging this control will $description.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? AppColors.emeraldGreen
                        : AppColors.crimsonRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                  ),
                  icon: Icon(
                      isActive ? Icons.lock_open : Icons.power_settings_new,
                      color: Colors.white,
                      size: 18.0),
                  label: Text(actionLabel,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  onPressed: onToggle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
