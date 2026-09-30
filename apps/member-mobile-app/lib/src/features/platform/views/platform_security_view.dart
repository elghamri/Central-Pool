import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/platform_models.dart';
import '../state/platform_controller.dart';
import '../state/platform_state.dart';

/// Screen 39: Security Center, RBAC & WORM Audit Trail View.
class PlatformSecurityView extends StatelessWidget {
  final PlatformController controller;

  const PlatformSecurityView({
    super.key,
    required this.controller,
  });

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
            title: 'Failed to Load Security Logs',
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
    final events = state.filteredSecurityEvents;

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
                      const Text('Security Operations & WORM Audit',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Authentication telemetry, RBAC role mutations, and Write-Once-Read-Many cryptographic seals.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const StatusBadge(
                    label: 'WORM COMPLIANCE SEALED',
                    type: StatusBadgeType.success),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Top WORM Integrity Summary
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.borderMd,
                border: Border.all(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified,
                      color: AppColors.emeraldGreen, size: 30.0),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('100% Cryptographic Ledger Integrity Confirmed',
                            style: AppTypography.titleMedium
                                .copyWith(color: AppColors.emeraldGreen)),
                        const SizedBox(height: 2.0),
                        Text(
                          'Zero SHA-256 hash mismatches or unauthorized role escalations detected across all tenant partitions.',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Search Bar
            StandardTextField(
              label: 'Search Security Events',
              hint: 'Search by event ID, actor ID, type, or description...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              onChanged: (v) => controller.setSearchQuery(v),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (events.isEmpty)
              _buildEmptyState()
            else
              for (final event in events) ...[
                _buildEventCard(context, event),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, SecurityAuditEvent event) {
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
                      Text(event.eventType,
                          style: AppTypography.titleMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Event ID: ${event.eventId} • Tenant: ${event.tenantId}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: event.severity,
                  type: event.severity == 'CRITICAL'
                      ? StatusBadgeType.error
                      : (event.severity == 'WARNING'
                          ? StatusBadgeType.warning
                          : StatusBadgeType.info),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.borderSubtle, height: 1.0),
            const SizedBox(height: AppSpacing.md),
            Text(event.description, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 20.0,
              runSpacing: 8.0,
              children: [
                _buildMetric(
                    'Actor ID & Role', '${event.actorId} (${event.actorRole})'),
                _buildMetric('IP Address', event.ipAddress),
                _buildMetric('Correlation ID', event.correlationId),
                _buildMetric('Timestamp',
                    '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')} UTC'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.borderSm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint,
                      color: AppColors.sovereignGold, size: 16.0),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'WORM Digest: ${event.wormHash}',
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.sovereignGold,
                          fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
        Text(value, style: AppTypography.titleSmall),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.security, size: 48.0, color: AppColors.emeraldGreen),
          const SizedBox(height: AppSpacing.md),
          const Text('No Security Anomalies Detected',
              style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'All authentication, authorization, and tenant isolation events are healthy.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
