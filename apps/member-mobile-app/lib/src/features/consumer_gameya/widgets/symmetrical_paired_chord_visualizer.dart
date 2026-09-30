import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';

/// Interactive Symmetrical Paired 50/50 Chord Visualizer Widget.
/// Graphically renders the bilateral mapping between Early-Half and Late-Half payout slots.
class SymmetricalPairedChordVisualizer extends StatelessWidget {
  final GameyaCircle circle;
  final int? selectedSlotNumber;
  final ValueChanged<int>? onSlotSelected;

  const SymmetricalPairedChordVisualizer({
    super.key,
    required this.circle,
    this.selectedSlotNumber,
    this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (circle.allocationMode != GameyaAllocationMode.symmetricalPaired) {
      return const SizedBox.shrink();
    }

    final totalMembers = circle.totalPeriods;
    final halfCount = totalMembers ~/ 2;
    final halfPayoutMinor = circle.slots.isNotEmpty ? circle.slots.first.payoutAmountMinor : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '50/50 SYMMETRICAL PAIRED',
                  style: TextStyle(
                    color: AppColors.emeraldGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Total Pool: \$${(circle.totalPoolMinor / 100).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Each monthly cycle pays two paired members 50% of the pool:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          for (int i = 1; i <= halfCount; i++) ...[
            _buildPairRow(
              periodNumber: i,
              earlySlotNumber: i,
              lateSlotNumber: totalMembers + 1 - i,
              halfPayoutMinor: halfPayoutMinor,
            ),
            if (i < halfCount || totalMembers.isOdd) const SizedBox(height: 8),
          ],
          if (totalMembers.isOdd) ...[
            _buildMiddleRow(
              middleSlotNumber: (totalMembers + 1) ~/ 2,
              totalPoolMinor: circle.totalPoolMinor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiddleRow({
    required int middleSlotNumber,
    required int totalPoolMinor,
  }) {
    final isCurrentPeriod = circle.currentPeriod == middleSlotNumber;
    final isSelected = selectedSlotNumber == middleSlotNumber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentPeriod ? AppColors.surfaceElevated : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentPeriod ? AppColors.amberWarning.withValues(alpha: 0.5) : AppColors.amberWarning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          // Period Label
          Container(
            width: 60,
            alignment: Alignment.centerLeft,
            child: Text(
              'Month $middleSlotNumber',
              style: TextStyle(
                color: isCurrentPeriod ? AppColors.amberWarning : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isCurrentPeriod ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),

          // Full Middle Slot
          Expanded(
            child: _buildSlotChip(
              slotNumber: middleSlotNumber,
              isEarly: true,
              isSelected: isSelected,
              payoutMinor: totalPoolMinor,
              isMiddleFull: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairRow({
    required int periodNumber,
    required int earlySlotNumber,
    required int lateSlotNumber,
    required int halfPayoutMinor,
  }) {
    final isCurrentPeriod = circle.currentPeriod == periodNumber;
    final isEarlySelected = selectedSlotNumber == earlySlotNumber;
    final isLateSelected = selectedSlotNumber == lateSlotNumber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentPeriod ? AppColors.surfaceElevated : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentPeriod ? AppColors.emeraldGreen.withValues(alpha: 0.5) : AppColors.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Period Label
          Container(
            width: 60,
            alignment: Alignment.centerLeft,
            child: Text(
              'Month $periodNumber',
              style: TextStyle(
                color: isCurrentPeriod ? AppColors.emeraldGreen : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isCurrentPeriod ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),

          // Early Slot
          Expanded(
            child: _buildSlotChip(
              slotNumber: earlySlotNumber,
              isEarly: true,
              isSelected: isEarlySelected,
              payoutMinor: halfPayoutMinor,
            ),
          ),

          // Connecting Dual-Arrow Conduit
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.swap_horiz,
              color: isCurrentPeriod ? AppColors.emeraldGreen : AppColors.textMuted,
              size: 18,
            ),
          ),

          // Late Slot
          Expanded(
            child: _buildSlotChip(
              slotNumber: lateSlotNumber,
              isEarly: false,
              isSelected: isLateSelected,
              payoutMinor: halfPayoutMinor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotChip({
    required int slotNumber,
    required bool isEarly,
    required bool isSelected,
    required int payoutMinor,
    bool isMiddleFull = false,
  }) {
    final slot = circle.slots.firstWhere(
      (s) => s.slotNumber == slotNumber,
      orElse: () => GameyaSlot(slotNumber: slotNumber, payoutAmountMinor: payoutMinor, scheduledMonthName: 'Month $slotNumber'),
    );

    final isUser = slot.isCurrentUser;
    final label = isUser ? 'Slot #$slotNumber (YOU)' : (slot.assignedMemberName ?? 'Slot #$slotNumber');

    return GestureDetector(
      onTap: () => onSlotSelected?.call(slotNumber),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.emeraldGreen.withValues(alpha: 0.2)
              : (isUser ? AppColors.amberWarning.withValues(alpha: 0.15) : AppColors.cardSurface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.emeraldGreen
                : (isUser ? AppColors.amberWarning : AppColors.borderSubtle),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isUser ? AppColors.amberWarning : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: isUser ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMiddleFull)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.amberWarning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '100% MID',
                      style: TextStyle(color: AppColors.amberWarning, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            Text(
              isMiddleFull
                  ? '\$${(payoutMinor / 100).toStringAsFixed(0)} (100% Mid Payout)'
                  : '\$${(payoutMinor / 100).toStringAsFixed(0)} (50%)',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
