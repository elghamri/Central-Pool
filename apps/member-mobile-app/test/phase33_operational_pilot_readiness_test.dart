import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/i18n/gameya_strings.dart';

void main() {
  group('Phase 33: Controlled Real-World Pilot Deployment & Operational Readiness', () {
    // Helper to generate canonical pilot circles
    GameyaCircle createPilotCircle({
      required String id,
      required String name,
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
        final pairedSlot = isPaired ? (membersCount + 1 - slotNum) : null;
        final slotPayout = isPaired ? (totalPool ~/ 2) : totalPool;
        return GameyaSlot(
          slotNumber: slotNum,
          assignedMemberId: 'pilot-usr-$slotNum',
          assignedMemberName: 'Pilot Member $slotNum',
          isCurrentUser: userSlot == slotNum,
          isClaimed: true,
          paymentStatus: slotNum < currentPeriod ? SlotPaymentStatus.paid : SlotPaymentStatus.scheduled,
          payoutAmountMinor: slotPayout,
          scheduledMonthName: 'Month $slotNum',
          pairedSlotNumber: pairedSlot,
        );
      });

      return GameyaCircle(
        id: id,
        name: name,
        goalCategory: 'Community Savings',
        monthlyContributionMinor: monthlyMinor,
        totalPeriods: membersCount,
        currentPeriod: currentPeriod,
        totalPoolMinor: totalPool,
        allocationMode: mode,
        status: GameyaCircleStatus.active,
        startDate: DateTime(2026, 9, 1),
        organizerName: 'Pilot Organizer',
        currentUserSlotPosition: userSlot,
        slots: slots,
      );
    }

    // =========================================================================
    // 1. WORKSTREAM 1 & 2: PILOT ENVIRONMENT & REALISTIC SEED DATA
    // =========================================================================
    test('WS 1 & 2: Canonical Pilot Seed Data validates all denominations (\$200, \$500, \$1,000)', () {
      final pilotCircles = [
        createPilotCircle(
          id: 'PILOT-CIRC-200',
          name: 'Starter Savings 2026',
          membersCount: 10,
          monthlyMinor: 20000, // $200
          mode: GameyaAllocationMode.sequential,
        ),
        createPilotCircle(
          id: 'PILOT-CIRC-500',
          name: 'Home Appliance Fund',
          membersCount: 10,
          monthlyMinor: 50000, // $500
          mode: GameyaAllocationMode.symmetricalPaired,
        ),
        createPilotCircle(
          id: 'PILOT-CIRC-1000',
          name: 'Executive Capital Circle',
          membersCount: 10,
          monthlyMinor: 100000, // $1,000
          mode: GameyaAllocationMode.symmetricalPaired,
        ),
      ];

      expect(pilotCircles[0].totalPoolMinor, equals(200000)); // $2,000 pool
      expect(pilotCircles[1].totalPoolMinor, equals(500000)); // $5,000 pool
      expect(pilotCircles[2].totalPoolMinor, equals(1000000)); // $10,000 pool

      // Check Symmetrical Paired split amounts
      expect(pilotCircles[1].payoutAmountForSlotInPeriod(1, 1), equals(250000)); // $2,500
      expect(pilotCircles[1].payoutAmountForSlotInPeriod(10, 1), equals(250000)); // $2,500
      expect(pilotCircles[2].payoutAmountForSlotInPeriod(1, 1), equals(500000)); // $5,000
      expect(pilotCircles[2].payoutAmountForSlotInPeriod(10, 1), equals(500000)); // $5,000
    });

    // =========================================================================
    // 2. WORKSTREAM 3: END-TO-END HUMAN USER PILOT JOURNEY
    // =========================================================================
    test('WS 3: Full Human Pilot Journey (Join -> Lock -> Pay -> Claim Payout -> Settle)', () async {
      final controller = GameyaController(autoLoad: false);

      // 1. Discovery and Join Slot 1 in $500 Symmetrical Circle
      final openSlot1 = GameyaSlot.open(slotNumber: 1, payoutAmountMinor: 250000, scheduledMonthName: 'Month 1', pairedSlotNumber: 10);
      final formingCircle = GameyaCircle(
        id: 'PILOT-JOURNEY-01',
        name: 'Alexandria Family Circle',
        goalCategory: 'Family Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 10,
        currentPeriod: 1,
        totalPoolMinor: 500000,
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        status: GameyaCircleStatus.forming,
        startDate: DateTime(2026, 9, 1),
        organizerName: 'Mona Zaki',
        slots: [
          openSlot1,
          ...List.generate(9, (i) => GameyaSlot(
            slotNumber: i + 2,
            assignedMemberId: 'pilot-usr-${i + 2}',
            assignedMemberName: 'Pilot Member ${i + 2}',
            isClaimed: true,
            paymentStatus: SlotPaymentStatus.scheduled,
            payoutAmountMinor: 250000,
            scheduledMonthName: 'Month ${i + 2}',
            pairedSlotNumber: 10 - i,
          )),
        ],
      );

      final state = controller.value as GameyaLoaded;
      controller.value = state.copyWith(marketplaceCircles: [formingCircle]);

      final joinResult = await controller.joinCircleWithSlot(circleId: formingCircle.id, slotNumber: 1);
      expect(joinResult, isTrue);

      // 2. Make Month 1 Contribution
      final payResult = await controller.submitContributionPayment(
        circleId: formingCircle.id,
        amountMinor: 50000,
        idempotencyKey: 'PILOT-TX-PAY-M1',
      );
      expect(payResult, isTrue);

      // 3. Claim Month 1 Paired Payout ($2,500.00)
      final claimResult = await controller.claimPayoutDisbursement(
        circleId: formingCircle.id,
        amountMinor: 250000,
        destinationAccount: 'CIB Bank (**** 4421)',
      );
      expect(claimResult, isTrue);

      // 4. Verify Activity Timeline recorded both events
      final updatedState = controller.value as GameyaLoaded;
      expect(updatedState.activityTimeline.any((t) => t.id == 'PILOT-TX-PAY-M1'), isTrue);
      expect(updatedState.activityTimeline.any((t) => t.eventType == ActivityEventType.payoutReceived), isTrue);
    });

    // =========================================================================
    // 3. WORKSTREAM 4: SYMMETRICAL PAIRED TRUTH (50/50 Multi-Period Verification)
    // =========================================================================
    test('WS 4: Symmetrical Paired 50/50 Verification (Position 1 gets \$2,500 in M1 and \$2,500 in M10)', () {
      final circle = createPilotCircle(
        id: 'PILOT-SYM-TRUTH',
        name: 'Paired Truth Circle',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
        userSlot: 1,
        currentPeriod: 1,
      );

      // Month 1 Payout
      expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(250000)); // $2,500.00
      expect(circle.isFirstHalfPayout(1, 1), isTrue);
      expect(circle.isFinalHalfPayout(1, 1), isFalse);

      // Month 10 Payout
      final circleM10 = circle.copyWith(currentPeriod: 10);
      expect(circleM10.payoutAmountForSlotInPeriod(1, 10), equals(250000)); // $2,500.00
      expect(circleM10.isFirstHalfPayout(1, 10), isFalse);
      expect(circleM10.isFinalHalfPayout(1, 10), isTrue);

      // Total lifetime received = $5,000.00
      final totalLifetime = circle.payoutAmountForSlotInPeriod(1, 1) + circleM10.payoutAmountForSlotInPeriod(1, 10);
      expect(totalLifetime, equals(500000));
    });

    // =========================================================================
    // 4. WORKSTREAM 5: PAYMENT FAILURE & RETRY RESILIENCY
    // =========================================================================
    test('WS 5: Controlled Payment Rejection & Safe Recovery', () async {
      final controller = GameyaController(autoLoad: false);

      // Negative amount rejected
      final failNeg = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: -100,
      );
      expect(failNeg, isFalse);

      // Retry with valid amount succeeds
      final retrySuccess = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 50000,
        idempotencyKey: 'RETRY-KEY-001',
      );
      expect(retrySuccess, isTrue);

      // Second replay with same idempotency key is deduplicated safely
      final replayDedupe = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 50000,
        idempotencyKey: 'RETRY-KEY-001',
      );
      expect(replayDedupe, isTrue);
    });

    // =========================================================================
    // 5. WORKSTREAM 10 & 11: SECURITY & HUMAN USABILITY AUDIT
    // =========================================================================
    test('WS 10 & 11: Security role boundary & clear economic terminology', () {
      final circle = createPilotCircle(
        id: 'PILOT-SEC-01',
        name: 'Security Test Circle',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
        userSlot: 2,
        currentPeriod: 1, // User is slot 2, current period is 1
      );

      // User slot 2 cannot claim payout in period 1
      expect(circle.isPayoutDueForUserInPeriod(1), isFalse);

      // Strings in English & Arabic communicate transparent rotating savings
      expect(GameyaStrings.en.repayingAdvancePayout, equals('Repaying Advance Payout'));
      expect(GameyaStrings.en.accumulatingSavings, equals('Accumulating Savings'));
      expect(GameyaStrings.ar.repayingAdvancePayout, equals('سداد الدفعة المقدمة'));
      expect(GameyaStrings.ar.accumulatingSavings, equals('ادخار تراكمي'));
    });
  });
}
