import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/platform_models.dart';
import '../state/platform_controller.dart';
import '../state/platform_state.dart';

/// Screen 36: Platform Infrastructure & Microservice Health Console View.
class PlatformHealthView extends StatelessWidget {
  final PlatformController controller;

  const PlatformHealthView({
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
            title: 'Failed to Load Platform Telemetry',
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
    final overallStatus = state.overallPlatformStatus;
    final nodes = state.filteredHealthNodes;

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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('System Health & Infrastructure',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Cluster liveness, microservice topology, and distributed lock health.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: overallStatus.displayName,
                  type: _getStatusBadgeType(overallStatus),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Top Status Summary Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: overallStatus == SubsystemHealthStatus.healthy
                    ? AppColors.emeraldGreen.withValues(alpha: 0.1)
                    : AppColors.crimsonRed.withValues(alpha: 0.1),
                borderRadius: AppRadii.borderMd,
                border: Border.all(
                  color: overallStatus == SubsystemHealthStatus.healthy
                      ? AppColors.emeraldGreen.withValues(alpha: 0.4)
                      : AppColors.crimsonRed.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    overallStatus == SubsystemHealthStatus.healthy
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: overallStatus == SubsystemHealthStatus.healthy
                        ? AppColors.emeraldGreen
                        : AppColors.crimsonRed,
                    size: 32.0,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overallStatus == SubsystemHealthStatus.healthy
                              ? 'All Core Financial Subsystems Operational'
                              : 'System Attention Required: Subsystem Degraded',
                          style: AppTypography.titleMedium.copyWith(
                            color:
                                overallStatus == SubsystemHealthStatus.healthy
                                    ? AppColors.emeraldGreen
                                    : AppColors.crimsonRed,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '8 of 8 service pods reporting active health probes. Zero outbox backlog detected.',
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
              label: 'Filter Service Nodes',
              hint: 'Search by service name or node identifier...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              onChanged: (v) => controller.setSearchQuery(v),
            ),
            const SizedBox(height: AppSpacing.md),

            // Status Filter Chips
            const Text('Health Status Filter', style: AppTypography.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'ALL', state.statusFilter),
                  _buildFilterChip('HEALTHY', 'Healthy', state.statusFilter),
                  _buildFilterChip('DEGRADED', 'Degraded', state.statusFilter),
                  _buildFilterChip(
                      'UNAVAILABLE', 'Unavailable', state.statusFilter),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Service Health Nodes List
            if (nodes.isEmpty)
              _buildEmptyState()
            else
              for (final node in nodes) ...[
                _buildNodeCard(context, node),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String activeValue) {
    final isSelected = activeValue.toUpperCase() == value.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.emeraldGreen.withValues(alpha: 0.2),
        backgroundColor: AppColors.cardSurface,
        labelStyle: AppTypography.labelSmall.copyWith(
          color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle,
        ),
        onSelected: (_) => controller.setStatusFilter(value),
      ),
    );
  }

  Widget _buildNodeCard(BuildContext context, SystemHealthNode node) {
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
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppRadii.borderSm,
                        ),
                        child: Icon(_getNodeIcon(node.nodeId),
                            color: AppColors.emeraldGreen, size: 20.0),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(node.serviceName,
                                style: AppTypography.titleMedium,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              'Node ID: ${node.nodeId}',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: node.status.displayName,
                  type: _getStatusBadgeType(node.status),
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
                _buildMetric('p99 Latency', '${node.latencyMs} ms'),
                _buildMetric('30-Day Uptime',
                    '${node.uptimePercent.toStringAsFixed(2)}%'),
                _buildMetric('Active Errors', '${node.errorCount}'),
                _buildMetric('Last Health Probe',
                    '${node.lastChecked.hour.toString().padLeft(2, '0')}:${node.lastChecked.minute.toString().padLeft(2, '0')}:${node.lastChecked.second.toString().padLeft(2, '0')} UTC'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              node.details,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
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

  StatusBadgeType _getStatusBadgeType(SubsystemHealthStatus status) {
    switch (status) {
      case SubsystemHealthStatus.healthy:
        return StatusBadgeType.success;
      case SubsystemHealthStatus.degraded:
        return StatusBadgeType.warning;
      case SubsystemHealthStatus.unavailable:
        return StatusBadgeType.error;
      case SubsystemHealthStatus.unknown:
        return StatusBadgeType.info;
    }
  }

  IconData _getNodeIcon(String nodeId) {
    if (nodeId.contains('postgres')) return Icons.storage;
    if (nodeId.contains('redis')) return Icons.memory;
    if (nodeId.contains('kafka')) return Icons.sync_alt;
    if (nodeId.contains('gateway')) return Icons.router;
    if (nodeId.contains('funding')) return Icons.monetization_on_outlined;
    if (nodeId.contains('treasury')) return Icons.account_balance;
    if (nodeId.contains('accounting')) return Icons.receipt_long;
    return Icons.dns;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.search_off,
              size: 48.0, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          const Text('No matching infrastructure nodes found',
              style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Adjust search filter or select another health status chip.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
