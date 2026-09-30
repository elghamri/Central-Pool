import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';

/// Card widget rendering a Game'ya circle's progress, monthly due, slot, and status.
class GameyaSummaryCard extends StatelessWidget {
  final GameyaCircle circle;
  final VoidCallback? onTap;

  const GameyaSummaryCard({
    super.key,
    required this.circle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnrolled = circle.isUserEnrolled;
    final isForming = circle.status == GameyaCircleStatus.forming;
    final isSymmetrical = circle.allocationMode == GameyaAllocationMode.symmetricalPaired;

    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Goal Badge + Title + Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Icon / Category
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(
                  _getCategoryIcon(circle.goalCategory),
                  color: AppColors.emeraldGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Organizer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      circle.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Organizer: ${circle.organizerName}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: AppColors.amberWarning, size: 12),
                        Text(
                          ' ${circle.organizerTrustRating.toStringAsFixed(1)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Chip
              StatusBadge(
                label: isForming ? '${circle.claimedSlotsCount}/${circle.totalPeriods} Joined' : circle.status.displayName,
                type: isForming ? StatusBadgeType.warning : (circle.status == GameyaCircleStatus.active ? StatusBadgeType.success : StatusBadgeType.neutral),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Financial Terms Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Monthly Contribution
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Due', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    FinancialAmountText(
                      amountMinor: circle.monthlyContributionMinor,
                      currency: 'USD',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Total Payout
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(isSymmetrical ? 'Pair Payout' : 'Total Payout', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    FinancialAmountText(
                      amountMinor: circle.slots.isNotEmpty ? circle.slots.first.payoutAmountMinor : 0,
                      currency: 'USD',
                      style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Duration / Slots
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Duration', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      '${circle.totalPeriods} Mos',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress Bar (if active) OR Open Slots (if forming)
          if (!isForming) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: circle.progressFraction,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Month ${circle.currentPeriod} of ${circle.totalPeriods}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isEnrolled) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Slot #${circle.currentUserSlotPosition}',
                      style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${circle.openSlotsCount} Payout Positions Available',
                      style: const TextStyle(color: AppColors.amberWarning, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Pick Month →',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'family':
        return Icons.family_restroom;
      case 'vehicle':
      case 'car':
        return Icons.directions_car;
      case 'wedding':
        return Icons.favorite;
      case 'education':
        return Icons.school;
      case 'home':
        return Icons.home;
      default:
        return Icons.savings_outlined;
    }
  }
}
