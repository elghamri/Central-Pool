import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/data/gameya_repository.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/circle_room_view.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_gameya_repository.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_firestore_service.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_auth_service.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_controller.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_state.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 47.2.8 — Firebase Security & Runtime Data Integrity Forensic Suite', () {
    
    // =========================================================================
    // TEST 1 (Classification: B - Controller/State Integration Test): Auth UID Mismatch
    // =========================================================================
    test('1. Auth UID Mismatch: Protected operations reject mismatched authenticated UID', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-01',
        name: 'Security Test Circle',
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
        repository: _MockProfileRepo(circle, profileId: 'usr-attacker-eve'),
        currentUserId: 'usr-victim-alice',
        autoLoad: false,
      );
      await controller.loadInitialData();

      // Mismatched profile vs currentUserId must fail closed
      final joinResult = await controller.joinCircleWithSlot(circleId: 'CIRCLE-SEC-01', slotNumber: 1);
      expect(joinResult, isFalse);
    });

    // =========================================================================
    // TEST 2 (Classification: B - Controller/State Integration Test): Profile ID Tampering
    // =========================================================================
    test('2. Profile ID Tampering: Local alteration of profile ID cannot hijack operations', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-02',
        name: 'Profile Tamper Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        currentPeriod: 1,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Organizer',
        organizerId: 'usr-org',
        currentUserSlotPosition: 1,
        slots: const [
          GameyaSlot(
            slotNumber: 1,
            assignedMemberId: 'usr-valid-user',
            assignedMemberName: 'Valid Member',
            isCurrentUser: true,
            isClaimed: true,
            payoutAmountMinor: 200000,
            scheduledMonthName: 'Month 1',
          ),
        ],
      );

      final controller = GameyaController(
        repository: _MockProfileRepo(circle, profileId: 'usr-tampered-id'),
        currentUserId: 'usr-valid-user',
        autoLoad: false,
      );
      await controller.loadInitialData();

      final contribResult = await controller.submitContributionPayment(
        circleId: 'CIRCLE-SEC-02',
        amountMinor: 50000,
      );
      expect(contribResult, isFalse);
    });

    // =========================================================================
    // TEST 3 (Classification: A - True Widget Integration Test): Organizer Impersonation
    // =========================================================================
    testWidgets('3. Organizer Impersonation: Non-organizer cannot view or trigger organizer panel', (tester) async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-03',
        name: 'Organizer Guard Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        currentPeriod: 1,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Real Organizer',
        organizerId: 'usr-real-organizer-999',
        currentUserSlotPosition: 2,
        slots: const [
          GameyaSlot(slotNumber: 1, assignedMemberId: 'usr-real-organizer-999', isClaimed: true, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1'),
          GameyaSlot(slotNumber: 2, assignedMemberId: 'usr-peer-member', isCurrentUser: true, isClaimed: true, payoutAmountMinor: 200000, scheduledMonthName: 'Month 2'),
        ],
      );

      final controller = GameyaController(
        repository: _MockProfileRepo(circle, profileId: 'usr-peer-member'),
        currentUserId: 'usr-peer-member',
        autoLoad: false,
      );
      await controller.loadInitialData();
      controller.selectCircleRoom('CIRCLE-SEC-03');

      await tester.pumpWidget(
        MaterialApp(
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-SEC-03',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Organizer Controls card MUST NOT exist for peer member
      expect(find.text('ORGANIZER CONTROLS'), findsNothing);
      expect(find.text('Send Reminder'), findsNothing);
    });

    // =========================================================================
    // TEST 4 (Classification: B - Controller/State Integration Test): Occupied Slot Claim
    // =========================================================================
    test('4. Occupied Slot Claim: Attempting to join already-claimed slot fails closed', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-04',
        name: 'Occupied Slot Circle',
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
            assignedMemberId: 'usr-first-member',
            assignedMemberName: 'First Member',
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
        repository: _MockProfileRepo(circle, profileId: 'usr-second-claimant'),
        currentUserId: 'usr-second-claimant',
        autoLoad: false,
      );
      await controller.loadInitialData();

      // Attempting to claim Slot #1 (already occupied)
      final claimResult = await controller.joinCircleWithSlot(circleId: 'CIRCLE-SEC-04', slotNumber: 1);
      expect(claimResult, isFalse);
    });

    // =========================================================================
    // TEST 5 (Classification: B - Controller/State Integration Test): Duplicate Slot Claim
    // =========================================================================
    test('5. Duplicate Slot Claim: Member already enrolled cannot acquire second slot', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-05',
        name: 'Single Slot Invariant Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 3,
        currentPeriod: 1,
        totalPoolMinor: 150000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Organizer',
        organizerId: 'usr-org',
        currentUserSlotPosition: 1,
        slots: const [
          GameyaSlot(
            slotNumber: 1,
            assignedMemberId: 'usr-enrolled-member',
            assignedMemberName: 'Enrolled Member',
            isCurrentUser: true,
            isClaimed: true,
            payoutAmountMinor: 150000,
            scheduledMonthName: 'Month 1',
          ),
          GameyaSlot(
            slotNumber: 2,
            assignedMemberId: null,
            isCurrentUser: false,
            isClaimed: false,
            payoutAmountMinor: 150000,
            scheduledMonthName: 'Month 2',
          ),
          GameyaSlot(
            slotNumber: 3,
            assignedMemberId: null,
            isCurrentUser: false,
            isClaimed: false,
            payoutAmountMinor: 150000,
            scheduledMonthName: 'Month 3',
          ),
        ],
      );

      final controller = GameyaController(
        repository: _MockProfileRepo(circle, profileId: 'usr-enrolled-member'),
        currentUserId: 'usr-enrolled-member',
        autoLoad: false,
      );
      await controller.loadInitialData();

      // User in Slot 1 attempts to join Slot 2 in same circle
      final secondSlotClaim = await controller.joinCircleWithSlot(circleId: 'CIRCLE-SEC-05', slotNumber: 2);
      expect(secondSlotClaim, isFalse);
    });

    // =========================================================================
    // TEST 6 (Classification: C - Unit Test): Missing Slot Fails Closed
    // =========================================================================
    test('6. Missing Slot: Requesting non-existent slot position returns 0 and fails closed', () {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-06',
        name: 'Slot Range Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        organizerId: 'usr-org',
        slots: const [
          GameyaSlot(slotNumber: 1, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1', isClaimed: true),
          GameyaSlot(slotNumber: 2, payoutAmountMinor: 200000, scheduledMonthName: 'Month 2', isClaimed: true),
        ],
      );

      // Slot 99 does not exist
      final payoutForMissing = circle.payoutAmountForSlotInPeriod(99, 1);
      expect(payoutForMissing, equals(0));
    });

    // =========================================================================
    // TEST 7 (Classification: B - Repository Integration Test): Network Failure
    // =========================================================================
    test('7. Network Failure: Repository transport errors fail closed without corrupting state', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-07',
        name: 'Network Failure Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 2,
        totalPoolMinor: 100000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        organizerId: 'usr-org',
        slots: [
          GameyaSlot.open(slotNumber: 1, payoutAmountMinor: 100000, scheduledMonthName: 'Month 1'),
        ],
      );

      final controller = GameyaController(
        repository: _ThrowingRepo(circle),
        currentUserId: 'usr-net-user',
        autoLoad: false,
      );
      await controller.loadInitialData();

      final joinResult = await controller.joinCircleWithSlot(circleId: 'CIRCLE-SEC-07', slotNumber: 1);
      expect(joinResult, isFalse);

      final state = controller.value as GameyaLoaded;
      expect(state.hubSummary.activeCircles.any((c) => c.id == 'CIRCLE-SEC-07'), isFalse);
    });

    // =========================================================================
    // TEST 8 (Classification: B - Controller/State Integration Test): Offline Mutation Guard
    // =========================================================================
    test('8. Offline Financial Mutation: Financial Safety Lock prevents offline mutation', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-08',
        name: 'Offline Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 2,
        currentPeriod: 1,
        totalPoolMinor: 100000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        organizerId: 'usr-org',
        currentUserSlotPosition: 1,
        slots: const [
          GameyaSlot(
            slotNumber: 1,
            assignedMemberId: 'usr-offline-user',
            isCurrentUser: true,
            isClaimed: true,
            payoutAmountMinor: 100000,
            scheduledMonthName: 'Month 1',
          ),
        ],
      );

      final controller = GameyaController(
        repository: _MockProfileRepo(circle, profileId: 'usr-offline-user'),
        currentUserId: 'usr-offline-user',
        autoLoad: false,
      );
      await controller.loadInitialData();

      // Financial Safety Lock actively blocks offline mutation
      final contribBlocked = await controller.submitContributionPayment(
        circleId: 'CIRCLE-SEC-08',
        amountMinor: 50000,
        isSafetyLockActive: true,
      );
      expect(contribBlocked, isFalse);

      final payoutBlocked = await controller.claimPayoutDisbursement(
        circleId: 'CIRCLE-SEC-08',
        amountMinor: 100000,
        destinationAccount: 'EG1234567890',
        isSafetyLockActive: true,
      );
      expect(payoutBlocked, isFalse);
    });

    // =========================================================================
    // TEST 9 (Classification: C - Unit Test): Payout Field Tampering
    // =========================================================================
    test('9. Payout Field Tampering: UI consumes persisted slot amount, not client formula', () {
      // Circle totalPool = 1,000,000, but slot payout explicitly persisted as 450,000 (e.g. customized tier)
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-09',
        name: 'Tamper Proof Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 100000,
        totalPeriods: 10,
        totalPoolMinor: 1000000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        organizerId: 'usr-org',
        slots: const [
          GameyaSlot(slotNumber: 1, payoutAmountMinor: 450000, scheduledMonthName: 'Month 1', isClaimed: true),
        ],
      );

      // Must strictly read 450,000 and NOT derive 500,000 (totalPool / 2)
      expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(450000));
    });

    // =========================================================================
    // TEST 10 (Classification: C - Unit Test): Paired Slot Tampering
    // =========================================================================
    test('10. Paired Slot Tampering: Symmetrical paired chord reads persisted pairedSlotNumber', () {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-10',
        name: 'Paired Topology Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 10,
        totalPoolMinor: 500000,
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        organizerId: 'usr-org',
        slots: const [
          GameyaSlot(slotNumber: 1, payoutAmountMinor: 250000, scheduledMonthName: 'Month 1', pairedSlotNumber: 10, isClaimed: true),
          GameyaSlot(slotNumber: 2, payoutAmountMinor: 250000, scheduledMonthName: 'Month 2', pairedSlotNumber: 9, isClaimed: true),
        ],
      );

      expect(circle.slots[0].pairedSlotNumber, equals(10));
      expect(circle.slots[1].pairedSlotNumber, equals(9));
      expect(circle.primaryPayoutPeriodFor(1), equals(1));
      expect(circle.mirrorPayoutPeriodFor(1), equals(10));
    });

    // =========================================================================
    // TEST 11 (Classification: B - Controller/State Integration Test): Stale State Mutation
    // =========================================================================
    test('11. Stale State Mutation: Actions targeted for Circle A do not mutate Circle B', () async {
      final circleA = GameyaCircle(
        id: 'CIRCLE-A',
        name: 'Circle Alpha',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 2,
        currentPeriod: 1,
        totalPoolMinor: 100000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org A',
        organizerId: 'usr-org-a',
        currentUserSlotPosition: 1,
        slots: const [
          GameyaSlot(slotNumber: 1, assignedMemberId: 'usr-user-1', isCurrentUser: true, isClaimed: true, payoutAmountMinor: 100000, scheduledMonthName: 'M1'),
        ],
      );

      final circleB = GameyaCircle(
        id: 'CIRCLE-B',
        name: 'Circle Beta',
        goalCategory: 'Tech',
        monthlyContributionMinor: 20000,
        totalPeriods: 2,
        currentPeriod: 1,
        totalPoolMinor: 40000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org B',
        organizerId: 'usr-org-b',
        currentUserSlotPosition: null, // NOT enrolled in Circle B
        slots: [
          GameyaSlot.open(slotNumber: 1, payoutAmountMinor: 40000, scheduledMonthName: 'M1'),
        ],
      );

      final controller = GameyaController(
        repository: _MultiMockRepo([circleA, circleB], profileId: 'usr-user-1'),
        currentUserId: 'usr-user-1',
        autoLoad: false,
      );
      await controller.loadInitialData();

      // Attempting contribution payment on Circle B where user is NOT enrolled
      final contribB = await controller.submitContributionPayment(
        circleId: 'CIRCLE-B',
        amountMinor: 20000,
      );
      expect(contribB, isFalse);
    });

    // =========================================================================
    // TEST 12 (Classification: B - Auth Controller Integration Test): Logout Protected Ops
    // =========================================================================
    test('12. Logout Protected Operations: Clearing session revokes access to protected shell', () async {
      final storage = SecureSessionStorage();
      await storage.saveSession(UserSession(
        userId: 'usr-logout-test',
        email: 'logout@gameya.eg',
        fullName: 'Logout User',
        tenantId: 'TENANT-01',
        role: UserRole.member,
        accessToken: 'active_token',
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      ));

      final client = ApiClient(sessionStorage: storage);
      final auth = AuthController(apiClient: client, sessionStorage: storage);
      await auth.initialize();
      expect(auth.value, isA<Authenticated>());

      await auth.logout();
      expect(auth.value, isA<Unauthenticated>());
      expect(await storage.getSession(), isNull);
    });

    // =========================================================================
    // TEST 13 (Classification: B - Production Bootstrap Test): Fixture Repo Production Injection
    // =========================================================================
    test('13. Fixture Repository Isolation: Production repository binds to Firestore, not fixtures', () {
      final firestore = FirebaseFirestoreService();
      final auth = FirebaseAuthService();
      final prodRepo = FirebaseGameyaRepository(firestoreService: firestore, authService: auth);

      // Verify that prodRepo uses Firebase service instances and does NOT expose ApiClient mock
      expect(prodRepo.apiClient, isNull);
      expect(prodRepo.firestoreService, equals(firestore));
      expect(prodRepo.authService, equals(auth));
    });

    // =========================================================================
    // TEST 14 (Classification: C - Unit Test): Fixture Identity Leakage
    // =========================================================================
    test('14. Fixture Identity Leakage: "usr-current" string cannot authorize production controls', () {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-14',
        name: 'Production Auth Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Real Organizer',
        organizerId: 'usr-live-organizer-777',
        slots: const [
          GameyaSlot(slotNumber: 1, assignedMemberId: 'usr-live-organizer-777', isClaimed: true, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1'),
        ],
      );

      // Passing fixture string 'usr-current' as authenticated user must return false
      expect(circle.isOrganizer('usr-current'), isFalse);
      expect(circle.isOrganizer('usr-current-mansour'), isFalse);
      expect(circle.isOrganizer('usr-live-organizer-777'), isTrue);
    });

    // =========================================================================
    // TEST 15 (Classification: B - Controller/State Integration Test): Duplicate Join Replay
    // =========================================================================
    test('15. Duplicate Join Replay: Replaying join request for already joined slot fails', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-15',
        name: 'Join Replay Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 2,
        currentPeriod: 1,
        totalPoolMinor: 100000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        organizerId: 'usr-org',
        slots: [
          GameyaSlot.open(slotNumber: 1, payoutAmountMinor: 100000, scheduledMonthName: 'Month 1'),
        ],
      );

      final controller = GameyaController(
        repository: _MockProfileRepo(circle, profileId: 'usr-replay-user'),
        currentUserId: 'usr-replay-user',
        autoLoad: false,
      );
      await controller.loadInitialData();

      // First join succeeds
      final firstJoin = await controller.joinCircleWithSlot(circleId: 'CIRCLE-SEC-15', slotNumber: 1);
      expect(firstJoin, isTrue);

      // Replayed join for same slot in active circle returns false or is prevented
      final replayedJoin = await controller.joinCircleWithSlot(circleId: 'CIRCLE-SEC-15', slotNumber: 1);
      expect(replayedJoin, isFalse);
    });

    // =========================================================================
    // TEST 16 (Classification: B - Controller/State Integration Test): Payout Replay
    // =========================================================================
    test('16. Payout Replay Guard: Payout cannot be claimed if not user turn or already claimed', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-16',
        name: 'Payout Replay Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        currentPeriod: 2, // Period 2
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        organizerId: 'usr-org',
        currentUserSlotPosition: 1, // User is slot 1 (Due in Period 1, not Period 2)
        slots: const [
          GameyaSlot(slotNumber: 1, assignedMemberId: 'usr-payout-user', isCurrentUser: true, isClaimed: true, payoutAmountMinor: 200000, scheduledMonthName: 'Month 1'),
        ],
      );

      final controller = GameyaController(
        repository: _MockProfileRepo(circle, profileId: 'usr-payout-user'),
        currentUserId: 'usr-payout-user',
        autoLoad: false,
      );
      await controller.loadInitialData();

      // Not user's payout period
      final outOfTurnClaim = await controller.claimPayoutDisbursement(
        circleId: 'CIRCLE-SEC-16',
        amountMinor: 200000,
        destinationAccount: 'EG1234567890',
      );
      expect(outOfTurnClaim, isFalse);
    });

    // =========================================================================
    // TEST 17 (Classification: B - Controller/State Integration Test): Contribution Idempotency
    // =========================================================================
    test('17. Contribution Idempotency: Duplicate idempotency key returns idempotent success without double-posting', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-17',
        name: 'Idempotent Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 2,
        currentPeriod: 1,
        totalPoolMinor: 100000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        organizerId: 'usr-org',
        currentUserSlotPosition: 1,
        slots: const [
          GameyaSlot(slotNumber: 1, assignedMemberId: 'usr-idem-user', isCurrentUser: true, isClaimed: true, payoutAmountMinor: 100000, scheduledMonthName: 'Month 1'),
        ],
      );

      final controller = GameyaController(
        repository: _MockProfileRepo(circle, profileId: 'usr-idem-user'),
        currentUserId: 'usr-idem-user',
        autoLoad: false,
      );
      await controller.loadInitialData();

      const idemKey = 'PAY-IDEM-001';
      final firstPay = await controller.submitContributionPayment(
        circleId: 'CIRCLE-SEC-17',
        amountMinor: 50000,
        idempotencyKey: idemKey,
      );
      expect(firstPay, isTrue);

      final stateAfterFirst = controller.value as GameyaLoaded;
      final timelineCountBefore = stateAfterFirst.activityTimeline.length;

      // Replaying with identical idempotencyKey
      final secondPay = await controller.submitContributionPayment(
        circleId: 'CIRCLE-SEC-17',
        amountMinor: 50000,
        idempotencyKey: idemKey,
      );
      expect(secondPay, isTrue); // Idempotent true

      final stateAfterSecond = controller.value as GameyaLoaded;
      expect(stateAfterSecond.activityTimeline.length, equals(timelineCountBefore)); // No duplicate posting
    });

    // =========================================================================
    // TEST 18 (Classification: B - Controller/State Integration Test): Unauthorized Member Mutation
    // =========================================================================
    test('18. Unauthorized Member Mutation: User cannot claim payout specifying attacker member ID', () async {
      final circle = GameyaCircle(
        id: 'CIRCLE-SEC-18',
        name: 'Member Boundary Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 2,
        currentPeriod: 1,
        totalPoolMinor: 100000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Org',
        organizerId: 'usr-org',
        currentUserSlotPosition: 1,
        slots: const [
          GameyaSlot(slotNumber: 1, assignedMemberId: 'usr-legit-user', isCurrentUser: true, isClaimed: true, payoutAmountMinor: 100000, scheduledMonthName: 'Month 1'),
        ],
      );

      final controller = GameyaController(
        repository: _MockProfileRepo(circle, profileId: 'usr-legit-user'),
        currentUserId: 'usr-legit-user',
        autoLoad: false,
      );
      await controller.loadInitialData();

      // Malicious attempt to disburse on behalf of attacker
      final attackerClaim = await controller.claimPayoutDisbursement(
        circleId: 'CIRCLE-SEC-18',
        amountMinor: 100000,
        destinationAccount: 'EG9999999999',
        claimingMemberId: 'usr-attacker-eve',
      );
      expect(attackerClaim, isFalse);
    });

    // =========================================================================
    // TEST 19 (Classification: B - Repository Integration Test): Cross-User Document Mutation
    // =========================================================================
    test('19. Cross-User Mutation Guard: User cannot fetch another user profile without auth', () async {
      final firestore = FirebaseFirestoreService();
      final auth = FirebaseAuthService();
      await auth.signOut(); // Unauthenticated

      final repo = FirebaseGameyaRepository(firestoreService: firestore, authService: auth);
      expect(() => repo.fetchConsumerProfile(), throwsA(isA<StateError>()));
    });

    // =========================================================================
    // TEST 20 (Classification: C - Unit Test): Financial Field Client Tampering
    // =========================================================================
    test('20. Financial Field Client Tampering: REAL_MONEY_ENABLED remains strictly false', () {
      const gate = CommercialGateConfiguration();
      expect(gate.realMoneyEnabled, isFalse);
      expect(gate.canActivateRealMoney, isFalse);
    });
  });
}

