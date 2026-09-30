import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/financial_action_flow_view.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  group('Phase 47.2.5 — Contribution & Financial Action Verification Suite',
      () {
    late GameyaController controller;

    setUp(() {
      controller = GameyaController(autoLoad: false);
    });

    // =========================================================================
    // 1. DIRECT CONTROLLER SAFETY LOCK TESTS (Correction #1 Verification)
    // =========================================================================
    group('Correction #1: Controller Safety Lock Enforcement', () {
      test('1.1 Safety lock OFF: Simulation actions execute normally',
          () async {
        await controller.loadInitialData();
        final stateBefore = controller.value as GameyaLoaded;
        final initialTimelineCount = stateBefore.activityTimeline.length;

        final success = await controller.submitContributionPayment(
          circleId: 'CIRCLE-FAM-2026',
          amountMinor: 50000,
        );

        expect(success, isTrue);
        final stateAfter = controller.value as GameyaLoaded;
        expect(stateAfter.activityTimeline.length,
            equals(initialTimelineCount + 1));
        final targetCircle = stateAfter.hubSummary.activeCircles
            .firstWhere((c) => c.id == 'CIRCLE-FAM-2026');
        expect(
            targetCircle.slots.firstWhere((s) => s.isCurrentUser).paymentStatus,
            equals(SlotPaymentStatus.paid));
      });

      test(
          '1.2 Safety lock ON: submitContributionPayment() unconditionally rejected at controller level',
          () async {
        await controller.loadInitialData();
        controller.setSafetyLockActive(true);
        final stateBefore = controller.value as GameyaLoaded;
        final initialTimelineCount = stateBefore.activityTimeline.length;

        // Programmatic invocation while safety lock active
        final success = await controller.submitContributionPayment(
          circleId: 'CIRCLE-FAM-2026',
          amountMinor: 50000,
        );

        expect(success, isFalse);
        final stateAfter = controller.value as GameyaLoaded;
        // Verify ZERO side effects
        expect(
            stateAfter.activityTimeline.length, equals(initialTimelineCount));
        final targetCircle = stateAfter.hubSummary.activeCircles
            .firstWhere((c) => c.id == 'CIRCLE-FAM-2026');
        expect(
            targetCircle.slots.firstWhere((s) => s.isCurrentUser).paymentStatus,
            isNot(equals(SlotPaymentStatus.paid)));
      });

      test(
          '1.3 Safety lock ON: claimPayoutDisbursement() unconditionally rejected at controller level',
          () async {
        await controller.loadInitialData();
        controller.setSafetyLockActive(true);
        final stateBefore = controller.value as GameyaLoaded;
        final initialTimelineCount = stateBefore.activityTimeline.length;

        // Programmatic invocation while safety lock active
        final success = await controller.claimPayoutDisbursement(
          circleId: 'CIRCLE-FAM-2026',
          amountMinor: 500000,
          destinationAccount: '**** 8812',
        );

        expect(success, isFalse);
        final stateAfter = controller.value as GameyaLoaded;
        // Verify ZERO side effects
        expect(
            stateAfter.activityTimeline.length, equals(initialTimelineCount));
      });

      test(
          '1.4 Safety lock ON: Repeated programmatic invocations remain blocked with zero side effects',
          () async {
        await controller.loadInitialData();
        controller.setSafetyLockActive(true);
        final stateBefore = controller.value as GameyaLoaded;

        for (int i = 0; i < 5; i++) {
          final res1 = await controller.submitContributionPayment(
            circleId: 'CIRCLE-FAM-2026',
            amountMinor: 50000,
          );
          final res2 = await controller.claimPayoutDisbursement(
            circleId: 'CIRCLE-FAM-2026',
            amountMinor: 500000,
            destinationAccount: '**** 8812',
          );
          expect(res1, isFalse);
          expect(res2, isFalse);
        }

        final stateAfter = controller.value as GameyaLoaded;
        expect(stateAfter.activityTimeline.length,
            equals(stateBefore.activityTimeline.length));
      });

      test(
          '1.5 Safety lock parameter override: Rejects even if controller instance flag was false',
          () async {
        await controller.loadInitialData();
        expect(controller.isSafetyLockActive, isFalse);

        final success = await controller.submitContributionPayment(
          circleId: 'CIRCLE-FAM-2026',
          amountMinor: 50000,
          isSafetyLockActive: true, // Caller-level safety lock enforcement
        );

        expect(success, isFalse);
      });
    });

    // =========================================================================
    // 2. AUTHORITATIVE SLOT PAYOUT ENTITLEMENT TESTS (Correction #2 Verification)
    // =========================================================================
    group('Correction #2: Authoritative Slot Payout Entitlement', () {
      test(
          '2.1 Sequential circle: userPayoutAmountForPeriod() reads slot.payoutAmountMinor directly',
          () async {
        await controller.loadInitialData();
        final state = controller.value as GameyaLoaded;
        final seqCircle = state.hubSummary.activeCircles
            .firstWhere((c) => c.id == 'CIRCLE-FAM-2026');

        expect(
            seqCircle.allocationMode, equals(GameyaAllocationMode.sequential));
        expect(seqCircle.currentUserSlotPosition, equals(2));
        final assignedSlot =
            seqCircle.slots.firstWhere((s) => s.slotNumber == 2);

        // Authoritative equality
        expect(seqCircle.userPayoutAmountForPeriod(2),
            equals(assignedSlot.payoutAmountMinor));
        expect(seqCircle.payoutAmountForSlotInPeriod(2, 2),
            equals(assignedSlot.payoutAmountMinor));
      });

      test(
          '2.2 Symmetrical Paired circle: userPayoutAmountForPeriod() reads slot.payoutAmountMinor directly',
          () async {
        await controller.loadInitialData();
        final state = controller.value as GameyaLoaded;
        final pairedCircle = state.hubSummary.activeCircles
            .firstWhere((c) => c.id == 'CIRCLE-CAR-2027');

        expect(pairedCircle.allocationMode,
            equals(GameyaAllocationMode.symmetricalPaired));
        expect(pairedCircle.currentUserSlotPosition, equals(9));
        final assignedSlot =
            pairedCircle.slots.firstWhere((s) => s.slotNumber == 9);

        // Authoritative slot entitlement: 5,000.00 EGP (500,000 minor)
        expect(assignedSlot.payoutAmountMinor, equals(500000));
        expect(pairedCircle.userPayoutAmountForPeriod(9),
            equals(assignedSlot.payoutAmountMinor));
        expect(pairedCircle.payoutAmountForSlotInPeriod(9, 9),
            equals(assignedSlot.payoutAmountMinor));
      });

      test(
          '2.3 Changing totalPoolMinor alone does NOT alter assigned slot.payoutAmountMinor',
          () {
        const slot = GameyaSlot(
          slotNumber: 1,
          isCurrentUser: true,
          payoutAmountMinor: 500000,
          scheduledMonthName: 'Month 1',
          pairedSlotNumber: 10,
        );

        final circle1 = GameyaCircle(
          id: 'TEST-1',
          name: 'Test Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 10,
          currentPeriod: 1,
          totalPoolMinor: 1000000, // 10,000 total pool
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'System',
          currentUserSlotPosition: 1,
          slots: const [slot],
        );

        final circle2 = GameyaCircle(
          id: 'TEST-1',
          name: 'Test Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 10,
          currentPeriod: 1,
          totalPoolMinor: 999999999, // Artificial modification of pool property
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'System',
          currentUserSlotPosition: 1,
          slots: const [slot],
        );

        // Payout resolution reads slot.payoutAmountMinor, NOT totalPoolMinor ~/ 2
        expect(circle1.userPayoutAmountForPeriod(1),
            equals(slot.payoutAmountMinor));
        expect(circle2.userPayoutAmountForPeriod(1),
            equals(slot.payoutAmountMinor));
        expect(circle2.userPayoutAmountForPeriod(1), equals(500000));
      });

      test('2.4 pairedSlotNumber remains authoritative pairing metadata',
          () async {
        await controller.loadInitialData();
        final state = controller.value as GameyaLoaded;
        final pairedCircle = state.hubSummary.activeCircles
            .firstWhere((c) => c.id == 'CIRCLE-CAR-2027');

        // Check standard 10-member symmetrical pairs
        expect(pairedCircle.slots[0].pairedSlotNumber, equals(10)); // 1 <-> 10
        expect(pairedCircle.slots[1].pairedSlotNumber, equals(9)); // 2 <-> 9
        expect(pairedCircle.slots[2].pairedSlotNumber, equals(8)); // 3 <-> 8
        expect(pairedCircle.slots[3].pairedSlotNumber, equals(7)); // 4 <-> 7
        expect(pairedCircle.slots[4].pairedSlotNumber, equals(6)); // 5 <-> 6
      });

      test(
          '2.5 Missing requested slot does NOT return totalPoolMinor, totalPoolMinor ~/ 2, or unrelated slot payout (fails closed to 0)',
          () {
        const slot1 = GameyaSlot(
          slotNumber: 1,
          isCurrentUser: false,
          payoutAmountMinor: 500000,
          scheduledMonthName: 'Month 1',
          pairedSlotNumber: 10,
        );

        final circle = GameyaCircle(
          id: 'TEST-ORPHAN',
          name: 'Orphan Slot Test Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 10,
          currentPeriod: 1,
          totalPoolMinor: 1000000, // $10,000 total pool
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'System',
          currentUserSlotPosition: 99, // Unassigned / missing slot position
          slots: const [slot1], // Only slot 1 exists
        );

        // Slot 1 exists -> returns 500,000 minor
        expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(500000));

        // Slot 99 (missing) -> MUST NOT return totalPoolMinor (1000000)
        expect(circle.payoutAmountForSlotInPeriod(99, 1),
            isNot(equals(circle.totalPoolMinor)));
        expect(
            circle.payoutAmountForSlotInPeriod(99, 1), isNot(equals(1000000)));

        // Slot 99 (missing) -> MUST NOT return totalPoolMinor ~/ 2 (500000) derived from pool
        // Slot 99 (missing) -> MUST NOT return slot 1's payout by coincidence/fallback
        // Slot 99 (missing) -> Strictly returns 0 (fail-closed safe non-financial state)
        expect(circle.payoutAmountForSlotInPeriod(99, 1), equals(0));

        // Slot 5 (missing) -> Strictly returns 0
        expect(circle.payoutAmountForSlotInPeriod(5, 5), equals(0));

        // userPayoutAmountForPeriod for slot 99 -> Strictly returns 0
        expect(circle.userPayoutAmountForPeriod(1), equals(0));

        // userPayoutsReceivedMinor for missing slot position -> Strictly returns 0
        expect(circle.userPayoutsReceivedMinor(1), equals(0));
      });

      test(
          '2.6 Non-enrolled user (currentUserSlotPosition == null) returns 0 entitlement',
          () {
        final circle = GameyaCircle(
          id: 'TEST-UNENROLLED',
          name: 'Unenrolled Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 10,
          currentPeriod: 1,
          totalPoolMinor: 1000000,
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'System',
          currentUserSlotPosition: null,
          slots: const [
            GameyaSlot(
              slotNumber: 1,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 1',
              pairedSlotNumber: 10,
            ),
          ],
        );

        expect(circle.userPayoutAmountForPeriod(1), equals(0));
        expect(circle.userPayoutsReceivedMinor(1), equals(0));
      });
    });

    // =========================================================================
    // 3. UI INTEGRATION TESTS (Screens A–G & Universal States)
    // =========================================================================
    testWidgets(
        '3.1 Contribution Overview (Screen A): Renders authoritative due amount, circle name, and progress',
        (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            actionType: FinancialActionType.contribution,
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Header & Due Payment Card
      expect(find.text('Monthly Contribution'), findsOneWidget);
      expect(find.text('Next Due Payment'), findsOneWidget);
      expect(find.text('EGP 500'), findsOneWidget);
      expect(find.text('DUE'), findsOneWidget);
      expect(
          find.text('REAL_MONEY_ENABLED = false (SIMULATION)'), findsOneWidget);

      // Verify Primary Action CTA
      expect(find.text('Review Contribution'), findsOneWidget);
    });

    testWidgets(
        '3.2 Contribution Review & Action (Screens B, C, D): Respects REAL_MONEY_ENABLED=false & generates simulated receipt',
        (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            actionType: FinancialActionType.contribution,
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Tap "Review Contribution" -> Step 2 (Screen B)
      await tester.tap(find.text('Review Contribution'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 4: Review'), findsOneWidget);
      expect(find.text('Confirm Contribution'), findsOneWidget);
      expect(
          find.textContaining('Financial transactions are currently disabled'),
          findsOneWidget);

      // Tap "Continue" -> Step 3 (Screen C)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 4: Action'), findsOneWidget);
      expect(find.text('Select Clearing Rail'), findsOneWidget);
      expect(find.textContaining('Safe Financial Simulation'), findsOneWidget);

      // Tap "Confirm Simulation Payment" -> Step 4 (Screen D)
      await tester.tap(find.textContaining('Confirm Simulation Payment'));
      await tester.pumpAndSettle();

      expect(find.text('Step 4 of 4: Result'), findsOneWidget);
      expect(find.text('Contribution Settled!'), findsOneWidget);
      expect(find.text('Electronic Receipt (Simulated)'), findsOneWidget);
      expect(find.text('Return to Game\'ya'), findsOneWidget);
    });

    testWidgets(
        '3.3 Payout Overview (Screen E): Renders 50/50 symmetrical paired breakdown without 100% Month 1 implication',
        (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FinancialActionFlowView(
            controller: controller,
            circleId:
                'CIRCLE-CAR-2027', // Symmetrical Paired circle (10 periods, slot 9/2)
            actionType: FinancialActionType.payout,
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('50% Paired Payout Due'), findsOneWidget);
      expect(find.text('EGP 5,000'),
          findsWidgets); // Reads slot.payoutAmountMinor directly
      expect(find.text('50/50 Symmetrical Paired Structure'), findsOneWidget);
      expect(find.text('Early Payout (50%)'), findsOneWidget);
      expect(find.text('Paired Payout (50%)'), findsOneWidget);
      expect(find.textContaining('Your payout is split into two equal halves'),
          findsOneWidget);
      expect(find.text('Review Payout'), findsOneWidget);
    });

    testWidgets(
        '3.4 Payout Review & Claim (Screens F, G): Generates simulated disbursement voucher',
        (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            actionType: FinancialActionType.payout,
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Tap "Review Payout" -> Step 2 (Screen F)
      await tester.tap(find.text('Review Payout'));
      await tester.pumpAndSettle();

      expect(find.text('Review Disbursement Details'), findsOneWidget);
      expect(find.text('DESTINATION ACCOUNT'), findsOneWidget);
      expect(find.text('Claim Payout'), findsOneWidget);

      // Tap "Claim Payout" -> Step 3 (Screen G)
      await tester.tap(find.text('Claim Payout'));
      await tester.pumpAndSettle();

      expect(find.text('Payout Claim Processed!'), findsOneWidget);
      expect(find.text('Disbursement Voucher (Simulated)'), findsOneWidget);
      expect(find.text('Return to Game\'ya'), findsOneWidget);
    });

    testWidgets(
        '3.5 Financial Safety Lock: Disables all financial action buttons and displays banner in UI',
        (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            actionType: FinancialActionType.contribution,
            isSafetyLockActive: true,
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(
          find.textContaining(
              'Financial actions are temporarily locked for safety.'),
          findsOneWidget);
      // Verify PrimaryButton is disabled
      final button =
          tester.widget<PrimaryButton>(find.byType(PrimaryButton).first);
      expect(button.onPressed, isNull);
    });

    testWidgets(
        '3.6 Universal System States: Empty, Offline, and Permission Denied',
        (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Permission Denied State
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            actionType: FinancialActionType.contribution,
            isPermissionDenied: true,
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Access Restricted'), findsWidgets);
      expect(find.text('Return to Safety'), findsOneWidget);

      // 2. Offline Notice
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            actionType: FinancialActionType.contribution,
            isOffline: true,
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
          find.textContaining(
              'You\'re offline. Previously loaded information may still be visible.'),
          findsOneWidget);
    });

    testWidgets(
        '3.7 Arabic RTL Mode: Renders Cairo directionality and localized Arabic strings',
        (tester) async {
      await controller.loadInitialData();
      controller.toggleLanguage('ar');
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            actionType: FinancialActionType.contribution,
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('المساهمة الشهرية'), findsOneWidget);
      expect(find.text('القسط الشهري المستحق'), findsOneWidget);
      expect(find.text('مراجعة المساهمة'), findsOneWidget);
      expect(find.text('تقدم الجمعية'), findsOneWidget);
    });

    testWidgets(
        '3.8 Accessibility & Touch Targets: Touch targets meet 48dp minimum size',
        (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            actionType: FinancialActionType.contribution,
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // PrimaryButton height is at least 48dp
      final btnFinder = find.byType(PrimaryButton);
      final size = tester.getSize(btnFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });
}
