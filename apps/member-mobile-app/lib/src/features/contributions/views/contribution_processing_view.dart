import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/contribution_models.dart';

/// Screen 13: Contribution Processing, Timeout, and Failure States View.
class ContributionProcessingView extends StatelessWidget {
  final String status; // PROCESSING, FAILED, TIMEOUT, PENDING
  final String? message;
  final String? errorCode;
  final String? correlationId;
  final ContributionDetail detail;
  final PaymentMethodItem paymentMethod;
  final VoidCallback onRetry;
  final VoidCallback onChangeMethod;
  final VoidCallback onReturnToOverview;

  const ContributionProcessingView({
    super.key,
    required this.status,
    this.message,
    this.errorCode,
    this.correlationId,
    required this.detail,
    required this.paymentMethod,
    required this.onRetry,
    required this.onChangeMethod,
    required this.onReturnToOverview,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'PROCESSING') {
      return _buildProcessingState();
    } else if (status == 'TIMEOUT') {
      return _buildTimeoutState();
    } else if (status == 'FAILED') {
      return _buildFailedState();
    }

    return _buildProcessingState();
  }

  Widget _buildProcessingState() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.3),
                    width: 2.0),
              ),
              child: const SizedBox(
                width: 48.0,
                height: 48.0,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Processing Contribution...',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ??
                  'Dispatching ISO 20022 clearing instruction to FedNow RTGS rail and verifying double-entry allocation...',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SurfaceCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      FinancialAmountText(
                          amountMinor: detail.amountMinor,
                          style: AppTypography.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Clearing Rail',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      Text(paymentMethod.title,
                          style: AppTypography.labelMedium),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedState() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.crimsonRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.crimsonRed),
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.crimsonRed, size: 48.0),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Center(
            child: Text(
              'Payment Authorization Failed',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              'The transaction could not be completed on the selected banking rail.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Error Explanation Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Failure Diagnostic',
                        style: AppTypography.titleMedium),
                    StatusBadge(
                        label: errorCode ?? 'ERR_REJECTED',
                        type: StatusBadgeType.error),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message ??
                      'The banking rail reported insufficient funds or connection failure.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.crimsonRed),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No money was deducted from your account. Your contribution remains due.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Recovery Actions
          PrimaryButton(
            label: 'Retry Payment (\$500.00)',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Select Different Payment Method',
            icon: Icons.payment,
            onPressed: onChangeMethod,
          ),
          const SizedBox(height: AppSpacing.sm),
          GhostButton(
            label: 'Return to Contributions Overview',
            onPressed: onReturnToOverview,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutState() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.sovereignGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.sovereignGold),
              ),
              child: const Icon(Icons.timer_off_outlined,
                  color: AppColors.sovereignGold, size: 48.0),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Center(
            child: Text(
              'Clearing Network Timeout',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              'The clearing network did not respond within the expected threshold.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: Unconfirmed',
                        style: AppTypography.titleMedium),
                    StatusBadge(
                        label: 'TIMEOUT / PENDING',
                        type: StatusBadgeType.warning),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This timeout is NOT considered a successful payment. To prevent double charges, our ledger is verifying the settlement status before resubmitting.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textPrimary),
                ),
                if (correlationId != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Tracking Correlation ID: $correlationId',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Check Status & Return to Overview',
            icon: Icons.refresh,
            onPressed: onReturnToOverview,
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Retry Authorization',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
