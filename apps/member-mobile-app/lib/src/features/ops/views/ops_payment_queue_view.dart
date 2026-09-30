import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/ops_models.dart';
import '../state/ops_controller.dart';
import '../state/ops_state.dart';

/// Screen 29: Operations Payment Queue & Live Rail Dispatches View.
class OpsPaymentQueueView extends StatelessWidget {
  final OpsController controller;
  final ValueChanged<OpsPaymentItem> onSelectPayment;

  const OpsPaymentQueueView({
    super.key,
    required this.controller,
    required this.onSelectPayment,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OpsState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is OpsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.emeraldGreen));
        }

        if (state is OpsError) {
          return ErrorCardWidget(
            title: 'Failed to Load Payment Queue',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => controller.loadOpsTelemetry(forceRefresh: true),
          );
        }

        if (state is OpsLoaded) {
          return _buildLoadedView(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, OpsLoaded state) {
    final filteredPayments = state.filteredPayments;

    return RefreshIndicator(
      onRefresh: () => controller.loadOpsTelemetry(forceRefresh: true),
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
                      const Text('Operations Payment Queue',
                          style: AppTypography.headlineMedium,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2.0),
                      Text(
                        'Monitor multi-rail clearing dispatches across FedNow, RTP, ACH, and Card rails.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                    label: '${filteredPayments.length} INSTRUCTIONS',
                    type: StatusBadgeType.success),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Search Bar
            StandardTextField(
              label: 'Search Payment Queue',
              hint:
                  'Search by Payment ID, Member, Instruction or Correlation ID...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              onChanged: (v) => controller.setSearchQuery(v),
            ),
            const SizedBox(height: AppSpacing.md),

            // Rail Filter Chips
            const Text('Payment Rail Filter', style: AppTypography.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRailChip('ALL', 'ALL', state.railFilter),
                  _buildRailChip('FEDNOW', 'FedNow Instant', state.railFilter),
                  _buildRailChip('RTP', 'RTP Network', state.railFilter),
                  _buildRailChip('ACH', 'ACH Batch', state.railFilter),
                  _buildRailChip('STRIPE', 'Card / Digital', state.railFilter),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Status Filter Chips
            const Text('Settlement Status Filter',
                style: AppTypography.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('ALL', 'ALL', state.statusFilter),
                  _buildStatusChip(
                      'DISPATCHED', 'Dispatched', state.statusFilter),
                  _buildStatusChip('SETTLED', 'Settled', state.statusFilter),
                  _buildStatusChip(
                      'PROCESSING', 'Processing', state.statusFilter),
                  _buildStatusChip(
                      'UNKNOWN', 'Unknown State', state.statusFilter),
                  _buildStatusChip('FAILED', 'Failed', state.statusFilter),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Payment items list
            if (filteredPayments.isEmpty)
              _buildEmptyState()
            else
              for (final payment in filteredPayments) ...[
                _buildPaymentCard(context, payment),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildRailChip(String value, String label, String activeValue) {
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
        onSelected: (_) => controller.setRailFilter(value),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, String activeValue) {
    final isSelected = activeValue.toUpperCase() == value.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.sovereignGold.withValues(alpha: 0.2),
        backgroundColor: AppColors.cardSurface,
        labelStyle: AppTypography.labelSmall.copyWith(
          color: isSelected ? AppColors.sovereignGold : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.sovereignGold : AppColors.borderSubtle,
        ),
        onSelected: (_) => controller.setStatusFilter(value),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, OpsPaymentItem payment) {
    final isSettled = payment.status == 'SETTLED';
    final isDispatched = payment.status == 'DISPATCHED';
    final isUnknown = payment.status == 'UNKNOWN';
    final isFailed = payment.status == 'FAILED';

    final badgeType = isSettled
        ? StatusBadgeType.success
        : (isDispatched
            ? StatusBadgeType.info
            : (isUnknown || isFailed
                ? StatusBadgeType.error
                : StatusBadgeType.warning));

    return SurfaceCard(
      child: InkWell(
        onTap: () => onSelectPayment(payment),
        borderRadius: AppRadii.borderMd,
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
                          child: Icon(_getRailIcon(payment.paymentRail),
                              color: AppColors.emeraldGreen, size: 20.0),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(payment.recipientName,
                                  style: AppTypography.titleMedium,
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                'Payment: ${payment.paymentId} • Rail: ${payment.paymentRail.displayName}',
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
                  StatusBadge(label: payment.status, type: badgeType),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.borderSubtle, height: 1.0),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount Dispatched',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 2.0),
                        FinancialAmountText(
                          amountMinor: payment.amountMinor,
                          style: AppTypography.titleLarge
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Correlation ID',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 2.0),
                        Text(
                          payment.correlationId,
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.sovereignGold,
                              fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRailIcon(PaymentRailType rail) {
    switch (rail) {
      case PaymentRailType.fedNow:
      case PaymentRailType.rtp:
        return Icons.bolt;
      case PaymentRailType.ach:
        return Icons.account_balance;
      case PaymentRailType.stripe:
        return Icons.credit_card;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 48.0, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          const Text('No matching payment instructions found',
              style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Adjust your search terms or filter chips to view payment queue records.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
