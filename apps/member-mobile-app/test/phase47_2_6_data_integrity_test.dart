import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_components/ui_components.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/data/gameya_repository.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/consumer_home_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/circle_discovery_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/financial_action_flow_view.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';

/// Mock repository that returns empty circles to verify empty-state integrity
class EmptyDataGameyaRepository extends GameyaRepository {
  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => [];

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    return const ConsumerHubSummary(
      memberName: 'Test Member',
      activeCircles: [],
      totalMonthlyDuesMinor: 0,
      nextPaymentDueAmountMinor: 0,
      nextPayoutAmountMinor: 0,
    );
  }

  @override
  Future<List<ActivityTimelineItem>> fetchActivityTimeline() async => [];

  @override
  Future<ConsumerProfile> fetchConsumerProfile() async {
    return const ConsumerProfile(
      id: 'usr-authenticated-999',
      fullName: 'Real Member',
      email: 'member@gameya.eg',
      phone: '+20 100 000 0000',
      isIdentityVerified: true,
      bankAccountName: 'National Bank of Egypt',
      bankAccountMasked: '**** 1234',
    );
  }
}

/// Mock repository that simulates network failure
class NetworkFailingGameyaRepository extends GameyaRepository {
  @override
  Future<List<GameyaCircle>> fetchAllCircles() async {
    throw const ApiException(
      statusCode: 503,
      title: 'Network / Transport Error',
      detail: 'ERR_NETWORK_UNAVAILABLE: Connection refused',
    );
  }

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    throw const ApiException(
      statusCode: 503,
      title: 'Network / Transport Error',
      detail: 'ERR_NETWORK_UNAVAILABLE: Connection refused',
    );
  }

  @override
  Future<List<ActivityTimelineItem>> fetchActivityTimeline() async {
    throw const ApiException(
      statusCode: 503,
      title: 'Network / Transport Error',
      detail: 'ERR_NETWORK_UNAVAILABLE: Connection refused',
    );
  }

  @override
  Future<ConsumerProfile> fetchConsumerProfile() async {
    throw const ApiException(
      statusCode: 503,
      title: 'Network / Transport Error',
      detail: 'ERR_NETWORK_UNAVAILABLE: Connection refused',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 47.2.6 — Consumer Game\'ya Data Integrity & State Forensic Tests', () {
    // =========================================================================
    // TEST A: Live/Authoritative Data Path Isolation
    // =========================================================================
    test('TEST A: Custom repository data is isolated and does NOT mix with fixtures', () async {
      final customCircle = GameyaCircle(
        id: 'CUSTOM-PROD-001',
        name: 'Custom Live Circle',
        goalCategory: 'Business',
        monthlyContributionMinor: 75000,
        totalPeriods: 6,
        currentPeriod: 1,
        totalPoolMinor: 450000,
        allocationMode: GameyaAllocationMode.sequential,
        status: GameyaCircleStatus.active,
        startDate: DateTime(2026, 6, 1),
        organizerName: 'Custom Organizer',
        organizerId: 'usr-custom-org',
        currentUserSlotPosition: 1,
        slots: const [
          GameyaSlot(slotNumber: 1, payoutAmountMinor: 450000, scheduledMonthName: 'Jun 2026', isCurrentUser: true),
        ],
      );

      final controller = GameyaController(
        repository: _SingleCircleRepository(customCircle),
        autoLoad: false,
      );

      await controller.loadInitialData();
      final state = controller.value;
      expect(state, isA<GameyaLoaded>());
      final loaded = state as GameyaLoaded;

      expect(loaded.hubSummary.activeCircles.length, equals(1));
      expect(loaded.hubSummary.activeCircles.first.id, equals('CUSTOM-PROD-001'));
      expect(loaded.hubSummary.activeCircles.first.name, equals('Custom Live Circle'));
      // Verifies no fixture circles bled into active list
      expect(loaded.hubSummary.activeCircles.any((c) => c.id == 'CIRCLE-FAM-2026'), isFalse);
      expect(loaded.hubSummary.activeCircles.any((c) => c.id == 'CIRCLE-CAR-2027'), isFalse);
    });

    // =========================================================================
    // TEST B: Network Failure Does NOT Produce Fixture Circles
    // =========================================================================
    test('TEST B: Network failure emits GameyaError and does NOT fall back to fixtures', () async {
      final controller = GameyaController(
        repository: NetworkFailingGameyaRepository(),
        autoLoad: false,
      );

      await controller.loadInitialData();
      final state = controller.value;

      expect(state, isA<GameyaError>());
      final error = state as GameyaError;
      expect(error.message, contains('ERR_NETWORK_UNAVAILABLE'));
    });

    testWidgets('TEST B (Widget): Network failure renders ErrorCardWidget, NOT fixtures', (tester) async {
      final controller = GameyaController(
        repository: NetworkFailingGameyaRepository(),
        autoLoad: false,
      );

      await controller.loadInitialData();

      await tester.pumpWidget(
        MaterialApp(
          home: ConsumerHomeView(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.byType(ErrorCardWidget), findsOneWidget);
      expect(find.text('Family Savings 2026'), findsNothing);
      expect(find.text('New Car Fund 2027'), findsNothing);
    });

    testWidgets('TEST B (Discovery): Network failure in Discovery renders ErrorCardWidget', (tester) async {
      final controller = GameyaController(
        repository: NetworkFailingGameyaRepository(),
        autoLoad: false,
      );

      await controller.loadInitialData();

      await tester.pumpWidget(
        MaterialApp(
          home: CircleDiscoveryView(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.byType(ErrorCardWidget), findsOneWidget);
      expect(find.text('Wedding Savings Circle'), findsNothing);
    });

    // =========================================================================
    // TEST C: Empty Authoritative Result Does NOT Produce Fixture Circles
    // =========================================================================
    testWidgets('TEST C: Empty result renders clean empty state, NOT fixtures', (tester) async {
      final controller = GameyaController(
        repository: EmptyDataGameyaRepository(),
        autoLoad: false,
      );

      await controller.loadInitialData();

      await tester.pumpWidget(
        MaterialApp(
          home: ConsumerHomeView(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('You are not enrolled in any active circles'), findsOneWidget);
      expect(find.text('Family Savings 2026'), findsNothing);
      expect(find.text('New Car Fund 2027'), findsNothing);
    });

    // =========================================================================
    // TEST D: Missing Authoritative Circle Fails Closed
    // =========================================================================
    test('TEST D (Repository): fetchCircleById returns null for missing circleId', () async {
      final repo = GameyaRepository();
      final circle = await repo.fetchCircleById('NON-EXISTENT-CIRCLE-ID');
      expect(circle, isNull);
    });

    testWidgets('TEST D (UI): FinancialActionFlowView renders empty scaffold on missing circleId', (tester) async {
      final controller = GameyaController(autoLoad: false);
      await controller.loadInitialData();

      await tester.pumpWidget(
        MaterialApp(
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'NON-EXISTENT-CIRCLE-999',
            actionType: FinancialActionType.contribution,
            onFinish: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Record Not Found'), findsOneWidget);
    });

    // =========================================================================
    // TEST E: Missing Slot Returns Zero / Non-Financial Unavailable State
    // =========================================================================
    test('TEST E: Missing slot strictly returns 0 and does NOT fabricate payout', () {
      final circle = GameyaCircle(
        id: 'C-TEST-001',
        name: 'Single Slot Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 10,
        currentPeriod: 1,
        totalPoolMinor: 500000,
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'System',
        currentUserSlotPosition: null,
        slots: const [
          GameyaSlot(
            slotNumber: 1,
            payoutAmountMinor: 250000,
            scheduledMonthName: 'Month 1',
            pairedSlotNumber: 10,
          ),
        ],
      );

      expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(250000));
      expect(circle.payoutAmountForSlotInPeriod(2, 1), equals(0)); // Missing slot -> 0
      expect(circle.payoutAmountForSlotInPeriod(99, 1), equals(0)); // Missing slot -> 0
      expect(circle.userPayoutAmountForPeriod(1), equals(0)); // Unenrolled -> 0
    });

    // =========================================================================
    // TEST F: Placeholder User ID Cannot Silently Match Real Identity
    // =========================================================================
    test('TEST F: isOrganizerCurrentUser matches exact identifier, not name substring', () {
      final circle = GameyaCircle(
        id: 'C-AHMED-ORG',
        name: 'Ahmed Circle',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        allocationMode: GameyaAllocationMode.sequential,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Ahmed Someone Else', // Name contains 'Ahmed'
        organizerId: 'usr-different-org', // ID is NOT current user
        slots: const [],
      );

      // Must be false because organizerId does not match current user ID
      expect(circle.isOrganizerCurrentUser, isFalse);
    });

    // =========================================================================
    // TEST G: Simulation Payment Fails Closed on Invalid / Missing Circle
    // =========================================================================
    test('TEST G: submitContributionPayment rejects missing circle with zero side effects', () async {
      final controller = GameyaController(autoLoad: false);
      await controller.loadInitialData();

      final result = await controller.submitContributionPayment(
        circleId: 'NON-EXISTENT-CIRCLE-ID',
        amountMinor: 50000,
      );

      expect(result, isFalse);
    });

    // =========================================================================
    // TEST H: Simulation Payout Fails Closed on Invalid / Missing Circle
    // =========================================================================
    test('TEST H: claimPayoutDisbursement rejects missing circle with zero side effects', () async {
      final controller = GameyaController(autoLoad: false);
      await controller.loadInitialData();

      final result = await controller.claimPayoutDisbursement(
        circleId: 'NON-EXISTENT-CIRCLE-ID',
        amountMinor: 500000,
        destinationAccount: 'Chase Checking',
      );

      expect(result, isFalse);
    });

    // =========================================================================
    // TEST I: Offline State Distinguishable from Live State
    // =========================================================================
    testWidgets('TEST I: Offline mode renders explicit Offline Banner', (tester) async {
      final controller = GameyaController(autoLoad: false);
      await controller.loadInitialData();

      await tester.pumpWidget(
        MaterialApp(
          home: ConsumerHomeView(
            controller: controller,
            isOffline: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Offline Mode'), findsOneWidget);
    });

    // =========================================================================
    // TEST J: Safety Lock Remains Strictly Enforced
    // =========================================================================
    test('TEST J: Financial Safety Lock blocks controller operations', () async {
      final controller = GameyaController(
        isSafetyLockActive: true,
        autoLoad: false,
      );
      await controller.loadInitialData();

      final payResult = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 50000,
      );
      expect(payResult, isFalse);

      final claimResult = await controller.claimPayoutDisbursement(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 500000,
        destinationAccount: 'Bank',
      );
      expect(claimResult, isFalse);
    });
  });
}

class _SingleCircleRepository extends GameyaRepository {
  final GameyaCircle circle;

  _SingleCircleRepository(this.circle);

  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => [circle];

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    return ConsumerHubSummary(
      memberName: 'Custom Member',
      activeCircles: [circle],
      totalMonthlyDuesMinor: circle.monthlyContributionMinor,
      nextPaymentDueAmountMinor: circle.monthlyContributionMinor,
      nextPayoutAmountMinor: circle.slots.first.payoutAmountMinor,
    );
  }

  @override
  Future<List<ActivityTimelineItem>> fetchActivityTimeline() async => [];

  @override
  Future<ConsumerProfile> fetchConsumerProfile() async {
    return const ConsumerProfile(
      id: 'usr-custom',
      fullName: 'Custom Member',
      email: 'custom@gameya.eg',
      phone: '+20 100 123 4567',
      isIdentityVerified: true,
      bankAccountName: 'National Bank of Egypt',
      bankAccountMasked: '**** 5678',
    );
  }
}
