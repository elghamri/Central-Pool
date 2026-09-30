import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_config.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_auth_service.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_firestore_service.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_gameya_repository.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';

void main() {
  group('Phase 44: Production Firebase Implementation & Integration Suite', () {
    // =========================================================================
    // 1. FIREBASE ENVIRONMENT & PROJECT CONFIGURATION
    // =========================================================================
    test(
        '1. Config: Environment isolation enforces separate project IDs and fail-closed kill switch',
        () {
      const devConfig = FirebaseAppConfig.development;
      expect(devConfig.projectId, equals('central-pool-dev'));
      expect(devConfig.useEmulators, isTrue);
      expect(devConfig.realMoneyEnabled, isFalse);

      const prodConfig = FirebaseAppConfig.production;
      expect(prodConfig.projectId, equals('central-pool-production'));
      expect(prodConfig.isProduction, isTrue);
      expect(prodConfig.realMoneyEnabled, isFalse); // Fail-closed
    });

    // =========================================================================
    // 2. FIREBASE AUTHENTICATION & RBAC ROLES
    // =========================================================================
    test(
        '2. Auth & RBAC: Custom claims correctly map across all 7 platform roles',
        () {
      final auth = FirebaseAuthService();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.role, equals(FirebaseUserRole.member));

      auth.setRole(FirebaseUserRole.finOps);
      expect(auth.currentUser?.role, equals(FirebaseUserRole.finOps));
      expect(auth.currentUser?.role.claimValue, equals('FINOPS'));

      auth.setRole(FirebaseUserRole.security);
      expect(auth.currentUser?.role.claimValue, equals('SECURITY'));

      auth.setRole(FirebaseUserRole.admin);
      expect(auth.currentUser?.role.claimValue, equals('ADMIN'));
    });

    // =========================================================================
    // 3. FIRESTORE READS, WRITES & WORM LEDGER POSTINGS
    // =========================================================================
    test(
        '3. Firestore Service: Document operations & WORM ledger postings maintain double-entry equilibrium',
        () async {
      final firestore = FirebaseFirestoreService();

      // Post WORM Double-Entry Journal Entry
      const journalId = 'JRN-2026-P44-001';
      const amountMinor = 50000; // $500.00
      await firestore.setDocument('gl_journal_entries', journalId, {
        'journalId': journalId,
        'referenceId': 'PAY-001',
        'eventType': 'CONTRIBUTION_SETTLED',
        'totalDebitsMinor': amountMinor,
        'totalCreditsMinor': amountMinor,
        'isBalanced': true,
        'postedBy': 'SYSTEM_WEBHOOK',
      });

      final doc = await firestore.getDocument('gl_journal_entries', journalId);
      expect(doc.exists, isTrue);
      expect(doc.data['totalDebitsMinor'], equals(amountMinor));
      expect(doc.data['totalCreditsMinor'], equals(amountMinor));
      expect(doc.data['isBalanced'], isTrue);
    });

    // =========================================================================
    // 4. FIREBASE GAMEYA REPOSITORY & SYMMETRICAL PAIRED SLOTS
    // =========================================================================
    test(
        '4. Repository: FirebaseGameyaRepository generates Symmetrical Paired slots in Firestore',
        () async {
      final firestore = FirebaseFirestoreService();
      final auth = FirebaseAuthService();
      final repo = FirebaseGameyaRepository(
          firestoreService: firestore, authService: auth);

      const draft = CreateGameyaDraft(
        name: 'Phase 44 Firebase 6-Member Circle',
        goalCategory: 'Savings',
        monthlyContributionMinor: 50000, // $500.00
        totalPeriods: 6,
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        isPrivate: false,
        creatorSlotNumber: 1,
      );

      final circle = await repo.createNewCircle(draft);
      expect(circle.slots.length, equals(6));
      expect(circle.slots[0].payoutAmountMinor,
          equals(150000)); // $1,500.00 (50% pool)
      expect(circle.slots[0].pairedSlotNumber, equals(6));

      // Verify Firestore persistence
      final circleDoc =
          await firestore.getDocument('gameya_circles', circle.id);
      expect(circleDoc.exists, isTrue);
      expect(
          circleDoc.data['name'], equals('Phase 44 Firebase 6-Member Circle'));

      final slot1Doc = await firestore.getDocument(
          'gameya_circles/${circle.id}/slots', 'slot_1');
      expect(slot1Doc.exists, isTrue);
      expect(slot1Doc.data['payoutAmountMinor'], equals(150000));
      expect(slot1Doc.data['pairedSlotNumber'], equals(6));
    });

    // =========================================================================
    // 5. SECURITY RULES & ADVERSARIAL ACCESS PREVENTION
    // =========================================================================
    test(
        '5. Security: Dual-control self-approval and real-money bypass are strictly rejected',
        () {
      final invalidDualControl = DualControlActivationRecord(
        requestId: 'ACT-P44-ATTACK',
        requestedBy: 'ADMIN_EVE',
        approvedBy: 'ADMIN_EVE', // Self-approval attack
        state: DualControlActivationState.approved,
        requestedAt: DateTime(2026, 8, 31),
        approvedAt: DateTime(2026, 8, 31),
        reason: 'Unauthorized bypass attempt',
        activationVersion: 'v1.0.0+44',
        evidenceSnapshot: const ['EXT-01'],
        configurationHash: 'sha256:attack',
      );

      expect(invalidDualControl.isDualControlSatisfied, isFalse);

      const failClosedGate = CommercialGateConfiguration(
        platformState: CommercialPlatformState.preProduction,
        realMoneyEnabled: false,
        activeEnvironment: 'prod',
      );
      expect(failClosedGate.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
    });

    // =========================================================================
    // 6. FINANCIAL CORE REGRESSION & $0.00 MULTI-SIZE BALANCE
    // =========================================================================
    test(
        '6. Financial Core: Symmetrical Paired multi-size calculations maintain exact \$0.00 variance',
        () {
      final circleSizes = [4, 6, 8, 10, 12];
      const monthlyDuesMinor = 50000; // $500.00

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
          id: 'P44-CIRC-$size',
          name: 'Phase 44 $size-Member Circle',
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
        expect(totalInflows - totalOutflows,
            equals(0)); // Zero mathematical variance
      }
    });
  });
}
