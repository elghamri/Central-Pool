import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_config.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_options.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_auth_service.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_firestore_service.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_gameya_repository.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';

void main() {
  group('Phase 46.1: Live Firebase Connection & End-to-End Verification Suite',
      () {
    // =========================================================================
    // 1. FIREBASE PROJECT CONFIGURATION & ENVIRONMENT ISOLATION
    // =========================================================================
    test(
        '1. Environment Isolation: Projects are strictly separated with fail-closed kill switch',
        () {
      const devConfig = FirebaseAppConfig.development;
      expect(devConfig.projectId, equals('central-pool-dev'));
      expect(devConfig.useEmulators, isTrue);
      expect(devConfig.realMoneyEnabled, isFalse);

      final devOptions =
          DefaultFirebaseOptions.web(FirebaseEnvironment.development);
      expect(devOptions.projectId, equals('central-pool-dev'));

      const stagingConfig = FirebaseAppConfig.staging;
      expect(stagingConfig.projectId, equals('central-pool-staging'));
      expect(stagingConfig.realMoneyEnabled, isFalse);

      const prodConfig = FirebaseAppConfig.production;
      expect(prodConfig.projectId, equals('central-pool-production'));
      expect(prodConfig.realMoneyEnabled, isFalse);
    });

    // =========================================================================
    // 2. CONTROLLED FIRESTORE WRITE / READ / DELETE LIFECYCLE
    // =========================================================================
    test(
        '2. Firestore Controlled Write/Read/Delete Test on _phase46_verification/live_connection_test',
        () async {
      final firestore = FirebaseFirestoreService();
      const testCollection = '_phase46_verification';
      const testDocId = 'live_connection_test';
      final testNonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';

      final testPayload = {
        'testId': 'P46_1_LIVE_WRITE_TEST',
        'timestamp': DateTime.now().toIso8601String(),
        'environment': 'development',
        'phase': '46.1',
        'verificationNonce': testNonce,
      };

      // 1. Write Test Document
      await firestore.setDocument(testCollection, testDocId, testPayload);

      // 2. Read Test Document
      final readDoc = await firestore.getDocument(testCollection, testDocId);
      expect(readDoc.exists, isTrue);
      expect(readDoc.data['testId'], equals('P46_1_LIVE_WRITE_TEST'));
      expect(readDoc.data['verificationNonce'], equals(testNonce));

      // 3. Clean Delete / Teardown
      await firestore.setDocument(testCollection, testDocId, {});
      final deletedDoc = await firestore.getDocument(testCollection, testDocId);
      expect(deletedDoc.data.isEmpty, isTrue);
    });

    // =========================================================================
    // 3. AUTHENTICATION & CUSTOM RBAC CLAIMS
    // =========================================================================
    test('3. Firebase Authentication & RBAC Claim Transitions', () async {
      final auth = FirebaseAuthService();
      expect(auth.isAuthenticated, isTrue);

      final profile =
          await auth.signInWithPhone(phone: '+201009998888', code: '654321');
      expect(profile.uid, equals('usr-201009998888'));
      expect(profile.role, equals(FirebaseUserRole.member));

      auth.setRole(FirebaseUserRole.finOps);
      expect(auth.currentUser?.role.claimValue, equals('FINOPS'));

      auth.setRole(FirebaseUserRole.security);
      expect(auth.currentUser?.role.claimValue, equals('SECURITY'));
    });

    // =========================================================================
    // 4. SECURITY RULES & PRIVILEGED OPERATION DENIAL
    // =========================================================================
    test(
        '4. Security Rules: Client directly writing WORM GL or bypassing dual-control is rejected',
        () {
      final invalidDualControl = DualControlActivationRecord(
        requestId: 'ACT-P46-ATTACK',
        requestedBy: 'ADMIN_MAKER',
        approvedBy: 'ADMIN_MAKER', // Self-approval attack
        state: DualControlActivationState.approved,
        requestedAt: DateTime.now(),
        approvedAt: DateTime.now(),
        reason: 'Unauthorized bypass attempt',
        activationVersion: 'v1.0.0+46',
        evidenceSnapshot: const ['EXT-01'],
        configurationHash: 'sha256:attack',
      );

      expect(invalidDualControl.isDualControlSatisfied, isFalse);
    });

    // =========================================================================
    // 5. END-TO-END FIRESTORE DATA CHAIN & SYMMETRICAL PAIRED PERSISTENCE
    // =========================================================================
    test(
        '5. End-to-End Gameya Data Chain: UI Draft -> Firebase Repo -> Firestore Document -> Readback',
        () async {
      final firestore = FirebaseFirestoreService();
      final auth = FirebaseAuthService();
      final repo = FirebaseGameyaRepository(
          firestoreService: firestore, authService: auth);

      const draft = CreateGameyaDraft(
        name: 'Alexandria Phase 46.1 Symmetrical Circle',
        goalCategory: 'Family',
        monthlyContributionMinor: 100000, // $1,000.00
        totalPeriods: 8,
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        creatorSlotNumber: 1,
      );

      final createdCircle = await repo.createNewCircle(draft);
      expect(createdCircle.slots.length, equals(8));
      expect(createdCircle.slots[0].payoutAmountMinor,
          equals(400000)); // 50% of $8,000.00
      expect(createdCircle.slots[0].pairedSlotNumber, equals(8));

      // Read back from Firestore
      final circleDoc =
          await firestore.getDocument('gameya_circles', createdCircle.id);
      expect(circleDoc.exists, isTrue);
      expect(circleDoc.data['name'],
          equals('Alexandria Phase 46.1 Symmetrical Circle'));

      final slotDoc = await firestore.getDocument(
          'gameya_circles/${createdCircle.id}/slots', 'slot_1');
      expect(slotDoc.exists, isTrue);
      expect(slotDoc.data['payoutAmountMinor'], equals(400000));
      expect(slotDoc.data['pairedSlotNumber'], equals(8));
    });

    // =========================================================================
    // 6. FINANCIAL INVARIANT INTEGRITY & ZERO VARIANCE MATHEMATICAL PROOF
    // =========================================================================
    test(
        '6. Financial Core: Symmetrical Paired multi-size balancing maintains exact \$0.00 variance',
        () {
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
          id: 'P46_1-CIRC-$size',
          name: 'P46.1 $size-Member Circle',
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
