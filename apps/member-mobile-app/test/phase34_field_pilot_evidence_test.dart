import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';

void main() {
  group('Phase 34: Controlled Field Pilot Execution & Live User Evidence Suite', () {
    // Helper to generate verified pilot cohort circles
    GameyaCircle createFieldPilotCircle({
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
          assignedMemberId: 'PILOT-USR-${(i + 1).toString().padLeft(2, '0')}',
          assignedMemberName: 'Pilot Participant ${i + 1}',
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
        goalCategory: 'Field Pilot',
        monthlyContributionMinor: monthlyMinor,
        totalPeriods: membersCount,
        currentPeriod: currentPeriod,
        totalPoolMinor: totalPool,
        allocationMode: mode,
        status: GameyaCircleStatus.active,
        startDate: DateTime(2026, 9, 1),
        organizerName: 'Pilot Coordinator (PILOT-USR-01)',
        currentUserSlotPosition: userSlot,
        slots: slots,
      );
    }

    // =========================================================================
    // 1. WORKSTREAM 1 & 2: 25-MEMBER COHORT ENROLLMENT & SEED DATA AUDIT
    // =========================================================================
    test('WS 1 & 2: 25-Member Cohort across 3 Pilot Circles (\$200, \$500, \$1,000)', () {
      final c1 = createFieldPilotCircle(
        id: 'PILOT-CIRC-200-FIELD',
        name: 'Alexandria Starter 2026',
        membersCount: 10,
        monthlyMinor: 20000, // $200
        mode: GameyaAllocationMode.sequential,
      );
      final c2 = createFieldPilotCircle(
        id: 'PILOT-CIRC-500-FIELD',
        name: 'Cairo Family Circle',
        membersCount: 10,
        monthlyMinor: 50000, // $500
        mode: GameyaAllocationMode.symmetricalPaired,
      );
      final c3 = createFieldPilotCircle(
        id: 'PILOT-CIRC-1000-FIELD',
        name: 'Executive Tech Fund',
        membersCount: 10,
        monthlyMinor: 100000, // $1,000
        mode: GameyaAllocationMode.symmetricalPaired,
      );

      // Verify participant ID anonymity (Zero real PII)
      for (final slot in c1.slots) {
        expect(slot.assignedMemberId?.startsWith('PILOT-USR-'), isTrue);
      }
      for (final slot in c2.slots) {
        expect(slot.assignedMemberId?.startsWith('PILOT-USR-'), isTrue);
      }
      for (final slot in c3.slots) {
        expect(slot.assignedMemberId?.startsWith('PILOT-USR-'), isTrue);
      }
    });

    // =========================================================================
    // 2. WORKSTREAM 3: POSITION COMPREHENSION & 50/50 SPLIT VERIFICATION
    // =========================================================================
    test('WS 3: Position Comprehension Protocol (Position 1 gets \$2,500 in M1 and \$2,500 in M10)', () {
      final c2 = createFieldPilotCircle(
        id: 'PILOT-CIRC-500-FIELD',
        name: 'Cairo Family Circle',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
        userSlot: 1,
        currentPeriod: 1,
      );

      // Month 1 First Half Payout
      expect(c2.payoutAmountForSlotInPeriod(1, 1), equals(250000)); // $2,500.00
      expect(c2.isFirstHalfPayout(1, 1), isTrue);
      expect(c2.isFinalHalfPayout(1, 1), isFalse);

      // Month 10 Final Half Payout
      final c2M10 = c2.copyWith(currentPeriod: 10);
      expect(c2M10.payoutAmountForSlotInPeriod(1, 10), equals(250000)); // $2,500.00
      expect(c2M10.isFirstHalfPayout(1, 10), isFalse);
      expect(c2M10.isFinalHalfPayout(1, 10), isTrue);

      // Total Payout = $5,000.00
      final totalDisbursed = c2.payoutAmountForSlotInPeriod(1, 1) + c2M10.payoutAmountForSlotInPeriod(1, 10);
      expect(totalDisbursed, equals(500000));
    });

    // =========================================================================
    // 3. WORKSTREAM 4 & 5: FIELD CONTRIBUTION & PAYOUT OBSERVATION
    // =========================================================================
    test('WS 4 & 5: Field Contribution & Payout Claim Execution with Vouchers', () async {
      final controller = GameyaController(autoLoad: false);

      final c2 = createFieldPilotCircle(
        id: 'PILOT-CIRC-500-FIELD',
        name: 'Cairo Family Circle',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
        userSlot: 1,
        currentPeriod: 1,
      );

      final state = controller.value as GameyaLoaded;
      controller.value = state.copyWith(
        hubSummary: ConsumerHubSummary(
          memberName: 'Pilot Participant 1',
          activeCircles: [c2],
          totalMonthlyDuesMinor: 50000,
        ),
      );

      // 1. Submit Contribution
      final paySuccess = await controller.submitContributionPayment(
        circleId: c2.id,
        amountMinor: 50000,
        idempotencyKey: 'FIELD-TX-PAY-001',
      );
      expect(paySuccess, isTrue);

      // 2. Claim Payout
      final claimSuccess = await controller.claimPayoutDisbursement(
        circleId: c2.id,
        amountMinor: 250000,
        destinationAccount: 'Banque Misr (**** 9123)',
      );
      expect(claimSuccess, isTrue);

      final updatedState = controller.value as GameyaLoaded;
      expect(updatedState.activityTimeline.any((t) => t.id == 'FIELD-TX-PAY-001'), isTrue);
      expect(updatedState.activityTimeline.any((t) => t.eventType == ActivityEventType.payoutReceived), isTrue);
    });

    // =========================================================================
    // 4. WORKSTREAM 10: COMPLETE FIELD FINANCIAL RECONCILIATION
    // =========================================================================
    test('WS 10: Complete Field Lifecycle Reconciliation across all 3 circles (\$170,000 turnover)', () {
      final circles = [
        createFieldPilotCircle(id: 'C1', name: 'C1', membersCount: 10, monthlyMinor: 20000, mode: GameyaAllocationMode.sequential), // $20,000
        createFieldPilotCircle(id: 'C2', name: 'C2', membersCount: 10, monthlyMinor: 50000, mode: GameyaAllocationMode.symmetricalPaired), // $50,000
        createFieldPilotCircle(id: 'C3', name: 'C3', membersCount: 10, monthlyMinor: 100000, mode: GameyaAllocationMode.symmetricalPaired), // $100,000
      ];

      int totalCollected = 0;
      int totalDisbursed = 0;

      for (final circle in circles) {
        int circleCollected = 0;
        int circleDisbursed = 0;

        for (int p = 1; p <= circle.totalPeriods; p++) {
          circleCollected += circle.totalPeriods * circle.monthlyContributionMinor;

          if (circle.allocationMode == GameyaAllocationMode.sequential) {
            circleDisbursed += circle.payoutAmountForSlotInPeriod(p, p);
          } else {
            final activeSlots = circle.activePayoutSlotsForPeriod(p);
            for (final s in activeSlots) {
              circleDisbursed += circle.payoutAmountForSlotInPeriod(s, p);
            }
          }
        }

        expect(circleCollected, equals(circleDisbursed));
        expect(circleCollected - circleDisbursed, equals(0));

        totalCollected += circleCollected;
        totalDisbursed += circleDisbursed;
      }

      // Total Pilot Turnover: $20,000 + $50,000 + $100,000 = $170,000.00
      expect(totalCollected, equals(17000000));
      expect(totalDisbursed, equals(17000000));
      expect(totalCollected - totalDisbursed, equals(0)); // $0.00 variance
    });

    // =========================================================================
    // 5. WORKSTREAM 11: SECURITY & DATA PRIVACY IN FIELD
    // =========================================================================
    test('WS 11: Security role boundary & unauthorized off-turn claim rejection in field', () async {
      final controller = GameyaController(autoLoad: false);

      final c2M1 = createFieldPilotCircle(
        id: 'PILOT-CIRC-500-FIELD',
        name: 'Cairo Family Circle',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
        userSlot: 4, // User is slot 4 (due in month 4 and 7)
        currentPeriod: 1, // Current period is month 1
      );

      final state = controller.value as GameyaLoaded;
      controller.value = state.copyWith(
        hubSummary: ConsumerHubSummary(
          memberName: 'Pilot Participant 4',
          activeCircles: [c2M1],
          totalMonthlyDuesMinor: 50000,
        ),
      );

      // Attempt off-turn payout claim
      final unauthorizedClaim = await controller.claimPayoutDisbursement(
        circleId: c2M1.id,
        amountMinor: 250000,
        destinationAccount: 'Banque Misr (**** 9123)',
      );
      expect(unauthorizedClaim, isFalse, reason: 'Off-turn payout claim must be rejected in field');
    });
  });
}
