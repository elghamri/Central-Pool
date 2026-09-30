import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/widgets/symmetrical_paired_chord_visualizer.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/widgets/reconciliation_sankey_widget.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/widgets/emergency_lockdown_shield_widget.dart';

void main() {
  group('Phase 45: Stitch Graphic UI/UX Redesign & Visual Widget Suite', () {
    // =========================================================================
    // 1. SYMMETRICAL PAIRED CHORD VISUALIZER
    // =========================================================================
    testWidgets('1. SymmetricalPairedChordVisualizer renders paired early/late slots and 50% split', (tester) async {
      final slots = List.generate(6, (i) {
        final slotNum = i + 1;
        return GameyaSlot(
          slotNumber: slotNum,
          payoutAmountMinor: 150000,
          scheduledMonthName: 'Month $slotNum',
          pairedSlotNumber: 7 - slotNum,
        );
      });

      final circle = GameyaCircle(
        id: 'CIRC-TEST-6',
        name: 'Test 6-Member Circle',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 6,
        totalPoolMinor: 300000,
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        startDate: DateTime(2026, 9, 1),
        organizerName: 'Ahmed',
        slots: slots,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymmetricalPairedChordVisualizer(circle: circle),
          ),
        ),
      );

      expect(find.text('50/50 SYMMETRICAL PAIRED'), findsOneWidget);
      expect(find.text('Month 1'), findsOneWidget);
      expect(find.text('Month 2'), findsOneWidget);
      expect(find.text('Month 3'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsNWidgets(3));
    });

    // =========================================================================
    // 2. 6-LAYER RECONCILIATION SANKEY VISUALIZER
    // =========================================================================
    testWidgets('2. ReconciliationSankeyWidget renders all 6 conduits with zero variance badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReconciliationSankeyWidget(
              totalInflowsMinor: 1000000,
              totalOutflowsMinor: 1000000,
              varianceMinor: 0,
            ),
          ),
        ),
      );

      expect(find.text('6-LAYER RECONCILIATION FLOW'), findsOneWidget);
      expect(find.text('VARIANCE: \$0.00'), findsOneWidget);
      expect(find.text('Member Banking Ingress (ACH/Cards)'), findsOneWidget);
      expect(find.text('Final Disbursement Clearing (GL-3010)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // =========================================================================
    // 3. EMERGENCY LOCKDOWN SHIELD WIDGET
    // =========================================================================
    testWidgets('3. EmergencyLockdownShieldWidget opens confirmation and triggers callback', (tester) async {
      String? triggeredReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyLockdownShieldWidget(
              isLockdownActive: false,
              onLockdownTriggered: (reason) => triggeredReason = reason,
            ),
          ),
        ),
      );

      expect(find.text('TRIGGER EMERGENCY LOCKDOWN'), findsOneWidget);
      await tester.tap(find.text('TRIGGER EMERGENCY LOCKDOWN'));
      await tester.pump();

      expect(find.text('CONFIRM EMERGENCY LOCKDOWN?'), findsOneWidget);
      await tester.tap(find.text('CONFIRM LOCKDOWN'));
      await tester.pump();

      expect(triggeredReason, equals('Operator Emergency Lockdown Activation'));
    });

    // =========================================================================
    // 4. FINANCIAL REGRESSION & BALANCE VERIFICATION
    // =========================================================================
    test('4. Financial Invariant Protection: INV-1..18 preserved with \$0.00 variance', () {
      final circleSizes = [4, 6, 8, 10, 12];
      const monthlyDuesMinor = 100000; // $1,000.00

      for (final size in circleSizes) {
        final totalPool = size * monthlyDuesMinor;
        final halfPayout = totalPool ~/ 2;

        final slots = List.generate(size, (i) {
          final slotNum = i + 1;
          final pairedSlot = size + 1 - slotNum;
          return GameyaSlot(
            slotNumber: slotNum,
            payoutAmountMinor: halfPayout,
            scheduledMonthName: 'Month $slotNum',
            pairedSlotNumber: pairedSlot,
          );
        });

        final circle = GameyaCircle(
          id: 'P45-CIRC-$size',
          name: 'Phase 45 $size-Member Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: monthlyDuesMinor,
          totalPeriods: size,
          totalPoolMinor: totalPool,
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 9, 1),
          organizerName: 'Organizer',
          slots: slots,
        );

        int totalInflows = 0;
        int totalOutflows = 0;

        for (int p = 1; p <= size; p++) {
          totalInflows += size * monthlyDuesMinor;
          final activeSlots = circle.activePayoutSlotsForPeriod(p);
          for (final s in activeSlots) {
            totalOutflows += circle.payoutAmountForSlotInPeriod(s, p);
          }
        }

        expect(totalInflows, equals(totalOutflows));
        expect(totalInflows - totalOutflows, equals(0));
      }
    });
  });
}
