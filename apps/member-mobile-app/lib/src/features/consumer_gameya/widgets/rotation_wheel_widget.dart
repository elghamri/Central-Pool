import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';

/// Signature interactive Rotation Wheel Widget for the Game'ya Circle Room.
class RotationWheelWidget extends StatefulWidget {
  final GameyaCircle circle;
  final ValueChanged<GameyaSlot>? onSlotTapped;
  final GameyaSlot? selectedSlot;
  final double size;

  const RotationWheelWidget({
    super.key,
    required this.circle,
    this.onSlotTapped,
    this.selectedSlot,
    this.size = 320.0,
  });

  @override
  State<RotationWheelWidget> createState() => _RotationWheelWidgetState();
}

class _RotationWheelWidgetState extends State<RotationWheelWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedSize = widget.size.clamp(280.0, 420.0);
    final slots = widget.circle.slots;
    final totalSlots = slots.length;
    final isPaired = widget.circle.allocationMode == GameyaAllocationMode.symmetricalPaired;

    // Determine active pair for current selection or current period
    final activeFocusPeriod = widget.selectedSlot != null
        ? widget.circle.primaryPayoutPeriodFor(widget.selectedSlot!.slotNumber)
        : widget.circle.currentPeriod;
    final activePairSlots = isPaired
        ? widget.circle.activePayoutSlotsForPeriod(activeFocusPeriod)
        : [widget.selectedSlot?.slotNumber ?? widget.circle.currentPeriod];

    return Center(
      child: SizedBox(
        width: clampedSize,
        height: clampedSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Background Custom Paint for Track & Symmetrical Pairing Lines
            CustomPaint(
              size: Size(clampedSize, clampedSize),
              painter: _WheelTrackPainter(
                totalSlots: totalSlots,
                isPairedMode: isPaired,
                currentPeriod: widget.circle.currentPeriod,
                activePairSlots: activePairSlots,
              ),
            ),

            // 2. Center Hub Container
            _buildCenterHub(clampedSize * 0.44, activePairSlots, isPaired),

            // 3. Orbital Slot Nodes
            for (int i = 0; i < totalSlots; i++)
              _buildSlotNode(i, slots[i], totalSlots, clampedSize, activePairSlots, isPaired),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHub(double diameter, List<int> activePairSlots, bool isPaired) {
    final currentPeriod = widget.circle.currentPeriod;
    final totalPoolMinor = widget.circle.totalPoolMinor;
    final halfPayoutMinor = totalPoolMinor ~/ 2;

    String member1Label = 'Open';
    String member2Label = 'Open';
    bool isUserInActivePair = false;

    final isMidPeriod = isPaired && activePairSlots.length == 1;

    if (isMidPeriod) {
      final pMid = activePairSlots.first;
      final slotMatches = widget.circle.slots.where((s) => s.slotNumber == pMid);
      final s = slotMatches.isNotEmpty ? slotMatches.first : null;
      member1Label = s?.isCurrentUser == true
          ? 'You (100%)'
          : (s?.isClaimed == true ? '${s?.assignedMemberName?.split(" ").first} (100%)' : 'Open (100%)');
      isUserInActivePair = widget.circle.currentUserSlotPosition == pMid;
    } else if (isPaired && activePairSlots.length >= 2) {
      final p1 = activePairSlots.first;
      final p2 = activePairSlots.last;
      final slot1Matches = widget.circle.slots.where((s) => s.slotNumber == p1);
      final slot2Matches = widget.circle.slots.where((s) => s.slotNumber == p2);
      final s1 = slot1Matches.isNotEmpty ? slot1Matches.first : null;
      final s2 = slot2Matches.isNotEmpty ? slot2Matches.first : null;

      member1Label = s1?.isCurrentUser == true
          ? 'You (50%)'
          : (s1?.isClaimed == true ? '${s1?.assignedMemberName?.split(" ").first} (50%)' : 'Open (50%)');
      member2Label = s2?.isCurrentUser == true
          ? 'You (50%)'
          : (s2?.isClaimed == true ? '${s2?.assignedMemberName?.split(" ").first} (50%)' : 'Open (50%)');

      isUserInActivePair = widget.circle.currentUserSlotPosition != null &&
          activePairSlots.contains(widget.circle.currentUserSlotPosition);
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isUserInActivePair ? AppColors.emeraldGreen : AppColors.borderSubtle,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isUserInActivePair
                ? AppColors.emeraldGreen.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MONTH $currentPeriod OF ${widget.circle.totalPeriods}',
                style: TextStyle(
                  color: isUserInActivePair ? AppColors.emeraldGreen : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                isMidPeriod ? '100% Middle Pool Share' : (isPaired ? '50% Pool Share' : 'Turn Payout'),
                style: TextStyle(
                  color: isMidPeriod ? AppColors.amberWarning : AppColors.textSecondary,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              FinancialAmountText(
                amountMinor: (isPaired && !isMidPeriod) ? halfPayoutMinor : totalPoolMinor,
                style: TextStyle(
                  color: isMidPeriod ? AppColors.amberWarning : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isMidPeriod) ...[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.amberWarning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '1 Member • 100% Full Payout',
                    style: TextStyle(color: AppColors.amberWarning, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '#${activePairSlots.first} $member1Label',
                  style: TextStyle(
                    color: isUserInActivePair ? AppColors.amberWarning : AppColors.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else if (isPaired) ...[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '2 Members • 50% Each',
                    style: TextStyle(color: AppColors.emeraldGreen, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '#${activePairSlots.first} $member1Label ↔ #${activePairSlots.last} $member2Label',
                  style: TextStyle(
                    color: isUserInActivePair ? AppColors.emeraldGreen : AppColors.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                const SizedBox(height: 2),
                Text(
                  widget.circle.slots.firstWhere((s) => s.slotNumber == currentPeriod, orElse: () => widget.circle.slots.first).assignedMemberName ?? 'Open Slot',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotNode(
    int index,
    GameyaSlot slot,
    int totalSlots,
    double wheelSize,
    List<int> activePairSlots,
    bool isPaired,
  ) {
    final angle = (-math.pi / 2) + (index * 2 * math.pi / totalSlots);
    final radius = (wheelSize / 2) - 24.0;
    final centerX = (wheelSize / 2) + radius * math.cos(angle);
    final centerY = (wheelSize / 2) + radius * math.sin(angle);

    final isSelected = widget.selectedSlot?.slotNumber == slot.slotNumber;
    final isInActivePair = isPaired && activePairSlots.contains(slot.slotNumber);
    final isCurrentPeriod = slot.slotNumber == widget.circle.currentPeriod;
    final isMidSlot = isPaired && slot.pairedSlotNumber == null;

    Color nodeBorderColor = AppColors.borderSubtle;
    Color nodeBgColor = AppColors.surfaceElevated;
    Widget nodeContent;

    if (!slot.isClaimed) {
      nodeBorderColor = AppColors.amberWarning;
      nodeBgColor = AppColors.amberWarning.withValues(alpha: 0.15);
      nodeContent = const Icon(Icons.add, color: AppColors.amberWarning, size: 18);
    } else if (slot.isCurrentUser) {
      nodeBorderColor = isMidSlot ? AppColors.amberWarning : AppColors.emeraldGreen;
      nodeBgColor = (isMidSlot ? AppColors.amberWarning : AppColors.emeraldGreen).withValues(alpha: 0.25);
      nodeContent = Text(
        'YOU',
        style: TextStyle(
          color: isMidSlot ? AppColors.amberWarning : AppColors.emeraldGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      final initials = slot.assignedMemberName != null && slot.assignedMemberName!.isNotEmpty
          ? slot.assignedMemberName!.substring(0, math.min(2, slot.assignedMemberName!.length)).toUpperCase()
          : '#${slot.slotNumber}';

      if (slot.paymentStatus == SlotPaymentStatus.paid) {
        nodeBorderColor = AppColors.emeraldGreen;
      } else if (slot.paymentStatus == SlotPaymentStatus.pending) {
        nodeBorderColor = AppColors.amberWarning;
      }

      nodeContent = Text(
        initials,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
      );
    }

    return Positioned(
      left: centerX - 24,
      top: centerY - 24,
      child: GestureDetector(
        onTap: () => widget.onSlotTapped?.call(slot),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final shouldHighlight = isSelected || isInActivePair || isCurrentPeriod;
            final scale = shouldHighlight ? 1.0 + (_pulseController.value * 0.08) : 1.0;
            return Transform.scale(
              scale: scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: nodeBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: shouldHighlight ? (isInActivePair ? (isMidSlot ? AppColors.amberWarning : AppColors.emeraldGreen) : Colors.white) : nodeBorderColor,
                        width: shouldHighlight ? 2.5 : 1.5,
                      ),
                      boxShadow: shouldHighlight
                          ? [
                              BoxShadow(
                                color: (isInActivePair ? (isMidSlot ? AppColors.amberWarning : AppColors.emeraldGreen) : nodeBorderColor).withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Center(child: nodeContent),
                  ),
                  if (isPaired)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isInActivePair ? (isMidSlot ? AppColors.amberWarning : AppColors.emeraldGreen) : (isMidSlot ? AppColors.amberWarning.withValues(alpha: 0.5) : AppColors.borderSubtle),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isMidSlot ? '100%' : '50%',
                          style: TextStyle(
                            color: isMidSlot ? AppColors.amberWarning : AppColors.emeraldGreen,
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WheelTrackPainter extends CustomPainter {
  final int totalSlots;
  final bool isPairedMode;
  final int currentPeriod;
  final List<int> activePairSlots;

  _WheelTrackPainter({
    required this.totalSlots,
    required this.isPairedMode,
    required this.currentPeriod,
    this.activePairSlots = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 24.0;

    final trackPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, trackPaint);

    if (isPairedMode && totalSlots > 1) {
      final half = totalSlots ~/ 2;
      for (int k = 0; k < half; k++) {
        final slot1 = k + 1;
        final slot2 = totalSlots - k;
        final isActivePair = activePairSlots.contains(slot1) && activePairSlots.contains(slot2);

        final chordPaint = Paint()
          ..color = isActivePair
              ? AppColors.emeraldGreen
              : AppColors.emeraldGreen.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActivePair ? 2.5 : 1.0;

        final angle1 = (-math.pi / 2) + (k * 2 * math.pi / totalSlots);
        final angle2 = (-math.pi / 2) + ((totalSlots - 1 - k) * 2 * math.pi / totalSlots);

        final p1 = Offset(center.dx + radius * math.cos(angle1), center.dy + radius * math.sin(angle1));
        final p2 = Offset(center.dx + radius * math.cos(angle2), center.dy + radius * math.sin(angle2));

        canvas.drawLine(p1, p2, chordPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WheelTrackPainter oldDelegate) {
    return oldDelegate.totalSlots != totalSlots ||
        oldDelegate.isPairedMode != isPairedMode ||
        oldDelegate.currentPeriod != currentPeriod ||
        oldDelegate.activePairSlots != activePairSlots;
  }
}
