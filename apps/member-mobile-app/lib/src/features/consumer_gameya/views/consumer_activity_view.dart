import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';
import '../state/gameya_controller.dart';
import '../i18n/gameya_strings.dart';

/// Surface C (Tab 2): Unified Personal Financial Activity Timeline.
class ConsumerActivityView extends StatelessWidget {
  final GameyaController controller;

  const ConsumerActivityView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameyaState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is! GameyaLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.emeraldGreen));
        }

        final strings = GameyaStrings.of(state.languageCode);
        final timeline = state.activityTimeline;

        return Directionality(
          textDirection: strings.textDirection,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title & Subtitle
                Text(
                  strings.activityTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.activitySubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                // Activity List
                if (timeline.isEmpty)
                  _buildEmptyActivityCard()
                else
                  for (final item in timeline) ...[
                    _buildActivityTimelineCard(item),
                    const SizedBox(height: 10),
                  ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Column(
        children: [
          Icon(Icons.history, color: AppColors.textMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No recent activity',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Your circle contributions and payouts will appear here.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineCard(ActivityTimelineItem item) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (item.eventType) {
      case ActivityEventType.contributionPaid:
        icon = Icons.arrow_upward;
        iconColor = AppColors.emeraldGreen;
        iconBg = AppColors.emeraldGreen.withValues(alpha: 0.15);
        break;
      case ActivityEventType.payoutReceived:
      case ActivityEventType.payoutScheduled:
        icon = Icons.stars_rounded;
        iconColor = AppColors.amberWarning;
        iconBg = AppColors.amberWarning.withValues(alpha: 0.15);
        break;
      case ActivityEventType.circleActivated:
      case ActivityEventType.circleJoined:
        icon = Icons.groups_outlined;
        iconColor = AppColors.emeraldGreen;
        iconBg = AppColors.emeraldGreen.withValues(alpha: 0.15);
        break;
      case ActivityEventType.reminderSent:
        icon = Icons.notifications_active_outlined;
        iconColor = AppColors.amberWarning;
        iconBg = AppColors.amberWarning.withValues(alpha: 0.15);
        break;
      default:
        icon = Icons.check_circle_outline;
        iconColor = AppColors.textSecondary;
        iconBg = AppColors.surfaceElevated;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.amountMinor != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${item.isDebit ? "-" : "+"}\$${(item.amountMinor! / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: item.isDebit ? AppColors.textPrimary : AppColors.emeraldGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.circleName,
                  style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTimeAgo(item.timestamp),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
