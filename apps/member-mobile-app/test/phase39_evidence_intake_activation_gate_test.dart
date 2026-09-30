import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';

void main() {
  group(
      'Phase 39: External Evidence Intake, Commercial Go-Live Control & Production Gate Suite',
      () {
    // =========================================================================
    // 1. EVIDENCE-DRIVEN COMMERCIAL ACTIVATION GATE
    // =========================================================================
    test(
        'Gate: Evidence-Driven Commercial Gate fails closed when any external dependency lacks production evidence',
        () {
      final unverifiedEvidence = [
        const ExternalEvidenceRecord(
          id: 'EXT-01',
          name: 'Regulatory Legal Opinion',
          category: 'Legal',
          status: EvidenceStatus.underReview,
          requiredEvidence: 'Formal legal opinion letter',
          environment: EvidenceEnvironment.production,
        ),
        const ExternalEvidenceRecord(
          id: 'EXT-02',
          name: 'Sponsor Bank Agreement',
          category: 'Banking',
          status: EvidenceStatus.requested,
          requiredEvidence: 'Executed ODFI agreement',
          environment: EvidenceEnvironment.production,
        ),
      ];

      final config = CommercialGateConfiguration(
        activeEnvironment: 'prod',
        realMoneyEnabled: true,
        isLegalSignoffComplete: true,
        isBankingPartnerApproved: true,
        isFboCustodyVerified: true,
        isPaymentProcessorLive: true,
        isKycAmlLive: true,
        isAmlOfacScreeningLive: true,
        isSecretsManagementVerified: true,
        isWebhookSecurityVerified: true,
        isSecurityPenTestComplete: true,
        isProductionInfrastructureApproved: true,
        isReconciliationReadinessVerified: true,
        isBackupRestoreVerified: true,
        isIncidentResponseReady: true,
        isCustomerSupportReady: true,
        isPrivacyTermsPublished: true,
        platformState: CommercialPlatformState.commercialActive,
        evidenceRecords: unverifiedEvidence,
      );

      expect(config.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(config.canActivateRealMoney, isFalse);
    });

    // =========================================================================
    // 2. DEMO / TEST / SANDBOX CONTAMINATION PREVENTION
    // =========================================================================
    test(
        'Contamination: Sandbox or Demo verified evidence strictly CANNOT satisfy production activation',
        () {
      final sandboxVerifiedRecord = ExternalEvidenceRecord(
        id: 'EXT-04',
        name: 'Live ACH Rail',
        category: 'Payments',
        status: EvidenceStatus.verified,
        requiredEvidence: 'Live Payment Processor API Key',
        evidenceReference: 'SANDBOX-KEY-REF-12345',
        evidenceHash:
            'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        verifiedAt: DateTime(2026, 8, 30),
        environment: EvidenceEnvironment.sandbox, // NON-PROD ENVIRONMENT
      );

      expect(sandboxVerifiedRecord.status.isVerified, isTrue);
      expect(sandboxVerifiedRecord.isProductionVerified, isFalse,
          reason:
              'Sandbox evidence must never satisfy production verification');

      final pilotRecord = sandboxVerifiedRecord.copyWith(
        environment: EvidenceEnvironment.pilot,
      );
      expect(pilotRecord.isProductionVerified, isFalse,
          reason: 'Pilot evidence must never satisfy production verification');

      final genuineProdRecord = sandboxVerifiedRecord.copyWith(
        environment: EvidenceEnvironment.production,
      );
      expect(genuineProdRecord.isProductionVerified, isTrue);
    });

    // =========================================================================
    // 3. EVIDENCE REGISTRY STATUS MACHINE & HASH INTEGRITY
    // =========================================================================
    test('Evidence: Status lifecycle transitions and mandatory hash validation',
        () {
      const initial = ExternalEvidenceRecord(
        id: 'EXT-01',
        name: 'Regulatory Legal Opinion',
        category: 'Legal',
        requiredEvidence: 'Signed Counsel Letter',
        environment: EvidenceEnvironment.production,
      );

      expect(initial.status, equals(EvidenceStatus.notStarted));
      expect(initial.isProductionVerified, isFalse);

      final requested = initial.copyWith(status: EvidenceStatus.requested);
      expect(requested.isProductionVerified, isFalse);

      final received = requested.copyWith(
        status: EvidenceStatus.received,
        evidenceReference: 'DOC-COUNSEL-2026-OPINION.pdf',
        evidenceHash:
            'sha256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
      );
      expect(received.isProductionVerified,
          isFalse); // Not yet verified by human reviewer

      final verified = received.copyWith(
        status: EvidenceStatus.verified,
        verifiedAt: DateTime(2026, 8, 30, 10, 0),
        verifiedBy: 'General Counsel',
        verificationMethod: 'Cryptographic Signature & Bar Registration Match',
      );
      expect(verified.isProductionVerified, isTrue);

      final revoked = verified.copyWith(status: EvidenceStatus.revoked);
      expect(revoked.isProductionVerified, isFalse);
    });

    // =========================================================================
    // 4. REAL-MONEY KILL SWITCH PERSISTENCE
    // =========================================================================
    test(
        'KillSwitch: REAL_MONEY_ENABLED defaults to false across all environments',
        () {
      const defaultGate = CommercialGateConfiguration();
      expect(defaultGate.realMoneyEnabled, isFalse);
      expect(defaultGate.canActivateRealMoney, isFalse);

      final environments = ['dev', 'test', 'sandbox', 'pilot', 'staging'];
      for (final env in environments) {
        final envGate = CommercialGateConfiguration(activeEnvironment: env);
        expect(envGate.realMoneyEnabled, isFalse);
        expect(envGate.canActivateRealMoney, isFalse);
      }
    });

    // =========================================================================
    // 5. EMERGENCY FINANCIAL LOCKDOWN INSTANT TRIP
    // =========================================================================
    test(
        'Lockdown: Emergency Lockdown instantly terminates real-money eligibility',
        () {
      const activeProd = CommercialGateConfiguration(
        activeEnvironment: 'prod',
        realMoneyEnabled: true,
        isLegalSignoffComplete: true,
        isBankingPartnerApproved: true,
        isFboCustodyVerified: true,
        isPaymentProcessorLive: true,
        isKycAmlLive: true,
        isAmlOfacScreeningLive: true,
        isSecretsManagementVerified: true,
        isWebhookSecurityVerified: true,
        isSecurityPenTestComplete: true,
        isProductionInfrastructureApproved: true,
        isReconciliationReadinessVerified: true,
        isBackupRestoreVerified: true,
        isIncidentResponseReady: true,
        isCustomerSupportReady: true,
        isPrivacyTermsPublished: true,
        platformState: CommercialPlatformState.commercialActive,
      );
      expect(activeProd.canActivateRealMoney, isTrue);

      final locked = activeProd.copyWith(
        platformState: CommercialPlatformState.emergencyLockdown,
      );
      expect(locked.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(locked.canActivateRealMoney, isFalse);
    });

    // =========================================================================
    // 6. DUAL-CONTROL ACTIVATION (TWO-PERSON RULE)
    // =========================================================================
    test(
        'DualControl: Activation blocked if requester == approver or status != approved',
        () {
      final selfApproved = DualControlActivationRecord(
        requestId: 'ACT-REQ-001',
        requestedBy: 'ADMIN_ALICE',
        approvedBy: 'ADMIN_ALICE', // SAME PERSON - VIOLATION
        state: DualControlActivationState.approved,
        requestedAt: DateTime(2026, 8, 30, 8, 0),
        approvedAt: DateTime(2026, 8, 30, 8, 5),
        reason: 'Commercial Launch',
        activationVersion: 'v1.0.0',
        evidenceSnapshot: const ['EXT-01', 'EXT-02'],
        configurationHash: 'sha256:abc123456789',
      );
      expect(selfApproved.isDualControlSatisfied, isFalse);

      final unapproved = selfApproved.copyWith(
        approvedBy: 'ADMIN_BOB',
        state: DualControlActivationState.requested, // Not yet approved
      );
      expect(unapproved.isDualControlSatisfied, isFalse);

      final validDualControl = selfApproved.copyWith(
        approvedBy: 'ADMIN_BOB', // DISTINCT APPROVER
        state: DualControlActivationState.approved,
      );
      expect(validDualControl.isDualControlSatisfied, isTrue);
    });

    // =========================================================================
    // 7. SYMMETRICAL PAIRED FINANCIAL RECONCILIATION & ADVERSARIAL INTEGRITY
    // =========================================================================
    test(
        'Financial: Symmetrical Paired multi-size rotation yields exact \$0.00 variance and 50% early payout',
        () {
      final evenSizes = [4, 6, 8, 10, 12];
      const monthlyDuesMinor = 50000; // $500.00

      for (final size in evenSizes) {
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
          id: 'P39-CIRC-$size',
          name: 'Phase 39 Certified $size-Member Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: monthlyDuesMinor,
          totalPeriods: size,
          totalPoolMinor: totalPool,
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 9, 1),
          organizerName: 'Coordinator',
          slots: slots,
        );

        // Adversarial check: In period 1, Slot #1 must receive exactly 50% (never 100%)
        final period1Slots = circle.activePayoutSlotsForPeriod(1);
        expect(period1Slots.length, equals(2));
        expect(period1Slots.contains(1), isTrue);
        expect(period1Slots.contains(size), isTrue);
        expect(circle.payoutAmountForSlotInPeriod(1, 1), equals(halfPayout));
        expect(circle.payoutAmountForSlotInPeriod(size, 1), equals(halfPayout));

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
        expect(totalInflows - totalOutflows, equals(0)); // $0.00 variance
      }
    });
  });
}
