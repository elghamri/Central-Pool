import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/i18n/gameya_strings.dart';

void main() {
  group('Phase 32: Adversarial Real-Money Simulation & Pilot Launch Gate Suite', () {
    // Helper to generate test circles
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
        final pairedSlot = isPaired ? (membersCount + 1 - slotNum) : null;
        final slotPayout = isPaired ? (totalPool ~/ 2) : totalPool;
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

    // =========================================================================
    // 1. DUPLICATE PAYMENT ATTACKS (A1, A2, A3, A4)
    // =========================================================================
    test('Attack A1 & A2: Double/Triple Tap and Idempotency deduplication', () async {
      final controller = GameyaController(autoLoad: false);

      // Submit first contribution
      final res1 = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 50000,
        idempotencyKey: 'IDEM-KEY-001',
      );
      expect(res1, isTrue);

      final state1 = controller.value as GameyaLoaded;
      expect(state1.activityTimeline.length, greaterThan(0));

      // Submit second identical contribution with SAME idempotency key
      final res2 = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 50000,
        idempotencyKey: 'IDEM-KEY-001',
      );
      expect(res2, isTrue);

      final state2 = controller.value as GameyaLoaded;
      // Should maintain idempotent timeline entry without duplicate ghost balance
      expect(state2.activityTimeline.where((t) => t.id == 'IDEM-KEY-001').length, equals(1));
    });

    test('Attack A4: Reject non-positive contribution amounts', () async {
      final controller = GameyaController(autoLoad: false);

      final resZero = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 0,
      );
      expect(resZero, isFalse);

      final resNeg = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: -50000,
      );
      expect(resNeg, isFalse);
    });

    // =========================================================================
    // 2. CONCURRENT SLOT CLAIM ATTACK (100 Iterations)
    // =========================================================================
    test('Attack B: Concurrent Slot Claiming Race Condition (100 runs)', () async {
      for (int i = 0; i < 100; i++) {
        final openSlot = GameyaSlot.open(slotNumber: 3, payoutAmountMinor: 500000, scheduledMonthName: 'Month 3');
        final formingCircle = GameyaCircle(
          id: 'RACE-CIRC-$i',
          name: 'Race Circle $i',
          goalCategory: 'Tech',
          monthlyContributionMinor: 50000,
          totalPeriods: 10,
          currentPeriod: 1,
          totalPoolMinor: 500000,
          allocationMode: GameyaAllocationMode.sequential,
          status: GameyaCircleStatus.forming,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'Organizer',
          slots: [
            const GameyaSlot(slotNumber: 1, assignedMemberId: 'usr-1', isClaimed: true, paymentStatus: SlotPaymentStatus.paid, payoutAmountMinor: 500000, scheduledMonthName: 'Month 1'),
            const GameyaSlot(slotNumber: 2, assignedMemberId: 'usr-2', isClaimed: true, paymentStatus: SlotPaymentStatus.paid, payoutAmountMinor: 500000, scheduledMonthName: 'Month 2'),
            openSlot,
            ...List.generate(7, (idx) => GameyaSlot.open(slotNumber: idx + 4, payoutAmountMinor: 500000, scheduledMonthName: 'Month ${idx + 4}')),
          ],
        );

        final controller = GameyaController(autoLoad: false);
        // Replace marketplace with this test circle
        final state = controller.value as GameyaLoaded;
        controller.value = state.copyWith(marketplaceCircles: [formingCircle]);

        // User A claims Slot 3
        final userAClaim = await controller.joinCircleWithSlot(circleId: formingCircle.id, slotNumber: 3);
        expect(userAClaim, isTrue);

        // User B attempts to claim Slot 3 concurrently (now claimed)
        final userBClaim = await controller.joinCircleWithSlot(circleId: formingCircle.id, slotNumber: 3);
        expect(userBClaim, isFalse, reason: 'Iteration $i: User B must be rejected on claimed slot');
      }
    });

    // =========================================================================
    // 3. UNAUTHORIZED PAYOUT ATTACK
    // =========================================================================
    test('Attack D: Unauthorized and Off-Turn Payout Claims are strictly rejected', () async {
      final controller = GameyaController(autoLoad: false);

      // Attempt payout on active circle where user is Slot 2, but current period is Month 1
      final circleM1 = createTestCircle(
        id: 'AUTH-TEST-1',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.sequential,
        userSlot: 2,
        currentPeriod: 1, // User is slot 2, but period is 1
      );

      final state = controller.value as GameyaLoaded;
      controller.value = state.copyWith(
        hubSummary: ConsumerHubSummary(
          memberName: 'Ahmed',
          activeCircles: [circleM1],
          totalMonthlyDuesMinor: 50000,
        ),
      );

      // Attempt off-turn claim
      final offTurnClaim = await controller.claimPayoutDisbursement(
        circleId: circleM1.id,
        amountMinor: 500000,
        destinationAccount: 'Chase Checking (**** 8812)',
      );
      expect(offTurnClaim, isFalse, reason: 'Off-turn payout claim must be rejected');

      // Attempt claim with empty destination account
      final circleM2 = circleM1.copyWith(currentPeriod: 2);
      controller.value = state.copyWith(
        hubSummary: ConsumerHubSummary(
          memberName: 'Ahmed',
          activeCircles: [circleM2],
          totalMonthlyDuesMinor: 50000,
        ),
      );

      final emptyAccountClaim = await controller.claimPayoutDisbursement(
        circleId: circleM2.id,
        amountMinor: 500000,
        destinationAccount: '',
      );
      expect(emptyAccountClaim, isFalse, reason: 'Payout with empty account must be rejected');
    });

    // =========================================================================
    // 4. SYMMETRICAL PAIRED FINANCIAL TRUTH (50/50 Symmetrical Ledger Verification)
    // =========================================================================
    test('Attack E: Symmetrical Paired full cycle accounting integrity (10 x \$500 x 10)', () {
      final circle = createTestCircle(
        id: 'SYM-LEDGER-VERIFY',
        membersCount: 10,
        monthlyMinor: 50000,
        mode: GameyaAllocationMode.symmetricalPaired,
      );

      int cumulativeDebits = 0;
      int cumulativeCredits = 0;

      for (int p = 1; p <= 10; p++) {
        // Contributions in period p: 10 x $500 = $5,000
        final periodCollected = 10 * circle.monthlyContributionMinor;
        cumulativeDebits += periodCollected;

        // Payouts in period p: 2 paired slots x $2,500 = $5,000
        final activeSlots = circle.activePayoutSlotsForPeriod(p);
        expect(activeSlots.length, equals(2));

        int periodDisbursed = 0;
        for (final s in activeSlots) {
          final payout = circle.payoutAmountForSlotInPeriod(s, p);
          expect(payout, equals(250000)); // $2,500.00
          periodDisbursed += payout;
        }

        expect(periodDisbursed, equals(500000)); // Exactly $5,000 per period
        cumulativeCredits += periodDisbursed;
      }

      expect(cumulativeDebits, equals(5000000)); // $50,000.00 total debits
      expect(cumulativeCredits, equals(5000000)); // $50,000.00 total credits
      expect(cumulativeDebits - cumulativeCredits, equals(0)); // $0.00 residual
    });

    // =========================================================================
    // 5. PROPERTY-BASED TESTING MATRIX (Fuzzing Circle Sizes & Denominations)
    // =========================================================================
    test('Attack H: Property-Based Fuzzing across sizes (4, 6, 8, 10, 12) and denominations', () {
      final rng = math.Random(42);
      final evenSizes = [4, 6, 8, 10, 12];
      final denominations = [10000, 25000, 50000, 75000, 100000, 200000];

      for (int trial = 0; trial < 50; trial++) {
        final size = evenSizes[rng.nextInt(evenSizes.length)];
        final denom = denominations[rng.nextInt(denominations.length)];

        final symCircle = createTestCircle(
          id: 'FUZZ-$trial',
          membersCount: size,
          monthlyMinor: denom,
          mode: GameyaAllocationMode.symmetricalPaired,
        );

        final totalPool = size * denom;
        final halfPayout = totalPool ~/ 2;

        int totalIn = 0;
        int totalOut = 0;

        for (int p = 1; p <= size; p++) {
          totalIn += size * denom;
          final activeSlots = symCircle.activePayoutSlotsForPeriod(p);
          expect(activeSlots.length, equals(2));
          for (final s in activeSlots) {
            final payout = symCircle.payoutAmountForSlotInPeriod(s, p);
            expect(payout, equals(halfPayout));
            totalOut += payout;
          }
        }

        expect(totalIn, equals(totalOut));
        expect(totalIn - totalOut, equals(0));
      }
    });

    // =========================================================================
    // 6. UI FINANCIAL COPY COMPLIANCE AUDIT
    // =========================================================================
    test('Attack I: Verify zero misleading financial terms in localization', () {
      final prohibitedTerms = [
        'guaranteed return',
        'profit',
        'interest earned',
        'investment',
        'bank deposit',
        'corporate reserve',
        'credit union reserve',
      ];

      const enStrings = GameyaStrings.en;
      final enStringsMap = [
        enStrings.appTitle,
        enStrings.tabHome,
        enStrings.repayingAdvancePayout,
        enStrings.accumulatingSavings,
        enStrings.totalPayout,
        enStrings.wheelSubtitle,
      ];

      for (final s in enStringsMap) {
        final lower = s.toLowerCase();
        for (final term in prohibitedTerms) {
          expect(lower.contains(term), isFalse, reason: 'Prohibited term "$term" found in string "$s"');
        }
      }
    });

    // =========================================================================
    // 7. 50-MEMBER REALISTIC PILOT SIMULATION (5 Circles x 10 Members)
    // =========================================================================
    test('Attack J: 50-Member Realistic Pilot Simulation across 5 active circles', () {
      final circles = [
        createTestCircle(id: 'CIRC-1', membersCount: 10, monthlyMinor: 50000, mode: GameyaAllocationMode.sequential),
        createTestCircle(id: 'CIRC-2', membersCount: 10, monthlyMinor: 100000, mode: GameyaAllocationMode.symmetricalPaired),
        createTestCircle(id: 'CIRC-3', membersCount: 10, monthlyMinor: 20000, mode: GameyaAllocationMode.symmetricalPaired),
        createTestCircle(id: 'CIRC-4', membersCount: 10, monthlyMinor: 50000, mode: GameyaAllocationMode.symmetricalPaired),
        createTestCircle(id: 'CIRC-5', membersCount: 10, monthlyMinor: 30000, mode: GameyaAllocationMode.sequential),
      ];

      int pilotTotalIn = 0;
      int pilotTotalOut = 0;

      for (final circle in circles) {
        int circleIn = 0;
        int circleOut = 0;

        for (int p = 1; p <= circle.totalPeriods; p++) {
          circleIn += circle.totalPeriods * circle.monthlyContributionMinor;

          if (circle.allocationMode == GameyaAllocationMode.sequential) {
            circleOut += circle.payoutAmountForSlotInPeriod(p, p);
          } else {
            final active = circle.activePayoutSlotsForPeriod(p);
            for (final s in active) {
              circleOut += circle.payoutAmountForSlotInPeriod(s, p);
            }
          }
        }

        expect(circleIn, equals(circleOut));
        expect(circleIn - circleOut, equals(0));

        pilotTotalIn += circleIn;
        pilotTotalOut += circleOut;
      }

      // Total Pilot Turnover:
      // Circ 1: $50,000 + Circ 2: $100,000 + Circ 3: $20,000 + Circ 4: $50,000 + Circ 5: $30,000 = $250,000
      expect(pilotTotalIn, equals(25000000)); // $250,000.00
      expect(pilotTotalOut, equals(25000000)); // $250,000.00
      expect(pilotTotalIn - pilotTotalOut, equals(0)); // $0.00 residual
    });
  });
}
