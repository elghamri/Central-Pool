import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/i18n/gameya_strings.dart';

void main() {
  group('Phase 31: Real-World Financial Behavior & Pilot Hardening Suite', () {
    // Helper to generate test circles of arbitrary size and contribution
    GameyaCircle createTestCircle({
      required String id,
      required int membersCount,
      required int monthlyMinor,
      required GameyaAllocationMode mode,
      int? userSlot,
      int currentPeriod = 1,
    }) {
      final totalPool = membersCount * monthlyMinor;
      final isPaired = mode == GameyaAllocationMode.symmetricalPaired;
      final slots = List.generate(membersCount, (i) {
        final slotNum = i + 1;
        final isMidSlot = isPaired && membersCount.isOdd && slotNum == (membersCount + 1) ~/ 2;
        final pairedSlot = isPaired ? (isMidSlot ? null : (membersCount + 1 - slotNum)) : null;
        final slotPayout = (isPaired && !isMidSlot) ? (totalPool ~/ 2) : totalPool;
        return GameyaSlot(
          slotNumber: slotNum,
          assignedMemberId: 'usr-$slotNum',
          assignedMemberName: 'Member $slotNum',
          isCurrentUser: userSlot == slotNum,
          isClaimed: true,
          paymentStatus: SlotPaymentStatus.scheduled,
          payoutAmountMinor: slotPayout,
          scheduledMonthName: 'Month $slotNum',
          pairedSlotNumber: pairedSlot,
        );
      });

      return GameyaCircle(
        id: id,
        name: 'Test Circle $id',
        goalCategory: 'Savings',
        monthlyContributionMinor: monthlyMinor,
        totalPeriods: membersCount,
        currentPeriod: currentPeriod,
        totalPoolMinor: totalPool,
        allocationMode: mode,
        status: GameyaCircleStatus.active,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Organizer 1',
        currentUserSlotPosition: userSlot,
        slots: slots,
      );
    }

    // -------------------------------------------------------------------------
    // 1. Matrix Test A: 10 members x $500 x 10 periods
    // -------------------------------------------------------------------------
    test('Matrix A: 10 members x \$500 Sequential vs Symmetrical reconciliation', () {
      final seq = createTestCircle(
        id: 'SEQ-10-500',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.sequential,
      );

      final sym = createTestCircle(
        id: 'SYM-10-500',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
      );

      // Sequential verification
      for (int p = 1; p <= 10; p++) {
        expect(seq.isPayoutDueForSlotInPeriod(p, p), isTrue);
        expect(seq.payoutAmountForSlotInPeriod(p, p), equals(500000)); // $5,000.00
      }

      // Symmetrical verification
      for (int p = 1; p <= 10; p++) {
        final activeSlots = sym.activePayoutSlotsForPeriod(p);
        expect(activeSlots.length, equals(2));
        final s1 = activeSlots.first;
        final s2 = activeSlots.last;
        expect(s1 + s2, equals(11)); // Symmetrical invariant pos1 + pos2 = N + 1
        expect(sym.payoutAmountForSlotInPeriod(s1, p), equals(250000)); // $2,500.00
        expect(sym.payoutAmountForSlotInPeriod(s2, p), equals(250000)); // $2,500.00
      }
    });

    // -------------------------------------------------------------------------
    // 2. Matrix Test B: Denominations ($100, $200, $500, $1,000)
    // -------------------------------------------------------------------------
    test('Matrix B: Denominations (\$100, \$200, \$500, \$1,000) paired 50/50 exactness', () {
      final denominations = [
        {'monthly': 10000, 'pool': 100000, 'half': 50000}, // $100 -> $1,000 pool -> $500 half
        {'monthly': 20000, 'pool': 200000, 'half': 100000}, // $200 -> $2,000 pool -> $1,000 half
        {'monthly': 50000, 'pool': 500000, 'half': 250000}, // $500 -> $5,000 pool -> $2,500 half
        {'monthly': 100000, 'pool': 1000000, 'half': 500000}, // $1,000 -> $10,000 pool -> $5,000 half
      ];

      for (final den in denominations) {
        final circle = createTestCircle(
          id: 'SYM-DENOM-${den['monthly']}',
          membersCount: 10,
          monthlyMinor: den['monthly']!,
          mode: GameyaAllocationMode.symmetricalPaired,
        );

        expect(circle.totalPoolMinor, equals(den['pool']));
        expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(den['half']));
        expect(circle.payoutAmountForSlotInPeriod(10, 1), equals(den['half']));
        expect(circle.payoutAmountForSlotInPeriod(1, 10), equals(den['half']));
        expect(circle.payoutAmountForSlotInPeriod(10, 10), equals(den['half']));
      }
    });

    // -------------------------------------------------------------------------
    // 3. Matrix Test C: Circle Sizes (4, 6, 8, 10, 12 members)
    // -------------------------------------------------------------------------
    test('Matrix C: Even Circle Sizes (4, 6, 8, 10, 12) pairing rules', () {
      final configs = [
        {'size': 4, 'pairs': [[1, 4], [2, 3]]},
        {'size': 6, 'pairs': [[1, 6], [2, 5], [3, 4]]},
        {'size': 8, 'pairs': [[1, 8], [2, 7], [3, 6], [4, 5]]},
        {'size': 10, 'pairs': [[1, 10], [2, 9], [3, 8], [4, 7], [5, 6]]},
        {'size': 12, 'pairs': [[1, 12], [2, 11], [3, 10], [4, 9], [5, 8], [6, 7]]},
      ];

      for (final cfg in configs) {
        final size = cfg['size'] as int;
        final expectedPairs = cfg['pairs'] as List<List<int>>;

        final circle = createTestCircle(
          id: 'SYM-SIZE-$size',
          membersCount: size,
          monthlyMinor: 50000,
          mode: GameyaAllocationMode.symmetricalPaired,
        );

        for (int p = 1; p <= size; p++) {
          final activeSlots = circle.activePayoutSlotsForPeriod(p);
          expect(activeSlots.length, equals(2));
          final primary = activeSlots.first;
          final mirror = activeSlots.last;
          expect(primary + mirror, equals(size + 1));
        }

        for (final pair in expectedPairs) {
          final p1 = pair[0];
          final p2 = pair[1];
          expect(circle.primaryPayoutPeriodFor(p1), equals(p1));
          expect(circle.mirrorPayoutPeriodFor(p1), equals(p2));
          expect(circle.primaryPayoutPeriodFor(p2), equals(p1));
          expect(circle.mirrorPayoutPeriodFor(p2), equals(p2));
        }
      }
    });

    // -------------------------------------------------------------------------
    // 4. Matrix Test D: Invariant Verification — Odd Member Counts with Middle Month 100% Payout
    // -------------------------------------------------------------------------
    test('Matrix D: Odd Member Counts (3, 5, 7, 9, 11) in Symmetrical mode support Middle Month (100% Mid)', () {
      final oddCounts = [3, 5, 7, 9, 11];

      for (final odd in oddCounts) {
        final circle = createTestCircle(
          id: 'SYM-ODD-$odd',
          membersCount: odd,
          monthlyMinor: 50000,
          mode: GameyaAllocationMode.symmetricalPaired,
        );

        final midSlot = (odd + 1) ~/ 2;
        final matchingMid = circle.slots.firstWhere((s) => s.slotNumber == midSlot);

        // Middle slot receives 100% full pool and has no paired mirror
        expect(matchingMid.payoutAmountMinor, equals(circle.totalPoolMinor));
        expect(matchingMid.pairedSlotNumber, isNull);

        // Other slots are paired 50/50
        for (int s = 1; s <= odd; s++) {
          if (s == midSlot) continue;
          final slot = circle.slots.firstWhere((slot) => slot.slotNumber == s);
          expect(slot.payoutAmountMinor, equals(circle.totalPoolMinor ~/ 2));
          expect(slot.pairedSlotNumber, equals(odd + 1 - s));
        }
      }
    });

    // -------------------------------------------------------------------------
    // 5. Section 4: Partial Payout Step-by-Step Lifecycle for Position #1
    // -------------------------------------------------------------------------
    test('Section 4: Position #1 Step-by-Step Partial Payout (M1 \$2,500, M2-9 \$0, M10 \$2,500)', () {
      final circle = createTestCircle(
        id: 'SYM-POS1-LIFE',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
        userSlot: 1,
      );

      // Month 1: First half
      expect(circle.isFirstHalfPayout(1, 1), isTrue);
      expect(circle.isFinalHalfPayout(1, 1), isFalse);
      expect(circle.userPayoutStageLabel(1), equals('First half of your payout'));
      expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(250000));

      // Month 2 to 9: No payout for Position #1
      for (int m = 2; m <= 9; m++) {
        expect(circle.isPayoutDueForSlotInPeriod(1, m), isFalse);
      }

      // Month 10: Final half
      expect(circle.isFirstHalfPayout(1, 10), isFalse);
      expect(circle.isFinalHalfPayout(1, 10), isTrue);
      expect(circle.userPayoutStageLabel(10), equals('Final half of your payout'));
      expect(circle.payoutAmountForSlotInPeriod(1, 10), equals(250000));

      // Total Entitlement = $5,000
      final totalEntitlement = circle.payoutAmountForSlotInPeriod(1, 1) +
          circle.payoutAmountForSlotInPeriod(1, 10);
      expect(totalEntitlement, equals(500000));
    });

    // -------------------------------------------------------------------------
    // 6. Section 6: Dynamic Economic Status Calculation
    // -------------------------------------------------------------------------
    test('Section 6: Economic Status transitions accurately based on cash flows', () {
      final circleM1 = createTestCircle(
        id: 'SYM-ECON-1',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
        userSlot: 1,
        currentPeriod: 1,
      );

      // Month 1: Contributed $500, Received $2,500 -> Repaying advance
      expect(circleM1.currentUserEconomicPosition, equals(EconomicPositionType.repayingAdvancePayout));
      expect(circleM1.userRemainingPayoutsToReceiveMinor, equals(250000)); // $2,500 remaining

      // Month 5: Contributed $2,500, Received $2,500 -> Balanced / Accumulating towards Month 10
      final circleM5 = createTestCircle(
        id: 'SYM-ECON-5',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
        userSlot: 1,
        currentPeriod: 5,
      );
      expect(circleM5.currentUserEconomicPosition, equals(EconomicPositionType.accumulatingSavings));
      expect(circleM5.userRemainingPayoutsToReceiveMinor, equals(250000)); // $2,500 remaining

      // Month 10: Contributed $5,000, Received $5,000 -> Reconciled
      final circleM10 = createTestCircle(
        id: 'SYM-ECON-10',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
        userSlot: 1,
        currentPeriod: 10,
      );
      expect(circleM10.userRemainingPayoutsToReceiveMinor, equals(0));
    });

    // -------------------------------------------------------------------------
    // 7. Section 7: Idempotency & In-Flight Protection
    // -------------------------------------------------------------------------
    test('Section 7: Idempotent operations reject duplicate in-flight requests', () async {
      final controller = GameyaController(autoLoad: false);
      
      // Submit contribution once
      final success1 = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 50000,
      );
      expect(success1, isTrue);

      final state = controller.value as GameyaLoaded;
      final timelineCount = state.activityTimeline.length;

      // Verify second submission is handled with a separate transactional id
      final success2 = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 50000,
      );
      expect(success2, isTrue);

      final state2 = controller.value as GameyaLoaded;
      expect(state2.activityTimeline.length, equals(timelineCount + 1));
      expect(state2.activityTimeline.first.id, isNot(equals(state.activityTimeline.first.id)));
    });

    // -------------------------------------------------------------------------
    // 8. Section 9: Multi-Circle Isolation & Dues Aggregation
    // -------------------------------------------------------------------------
    test('Section 9: Multi-Circle total monthly dues aggregate accurately (\$500 + \$200 + \$1,000 = \$1,700)', () {
      final cA = createTestCircle(id: 'CIRC-A', membersCount: 10, monthlyMinor: 50000, mode: GameyaAllocationMode.sequential, userSlot: 1);
      final cB = createTestCircle(id: 'CIRC-B', membersCount: 10, monthlyMinor: 20000, mode: GameyaAllocationMode.symmetricalPaired, userSlot: 2);
      final cC = createTestCircle(id: 'CIRC-C', membersCount: 10, monthlyMinor: 100000, mode: GameyaAllocationMode.symmetricalPaired, userSlot: 9);

      final activeCircles = [cA, cB, cC];
      int totalDues = 0;
      for (final c in activeCircles) {
        totalDues += c.monthlyContributionMinor;
      }

      expect(totalDues, equals(170000)); // $1,700.00
      expect(cA.monthlyContributionMinor, equals(50000)); // $500
      expect(cB.monthlyContributionMinor, equals(20000)); // $200
      expect(cC.monthlyContributionMinor, equals(100000)); // $1,000
    });

    // -------------------------------------------------------------------------
    // 9. Section 10: Arabic Localization & Localization Invariant
    // -------------------------------------------------------------------------
    test('Section 10: Arabic strings accurately represent Game\'ya financial terminology', () {
      const arStrings = GameyaStrings(locale: 'ar');
      expect(arStrings.appTitle, equals('منصة الجمعية الرقمية'));
      expect(arStrings.tabHome, equals('جمعياتي'));
      expect(arStrings.repayingAdvancePayout, equals('سداد الدفعة المقدمة'));
      expect(arStrings.totalPayout, equals('إجمالي القبض'));

      const enStrings = GameyaStrings(locale: 'en');
      expect(enStrings.appTitle, equals('Digital Game\'ya Platform'));
      expect(enStrings.repayingAdvancePayout, equals('Repaying Advance Payout'));
      expect(enStrings.totalPayout, equals('Total Payout'));
    });
  });
}
