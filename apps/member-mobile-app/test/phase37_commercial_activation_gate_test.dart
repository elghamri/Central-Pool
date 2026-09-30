import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';

void main() {
  group('Phase 37: Commercial Activation Gate & External Integration Suite',
      () {
    // =========================================================================
    // 1. WS-01 & WS-02: 10-POINT COMMERCIAL ACTIVATION GATE (FAIL-CLOSED)
    // =========================================================================
    test(
        'Gate: Commercial Activation Gate fails closed when any prerequisite is missing',
        () {
      const config = CommercialGateConfiguration();

      // Fresh config must be blocked
      expect(config.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(config.canActivateRealMoney, isFalse);

      // Partial approval (e.g. Bank approved, but KYC pending)
      final partial1 = config.copyWith(
        isLegalSignoffComplete: true,
        isBankingPartnerApproved: true,
        isFboCustodyVerified: true,
        isPaymentProcessorLive: true,
        isKycAmlLive: false, // Missing
        isAmlOfacScreeningLive: true,
        isSecretsManagementVerified: true,
        isWebhookSecurityVerified: true,
        isSecurityPenTestComplete: true,
        isProductionInfrastructureApproved: true,
        isReconciliationReadinessVerified: true,
        isObservabilityVerified: true,
        isBackupRestoreVerified: true,
        isEmergencyLockdownVerified: true,
        isIncidentResponseReady: true,
        isCustomerSupportReady: true,
        isPrivacyTermsPublished: true,
        realMoneyEnabled: true,
        activeEnvironment: 'prod',
      );
      expect(partial1.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(partial1.canActivateRealMoney, isFalse);

      // Fully approved in staging environment must still be blocked (environment safety)
      final stagingApproved = partial1.copyWith(
        isKycAmlLive: true,
        activeEnvironment: 'staging',
      );
      expect(stagingApproved.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(stagingApproved.canActivateRealMoney, isFalse);

      // Fully approved in prod environment with all 16 gates satisfied
      final prodApproved = stagingApproved.copyWith(
        activeEnvironment: 'prod',
        platformState: CommercialPlatformState.commercialActive,
      );
      expect(prodApproved.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationEligible));
      expect(prodApproved.canActivateRealMoney, isTrue);
    });

    // =========================================================================
    // 2. WS-01: EXTERNAL DEPENDENCY REGISTRY STATES
    // =========================================================================
    test('Registry: External dependency states and verification transitions',
        () {
      const dep = ExternalDependencyRecord(
        id: 'EXT-01',
        name: 'Regulatory Legal Opinion',
        category: 'Legal',
        owner: 'Legal Counsel',
        requiredEvidence: 'Formal legal opinion letter',
      );

      expect(dep.status, equals(ExternalDependencyState.notStarted));
      expect(dep.status.isVerified, isFalse);

      final requested = dep.copyWith(status: ExternalDependencyState.requested);
      expect(requested.status.isVerified, isFalse);

      final underReview =
          dep.copyWith(status: ExternalDependencyState.underReview);
      expect(underReview.status.isVerified, isFalse);

      final verified = dep.copyWith(
        status: ExternalDependencyState.verified,
        evidenceReference: 'OPINION-LETTER-2026-08',
        verificationTimestamp: DateTime(2026, 8, 30),
      );
      expect(verified.status.isVerified, isTrue);
      expect(verified.evidenceReference, isNotNull);
    });

    // =========================================================================
    // 3. WS-03: REAL-MONEY KILL SWITCH HARDENING
    // =========================================================================
    test(
        'KillSwitch: Real-money disabled by default across all test environments',
        () {
      final environments = ['dev', 'test', 'sandbox', 'pilot', 'staging'];

      for (final env in environments) {
        final cfg = CommercialGateConfiguration(activeEnvironment: env);
        expect(cfg.realMoneyEnabled, isFalse);
        expect(cfg.canActivateRealMoney, isFalse);

        // Attempting to force realMoneyEnabled in non-prod must still fail
        final forced = cfg.copyWith(
          realMoneyEnabled: true,
          isLegalSignoffComplete: true,
          isBankingPartnerApproved: true,
          isFboCustodyVerified: true,
          isPaymentProcessorLive: true,
          isKycAmlLive: true,
          isSecretsManagementVerified: true,
          isWebhookSecurityVerified: true,
          isObservabilityVerified: true,
          isBackupRestoreVerified: true,
          isEmergencyLockdownVerified: true,
        );
        expect(forced.canActivateRealMoney, isFalse,
            reason: 'Environment $env must block real money');
      }
    });

    // =========================================================================
    // 4. WS-05: KYC / AML PRODUCTION BOUNDARY STATES
    // =========================================================================
    test('KYC: All non-verified KYC states block financial operations', () {
      expect(
          KycVerificationStatus.none.isEligibleForFinancialOperations, isFalse);
      expect(KycVerificationStatus.notVerified.isEligibleForFinancialOperations,
          isFalse);
      expect(KycVerificationStatus.pending.isEligibleForFinancialOperations,
          isFalse);
      expect(KycVerificationStatus.failed.isEligibleForFinancialOperations,
          isFalse);
      expect(KycVerificationStatus.rejected.isEligibleForFinancialOperations,
          isFalse);
      expect(KycVerificationStatus.expired.isEligibleForFinancialOperations,
          isFalse);
      expect(
          KycVerificationStatus
              .manualReviewRequired.isEligibleForFinancialOperations,
          isFalse);
      expect(
          KycVerificationStatus.reviewRequired.isEligibleForFinancialOperations,
          isFalse);

      expect(KycVerificationStatus.approved.isEligibleForFinancialOperations,
          isTrue);
      expect(KycVerificationStatus.verified.isEligibleForFinancialOperations,
          isTrue);
    });

    // =========================================================================
    // 5. WS-09 & WS-10: FINANCIAL INVARIANT CERTIFICATION ($0.00 VARIANCE)
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
          id: 'CERT-CIRC-$size',
          name: 'Certified $size-Member Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: monthlyDuesMinor,
          totalPeriods: size,
          totalPoolMinor: totalPool,
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 9, 1),
          organizerName: 'Coordinator',
          slots: slots,
        );

        int totalInboundDues = 0;
        int totalOutboundDisbursed = 0;

        for (int p = 1; p <= size; p++) {
          totalInboundDues += size * monthlyDuesMinor;
          final activeSlots = circle.activePayoutSlotsForPeriod(p);
          for (final s in activeSlots) {
            totalOutboundDisbursed += circle.payoutAmountForSlotInPeriod(s, p);
          }
        }

        expect(totalInboundDues, equals(totalOutboundDisbursed));
        expect(totalInboundDues - totalOutboundDisbursed,
            equals(0)); // $0.00 residual
      }
    });

    // =========================================================================
    // 6. WS-12: EMERGENCY FINANCIAL LOCKDOWN SAFETY
    // =========================================================================
    test(
        'Lockdown: Emergency Lockdown instantly blocks eligible prod configuration',
        () {
      const eligibleConfig = CommercialGateConfiguration(
        activeEnvironment: 'prod',
        platformState: CommercialPlatformState.commercialActive,
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
        isObservabilityVerified: true,
        isBackupRestoreVerified: true,
        isEmergencyLockdownVerified: true,
        isIncidentResponseReady: true,
        isCustomerSupportReady: true,
        isPrivacyTermsPublished: true,
        realMoneyEnabled: true,
      );
      expect(eligibleConfig.canActivateRealMoney, isTrue);

      // Trigger Emergency Lockdown
      final locked = eligibleConfig.copyWith(
        platformState: CommercialPlatformState.emergencyLockdown,
      );
      expect(locked.evaluateActivationGate(),
          equals(CommercialGateDecision.commercialActivationBlocked));
      expect(locked.canActivateRealMoney, isFalse);
    });
  });
}
