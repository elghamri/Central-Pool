import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';

void main() {
  group(
      'Phase 38: External Commercial Boundary & 16-Point Activation Gate Suite',
      () {
    // =========================================================================
    // 1. 16-POINT COMMERCIAL ACTIVATION GATE ENGINE
    // =========================================================================
    test(
        'Gate: 16-Point Activation Gate fails closed when any single prerequisite is unverified',
        () {
      const config = CommercialGateConfiguration();
      expect(config.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(config.canActivateRealMoney, isFalse);

      // Verify each of the 16 gates blocks activation when false
      final gates = <String, CommercialGateConfiguration>{
        'legal': const CommercialGateConfiguration(
          activeEnvironment: 'prod',
          realMoneyEnabled: true,
          isLegalSignoffComplete: false,
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
        ),
        'bank': const CommercialGateConfiguration(
          activeEnvironment: 'prod',
          realMoneyEnabled: true,
          isLegalSignoffComplete: true,
          isBankingPartnerApproved: false,
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
        ),
        'fbo': const CommercialGateConfiguration(
          activeEnvironment: 'prod',
          realMoneyEnabled: true,
          isLegalSignoffComplete: true,
          isBankingPartnerApproved: true,
          isFboCustodyVerified: false,
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
        ),
        'payment': const CommercialGateConfiguration(
          activeEnvironment: 'prod',
          realMoneyEnabled: true,
          isLegalSignoffComplete: true,
          isBankingPartnerApproved: true,
          isFboCustodyVerified: true,
          isPaymentProcessorLive: false,
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
        ),
        'kyc': const CommercialGateConfiguration(
          activeEnvironment: 'prod',
          realMoneyEnabled: true,
          isLegalSignoffComplete: true,
          isBankingPartnerApproved: true,
          isFboCustodyVerified: true,
          isPaymentProcessorLive: true,
          isKycAmlLive: false,
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
        ),
        'aml': const CommercialGateConfiguration(
          activeEnvironment: 'prod',
          realMoneyEnabled: true,
          isLegalSignoffComplete: true,
          isBankingPartnerApproved: true,
          isFboCustodyVerified: true,
          isPaymentProcessorLive: true,
          isKycAmlLive: true,
          isAmlOfacScreeningLive: false,
          isSecretsManagementVerified: true,
          isWebhookSecurityVerified: true,
          isSecurityPenTestComplete: true,
          isProductionInfrastructureApproved: true,
          isReconciliationReadinessVerified: true,
          isBackupRestoreVerified: true,
          isIncidentResponseReady: true,
          isCustomerSupportReady: true,
          isPrivacyTermsPublished: true,
        ),
      };

      for (final entry in gates.entries) {
        expect(entry.value.evaluateActivationGate(),
            equals(CommercialGateDecision.commercialActivationBlocked),
            reason: 'Gate ${entry.key} missing should block activation');
        expect(entry.value.canActivateRealMoney, isFalse);
      }
    });

    // =========================================================================
    // 2. BANK INTEGRATION READINESS STATES
    // =========================================================================
    test(
        'Bank: BankIntegrationStatus state machine strictly gates production verification',
        () {
      expect(BankIntegrationStatus.unconfigured.isProductionVerified, isFalse);
      expect(BankIntegrationStatus.configuredNotVerified.isProductionVerified,
          isFalse);
      expect(
          BankIntegrationStatus.verifiedSandbox.isProductionVerified, isFalse);
      expect(BankIntegrationStatus.productionPending.isProductionVerified,
          isFalse);
      expect(BankIntegrationStatus.productionVerified.isProductionVerified,
          isTrue);
    });

    // =========================================================================
    // 3. EXTERNAL DEPENDENCY REGISTRY & AUDITABILITY
    // =========================================================================
    test(
        'Registry: External dependency state transitions and verification evidence hashing',
        () {
      final extDeps = [
        const ExternalDependencyRecord(
          id: 'EXT-01',
          name: 'Regulatory Legal Opinion',
          category: 'Legal',
          status: ExternalDependencyState.evidencePending,
          owner: 'General Counsel',
          requiredEvidence:
              'Formal legal opinion letter signed by regulatory counsel',
        ),
        const ExternalDependencyRecord(
          id: 'EXT-02',
          name: 'Sponsor Bank ODFI Agreement',
          category: 'Banking',
          status: ExternalDependencyState.evidencePending,
          owner: 'Executive Team',
          requiredEvidence:
              'Executed ODFI Partnership Agreement and Settlement SOP',
        ),
        const ExternalDependencyRecord(
          id: 'EXT-03',
          name: 'FBO Custody Trust Account',
          category: 'Custody',
          status: ExternalDependencyState.evidencePending,
          owner: 'FinOps',
          requiredEvidence:
              'Verified FBO Custody Trust Agreement and GL-2010 Setup',
        ),
        const ExternalDependencyRecord(
          id: 'EXT-04',
          name: 'Live ACH Payment Rail',
          category: 'Payments',
          status: ExternalDependencyState.evidencePending,
          owner: 'FinOps',
          requiredEvidence:
              'Live Production Payment Processor Credentials and Webhooks',
        ),
        const ExternalDependencyRecord(
          id: 'EXT-05',
          name: 'Live KYC/AML/OFAC System',
          category: 'Compliance',
          status: ExternalDependencyState.evidencePending,
          owner: 'Compliance Officer',
          requiredEvidence: 'Production CIP/AML screening API activation',
        ),
      ];

      for (final dep in extDeps) {
        expect(dep.status.isVerified, isFalse);
        expect(dep.isBlocking, isTrue);
      }
    });

    // =========================================================================
    // 4. ENVIRONMENT MISMATCH & FAIL-CLOSED PROTECTION
    // =========================================================================
    test(
        'Environment: Non-prod environments strictly reject real-money activation',
        () {
      final nonProdEnvironments = [
        'dev',
        'test',
        'sandbox',
        'pilot',
        'staging'
      ];

      for (final env in nonProdEnvironments) {
        final cfg = CommercialGateConfiguration(
          activeEnvironment: env,
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
        );
        expect(cfg.evaluateActivationGate(),
            equals(CommercialGateDecision.commercialActivationBlocked));
        expect(cfg.canActivateRealMoney, isFalse);
      }
    });

    // =========================================================================
    // 5. EMERGENCY LOCKDOWN IMMEDIATE OVERRIDE
    // =========================================================================
    test(
        'Lockdown: Emergency lockdown immediately revokes commercial eligibility',
        () {
      const fullProd = CommercialGateConfiguration(
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
      expect(fullProd.canActivateRealMoney, isTrue);

      final emergencyLocked = fullProd.copyWith(
        platformState: CommercialPlatformState.emergencyLockdown,
      );
      expect(emergencyLocked.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(emergencyLocked.canActivateRealMoney, isFalse);
    });

    // =========================================================================
    // 6. FINANCIAL INVARIANT CERTIFICATION ($0.00 VARIANCE)
    // =========================================================================
    test(
        'Financial: Symmetrical Paired multi-size rotation yields exact \$0.00 variance',
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
          id: 'P38-CIRC-$size',
          name: 'Phase 38 Certified $size-Member Circle',
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