class _MockProfileRepo extends GameyaRepository {
  final GameyaCircle circle;
  final String profileId;
  _MockProfileRepo(this.circle, {required this.profileId});

  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => [circle];

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    return ConsumerHubSummary(
      memberName: 'Member ($profileId)',
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
      id: profileId,
      fullName: 'Member ($profileId)',
      email: '$profileId@gameya.eg',
      phone: '+20 100 000 0000',
      bankAccountName: 'Bank',
      bankAccountMasked: '**** 1111',
    );
  }

  @override
  Future<bool> joinCircleSlot({required String circleId, required int slotNumber}) async {
    return true;
  }
}

class _MultiMockRepo extends GameyaRepository {
  final List<GameyaCircle> circles;
  final String profileId;
  _MultiMockRepo(this.circles, {required this.profileId});

  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => circles;

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    final active = circles.where((c) => c.isUserEnrolled).toList();
    return ConsumerHubSummary(
      memberName: 'Member ($profileId)',
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
    return ConsumerProfile(
      id: profileId,
      fullName: 'Member ($profileId)',
      email: '$profileId@gameya.eg',
      phone: '+20 100 000 0000',
      bankAccountName: 'Bank',
      bankAccountMasked: '**** 1111',
    );
  }
}

class _ThrowingRepo extends GameyaRepository {
  final GameyaCircle circle;
  _ThrowingRepo(this.circle);

  @override
  Future<List<GameyaCircle>> fetchAllCircles() async => [circle];

  @override
  Future<ConsumerHubSummary> fetchHubSummary() async {
    return ConsumerHubSummary(
      memberName: 'Net User',
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
      id: 'usr-net-user',
      fullName: 'Net User',
      email: 'net@gameya.eg',
      phone: '+20 100 000 0000',
      bankAccountName: 'Bank',
      bankAccountMasked: '**** 1111',
    );
  }

  @override
  Future<bool> joinCircleSlot({required String circleId, required int slotNumber}) async {
    throw Exception('ERR_NETWORK_UNAVAILABLE: Connection refused');
  }
}
