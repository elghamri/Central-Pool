import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';

/// Social peer tile rendering a member's slot, payment status chip, and trust rating.
class PeerRosterTile extends StatelessWidget {
  final GameyaSlot slot;
  final VoidCallback? onTap;
  final bool isPairedMode;
  final bool isRtl;

  const PeerRosterTile({
    super.key,
    required this.slot,
    this.onTap,
    this.isPairedMode = false,
    this.isRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = slot.isCurrentUser;
    final isClaimed = slot.isClaimed;
    final pairedSlotNum = slot.pairedSlotNumber;

    StatusBadgeType badgeType;

    switch (slot.paymentStatus) {
      case SlotPaymentStatus.paid:
        badgeType = StatusBadgeType.success;
        break;
      case SlotPaymentStatus.pending:
        badgeType = StatusBadgeType.warning;
        break;
      case SlotPaymentStatus.gracePeriod:
        badgeType = StatusBadgeType.error;
        break;
      case SlotPaymentStatus.scheduled:
        badgeType = StatusBadgeType.neutral;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isUser ? AppColors.emeraldGreen.withValues(alpha: 0.12) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser ? AppColors.emeraldGreen.withValues(alpha: 0.4) : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar Circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isUser ? AppColors.emeraldGreen.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUser ? AppColors.emeraldGreen : AppColors.borderSubtle,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isClaimed
                    ? Text(
                        isUser
                            ? 'YOU'
                            : (slot.assignedMemberName?.isNotEmpty == true
                                ? slot.assignedMemberName!.substring(0, 1).toUpperCase()
                                : '#${slot.slotNumber}'),
                        style: TextStyle(
                          color: isUser ? AppColors.emeraldGreen : AppColors.textPrimary,
                          fontSize: isUser ? 10 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Icon(Icons.add, color: AppColors.amberWarning, size: 16),
              ),
            ),
            const SizedBox(width: 12),

            // Member Info & Slot
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isClaimed
                              ? (isUser
                                  ? (isRtl ? 'أنت (${slot.assignedMemberName})' : 'You (${slot.assignedMemberName})')
                                  : slot.assignedMemberName ?? (isRtl ? 'عضو #${slot.slotNumber}' : 'Member #${slot.slotNumber}'))
                              : (isRtl ? 'دور شاغر' : 'Open Slot'),
                          style: TextStyle(
                            color: isClaimed ? AppColors.textPrimary : AppColors.amberWarning,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      if (isPairedMode) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: pairedSlotNum != null
                                ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                                : AppColors.amberWarning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: pairedSlotNum != null
                                  ? AppColors.emeraldGreen.withValues(alpha: 0.4)
                                  : AppColors.amberWarning.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            pairedSlotNum != null
                                ? (isRtl ? '٥٠٪' : '50%')
                                : (isRtl ? '١٠٠٪ أوسط' : '100% Mid'),
                            style: TextStyle(
                              color: pairedSlotNum != null ? AppColors.emeraldGreen : AppColors.amberWarning,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (isPairedMode && pairedSlotNum != null)
                        ? (isRtl
                            ? 'شهر ${slot.slotNumber} ↔ شهر $pairedSlotNum • دور #${slot.slotNumber} (EGP ${(slot.payoutAmountMinor ~/ 100)})'
                            : 'Month ${slot.slotNumber} ↔ Month $pairedSlotNum • Slot #${slot.slotNumber} (EGP ${(slot.payoutAmountMinor ~/ 100)})')
                        : (isPairedMode && pairedSlotNum == null)
                            ? (isRtl
                                ? '${slot.scheduledMonthName} (قبض أوسط كامل ١٠٠٪) • دور #${slot.slotNumber} (EGP ${(slot.payoutAmountMinor ~/ 100)})'
                                : '${slot.scheduledMonthName} (100% Mid Payout) • Slot #${slot.slotNumber} (EGP ${(slot.payoutAmountMinor ~/ 100)})')
                            : '${slot.scheduledMonthName} • Slot #${slot.slotNumber}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Status Badge
            if (isClaimed)
              StatusBadge(
                label: slot.paymentStatus.label,
                type: badgeType,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.amberWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.5)),
                ),
                child: Text(
                  isRtl ? 'احجز الدور' : 'Claim Slot',
                  style: const TextStyle(color: AppColors.amberWarning, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
