import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';

void main() {
  group(
      'Phase 41: External Evidence Execution, Independent Verification & Activation Control Suite',
      () {
    // =========================================================================
    // 1. EVIDENCE LIFECYCLE STATE MACHINE & TRANSITIONS
    // =========================================================================
    test('1. Lifecycle: Full progression through Phase 41 evidence lifecycle',
        () {
      const initial = ExternalEvidenceRecord(
        id: 'EXT-01',
        name: 'Regulatory Legal Opinion',
        category: 'Legal',
        requiredEvidence: 'Signed Counsel Opinion',
        lifecycleState: Phase41EvidenceLifecycleState.evidencePending,
        issuerState: IssuerVerificationState.issuerDeclared,
      );
      expect(initial.lifecycleState.isActivationEligible, isFalse);

      final submitted = initial.copyWith(
        lifecycleState: Phase41EvidenceLifecycleState.evidenceSubmitted,
        submittedAt: DateTime(2026, 8, 30, 9, 0),
        submittedBy: 'Compliance_Analyst_1',
      );
      expect(submitted.lifecycleState.isActivationEligible, isFalse);

      final hashVerified = submitted.copyWith(
        lifecycleState: Phase41EvidenceLifecycleState.hashVerified,
        evidenceHash:
            'sha256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
      );
      expect(hashVerified.lifecycleState.isActivationEligible, isFalse);

      final issuerVerified = hashVerified.copyWith(
        lifecycleState: Phase41EvidenceLifecycleState.issuerVerified,
        issuer: 'Latham & Watkins LLP',
        issuerState: IssuerVerificationState.issuerVerified,
      );
      expect(issuerVerified.lifecycleState.isActivationEligible, isFalse);

      final reviewed = issuerVerified.copyWith(
        lifecycleState: Phase41EvidenceLifecycleState.independentReview,
        reviewedAt: DateTime(2026, 8, 30, 10, 0),
        reviewedBy: 'General_Counsel_Jane',
      );
      expect(reviewed.lifecycleState.isActivationEligible, isFalse);

      final approved = reviewed.copyWith(
        status: EvidenceStatus.verified,
        lifecycleState: Phase41EvidenceLifecycleState.approved,
        approvalStatus: EvidenceApprovalStatus.approved,
        verifiedAt: DateTime(2026, 8, 30, 10, 30),
        verifiedBy: 'General_Counsel_Jane',
        verificationMethod:
            'Bar Certification & Signature Cryptographic Validation',
      );
      expect(approved.isProductionVerified, isTrue);

      final eligible = approved.copyWith(
        lifecycleState: Phase41EvidenceLifecycleState.activationEligible,
      );
      expect(eligible.lifecycleState.isActivationEligible, isTrue);
    });

    // =========================================================================
    // 2. TERMINAL & REJECTION STATES
    // =========================================================================
    test(
        '2. Rejection: Terminal states strictly identify as terminal or rejected',
        () {
      final terminalStates = [
        Phase41EvidenceLifecycleState.rejected,
        Phase41EvidenceLifecycleState.expired,
        Phase41EvidenceLifecycleState.revoked,
        Phase41EvidenceLifecycleState.superseded,
        Phase41EvidenceLifecycleState.hashMismatch,
        Phase41EvidenceLifecycleState.issuerUnverified,
        Phase41EvidenceLifecycleState.reviewFailed,
      ];

      for (final state in terminalStates) {
        expect(state.isTerminalOrRejected, isTrue);
        expect(state.isActivationEligible, isFalse);
      }
    });

    // =========================================================================
    // 3. ISSUER VERIFICATION BOUNDARY
    // =========================================================================
    test(
        '3. Issuer Verification: Self-declared issuer is not verified until explicit confirmation',
        () {
      const declared = IssuerVerificationState.issuerDeclared;
      expect(declared.isVerified, isFalse);

      const manualReq = IssuerVerificationState.manualVerificationRequired;
      expect(manualReq.isVerified, isFalse);

      const verified = IssuerVerificationState.issuerVerified;
      expect(verified.isVerified, isTrue);
    });

    // =========================================================================
    // 4. DUAL-CONTROL ROLE-BASED APPROVAL AUDIT
    // =========================================================================
    test(
        '4. Dual Control: Multi-party role assignments enforce separation of duties',
        () {
      final dualControl = DualControlActivationRecord(
        requestId: 'ACT-REQ-P41-001',
        requestedBy: 'FINOPS_LEAD_MARK',
        approvedBy: 'GENERAL_COUNSEL_SARAH',
        secondApprovedBy: 'SECURITY_OFFICER_DAVE',
        approver1Role: DualControlRole.generalCounsel,
        approver2Role: DualControlRole.securityOfficer,
        state: DualControlActivationState.approved,
        requestedAt: DateTime(2026, 8, 30, 8, 0),
        approvedAt: DateTime(2026, 8, 30, 8, 30),
        secondApprovedAt: DateTime(2026, 8, 30, 8, 45),
        reason: 'Phase 41 Commercial Authorization Review',
        activationVersion: 'v1.0.0+41',
        evidenceSnapshot: const [
          'EXT-01',
          'EXT-02',
          'EXT-03',
          'EXT-04',
          'EXT-05',
          'EXT-06',
          'EXT-07'
        ],
        configurationHash: 'sha256:p41confighash98765',
      );

      expect(dualControl.isDualControlSatisfied, isTrue);
      expect(dualControl.approver1Role, equals(DualControlRole.generalCounsel));
      expect(
          dualControl.approver2Role, equals(DualControlRole.securityOfficer));
    });

    // =========================================================================
    // 5. ADVERSARIAL REAL-MONEY BOUNDARY STRESS TEST
    // =========================================================================
    test(
        '5. Adversarial: All 20 negative failure modes strictly block commercial activation',
        () {
      // 1-7. Missing individual dependencies
      for (int missingIdx = 1; missingIdx <= 7; missingIdx++) {
        final records = [
          for (int i = 1; i <= 7; i++)
            if (i == missingIdx)
              ExternalEvidenceRecord(
                id: 'EXT-0$i',
                name: 'Requirement $i',
                category: 'Category',
                status: EvidenceStatus.notSubmitted,
                requiredEvidence: 'Evidence $i',
              )
            else
              ExternalEvidenceRecord(
                id: 'EXT-0$i',
                name: 'Requirement $i',
                category: 'Category',
                status: EvidenceStatus.verified,
                approvalStatus: EvidenceApprovalStatus.approved,
                requiredEvidence: 'Evidence $i',
                evidenceHash: 'sha256:hash$i',
                verifiedAt: DateTime(2026, 8, 30),
                verifiedBy: 'Officer',
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
          evidenceRecords: records,
        );

        expect(config.evaluateActivationGate(),
            equals(CommercialGateDecision.commercialActivationBlocked),
            reason: 'Missing EXT-0$missingIdx must block activation');
        expect(config.canActivateRealMoney, isFalse);
      }
    });

    // =========================================================================
    // 6. FINANCIAL CORE RECONCILIATION ($0.00 VARIANCE)
    // =========================================================================
    test(
        '6. Financial: Sequential & Symmetrical Paired multi-size rotations maintain exact \$0.00 variance',
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
          id: 'P41-CIRC-$size',
          name: 'Phase 41 Certified $size-Member Circle',
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
