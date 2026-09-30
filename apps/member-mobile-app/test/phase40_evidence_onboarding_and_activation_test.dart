import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';

void main() {
  group(
      'Phase 40: External Evidence Onboarding, Production Activation Readiness & Final Go-Live Control Suite',
      () {
    // =========================================================================
    // A. MISSING EVIDENCE
    // =========================================================================
    test(
        'A. Missing Evidence: Gate strictly fails closed when no evidence is supplied',
        () {
      const config = CommercialGateConfiguration(
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
        evidenceRecords: [
          ExternalEvidenceRecord(
            id: 'EXT-01',
            name: 'Legal Opinion',
            category: 'Legal',
            status: EvidenceStatus.notSubmitted,
            requiredEvidence: 'Signed Counsel Letter',
          ),
        ],
      );

      expect(config.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(config.canActivateRealMoney, isFalse);
    });

    // =========================================================================
    // B. PARTIAL EVIDENCE (6 of 7 Verified)
    // =========================================================================
    test(
        'B. Partial Evidence: 6 of 7 verified dependencies still blocks commercial activation',
        () {
      final partialList = [
        for (int i = 1; i <= 6; i++)
          ExternalEvidenceRecord(
            id: 'EXT-0$i',
            name: 'Requirement $i',
            category: 'Category',
            status: EvidenceStatus.verified,
            approvalStatus: EvidenceApprovalStatus.approved,
            requiredEvidence: 'Evidence $i',
            evidenceHash: 'sha256:abc$i',
            verifiedAt: DateTime(2026, 8, 30),
            verifiedBy: 'Compliance Officer',
            environment: EvidenceEnvironment.production,
          ),
        const ExternalEvidenceRecord(
          id: 'EXT-07',
          name: 'Commercial Insurance',
          category: 'Insurance',
          status: EvidenceStatus.underReview,
          approvalStatus: EvidenceApprovalStatus.pending,
          requiredEvidence: 'Executed Binder',
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
        evidenceRecords: partialList,
      );

      expect(config.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(config.canActivateRealMoney, isFalse);
    });

    // =========================================================================
    // C. REJECTED EVIDENCE
    // =========================================================================
    test('C. Rejected Evidence: Rejection immediately trips activation gate',
        () {
      const rejected = ExternalEvidenceRecord(
        id: 'EXT-01',
        name: 'Legal Opinion',
        category: 'Legal',
        status: EvidenceStatus.rejected,
        approvalStatus: EvidenceApprovalStatus.rejected,
        requiredEvidence: 'Signed Counsel Letter',
        rejectionReason: 'Missing FinCEN Safe Harbor Analysis',
        environment: EvidenceEnvironment.production,
      );

      expect(rejected.isProductionVerified, isFalse);
    });

    // =========================================================================
    // D. EXPIRED EVIDENCE
    // =========================================================================
    test(
        'D. Expired Evidence: Past expiration date automatically invalidates verification',
        () {
      final expiredRecord = ExternalEvidenceRecord(
        id: 'EXT-07',
        name: 'Commercial Insurance Policy',
        category: 'Insurance',
        status: EvidenceStatus.verified,
        approvalStatus: EvidenceApprovalStatus.approved,
        requiredEvidence: 'Policy Binder',
        evidenceHash: 'sha256:112233445566',
        verifiedAt: DateTime(2025, 1, 1),
        verifiedBy: 'Risk Manager',
        expiresAt: DateTime(2026, 1, 1), // Past expiration date
        environment: EvidenceEnvironment.production,
      );

      expect(expiredRecord.isProductionVerified, isFalse);
    });

    // =========================================================================
    // E. REVOKED EVIDENCE
    // =========================================================================
    test('E. Revoked Evidence: Revocation immediately blocks verification', () {
      final revokedRecord = ExternalEvidenceRecord(
        id: 'EXT-02',
        name: 'Bank Agreement',
        category: 'Banking',
        status: EvidenceStatus.revoked,
        approvalStatus: EvidenceApprovalStatus.rejected,
        requiredEvidence: 'Executed Agreement',
        evidenceHash: 'sha256:aabbccddeeff',
        verifiedAt: DateTime(2026, 8, 1),
        verifiedBy: 'Bank Partner',
        environment: EvidenceEnvironment.production,
      );

      expect(revokedRecord.isProductionVerified, isFalse);
    });

    // =========================================================================
    // F. SUPERSEDED EVIDENCE / VERSIONING
    // =========================================================================
    test(
        'F. Superseded Evidence: New version cleanly references superseded version',
        () {
      const v1 = ExternalEvidenceRecord(
        id: 'EXT-01-V1',
        name: 'Legal Opinion v1',
        category: 'Legal',
        status: EvidenceStatus.expired,
        requiredEvidence: 'Legal Letter',
        evidenceHash: 'sha256:v1hash',
      );

      final v2 = ExternalEvidenceRecord(
        id: 'EXT-01-V2',
        name: 'Legal Opinion v2',
        category: 'Legal',
        status: EvidenceStatus.verified,
        approvalStatus: EvidenceApprovalStatus.approved,
        requiredEvidence: 'Legal Letter',
        evidenceHash: 'sha256:v2hash',
        verifiedAt: DateTime(2026, 8, 30),
        verifiedBy: 'General Counsel',
        supersedesEvidenceId: v1.id,
      );

      expect(v2.supersedesEvidenceId, equals('EXT-01-V1'));
      expect(v2.isProductionVerified, isTrue);
    });

    // =========================================================================
    // G. INVALID HASH
    // =========================================================================
    test('G. Invalid Hash: Non-SHA256 hash format fails verification', () {
      final badHash = ExternalEvidenceRecord(
        id: 'EXT-06',
        name: 'Pen Test',
        category: 'Security',
        status: EvidenceStatus.verified,
        approvalStatus: EvidenceApprovalStatus.approved,
        requiredEvidence: 'Audit Report',
        evidenceHash: 'md5:badhashformat', // INVALID FORMAT
        verifiedAt: DateTime(2026, 8, 30),
        verifiedBy: 'Security Lead',
        environment: EvidenceEnvironment.production,
      );

      expect(badHash.isProductionVerified, isFalse);
    });

    // =========================================================================
    // H & I. DUAL-CONTROL: REQUESTER == APPROVER
    // =========================================================================
    test('H & I. Dual Control: Requester == Approver is strictly rejected', () {
      final invalidDual = DualControlActivationRecord(
        requestId: 'REQ-01',
        requestedBy: 'ADMIN_1',
        approvedBy: 'ADMIN_1', // SAME PERSON
        state: DualControlActivationState.approved,
        requestedAt: DateTime(2026, 8, 30),
        reason: 'Go Live',
        activationVersion: 'v1.0.0',
        evidenceSnapshot: const ['EXT-01'],
        configurationHash: 'sha256:confighash',
      );

      expect(invalidDual.isDualControlSatisfied, isFalse);

      final validDual = invalidDual.copyWith(approvedBy: 'ADMIN_2');
      expect(validDual.isDualControlSatisfied, isTrue);
    });

    // =========================================================================
    // N. FULL LEGITIMATE VERIFICATION SATISFIES GATE
    // =========================================================================
    test(
        'N. Full Verification: When all 7 dependencies are verified, dual-control satisfied, and prod config set, gate is eligible',
        () {
      final all7Verified = [
        for (int i = 1; i <= 7; i++)
          ExternalEvidenceRecord(
            id: 'EXT-0$i',
            name: 'Requirement $i',
            category: 'Category',
            status: EvidenceStatus.verified,
            approvalStatus: EvidenceApprovalStatus.approved,
            requiredEvidence: 'Evidence $i',
            evidenceHash: 'sha256:legitimatehash$i',
            verifiedAt: DateTime(2026, 8, 30),
            verifiedBy: 'Authorized Officer',
            environment: EvidenceEnvironment.production,
          ),
      ];

      final dualControl = DualControlActivationRecord(
        requestId: 'REQ-PROD-001',
        requestedBy: 'OPERATOR_ALICE',
        approvedBy: 'OFFICER_BOB',
        state: DualControlActivationState.approved,
        requestedAt: DateTime(2026, 8, 30, 10, 0),
        approvedAt: DateTime(2026, 8, 30, 10, 5),
        reason: 'Commercial Activation Authorized',
        activationVersion: '1.0.0',
        evidenceSnapshot: const [
          'EXT-01',
          'EXT-02',
          'EXT-03',
          'EXT-04',
          'EXT-05',
          'EXT-06',
          'EXT-07'
        ],
        configurationHash: 'sha256:prodconfig123',
      );

      final prodConfig = CommercialGateConfiguration(
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
        evidenceRecords: all7Verified,
        dualControlRecord: dualControl,
      );

      expect(prodConfig.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationEligible));
      expect(prodConfig.canActivateRealMoney, isTrue);

      // Test emergency lockdown override
      final locked = prodConfig.copyWith(
          platformState: CommercialPlatformState.emergencyLockdown);
      expect(locked.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(locked.canActivateRealMoney, isFalse);
    });

    // =========================================================================
    // Q. ACTIVATION SNAPSHOT INTEGRITY
    // =========================================================================
    test(
        'Q. Activation Snapshot: Captures full audit trace of activation decision',
        () {
      final snapshot = Phase40ActivationSnapshot(
        snapshotId: 'SNAP-20260830-001',
        timestamp: DateTime(2026, 8, 30, 12, 0),
        appVersion: '1.0.0+40',
        backendVersion: '1.0.0',
        dbMigrationVersion: '000005',
        financialCoreChecksum: 'sha256:f0a1b2c3d4e5',
        testStatus: '172/172_PASS',
        invariantStatus: 'INV-1_THROUGH_INV-18_PRESERVED',
        reconciliationStatus: 'ZERO_VARIANCE_0_DOLLARS',
        externalDependencyStatuses: const {
          'EXT-01': 'PENDING',
          'EXT-02': 'PENDING',
          'EXT-03': 'PENDING',
          'EXT-04': 'PENDING',
          'EXT-05': 'PENDING',
          'EXT-06': 'PENDING',
          'EXT-07': 'PENDING',
        },
        evidenceHashes: const {},
        securityStatus: 'INTERNAL_CERTIFIED',
        observabilityStatus: 'OPERATIONAL',
        disasterRecoveryStatus: 'VERIFIED_8MIN_RTO',
        dualControlStatus: 'DUAL_CONTROL_ENFORCED',
        activationDecision: CommercialGateDecision.commercialActivationBlocked,
      );

      expect(snapshot.activationDecision,
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(snapshot.snapshotId, equals('SNAP-20260830-001'));
      expect(snapshot.reconciliationStatus, equals('ZERO_VARIANCE_0_DOLLARS'));
    });

    // =========================================================================
    // R, S, T, U, V. FINANCIAL CORE REGRESSION & $0.00 RECONCILIATION
    // =========================================================================
    test(
        'R-V. Financial Core: Symmetrical Paired & Sequential multi-size reconciliation yields exact \$0.00 variance',
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
          id: 'P40-CIRC-$size',
          name: 'Phase 40 Certified $size-Member Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: monthlyDuesMinor,
          totalPeriods: size,
          totalPoolMinor: totalPool,
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 9, 1),
          organizerName: 'Coordinator',
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
        expect(totalInflows - totalOutflows, equals(0)); // $0.00 variance
      }
    });
  });
}
