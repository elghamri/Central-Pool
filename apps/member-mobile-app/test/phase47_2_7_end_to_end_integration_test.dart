import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/data/gameya_repository.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/consumer_home_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/circle_room_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/financial_action_flow_view.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_gameya_repository.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_firestore_service.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_auth_service.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_controller.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_state.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 47.2.7 — Consumer Game\'ya End-to-End Integration & State-Machine Forensic Suite', () {
    // =========================================================================
    // TEST 1: Authenticated Identity Survives Complete Navigation
    // =========================================================================
    test('TEST 1: Authenticated identity survives complete navigation', () async {
      final firestore = FirebaseFirestoreService();
      final auth = FirebaseAuthService();
      await auth.signInWithPhone(phone: '01005550192', code: '123456');
      final authUid = auth.currentUser!.uid;

      // Seed a forming circle
      await firestore.setDocument('gameya_circles', 'CIRCLE-E2E-01', {
        'circleId': 'CIRCLE-E2E-01',
        'tenantId': 'default_tenant',
        'name': 'E2E Test Circle',
        'goalCategory': 'Savings',
        'monthlyContributionMinor': 50000,
        'memberCount': 4,
        'currentPeriod': 1,
        'totalPoolMinor': 200000,
        'allocationMode': 'sequential',
        'status': 'FORMING',
        'organizerId': 'usr-other-organizer',
        'organizerName': 'Other Organizer',
      });
      await firestore.setDocument('gameya_circles/CIRCLE-E2E-01/slots', 'slot_1', {
        'slotNumber': 1,
        'payoutAmountMinor': 200000,
        'status': 'AVAILABLE',
      });

      final repo = FirebaseGameyaRepository(firestoreService: firestore, authService: auth);
      final controller = GameyaController(
        repository: repo,
        currentUserId: authUid,
        autoLoad: false,
      );
      await controller.loadInitialData();

      // Join circle with slot 1
      final joinResult = await controller.joinCircleWithSlot(circleId: 'CIRCLE-E2E-01', slotNumber: 1);
      expect(joinResult, isTrue);

      final state = controller.value as GameyaLoaded;
      final joinedCircle = state.hubSummary.activeCircles.firstWhere((c) => c.id == 'CIRCLE-E2E-01');
      expect(joinedCircle.currentUserSlotPosition, equals(1));
      expect(joinedCircle.slots.first.assignedMemberId, equals(authUid));
      expect(joinedCircle.slots.first.assignedMemberId, isNot(equals('usr-current')));
    });

    // =========================================================================
    // TEST 2: Selected circleId Survives Complete Navigation
    // =========================================================================
    testWidgets('TEST 2: Selected circleId survives complete navigation', (tester) async {
      final testCircle = GameyaCircle(
        id: 'CIRCLE-NAV-777',
        name: 'Navigation Test Circle',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        currentPeriod: 1,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Organizer',
        organizerId: 'usr-org',
        currentUserSlotPosition: 1,
        slots: const [
          GameyaSlot(slotNumber: 1, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1', isCurrentUser: true, isClaimed: true, paymentStatus: SlotPaymentStatus.pending),
        ],
      );

      final controller = GameyaController(
        repository: _SingleCircleRepo(testCircle),
        currentUserId: 'usr-nav-tester',
        autoLoad: false,
      );
      await controller.loadInitialData();

      // Open Circle Room for CIRCLE-NAV-777
      controller.selectCircleRoom('CIRCLE-NAV-777');
      expect(controller.value, isA<GameyaLoaded>());
      final loaded = controller.value as GameyaLoaded;
      expect(loaded.selectedCircleRoom?.id, equals('CIRCLE-NAV-777'));

      await tester.pumpWidget(
        MaterialApp(
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-NAV-777',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Navigation Test Circle'), findsWidgets);
    });

    // =========================================================================
    // TEST 3: Selected slotNumber Survives Complete Navigation
    // =========================================================================
    test('TEST 3: Selected slotNumber survives complete navigation', () async {
      final testCircle = GameyaCircle(
        id: 'CIRCLE-SLOT-333',
        name: 'Slot 3 Circle',
        goalCategory: 'Wedding',
        monthlyContributionMinor: 50000,
        totalPeriods: 6,
        currentPeriod: 1,
        totalPoolMinor: 300000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Organizer',
        organizerId: 'usr-org',
        slots: [
          const GameyaSlot(slotNumber: 1, payoutAmountMinor: 300000, scheduledMonthName: 'Month 1', isClaimed: true),
          const GameyaSlot(slotNumber: 2, payoutAmountMinor: 300000, scheduledMonthName: 'Month 2', isClaimed: true),
          GameyaSlot.open(slotNumber: 3, payoutAmountMinor: 300000, scheduledMonthName: 'Month 3'),
          GameyaSlot.open(slotNumber: 4, payoutAmountMinor: 300000, scheduledMonthName: 'Month 4'),
          GameyaSlot.open(slotNumber: 5, payoutAmountMinor: 300000, scheduledMonthName: 'Month 5'),
          GameyaSlot.open(slotNumber: 6, payoutAmountMinor: 300000, scheduledMonthName: 'Month 6'),
        ],
      );

      final controller = GameyaController(
        repository: _SingleCircleRepo(testCircle, profileUserId: 'usr-slot-tester'),
        currentUserId: 'usr-slot-tester',
        autoLoad: false,
      );
      await controller.loadInitialData();

      final joined = await controller.joinCircleWithSlot(circleId: 'CIRCLE-SLOT-333', slotNumber: 3);
      expect(joined, isTrue);

      final loaded = controller.value as GameyaLoaded;
      final circle = loaded.hubSummary.activeCircles.firstWhere((c) => c.id == 'CIRCLE-SLOT-333');
      expect(circle.currentUserSlotPosition, equals(3));
      expect(circle.slots[2].slotNumber, equals(3));
      expect(circle.slots[2].isCurrentUser, isTrue);
    });

    // =========================================================================
    // TEST 4: Missing Circle Fails Closed
    // =========================================================================
    testWidgets('TEST 4: Missing circle fails closed in UI and controller', (tester) async {
      final controller = GameyaController(autoLoad: false);
      await controller.loadInitialData();

      await tester.pumpWidget(
        MaterialApp(
          home: FinancialActionFlowView(
            controller: controller,
            circleId: 'MISSING-CIRCLE-ID',
            actionType: FinancialActionType.contribution,
            onFinish: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Record Not Found'), findsOneWidget);
    });

    // =========================================================================
    // TEST 5: Missing Slot Fails Closed
    // =========================================================================
    test('TEST 5: Missing slot returns 0 and fails closed', () {
      final circle = GameyaCircle(
        id: 'CIRCLE-SINGLE-SLOT',
        name: 'Single Slot',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Organizer',
        slots: const [
          GameyaSlot(slotNumber: 1, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1'),
        ],
      );

      expect(circle.payoutAmountForSlotInPeriod(99, 1), equals(0));
      expect(circle.isPayoutDueForSlotInPeriod(99, 1), isFalse);
    });

    // =========================================================================
    // TEST 6: Network Failure Never Activates Fixtures
    // =========================================================================
    test('TEST 6: Network failure never activates fixtures in production repository', () async {
      final failingFirestore = _FailingFirestore();
      final auth = FirebaseAuthService();
      final prodRepo = FirebaseGameyaRepository(firestoreService: failingFirestore, authService: auth);

      expect(() => prodRepo.fetchAllCircles(), throwsA(isA<Exception>()));
    });

    // =========================================================================
    // TEST 7: Empty Authoritative Data Never Activates Fixtures
    // =========================================================================
    test('TEST 7: Empty authoritative data returns empty list and does NOT load fixtures', () async {
      final emptyFirestore = FirebaseFirestoreService();
      final auth = FirebaseAuthService();
      final prodRepo = FirebaseGameyaRepository(firestoreService: emptyFirestore, authService: auth);

      final circles = await prodRepo.fetchAllCircles();
      expect(circles, isEmpty);
    });

    // =========================================================================
    // TEST 8: Organizer Authorization Uses Authenticated UID
    // =========================================================================
    test('TEST 8: Organizer authorization uses authenticated UID', () {
      final circle = GameyaCircle(
        id: 'C-ORG-01',
        name: 'Live Circle',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Verified Leader',
        organizerId: 'usr-verified-leader-99',
        slots: const [],
      );

      expect(circle.isOrganizer('usr-verified-leader-99'), isTrue);
      expect(circle.isOrganizer('usr-other-person-12'), isFalse);
    });

    // =========================================================================
    // TEST 9: Mock Identity Cannot Authorize Production Organizer Controls
    // =========================================================================
    test('TEST 9: Mock identity cannot authorize production organizer controls', () {
      final mockCircle = GameyaCircle(
        id: 'C-MOCK-01',
        name: 'Mock Circle',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Ahmed Mansour',
        organizerId: 'usr-current',
        slots: const [],
      );

      // Real user with production UID should not be recognized as organizer of mock circle
      expect(mockCircle.isOrganizer('usr-prod-real-member'), isFalse);
    });

    // =========================================================================
    // TEST 10: Runtime Payout Reads slot.payoutAmountMinor
    // =========================================================================
    test('TEST 10: Runtime payout reads authoritative slot.payoutAmountMinor', () {
      final circle = GameyaCircle(
        id: 'C-PAYOUT-01',
        name: 'Exact Payout Circle',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        slots: const [
          GameyaSlot(slotNumber: 1, payoutAmountMinor: 100000, scheduledMonthName: 'Month 1', pairedSlotNumber: 4),
          GameyaSlot(slotNumber: 2, payoutAmountMinor: 100000, scheduledMonthName: 'Month 2', pairedSlotNumber: 3),
          GameyaSlot(slotNumber: 3, payoutAmountMinor: 100000, scheduledMonthName: 'Month 3', pairedSlotNumber: 2),
          GameyaSlot(slotNumber: 4, payoutAmountMinor: 100000, scheduledMonthName: 'Month 4', pairedSlotNumber: 1),
        ],
      );

      expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(100000));
      expect(circle.payoutAmountForSlotInPeriod(2, 2), equals(100000));
    });

    // =========================================================================
    // TEST 11: Runtime Code Does Not Derive Payout from totalPool / 2
    // =========================================================================
    test('TEST 11: Runtime payout strictly respects slot value even if distinct from formula', () {
      // Slot has custom persisted amount 123456
      final circle = GameyaCircle(
        id: 'C-PAYOUT-CUSTOM',
        name: 'Custom Persisted Payout',
        goalCategory: 'Tech',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        slots: const [
          GameyaSlot(slotNumber: 1, payoutAmountMinor: 123456, scheduledMonthName: 'Month 1'),
        ],
      );

      // Verifies runtime method reads persisted value 123456, not totalPoolMinor ~/ 2 (100000)
      expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(123456));
    });

    // =========================================================================
    // TEST 12: Safety Lock Blocks Contribution
    // =========================================================================
    test('TEST 12: Financial Safety Lock blocks contribution action', () async {
      final controller = GameyaController(isSafetyLockActive: true, autoLoad: false);
      await controller.loadInitialData();

      final result = await controller.submitContributionPayment(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 50000,
      );
      expect(result, isFalse);
    });

    // =========================================================================
    // TEST 13: Safety Lock Blocks Payout
    // =========================================================================
    test('TEST 13: Financial Safety Lock blocks payout disbursement', () async {
      final controller = GameyaController(isSafetyLockActive: true, autoLoad: false);
      await controller.loadInitialData();

      final result = await controller.claimPayoutDisbursement(
        circleId: 'CIRCLE-FAM-2026',
        amountMinor: 500000,
        destinationAccount: 'Bank Account',
      );
      expect(result, isFalse);
    });

    // =========================================================================
    // TEST 14: Offline State Cannot Falsely Complete Financial Action
    // =========================================================================
    testWidgets('TEST 14: Offline mode renders explicit banner and warns user', (tester) async {
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
    // TEST 15: REAL_MONEY_ENABLED Remains False
    // =========================================================================
    test('TEST 15: REAL_MONEY_ENABLED remains strictly false in platform gate configuration', () {
      const gate = CommercialGateConfiguration();
      expect(gate.realMoneyEnabled, isFalse);
      expect(gate.canActivateRealMoney, isFalse);
    });

    // =========================================================================
    // TEST 16: Stale Circle A Cannot Appear After Selecting Circle B
    // =========================================================================
    test('TEST 16: Stale Circle A is replaced cleanly when selecting Circle B', () async {
      final circleA = GameyaCircle(
        id: 'CIRCLE-A',
        name: 'Circle Alpha',
        goalCategory: 'Tech',
        monthlyContributionMinor: 25000,
        totalPeriods: 4,
        totalPoolMinor: 100000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Alpha Org',
        slots: const [],
      );

      final circleB = GameyaCircle(
        id: 'CIRCLE-B',
        name: 'Circle Beta',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 6,
        totalPoolMinor: 300000,
        startDate: DateTime(2026, 2, 1),
        organizerName: 'Beta Org',
        slots: const [],
      );

      final controller = GameyaController(
        repository: _MultiCircleRepo([circleA, circleB]),
        autoLoad: false,
      );
      await controller.loadInitialData();

      // 1. Select Circle A
      controller.selectCircleRoom('CIRCLE-A');
      var state = controller.value as GameyaLoaded;
      expect(state.selectedCircleRoom?.id, equals('CIRCLE-A'));
      expect(state.selectedCircleRoom?.name, equals('Circle Alpha'));

      // 2. Select Circle B
      controller.selectCircleRoom('CIRCLE-B');
      state = controller.value as GameyaLoaded;
      expect(state.selectedCircleRoom?.id, equals('CIRCLE-B'));
      expect(state.selectedCircleRoom?.name, equals('Circle Beta'));

      // 3. Select Invalid Circle
      controller.selectCircleRoom('INVALID-ID');
      state = controller.value as GameyaLoaded;
      expect(state.selectedCircleRoom, isNull);
    });

    // =========================================================================
    // TEST 17: Logout Clears Authoritative Session State
    // =========================================================================
    test('TEST 17: Logout clears session storage and transitions to Unauthenticated', () async {
      final storage = SecureSessionStorage();
      final client = ApiClient(sessionStorage: storage);
      final auth = AuthController(apiClient: client, sessionStorage: storage);

      final session = UserSession(
        userId: 'usr-logout-test',
        email: 'test@gameya.eg',
        fullName: 'Test User',
        tenantId: 'TENANT-01',
        role: UserRole.member,
        accessToken: 'token-123',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      await storage.saveSession(session);
      await auth.initialize();
      expect(auth.value, isA<Authenticated>());

      await auth.logout();
      expect(auth.value, isA<Unauthenticated>());
      expect(await storage.getSession(), isNull);
    });

    // =========================================================================
    // TEST 18: Unauthenticated User Cannot Reach Protected Consumer Actions
    // =========================================================================
    testWidgets('TEST 18: Unauthenticated state displays WelcomeScreen, not consumer shell', (tester) async {
      final storage = SecureSessionStorage();
      final client = ApiClient(sessionStorage: storage);
      final auth = AuthController(apiClient: client, sessionStorage: storage);
      await auth.initialize();

      await tester.pumpWidget(
        CollaborativeFinanceApp(authController: auth),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('welcome_screen')), findsOneWidget);
      expect(find.byKey(const ValueKey('consumer_gameya_shell')), findsNothing);
    });

    // =========================================================================
    // TEST 19: Unauthorized Member Cannot Access Organizer Controls
    // =========================================================================
    testWidgets('TEST 19: Unauthorized peer member does not see organizer control card', (tester) async {
      final circle = GameyaCircle(
        id: 'CIRCLE-PEER-TEST',
        name: 'Peer View Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Real Organizer',
        organizerId: 'usr-organizer-true',
        currentUserSlotPosition: 2, // Current user is peer in Slot 2
        slots: const [
          GameyaSlot(slotNumber: 1, assignedMemberId: 'usr-organizer-true', isClaimed: true, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1'),
          GameyaSlot(slotNumber: 2, assignedMemberId: 'usr-peer-member-88', isCurrentUser: true, isClaimed: true, payoutAmountMinor: 200000, scheduledMonthName: 'Month 2'),
        ],
      );

      final controller = GameyaController(
        repository: _SingleCircleRepo(circle),
        currentUserId: 'usr-peer-member-88',
        autoLoad: false,
      );
      await controller.loadInitialData();
      controller.selectCircleRoom('CIRCLE-PEER-TEST');

      await tester.pumpWidget(
        MaterialApp(
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-PEER-TEST',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Organizer panel title is "ORGANIZER CONTROLS"
      expect(find.text('ORGANIZER CONTROLS'), findsNothing);
    });

    // =========================================================================
    // TEST 20: Arabic RTL Navigation Preserves Identifiers and State
    // =========================================================================
    testWidgets('TEST 20: Arabic RTL navigation preserves identifiers and state', (tester) async {
      final circle = GameyaCircle(
        id: 'CIRCLE-RTL-999',
        name: 'جمعية الادخار العائلية',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        currentPeriod: 1,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'طارق منصور',
        organizerId: 'usr-tariq',
        currentUserSlotPosition: 1,
        slots: const [
          GameyaSlot(slotNumber: 1, payoutAmountMinor: 200000, scheduledMonthName: 'شهر 1', isCurrentUser: true, isClaimed: true),
        ],
      );

      final controller = GameyaController(
        repository: _SingleCircleRepo(circle),
        currentUserId: 'usr-rtl-user',
        autoLoad: false,
      );
      await controller.loadInitialData();

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ConsumerHomeView(controller: controller),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('جمعية الادخار العائلية'), findsWidgets);
    });

    // =========================================================================
    // CORRECTION TESTS (TEST A THROUGH TEST G)
    // =========================================================================
    group('Phase 47.2.7 — Forensic Correction Tests (TEST A to TEST G)', () {
      test('TEST A: Authenticated UID and profile.id mismatch cannot authorize a protected operation', () async {
        final circle = GameyaCircle(
          id: 'CIRCLE-MISMATCH-1',
          name: 'Mismatch Protection Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 4,
          currentPeriod: 1,
          totalPoolMinor: 200000,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'Organizer',
          organizerId: 'usr-org',
          slots: [
            GameyaSlot.open(slotNumber: 1, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1'),
            GameyaSlot.open(slotNumber: 2, payoutAmountMinor: 200000, scheduledMonthName: 'Month 2'),
          ],
        );

        final controller = GameyaController(
          repository: _MismatchProfileRepo(circle, staleProfileId: 'usr-stale-attacker'),
          currentUserId: 'usr-auth-alice',
          autoLoad: false,
        );
        await controller.loadInitialData();

        // Join should fail closed due to identity mismatch
        final joinResult = await controller.joinCircleWithSlot(circleId: 'CIRCLE-MISMATCH-1', slotNumber: 1);
        expect(joinResult, isFalse);

        // Contribution should fail closed
        final contribResult = await controller.submitContributionPayment(circleId: 'CIRCLE-MISMATCH-1', amountMinor: 50000);
        expect(contribResult, isFalse);

        // Payout should fail closed
        final payoutResult = await controller.claimPayoutDisbursement(
          circleId: 'CIRCLE-MISMATCH-1',
          amountMinor: 200000,
          destinationAccount: 'EG1234567890',
        );
        expect(payoutResult, isFalse);
      });

      test('TEST B: Join operation cannot report success without authoritative persistence', () async {
        final circle = GameyaCircle(
          id: 'CIRCLE-REJECT-PERSIST',
          name: 'Persistence Rejection Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 4,
          currentPeriod: 1,
          totalPoolMinor: 200000,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'Organizer',
          organizerId: 'usr-org',
          slots: [
            GameyaSlot.open(slotNumber: 1, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1'),
          ],
        );

        final controller = GameyaController(
          repository: _RejectingPersistenceRepo(circle),
          currentUserId: 'usr-valid-alice',
          autoLoad: false,
        );
        await controller.loadInitialData();

        final joinResult = await controller.joinCircleWithSlot(circleId: 'CIRCLE-REJECT-PERSIST', slotNumber: 1);
        expect(joinResult, isFalse);

        final state = controller.value as GameyaLoaded;
        expect(state.hubSummary.activeCircles.any((c) => c.id == 'CIRCLE-REJECT-PERSIST'), isFalse);
      });

      test('TEST C: Join operation fails closed on network failure', () async {
        final circle = GameyaCircle(
          id: 'CIRCLE-NET-FAIL',
          name: 'Network Failure Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 4,
          currentPeriod: 1,
          totalPoolMinor: 200000,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'Organizer',
          organizerId: 'usr-org',
          slots: [
            GameyaSlot.open(slotNumber: 1, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1'),
          ],
        );

        final controller = GameyaController(
          repository: _ThrowingNetworkRepo(circle),
          currentUserId: 'usr-valid-alice',
          autoLoad: false,
        );
        await controller.loadInitialData();

        final joinResult = await controller.joinCircleWithSlot(circleId: 'CIRCLE-NET-FAIL', slotNumber: 1);
        expect(joinResult, isFalse);

        final state = controller.value as GameyaLoaded;
        expect(state.hubSummary.activeCircles.any((c) => c.id == 'CIRCLE-NET-FAIL'), isFalse);
      });

      test('TEST D: Join operation fails closed when selected slot disappears', () async {
        final circle = GameyaCircle(
          id: 'CIRCLE-VANISHED-SLOT',
          name: 'Vanished Slot Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 2,
          currentPeriod: 1,
          totalPoolMinor: 100000,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'Organizer',
          organizerId: 'usr-org',
          slots: [
            GameyaSlot.open(slotNumber: 1, payoutAmountMinor: 100000, scheduledMonthName: 'Month 1'),
            GameyaSlot.open(slotNumber: 2, payoutAmountMinor: 100000, scheduledMonthName: 'Month 2'),
          ],
        );

        final controller = GameyaController(
          repository: _SingleCircleRepo(circle),
          currentUserId: 'usr-valid-alice',
          autoLoad: false,
        );
        await controller.loadInitialData();

        // Attempting to join non-existent slot 99
        final joinResult = await controller.joinCircleWithSlot(circleId: 'CIRCLE-VANISHED-SLOT', slotNumber: 99);
        expect(joinResult, isFalse);
      });

      test('TEST E: Duplicate/competing slot claim cannot produce two successful enrollments', () async {
        final circle = GameyaCircle(
          id: 'CIRCLE-RACE-SLOT',
          name: 'Race Condition Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 2,
          currentPeriod: 1,
          totalPoolMinor: 100000,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'Organizer',
          organizerId: 'usr-org',
          slots: const [
            GameyaSlot(
              slotNumber: 1,
              assignedMemberId: 'usr-first-winner',
              assignedMemberName: 'Winner',
              isCurrentUser: false,
              isClaimed: true,
              payoutAmountMinor: 100000,
              scheduledMonthName: 'Month 1',
            ),
            GameyaSlot(
              slotNumber: 2,
              assignedMemberId: null,
              isCurrentUser: false,
              isClaimed: false,
              payoutAmountMinor: 100000,
              scheduledMonthName: 'Month 2',
            ),
          ],
        );

        final controller = GameyaController(
          repository: _SingleCircleRepo(circle),
          currentUserId: 'usr-second-claimant',
          autoLoad: false,
        );
        await controller.loadInitialData();

        // Attempting to claim already claimed slot 1
        final duplicateClaim = await controller.joinCircleWithSlot(circleId: 'CIRCLE-RACE-SLOT', slotNumber: 1);
        expect(duplicateClaim, isFalse);
      });

      test('TEST F: Payout operation uses authenticated UID only', () async {
        final circle = GameyaCircle(
          id: 'CIRCLE-PAYOUT-AUTH',
          name: 'Payout Auth Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 2,
          currentPeriod: 1,
          totalPoolMinor: 100000,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'Organizer',
          organizerId: 'usr-org',
          currentUserSlotPosition: 1,
          slots: const [
            GameyaSlot(
              slotNumber: 1,
              assignedMemberId: 'usr-auth-alice',
              assignedMemberName: 'Alice',
              isCurrentUser: true,
              isClaimed: true,
              payoutAmountMinor: 100000,
              scheduledMonthName: 'Month 1',
            ),
          ],
        );

        final controller = GameyaController(
          repository: _SingleCircleRepo(circle),
          currentUserId: 'usr-auth-alice',
          autoLoad: false,
        );
        await controller.loadInitialData();

        // Attempting payout claim with mismatched claimingMemberId
        final attackerClaim = await controller.claimPayoutDisbursement(
          circleId: 'CIRCLE-PAYOUT-AUTH',
          amountMinor: 100000,
          destinationAccount: 'EG1234567890',
          claimingMemberId: 'usr-attacker-bob',
        );
        expect(attackerClaim, isFalse);
      });

      test('TEST G: Contribution operation uses authenticated UID only', () async {
        final circle = GameyaCircle(
          id: 'CIRCLE-CONTRIB-AUTH',
          name: 'Contrib Auth Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: 2,
          currentPeriod: 1,
          totalPoolMinor: 100000,
          startDate: DateTime(2026, 1, 1),
          organizerName: 'Organizer',
          organizerId: 'usr-org',
          currentUserSlotPosition: 1,
          slots: const [
            GameyaSlot(
              slotNumber: 1,
              assignedMemberId: 'usr-auth-alice',
              assignedMemberName: 'Alice',
              isCurrentUser: true,
              isClaimed: true,
              payoutAmountMinor: 100000,
              scheduledMonthName: 'Month 1',
            ),
          ],
        );

        // Mismatched profile ID should be blocked
        final mismatchController = GameyaController(
          repository: _MismatchProfileRepo(circle, staleProfileId: 'usr-attacker-bob'),
          currentUserId: 'usr-auth-alice',
          autoLoad: false,
        );
        await mismatchController.loadInitialData();

        final blockedContrib = await mismatchController.submitContributionPayment(
          circleId: 'CIRCLE-CONTRIB-AUTH',
          amountMinor: 50000,
        );
        expect(blockedContrib, isFalse);

        // Matching authenticated user succeeds
        final validController = GameyaController(
          repository: _SingleCircleRepo(circle, profileUserId: 'usr-auth-alice'),
          currentUserId: 'usr-auth-alice',
          autoLoad: false,
        );
        await validController.loadInitialData();

        final validContrib = await validController.submitContributionPayment(
          circleId: 'CIRCLE-CONTRIB-AUTH',
          amountMinor: 50000,
        );
        expect(validContrib, isTrue);
      });
    });
  });
}

class _SingleCircleRepo extends GameyaRepository {
  final GameyaCircle circle;
  final String? profileUserId;
  _SingleCircleRepo(this.circle, {this.profileUserId});

  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => [circle];

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    return ConsumerHubSummary(
      memberName: 'Test Member',
      activeCircles: circle.isUserEnrolled ? [circle] : [],
      totalMonthlyDuesMinor: circle.isUserEnrolled ? circle.monthlyContributionMinor : 0,
      nextPaymentDueAmountMinor: circle.isUserEnrolled ? circle.monthlyContributionMinor : 0,
      nextPayoutAmountMinor: circle.slots.isNotEmpty ? circle.slots.first.payoutAmountMinor : 0,
    );
  }

  @override
  Future<List<ActivityTimelineItem>> fetchActivityTimeline() async => [];

  @override
  Future<ConsumerProfile> fetchConsumerProfile() async {
    return ConsumerProfile(
      id: profileUserId ?? 'usr-test',
      fullName: 'Test Member',
      email: 'member@gameya.eg',
      phone: '+20 100 000 0000',
      bankAccountName: 'National Bank',
      bankAccountMasked: '**** 1111',
    );
  }
}

class _MultiCircleRepo extends GameyaRepository {
  final List<GameyaCircle> circles;
  _MultiCircleRepo(this.circles);

  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => circles;

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    final active = circles.where((c) => c.isUserEnrolled).toList();
    return ConsumerHubSummary(
      memberName: 'Multi Member',
      activeCircles: active,
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
      id: 'usr-multi',
      fullName: 'Multi Member',
      email: 'multi@gameya.eg',
      phone: '+20 100 000 0000',
      bankAccountName: 'Bank',
      bankAccountMasked: '**** 2222',
    );
  }
}

class _FailingFirestore extends FirebaseFirestoreService {
  @override
  Future<FirestoreQuerySnapshot> getCollection(String collectionPath) async {
    throw Exception('ERR_NETWORK_UNAVAILABLE: Firestore transport down');
  }

  @override
  Future<FirestoreDocSnapshot> getDocument(String collectionPath, String documentId) async {
    throw Exception('ERR_NETWORK_UNAVAILABLE: Firestore transport down');
  }
}

class _MismatchProfileRepo extends GameyaRepository {
  final GameyaCircle circle;
  final String staleProfileId;
  _MismatchProfileRepo(this.circle, {required this.staleProfileId});

  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => [circle];

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    return ConsumerHubSummary(
      memberName: 'Stale User',
      activeCircles: circle.isUserEnrolled ? [circle] : [],
      totalMonthlyDuesMinor: circle.isUserEnrolled ? circle.monthlyContributionMinor : 0,
      nextPaymentDueAmountMinor: circle.isUserEnrolled ? circle.monthlyContributionMinor : 0,
      nextPayoutAmountMinor: circle.slots.isNotEmpty ? circle.slots.first.payoutAmountMinor : 0,
    );
  }

  @override
  Future<List<ActivityTimelineItem>> fetchActivityTimeline() async => [];

  @override
  Future<ConsumerProfile> fetchConsumerProfile() async {
    return ConsumerProfile(
      id: staleProfileId,
      fullName: 'Stale User',
      email: 'stale@gameya.eg',
      phone: '+20 100 000 0000',
      bankAccountName: 'Bank',
      bankAccountMasked: '**** 9999',
    );
  }
}

class _RejectingPersistenceRepo extends GameyaRepository {
  final GameyaCircle circle;
  _RejectingPersistenceRepo(this.circle);

  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => [circle];

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    return ConsumerHubSummary(
      memberName: 'Alice',
      activeCircles: circle.isUserEnrolled ? [circle] : [],
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
      id: 'usr-valid-alice',
      fullName: 'Alice',
      email: 'alice@gameya.eg',
      phone: '+20 100 000 0000',
      bankAccountName: 'Bank',
      bankAccountMasked: '**** 1111',
    );
  }

  @override
  Future<bool> joinCircleSlot({required String circleId, required int slotNumber}) async {
    return false; // Server rejected persistence
  }
}

class _ThrowingNetworkRepo extends GameyaRepository {
  final GameyaCircle circle;
  _ThrowingNetworkRepo(this.circle);

  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => [circle];

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    return ConsumerHubSummary(
      memberName: 'Alice',
      activeCircles: circle.isUserEnrolled ? [circle] : [],
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
      id: 'usr-valid-alice',
      fullName: 'Alice',
      email: 'alice@gameya.eg',
      phone: '+20 100 000 0000',
      bankAccountName: 'Bank',
      bankAccountMasked: '**** 1111',
    );
  }

  @override
  Future<bool> joinCircleSlot({required String circleId, required int slotNumber}) async {
    throw Exception('ERR_NETWORK_TIMEOUT: Firestore connection timed out');
  }
}
