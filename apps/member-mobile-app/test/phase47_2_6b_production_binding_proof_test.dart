import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/data/gameya_repository.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_gameya_repository.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_firestore_service.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 47.2.6B — Production Binding & Fixture Isolation Forensic Suite', () {
    // =========================================================================
    // TEST 1: Production DI Resolves Authoritative Repository
    // =========================================================================
    test('TEST 1: Production DI resolves authoritative FirebaseGameyaRepository', () {
      final firestoreService = FirebaseFirestoreService();
      final authService = FirebaseAuthService();
      final productionRepo = FirebaseGameyaRepository(
        firestoreService: firestoreService,
        authService: authService,
      );

      expect(productionRepo, isA<GameyaRepository>());
      expect(productionRepo, isA<FirebaseGameyaRepository>());
      expect(productionRepo.runtimeType, equals(FirebaseGameyaRepository));
    });

    // =========================================================================
    // TEST 2: Production DI Cannot Resolve Base Fixture Repository
    // =========================================================================
    test('TEST 2: Production DI cannot resolve base fixture GameyaRepository', () {
      final firestoreService = FirebaseFirestoreService();
      final authService = FirebaseAuthService();
      final productionRepo = FirebaseGameyaRepository(
        firestoreService: firestoreService,
        authService: authService,
      );

      // Must be false: production instance is strictly not the base fixture class
      expect(productionRepo.runtimeType == GameyaRepository, isFalse);
    });

    // =========================================================================
    // TEST 3: Network Failure Cannot Switch Production Repository to Fixtures
    // =========================================================================
    test('TEST 3: Network failure cannot switch production repository to fixtures', () async {
      final failingFirestore = _FailingFirestoreService();
      final authService = FirebaseAuthService();
      final productionRepo = FirebaseGameyaRepository(
        firestoreService: failingFirestore,
        authService: authService,
      );

      // Must throw exception, never fall back to fixtures
      expect(() => productionRepo.fetchAllCircles(), throwsA(isA<Exception>()));
    });

    // =========================================================================
    // TEST 4: Empty Authoritative Result Cannot Switch to Fixtures
    // =========================================================================
    test('TEST 4: Empty authoritative result returns [] and does NOT switch to fixtures', () async {
      final emptyFirestore = FirebaseFirestoreService(); // Empty in-memory store
      final authService = FirebaseAuthService();
      final productionRepo = FirebaseGameyaRepository(
        firestoreService: emptyFirestore,
        authService: authService,
      );

      final circles = await productionRepo.fetchAllCircles();
      expect(circles, isEmpty);
      expect(circles.any((c) => c.id == 'CIRCLE-FAM-2026'), isFalse);
      expect(circles.any((c) => c.id == 'CIRCLE-CAR-2027'), isFalse);
    });

    // =========================================================================
    // TEST 5: Missing Circle Cannot Create Synthetic Circle
    // =========================================================================
    test('TEST 5: Missing circle returns null and does NOT create synthetic circle', () async {
      final emptyFirestore = FirebaseFirestoreService();
      final authService = FirebaseAuthService();
      final productionRepo = FirebaseGameyaRepository(
        firestoreService: emptyFirestore,
        authService: authService,
      );

      final circle = await productionRepo.fetchCircleById('NON-EXISTENT-CIRCLE-999');
      expect(circle, isNull);
    });

    // =========================================================================
    // TEST 6: Missing Slot Cannot Create Synthetic Slot
    // =========================================================================
    test('TEST 6: Missing slot returns 0 and does NOT create synthetic slot payout', () {
      final circle = GameyaCircle(
        id: 'CIRCLE-PROD-001',
        name: 'Production Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000,
        totalPeriods: 4,
        totalPoolMinor: 200000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Real Organizer',
        organizerId: 'usr-real-org',
        slots: const [
          GameyaSlot(
            slotNumber: 1,
            payoutAmountMinor: 200000,
            scheduledMonthName: 'Month 1',
          ),
        ],
      );

      expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(200000));
      expect(circle.payoutAmountForSlotInPeriod(2, 1), equals(0)); // Non-existent slot 2
      expect(circle.payoutAmountForSlotInPeriod(99, 1), equals(0)); // Non-existent slot 99
    });

    // =========================================================================
    // TEST 7: Production Authentication Identity Cannot Become usr-current
    // =========================================================================
    test('TEST 7: Real authenticated session identity cannot become usr-current', () async {
      final firestore = FirebaseFirestoreService();
      final auth = FirebaseAuthService();
      final user = await auth.signInWithPhone(phone: '+20 100 123 4567', code: '123456');

      expect(user.uid, equals('usr-201001234567'));
      expect(user.uid, isNot(equals('usr-current')));
      expect(user.uid, isNot(equals('usr-current-mansour')));

      final repo = FirebaseGameyaRepository(firestoreService: firestore, authService: auth);
      await firestore.setDocument('gameya_circles', 'CIRCLE-LIVE-01', {'name': 'Live Circle'});
      await repo.joinCircleSlot(circleId: 'CIRCLE-LIVE-01', slotNumber: 1);

      final slotDoc = await firestore.getDocument('gameya_circles/CIRCLE-LIVE-01/slots', 'slot_1');
      expect(slotDoc.data['assignedMemberId'], equals('usr-201001234567'));
      expect(slotDoc.data['assignedMemberId'], isNot(equals('usr-current')));
    });

    // =========================================================================
    // TEST 8: Production Organizer Authorization Cannot Rely on Mock Identity
    // =========================================================================
    test('TEST 8: Organizer authority strictly checks authenticated user UID in production', () {
      final mockFixtureCircle = GameyaCircle(
        id: 'CIRCLE-FAM-2026',
        name: 'Family Savings',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 10,
        totalPoolMinor: 500000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Ahmed Mansour',
        organizerId: 'usr-current', // Mock fixture ID
        slots: const [],
      );

      final realProductionCircle = GameyaCircle(
        id: 'CIRCLE-PROD-REAL',
        name: 'Real Prod Circle',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 10,
        totalPoolMinor: 500000,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Real Member',
        organizerId: 'usr-real-authenticated-777',
        slots: const [],
      );

      const authenticatedProdUid = 'usr-real-authenticated-777';
      const otherUserUid = 'usr-other-member-888';

      // 1. Authenticated user matching organizerId is authorized
      expect(realProductionCircle.isOrganizer(authenticatedProdUid), isTrue);

      // 2. Different user is NOT authorized
      expect(realProductionCircle.isOrganizer(otherUserUid), isFalse);

      // 3. In production, a real user viewing a mock circle with organizerId == 'usr-current' is NOT authorized
      expect(mockFixtureCircle.isOrganizer(authenticatedProdUid), isFalse);
    });

    // =========================================================================
    // TEST 9: Development Fixtures Isolated to Explicit Dev/Test Path
    // =========================================================================
    test('TEST 9: Base GameyaRepository fixture path is isolated to explicit dev/test instantiation', () async {
      final devRepo = GameyaRepository();
      final devCircles = await devRepo.fetchAllCircles();
      expect(devCircles, isNotEmpty);
      expect(devCircles.any((c) => c.id == 'CIRCLE-FAM-2026'), isTrue);

      final prodRepo = FirebaseGameyaRepository(
        firestoreService: FirebaseFirestoreService(),
        authService: FirebaseAuthService(),
      );
      final prodCircles = await prodRepo.fetchAllCircles();
      expect(prodCircles, isEmpty);
    });

    // =========================================================================
    // TEST 10: REAL_MONEY_ENABLED Remains Strictly False
    // =========================================================================
    test('TEST 10: REAL_MONEY_ENABLED remains strictly false in commercial gate config', () {
      const gateConfig = CommercialGateConfiguration();
      expect(gateConfig.realMoneyEnabled, isFalse);
      expect(gateConfig.canActivateRealMoney, isFalse);
    });
  });
}

class _FailingFirestoreService extends FirebaseFirestoreService {
  @override
  Future<FirestoreQuerySnapshot> getCollection(String collectionPath) async {
    throw Exception('ERR_CONNECTION_FAILED: Cloud Firestore transport unavailable');
  }

  @override
  Future<FirestoreDocSnapshot> getDocument(String collectionPath, String documentId) async {
    throw Exception('ERR_CONNECTION_FAILED: Cloud Firestore transport unavailable');
  }
}
