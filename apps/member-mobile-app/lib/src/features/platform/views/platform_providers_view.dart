import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/platform_models.dart';
import '../state/platform_controller.dart';
import '../state/platform_state.dart';

/// Screen 38: Payment Provider & Clearing Rails Console View.
class PlatformProvidersView extends StatelessWidget {
  final PlatformController controller;

  const PlatformProvidersView({
    super.key,
    required this.controller,
  });

  Future<void> _handleEditProvider(
      BuildContext context, PaymentProviderConfig provider) async {
    final rateLimitController =
        TextEditingController(text: provider.rateLimitPerSec.toString());
    final timeoutController =
        TextEditingController(text: provider.timeoutSeconds.toString());
    final webhookController = TextEditingController(text: provider.webhookUrl);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Configure ${provider.displayName}',
            style: AppTypography.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust clearing gateway throughput, webhook delivery endpoints, and latency timeouts.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              StandardTextField(
                label: 'Webhook Notification URL',
                controller: webhookController,
              ),
              const SizedBox(height: AppSpacing.sm),
              StandardTextField(
                label: 'Throughput Rate Limit (req/sec)',
                controller: rateLimitController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              StandardTextField(
                label: 'Gateway Timeout (Seconds)',
                controller: timeoutController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Credential Security: API keys are managed in HashiCorp Vault. Key: ${provider.maskedApiKey}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.sovereignGold),
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
            label: 'Save Configuration',
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final rate = int.tryParse(rateLimitController.text.trim()) ??
          provider.rateLimitPerSec;
      final timeout = int.tryParse(timeoutController.text.trim()) ??
          provider.timeoutSeconds;

      final success = await controller.updateProviderConfig(
        provider.providerId,
        rateLimit: rate,
        timeoutSeconds: timeout,
        webhookUrl: webhookController.text.trim(),
      );

      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.displayName} configuration updated.'),
            backgroundColor: AppColors.emeraldGreen,
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
            title: 'Failed to Load Provider Configurations',
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
    final providers = state.providers;

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
                      const Text('Clearing Rails & Gateway Adapters',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Operational configuration and health monitoring for all clearing gateways.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const StatusBadge(
                    label: 'SANDBOX SIMULATION ACTIVE',
                    type: StatusBadgeType.warning),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Safety Warning Banner
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.borderMd,
                border: Border.all(
                    color: AppColors.sovereignGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.sovereignGold, size: 22.0),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Payment Safety Rule: Real-money clearing movement is disabled platform-wide. All rail dispatches run in simulated sandboxes.',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.sovereignGold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            for (final provider in providers) ...[
              _buildProviderCard(context, provider),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(
      BuildContext context, PaymentProviderConfig provider) {
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
                        child: Icon(_getRailIcon(provider.railName),
                            color: AppColors.emeraldGreen, size: 20.0),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider.displayName,
                                style: AppTypography.titleMedium,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              'Provider ID: ${provider.providerId} • Rail: ${provider.railName}',
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
                  label: provider.status.displayName,
                  type: provider.status == SubsystemHealthStatus.healthy
                      ? StatusBadgeType.success
                      : StatusBadgeType.warning,
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
                _buildMetric(
                    'Rate Limit Quota', '${provider.rateLimitPerSec} req/sec'),
                _buildMetric(
                    'Gateway Timeout', '${provider.timeoutSeconds} seconds'),
                _buildMetric(
                    'Execution Mode',
                    provider.isSandboxSimMode
                        ? 'Sandbox Simulation'
                        : 'Live Production'),
                _buildMetric('Vault Secret Key', provider.maskedApiKey),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Webhook Endpoint: ${provider.webhookUrl}',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary, fontFamily: 'monospace'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PrimaryButton(
                  label: 'Configure Adapter',
                  icon: Icons.tune,
                  isFullWidth: false,
                  onPressed: () => _handleEditProvider(context, provider),
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

  IconData _getRailIcon(String railName) {
    switch (railName.toUpperCase()) {
      case 'FEDNOW':
      case 'RTP':
        return Icons.bolt;
      case 'ACH':
        return Icons.account_balance;
      case 'STRIPE':
      default:
        return Icons.credit_card;
    }
  }
}
