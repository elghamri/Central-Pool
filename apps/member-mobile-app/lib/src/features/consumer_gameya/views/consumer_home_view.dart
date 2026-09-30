import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';
import '../state/gameya_controller.dart';
import '../widgets/gameya_summary_card.dart';
import '../i18n/gameya_strings.dart';

/// Screen 5: Consumer Member Home — Multi-Circle Financial Hub according to Stitch Baseline.
class ConsumerHomeView extends StatelessWidget {
  final GameyaController controller;
  final ValueChanged<int>? onNavigateTab;
  final ValueChanged<String>? onOpenCircleRoom;
  final VoidCallback? onOpenCreateCircle;
  final bool isOffline;
  final bool isSafetyLockActive;

  const ConsumerHomeView({
    super.key,
    required this.controller,
    this.onNavigateTab,
    this.onOpenCircleRoom,
    this.onOpenCreateCircle,
    this.isOffline = false,
    this.isSafetyLockActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameyaState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is GameyaLoading) {
          return const Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: Center(
              child: AppLoadingIndicator(
                message: 'Loading cooperative circles...',
              ),
            ),
          );
        }

        if (state is GameyaError) {
          return Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ErrorCardWidget(
                  title: 'Unable to Load Hub',
                  errorMessage: state.message,
                  onRetry: state.onRetry ?? controller.loadInitialData,
                ),
              ),
            ),
          );
        }

        if (state is! GameyaLoaded) {
          return const SizedBox.shrink();
        }

        final strings = GameyaStrings.of(state.languageCode);
        final summary = state.hubSummary;
        final activeCircles = summary.activeCircles;

        return Directionality(
          textDirection: strings.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emergency Financial Safety Lock Banner
                    if (isSafetyLockActive) ...[
                      _buildSafetyLockBanner(strings),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Offline Notice Banner
                    if (isOffline) ...[
                      _buildOfflineBanner(strings),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // 1. Personalized Greeting Header
                    _buildGreetingHeader(summary.memberName, strings),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Aggregated Monthly Obligation Hero Banner
                    _buildAggregatedDuesCard(summary, strings),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Next Upcoming Payout Card
                    if (summary.nextPayoutAmountMinor > 0) ...[
                      _buildUpcomingPayoutCard(summary, strings),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    const SizedBox(height: AppSpacing.sm),

                    // 4. Section Header: My Active Game'yas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${strings.myActiveGameyas} (${activeCircles.length})',
                            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onNavigateTab?.call(1),
                          child: Text(
                            strings.discoverMore,
                            style: AppTypography.labelMedium.copyWith(color: AppColors.emeraldGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // 5. Multi-Circle Cards List
                    if (activeCircles.isEmpty)
                      _buildEmptyCirclesCard(context, strings)
                    else
                      for (final circle in activeCircles) ...[
                        GameyaSummaryCard(
                          circle: circle,
                          onTap: () => onOpenCircleRoom?.call(circle.id),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                    const SizedBox(height: AppSpacing.lg),

                    // 6. Quick Actions Floating Bar
                    _buildQuickActionsBar(context, strings),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafetyLockBanner(GameyaStrings strings) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.crimsonRed.withValues(alpha: 0.15),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.crimsonRed.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.crimsonRed, size: 24.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Financial Safety Lock Active: Disbursements are temporarily paused by governance policy.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.crimsonRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(GameyaStrings strings) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.15),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.amberWarning, size: 22.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Offline Mode: Displaying locally cached circle data.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(String name, GameyaStrings strings) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.emeraldGreen.withValues(alpha: 0.2),
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
            style: const TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.greeting(name),
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                strings.homeSubtitle,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAggregatedDuesCard(ConsumerHubSummary summary, GameyaStrings strings) {
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  strings.totalMonthlyObligation,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: '${summary.activeCircles.length} ${strings.activeCirclesCountLabel}',
                type: StatusBadgeType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 6),
          FinancialAmountText(
            amountMinor: summary.totalMonthlyDuesMinor,
            currency: 'USD',
            style: AppTypography.financialDisplay.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.amberWarning, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings.nextPaymentDueIn(5, summary.nextPaymentDueCircleName ?? "Family Circle"),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPayoutCard(ConsumerHubSummary summary, GameyaStrings strings) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withValues(alpha: 0.08),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.emeraldGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.nextUpcomingPayout,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                FinancialAmountText(
                  amountMinor: summary.nextPayoutAmountMinor,
                  currency: 'USD',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.arrivingInDays(34, summary.nextPayoutCircleName ?? "Family Circle"),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCirclesCard(BuildContext context, GameyaStrings strings) {
    return SurfaceCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.groups_outlined, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            'You are not enrolled in any active circles',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Discover an open circle or start your own to begin saving with your community.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: strings.discoverCirclesBtn,
            onPressed: () => onNavigateTab?.call(1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar(BuildContext context, GameyaStrings strings) {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            label: strings.discoverCirclesBtn,
            icon: Icons.search,
            isFullWidth: false,
            onPressed: () => onNavigateTab?.call(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: strings.createGameyaBtn,
            icon: Icons.add,
            isFullWidth: false,
            onPressed: onOpenCreateCircle ?? () {},
          ),
        ),
      ],
    );
  }
}
