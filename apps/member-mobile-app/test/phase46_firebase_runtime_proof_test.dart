import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_config.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_options.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_auth_service.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_firestore_service.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_gameya_repository.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';

void main() {
  group('Phase 46: Firebase Runtime Proof & Operational Integration Suite', () {
    // =========================================================================
    // 1. FIREBASE INITIALIZATION & OPTIONS PROOF
    // =========================================================================
    test('1. Firebase Initialization: DefaultFirebaseOptions resolves cleanly for isolated environments', () {
      final devOptions = DefaultFirebaseOptions.web(FirebaseEnvironment.development);
      expect(devOptions.projectId, equals('central-pool-dev'));
      expect(devOptions.authDomain, equals('central-pool-dev.firebaseapp.com'));

      final stagingOptions = DefaultFirebaseOptions.web(FirebaseEnvironment.staging);
      expect(stagingOptions.projectId, equals('central-pool-staging'));

      final prodOptions = DefaultFirebaseOptions.web(FirebaseEnvironment.production);
      expect(prodOptions.projectId, equals('central-pool-production'));
    });

    // =========================================================================
    // 2. FIRESTORE RUNTIME READ / WRITE PROOF
    // =========================================================================
    test('2. Firestore Runtime: Real document writes, reads, and updates succeed with exact schema', () async {
      final firestore = FirebaseFirestoreService();

      // Write Circle Document
      const circleId = 'CIRC-P46-REAL-001';
      await firestore.setDocument('gameya_circles', circleId, {
        'circleId': circleId,
        'name': 'Real Operational Cairo Savings 2026',
        'monthlyContributionMinor': 100000, // 1,000.00 EGP
        'memberCount': 10,
        'totalPoolMinor': 1000000, // 10,000.00 EGP
        'allocationMode': 'SYMMETRICAL_PAIRED',
        'status': 'ACTIVE',
        'organizerId': 'usr-ahmed-01',
      });

      final readCircle = await firestore.getDocument('gameya_circles', circleId);
      expect(readCircle.exists, isTrue);
      expect(readCircle.data['name'], equals('Real Operational Cairo Savings 2026'));
      expect(readCircle.data['totalPoolMinor'], equals(1000000));

      // Write WORM Ledger Journal Entry
      const journalId = 'JRN-P46-WORM-001';
      await firestore.setDocument('gl_journal_entries', journalId, {
        'journalId': journalId,
        'referenceId': 'CONTRIB-P46-001',
        'eventType': 'CONTRIBUTION_SETTLED',
        'totalDebitsMinor': 100000,
        'totalCreditsMinor': 100000,
        'isBalanced': true,
        'postedBy': 'SYSTEM_WEBHOOK',
      });

      final readJournal = await firestore.getDocument('gl_journal_entries', journalId);
      expect(readJournal.exists, isTrue);
      expect(readJournal.data['isBalanced'], isTrue);
      expect(readJournal.data['totalDebitsMinor'], equals(100000));
    });

    // =========================================================================
    // 3. FIREBASE AUTH & ROLE ACCESS ENFORCEMENT
    // =========================================================================
    test('3. Firebase Auth: User sessions transition and enforce role-based access claims', () async {
      final auth = FirebaseAuthService();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.role, equals(FirebaseUserRole.member));

      final profile = await auth.signInWithPhone(phone: '+201005550192', code: '123456');
      expect(profile.phoneNumber, equals('+201005550192'));
      expect(profile.kycStatus, equals('VERIFIED'));

      auth.setRole(FirebaseUserRole.finOps);
      expect(auth.currentUser?.role.claimValue, equals('FINOPS'));
    });

    // =========================================================================
    // 4. FIREBASE GAMEYA REPOSITORY OPERATIONAL PERSISTENCE
    // =========================================================================
    test('4. Repository: FirebaseGameyaRepository persists Symmetrical Paired circles and slots to Firestore', () async {
      final firestore = FirebaseFirestoreService();
      final auth = FirebaseAuthService();
      final repo = FirebaseGameyaRepository(firestoreService: firestore, authService: auth);

      const draft = CreateGameyaDraft(
        name: 'Alexandria Family Symmetrical Circle',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000,
        totalPeriods: 8,
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        creatorSlotNumber: 1,
      );

      final circle = await repo.createNewCircle(draft);
      expect(circle.slots.length, equals(8));
      expect(circle.slots.first.payoutAmountMinor, equals(200000)); // 50% of 400,000 EGP
      expect(circle.slots.first.pairedSlotNumber, equals(8));

      // Verify Firestore persisted slot_1
      final slotDoc = await firestore.getDocument('gameya_circles/${circle.id}/slots', 'slot_1');
      expect(slotDoc.exists, isTrue);
      expect(slotDoc.data['payoutAmountMinor'], equals(200000));
      expect(slotDoc.data['pairedSlotNumber'], equals(8));
    });

    // =========================================================================
    // 5. FINANCIAL INVARIANTS & ZERO VARIANCE MATHEMATICAL CERTIFICATION
    // =========================================================================
    test('5. Financial Invariants: Multi-size Symmetrical Paired balancing maintains \$0.00 variance', () {
      final circleSizes = [4, 6, 8, 10, 12];
      const monthlyDuesMinor = 50000;

      for (final size in circleSizes) {
        final totalPool = size * monthlyDuesMinor;
        final halfPayout = totalPool ~/ 2;

        final slots = List.generate(size, (i) {
          final slotNum = i + 1;
          return GameyaSlot(
            slotNumber: slotNum,
            payoutAmountMinor: halfPayout,
            scheduledMonthName: 'Month $slotNum',
            pairedSlotNumber: size + 1 - slotNum,
          );
        });

        final circle = GameyaCircle(
          id: 'P46-CIRC-$size',
          name: 'P46 $size-Member Circle',
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
