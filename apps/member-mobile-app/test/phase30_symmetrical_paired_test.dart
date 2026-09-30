import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';

void main() {
  group('Phase 30: Symmetrical Paired Payout & Financial Reality Suite', () {
    late GameyaCircle symmetricalCircle;
    late GameyaCircle sequentialCircle;

    setUp(() {
      // 10 Members, $500/month, $5,000 total pool per period
      final slotsPaired = List.generate(10, (i) {
        final pos = i + 1;
        final pairedPos = 10 + 1 - pos;
        return GameyaSlot(
          slotNumber: pos,
          assignedMemberId: 'usr-$pos',
          assignedMemberName: 'Member $pos',
          isCurrentUser: pos == 1,
          isClaimed: true,
          paymentStatus: SlotPaymentStatus.scheduled,
          payoutAmountMinor: 250000, // $2,500.00 (50% of $5,000 pool)
          scheduledMonthName: 'Month $pos',
          pairedSlotNumber: pairedPos,
        );
      });

      symmetricalCircle = GameyaCircle(
        id: 'CIRCLE-SYM-10',
        name: 'Symmetrical Savings Circle 2026',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000, // $500.00
        totalPeriods: 10,
        currentPeriod: 1,
        totalPoolMinor: 500000, // $5,000.00
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        status: GameyaCircleStatus.active,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Member 1',
        currentUserSlotPosition: 1,
        slots: slotsPaired,
      );

      final slotsSeq = List.generate(10, (i) {
        final pos = i + 1;
        return GameyaSlot(
          slotNumber: pos,
          assignedMemberId: 'usr-$pos',
          assignedMemberName: 'Member $pos',
          isCurrentUser: pos == 1,
          isClaimed: true,
          paymentStatus: SlotPaymentStatus.scheduled,
          payoutAmountMinor: 500000, // $5,000.00 (100% of pool)
          scheduledMonthName: 'Month $pos',
        );
      });

      sequentialCircle = GameyaCircle(
        id: 'CIRCLE-SEQ-10',
        name: 'Sequential Savings Circle 2026',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000, // $500.00
        totalPeriods: 10,
        currentPeriod: 1,
        totalPoolMinor: 500000, // $5,000.00
        allocationMode: GameyaAllocationMode.sequential,
        status: GameyaCircleStatus.active,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Member 1',
        currentUserSlotPosition: 1,
        slots: slotsSeq,
      );
    });

    test('Test 1: Position #1 receives 50% in Period 1 (\$2,500) and 50% in Period 10 (\$2,500)', () {
      expect(symmetricalCircle.isPayoutDueForSlotInPeriod(1, 1), isTrue);
      expect(symmetricalCircle.payoutAmountForSlotInPeriod(1, 1), equals(250000)); // $2,500.00

      expect(symmetricalCircle.isPayoutDueForSlotInPeriod(1, 10), isTrue);
      expect(symmetricalCircle.payoutAmountForSlotInPeriod(1, 10), equals(250000)); // $2,500.00

      for (int p = 2; p <= 9; p++) {
        expect(symmetricalCircle.isPayoutDueForSlotInPeriod(1, p), isFalse);
      }

      final totalReceived = symmetricalCircle.payoutAmountForSlotInPeriod(1, 1) +
          symmetricalCircle.payoutAmountForSlotInPeriod(1, 10);
      expect(totalReceived, equals(500000)); // $5,000.00 total entitlement
    });

    test('Test 2: Position #10 (Paired Partner) receives 50% in Period 1 (\$2,500) and 50% in Period 10 (\$2,500)', () {
      expect(symmetricalCircle.isPayoutDueForSlotInPeriod(10, 1), isTrue);
      expect(symmetricalCircle.payoutAmountForSlotInPeriod(10, 1), equals(250000));

      expect(symmetricalCircle.isPayoutDueForSlotInPeriod(10, 10), isTrue);
      expect(symmetricalCircle.payoutAmountForSlotInPeriod(10, 10), equals(250000));

      for (int p = 2; p <= 9; p++) {
        expect(symmetricalCircle.isPayoutDueForSlotInPeriod(10, p), isFalse);
      }

      final totalReceived = symmetricalCircle.payoutAmountForSlotInPeriod(10, 1) +
          symmetricalCircle.payoutAmountForSlotInPeriod(10, 10);
      expect(totalReceived, equals(500000));
    });

    test('Test 3: All Five Pairs receive exact 50/50 disbursements in their respective periods', () {
      final expectedPairs = [
        {'pair': [1, 10], 'periods': [1, 10]},
        {'pair': [2, 9], 'periods': [2, 9]},
        {'pair': [3, 8], 'periods': [3, 8]},
        {'pair': [4, 7], 'periods': [4, 7]},
        {'pair': [5, 6], 'periods': [5, 6]},
      ];

      for (final item in expectedPairs) {
        final pair = item['pair'] as List<int>;
        final periods = item['periods'] as List<int>;

        for (final slotNum in pair) {
          for (final period in periods) {
            expect(symmetricalCircle.isPayoutDueForSlotInPeriod(slotNum, period), isTrue,
                reason: 'Slot $slotNum must be active in Period $period');
            expect(symmetricalCircle.payoutAmountForSlotInPeriod(slotNum, period), equals(250000));
          }
        }
      }
    });

    test('Test 4: Period Pool Integrity — Every period disburses exactly \$5,000 across the two paired slots', () {
      for (int p = 1; p <= 10; p++) {
        final activeSlots = symmetricalCircle.activePayoutSlotsForPeriod(p);
        expect(activeSlots.length, equals(2));

        int periodDisbursedMinor = 0;
        for (final slotNum in activeSlots) {
          periodDisbursedMinor += symmetricalCircle.payoutAmountForSlotInPeriod(slotNum, p);
        }

        expect(periodDisbursedMinor, equals(500000), // $5,000.00
            reason: 'Period $p must disburse exactly \$5,000.00');
      }
    });

    test('Test 5: Full Circle Zero-Sum Reconciliation — Total Contributions = \$50,000, Total Payouts = \$50,000, Residual = \$0.00', () {
      int totalContributionsMinor = 0;
      int totalPayoutsMinor = 0;

      for (int p = 1; p <= 10; p++) {
        // 10 members contribute $500 each per period
        totalContributionsMinor += 10 * symmetricalCircle.monthlyContributionMinor;

        // 2 paired slots receive $2,500 each per period
        final activeSlots = symmetricalCircle.activePayoutSlotsForPeriod(p);
        for (final slotNum in activeSlots) {
          totalPayoutsMinor += symmetricalCircle.payoutAmountForSlotInPeriod(slotNum, p);
        }
      }

      expect(totalContributionsMinor, equals(5000000)); // $50,000.00
      expect(totalPayoutsMinor, equals(5000000)); // $50,000.00
      expect(totalContributionsMinor - totalPayoutsMinor, equals(0)); // $0.00 residual
    });

    test('Test 6: Sequential Mode Regression — Linear mode preserves single full pool payout per period', () {
      for (int pos = 1; pos <= 10; pos++) {
        expect(sequentialCircle.isPayoutDueForSlotInPeriod(pos, pos), isTrue);
        expect(sequentialCircle.payoutAmountForSlotInPeriod(pos, pos), equals(500000)); // Full $5,000.00

        for (int otherP = 1; otherP <= 10; otherP++) {
          if (otherP != pos) {
            expect(sequentialCircle.isPayoutDueForSlotInPeriod(pos, otherP), isFalse);
          }
        }
      }
    });

    test('Test 7: Economic Status Calculation — Dynamic cash-flow position based on payouts received vs contributions paid', () {
      // Slot 1 (Paired with Slot 10):
      // Month 1: Contributed $500, Received $2,500 -> Repaying advance
      final circleM1 = symmetricalCircle.copyWith(currentPeriod: 1, currentUserSlotPosition: 1);
      expect(circleM1.currentUserEconomicPosition, equals(EconomicPositionType.repayingAdvancePayout));

      // Month 5: Contributed $2,500, Received $2,500 -> Balanced / Accumulating savings toward Month 10
      final circleM5 = symmetricalCircle.copyWith(currentPeriod: 5, currentUserSlotPosition: 1);
      expect(circleM5.currentUserEconomicPosition, equals(EconomicPositionType.accumulatingSavings));

      // Month 9: Contributed $4,500, Received $2,500 -> Accumulating savings toward Month 10
      final circleM9 = symmetricalCircle.copyWith(currentPeriod: 9, currentUserSlotPosition: 1);
      expect(circleM9.currentUserEconomicPosition, equals(EconomicPositionType.accumulatingSavings));
    });

    test('Test 8: Controller integration — Claiming payout in paired mode registers correct 50% amount', () async {
      final controller = GameyaController(autoLoad: false);
      final state = controller.value as GameyaLoaded;
      final carCircle = state.hubSummary.activeCircles.firstWhere((c) => c.id == 'CIRCLE-CAR-2027').copyWith(currentPeriod: 9);
      controller.value = state.copyWith(
        hubSummary: ConsumerHubSummary(
          memberName: state.hubSummary.memberName,
          activeCircles: state.hubSummary.activeCircles.map((c) => c.id == 'CIRCLE-CAR-2027' ? carCircle : c).toList(),
          totalMonthlyDuesMinor: state.hubSummary.totalMonthlyDuesMinor,
        ),
      );

      final claimSuccess = await controller.claimPayoutDisbursement(
        circleId: 'CIRCLE-CAR-2027',
        amountMinor: 500000, // $5,000.00 (50% of $10,000 pool in Car Fund)
        destinationAccount: 'Chase Checking (**** 8812)',
      );
      expect(claimSuccess, isTrue);

      final updatedState = controller.value as GameyaLoaded;
      final timelineItem = updatedState.activityTimeline.first;
      expect(timelineItem.eventType, equals(ActivityEventType.payoutReceived));
      expect(timelineItem.amountMinor, equals(500000));
      expect(timelineItem.isDebit, isFalse);
    });
  });
}
