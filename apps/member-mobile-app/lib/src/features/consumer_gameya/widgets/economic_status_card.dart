import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';

/// Transparent layman card communicating the member's economic position in a Game'ya.
class EconomicStatusCard extends StatelessWidget {
  final GameyaCircle circle;

  const EconomicStatusCard({
    super.key,
    required this.circle,
  });

  @override
  Widget build(BuildContext context) {
    final positionType = circle.currentUserEconomicPosition;
    if (positionType == null) return const SizedBox.shrink();

    final isDebtor = positionType == EconomicPositionType.repayingAdvancePayout;
    final primaryColor = isDebtor ? AppColors.emeraldGreen : AppColors.amberWarning;
    final bgColor = isDebtor
        ? AppColors.emeraldGreen.withValues(alpha: 0.12)
        : AppColors.amberWarning.withValues(alpha: 0.12);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDebtor ? Icons.check_circle_outline : Icons.savings_outlined,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  positionType.title,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              StatusBadge(
                label: 'Slot #${circle.currentUserSlotPosition}',
                type: isDebtor ? StatusBadgeType.success : StatusBadgeType.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            positionType.description,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isDebtor ? 'Remaining Monthly Dues' : 'Accumulated Savings',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FinancialAmountText(
                amountMinor: isDebtor
                    ? circle.userRemainingObligationMinor
                    : (circle.currentPeriod * circle.monthlyContributionMinor),
                currency: 'USD',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
