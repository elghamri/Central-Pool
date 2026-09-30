// Phase 50: Central Pool Step 13 Presentation Views & Shell Widget Test
// Invariant: Verifies all 6 new presentation views render correctly with data, empty states, and lockdown banners.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:member_mobile_app/src/features/central_pool/models/financial_obligation_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/contribution_schedule_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/contribution_event_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/payout_entitlement_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/period_projection_models.dart';
import 'package:member_mobile_app/src/features/central_pool/models/system_lockdown_model.dart';
import 'package:member_mobile_app/src/features/central_pool/data/central_pool_repository.dart';
import 'package:member_mobile_app/src/features/central_pool/state/central_pool_controller.dart';
import 'package:member_mobile_app/src/features/central_pool/widgets/locked_banner.dart';
import 'package:member_mobile_app/src/features/central_pool/views/financial_obligation_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/contribution_schedule_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/contribution_events_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/payout_entitlement_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/member_period_timeline_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/cycle_period_readiness_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/central_pool_shell_view.dart';

void main() {
  group('Central Pool Step 13 Views & Widgets Tests', () {
    late CentralPoolRepository mockRepo;
    late CentralPoolController controller;

    setUp(() {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      mockRepo = CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient);
      controller = CentralPoolController(repository: mockRepo, tenantId: 'tenant_cairo', memberId: 'mem_alice');
    });

    Widget testableWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('1. LockedBanner renders active and inactive states', (tester) async {
      // Inactive
      await tester.pumpWidget(testableWidget(const Scaffold(body: LockedBanner(isLocked: false))));
      expect(find.text('SYSTEM LOCKDOWN ACTIVE'), findsNothing);

      // Active
      final lockdown = SystemLockdownModel(
        lockdownId: 'lock_01',
        tenantId: 'tenant_cairo',
        isLocked: true,
        reason: 'Emergency Platform Freeze Test',
        initiatedAt: DateTime.now(),
      );

      await tester.pumpWidget(testableWidget(Scaffold(body: LockedBanner(lockdown: lockdown, isLocked: true))));
      expect(find.text('SYSTEM LOCKDOWN ACTIVE'), findsOneWidget);
      expect(find.text('Emergency Platform Freeze Test'), findsOneWidget);
      expect(find.text('READ ONLY'), findsOneWidget);
    });

    testWidgets('2. FinancialObligationView renders obligation data and simulation banner', (tester) async {
      final obligation = FinancialObligationModel(
        obligationId: 'ob_cairo_123',
        tenantId: 'tenant_cairo',
        memberUid: 'mem_alice',
        allocationUnitId: 'unit_cairo_123',
        allocationId: 'alloc_cairo_123',
        positionNumber: 3,
        totalObligationMinor: 500000,
        contributionMinor: 50000,
        totalPeriods: 10,
        fulfilledAmountMinor: 100000,
        currency: 'EGP',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      await tester.pumpWidget(testableWidget(
        FinancialObligationView(
          controller: controller,
          obligationOverride: obligation,
        ),
      ));

      expect(find.text('Financial Obligation Record'), findsOneWidget);
      expect(find.text('SIMULATION & ACCOUNTING PROJECTION'), findsOneWidget);
      expect(find.text('Position #3'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('500 EGP'), findsWidgets);
      expect(find.text('5000 EGP'), findsWidgets);
    });

    testWidgets('3. ContributionScheduleView renders schedule periods and status', (tester) async {
      final schedule = ContributionScheduleModel(
        scheduleId: 'cs_cairo_123',
        obligationId: 'ob_cairo_123',
        tenantId: 'tenant_cairo',
        memberUid: 'mem_alice',
        allocationUnitId: 'unit_cairo_123',
        totalPeriods: 3,
        periods: [
          ScheduledContributionPeriodModel(
            periodNumber: 1,
            scheduledAmountMinor: 50000,
            status: 'RECORDED',
            recordedAt: DateTime.now(),
            contributionEventId: 'ce_001',
          ),
          const ScheduledContributionPeriodModel(
            periodNumber: 2,
            scheduledAmountMinor: 50000,
            status: 'SCHEDULED',
          ),
          const ScheduledContributionPeriodModel(
            periodNumber: 3,
            scheduledAmountMinor: 50000,
            status: 'SCHEDULED',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      await tester.pumpWidget(testableWidget(
        ContributionScheduleView(
          controller: controller,
          scheduleOverride: schedule,
        ),
      ));

      expect(find.text('Contribution Schedule'), findsOneWidget);
      expect(find.text('3 Periods'), findsOneWidget);
      expect(find.text('Period #1'), findsOneWidget);
      expect(find.text('Period #2'), findsOneWidget);
      expect(find.text('Period #3'), findsOneWidget);
      expect(find.text('RECORDED'), findsOneWidget);
      expect(find.text('SCHEDULED'), findsWidgets);
    });

    testWidgets('4. ContributionEventsView renders event history list and empty state', (tester) async {
      // Empty state
      await tester.pumpWidget(testableWidget(
        ContributionEventsView(
          controller: controller,
          eventsOverride: const [],
        ),
      ));
      expect(find.text('No recorded contribution events yet.'), findsOneWidget);

      // Populated state
      final events = [
        ContributionEventModel(
          contributionEventId: 'ce_001',
          tenantId: 'tenant_cairo',
          memberUid: 'mem_alice',
          obligationId: 'ob_cairo_123',
          allocationUnitId: 'unit_cairo_123',
          periodNumber: 1,
          amountMinor: 50000,
          currency: 'EGP',
          recordedAt: DateTime.now(),
          idempotencyId: 'idem_ce_001',
        ),
      ];

      await tester.pumpWidget(testableWidget(
        ContributionEventsView(
          controller: controller,
          eventsOverride: events,
        ),
      ));

      expect(find.text('Period #1 Contribution'), findsOneWidget);
      expect(find.text('+500 EGP'), findsOneWidget);
      expect(find.text('Event ID: ce_001'), findsOneWidget);
    });

    testWidgets('5. PayoutEntitlementView renders disbursement slots', (tester) async {
      final entitlement = PayoutEntitlementModel(
        payoutEntitlementId: 'pe_cairo_123',
        tenantId: 'tenant_cairo',
        memberUid: 'mem_alice',
        allocationUnitId: 'unit_cairo_123',
        allocationId: 'alloc_cairo_123',
        positionNumber: 3,
        totalEntitlementMinor: 500000,
        currency: 'EGP',
        splits: const [
          FinancialDisbursementSlotModel(
            periodNumber: 2,
            amountMinor: 250000,
            basisPoints: 5000,
            isCenter: false,
          ),
          FinancialDisbursementSlotModel(
            periodNumber: 9,
            amountMinor: 250000,
            basisPoints: 5000,
            isCenter: false,
          ),
        ],
        status: 'SCHEDULED',
        calculatedAt: DateTime.now(),
        version: 1,
      );

      await tester.pumpWidget(testableWidget(
        PayoutEntitlementView(
          controller: controller,
          entitlementOverride: entitlement,
        ),
      ));

      expect(find.text('Payout Entitlement Projection'), findsOneWidget);
      expect(find.text('Position #3'), findsOneWidget);
      expect(find.text('5000 EGP'), findsOneWidget);
      expect(find.text('Period #2 Disbursement'), findsOneWidget);
      expect(find.text('Period #9 Disbursement'), findsOneWidget);
      expect(find.text('2500 EGP'), findsNWidgets(2));
    });

    testWidgets('6. MemberPeriodTimelineView renders period projections and net deltas', (tester) async {
      final timeline = MemberPeriodProjectionModel(
        projectionId: 'mpp_cairo_123',
        tenantId: 'tenant_cairo',
        memberUid: 'mem_alice',
        allocationId: 'alloc_cairo_123',
        allocationUnitId: 'unit_cairo_123',
        positionNumber: 2,
        totalPeriods: 2,
        periodicContributionMinor: 50000,
        totalObligationMinor: 100000,
        totalEntitlementMinor: 100000,
        currency: 'EGP',
        periods: [
          const MemberPeriodDetailModel(
            periodNumber: 1,
            contribution: PeriodContributionDetailModel(
              periodNumber: 1,
              dueAmountMinor: 50000,
              status: 'SCHEDULED',
            ),
            payout: MemberPeriodPayoutDetailModel(
              entitledAmountMinor: 50000,
              basisPoints: 5000,
              isPayoutPeriod: true,
              isCenter: false,
              mirrorPeriod: 2,
            ),
            netEntitlementDeltaMinor: 0,
          ),
          const MemberPeriodDetailModel(
            periodNumber: 2,
            contribution: PeriodContributionDetailModel(
              periodNumber: 2,
              dueAmountMinor: 50000,
              status: 'SCHEDULED',
            ),
            payout: MemberPeriodPayoutDetailModel(
              entitledAmountMinor: 50000,
              basisPoints: 5000,
              isPayoutPeriod: true,
              isCenter: false,
              mirrorPeriod: 1,
            ),
            netEntitlementDeltaMinor: 0,
          ),
        ],
        isProjection: true,
        classification: 'DERIVED_PROJECTION',
        generatedAt: DateTime.now(),
      );

      await tester.pumpWidget(testableWidget(
        MemberPeriodTimelineView(
          controller: controller,
          timelineOverride: timeline,
        ),
      ));

      expect(find.text('Member Period Timeline'), findsOneWidget);
      expect(find.text('Position #2'), findsOneWidget);
      expect(find.text('2 Periods Total'), findsOneWidget);
      expect(find.text('Period #1'), findsOneWidget);
      expect(find.text('Period #2'), findsOneWidget);
      expect(find.text('Net 0 EGP'), findsNWidgets(2));
    });

    testWidgets('7. CyclePeriodReadinessView renders unit cycle pot and balance', (tester) async {
      final cycleProj = CyclePeriodProjectionModel(
        projectionId: 'cpp_cairo_123',
        tenantId: 'tenant_cairo',
        allocationUnitId: 'unit_cairo_123',
        memberCount: 10,
        periodicContributionMinor: 50000,
        totalEntitlementMinor: 500000,
        totalPotMinor: 5000000,
        currency: 'EGP',
        periods: [
          const CyclePeriodSummaryModel(
            periodNumber: 1,
            expectedContributionPoolMinor: 500000,
            expectedDisbursementPoolMinor: 500000,
            payoutSlots: [
              PeriodPayoutSlotModel(
                positionNumber: 1,
                amountMinor: 250000,
                basisPoints: 5000,
                isCenter: false,
                mirrorPosition: 10,
              ),
            ],
            isBalanced: true,
          ),
        ],
        isProjection: true,
        classification: 'DERIVED_PROJECTION',
        generatedAt: DateTime.now(),
      );

      await tester.pumpWidget(testableWidget(
        CyclePeriodReadinessView(
          controller: controller,
          projectionOverride: cycleProj,
        ),
      ));

      expect(find.text('Cycle Period Projections'), findsOneWidget);
      expect(find.text('10 Members (N = 10)'), findsOneWidget);
      expect(find.text('50000 EGP'), findsOneWidget);
      expect(find.text('Balanced (50/50 Symmetrical)'), findsOneWidget);
    });

    testWidgets('8. CentralPoolShellView tab switching', (tester) async {
      await tester.pumpWidget(testableWidget(
        CentralPoolShellView(controller: controller),
      ));

      expect(find.text('Central Pool Platform'), findsOneWidget);
      expect(find.text('Central Pool Participation'), findsOneWidget);

      // Tap on Obligation Tab
      await tester.tap(find.text('Obligation'));
      await tester.pumpAndSettle();
      expect(find.text('Financial Obligation Record'), findsOneWidget);

      // Tap on Schedule Tab
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Contribution Schedule'), findsOneWidget);

      // Tap on Entitlement Tab
      await tester.tap(find.text('Entitlement'));
      await tester.pumpAndSettle();
      expect(find.text('Payout Entitlement Projection'), findsOneWidget);

      // Tap on Timeline Tab
      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      expect(find.text('Member Period Timeline'), findsOneWidget);

      // Tap on Cycle Tab
      await tester.tap(find.text('Cycle'));
      await tester.pumpAndSettle();
      expect(find.text('Cycle Period Projections'), findsOneWidget);
    });
  });
}
