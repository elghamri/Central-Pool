import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/commercial_readiness_models.dart';

void main() {
  group('Phase 36: Commercial Readiness & Pre-Production Hardening Suite', () {
    // =========================================================================
    // 1. MONEY SAFETY & REAL-MONEY KILL SWITCH
    // =========================================================================
    test(
        'Safety: Real-money disabled by default and gated by external prerequisites',
        () {
      const config = CommercialGateConfiguration();

      // Default state verification
      expect(config.realMoneyEnabled, isFalse);
      expect(
          config.platformState, equals(CommercialPlatformState.preProduction));
      expect(config.canActivateRealMoney, isFalse);

      // Attempt activation without partner sign-off
      final attemptedActivation = config.copyWith(realMoneyEnabled: true);
      expect(attemptedActivation.canActivateRealMoney, isFalse,
          reason:
              'Cannot activate real money without banking, KYC, and legal gates');

      // Full external gate satisfaction
      final fullyApproved = config.copyWith(
        isBankingPartnerApproved: true,
        isPaymentProcessorLive: true,
        isKycAmlLive: true,
        isAmlOfacScreeningLive: true,
        isLegalSignoffComplete: true,
        isSecurityPenTestComplete: true,
        isProductionInfrastructureApproved: true,
        isReconciliationReadinessVerified: true,
        isFboCustodyVerified: true,
        isSecretsManagementVerified: true,
        isWebhookSecurityVerified: true,
        isObservabilityVerified: true,
        isBackupRestoreVerified: true,
        isEmergencyLockdownVerified: true,
        isIncidentResponseReady: true,
        isCustomerSupportReady: true,
        isPrivacyTermsPublished: true,
        activeEnvironment: 'prod',
        realMoneyEnabled: true,
        platformState: CommercialPlatformState.commercialActive,
      );
      expect(fullyApproved.canActivateRealMoney, isTrue);
    });

    // =========================================================================
    // 2. EMERGENCY FINANCIAL LOCKDOWN
    // =========================================================================
    test('Lockdown: Emergency financial lockdown immediately blocks real money',
        () {
      final activeConfig = const CommercialGateConfiguration().copyWith(
        isBankingPartnerApproved: true,
        isPaymentProcessorLive: true,
        isKycAmlLive: true,
        isAmlOfacScreeningLive: true,
        isLegalSignoffComplete: true,
        isSecurityPenTestComplete: true,
        isProductionInfrastructureApproved: true,
        isReconciliationReadinessVerified: true,
        isFboCustodyVerified: true,
        isSecretsManagementVerified: true,
        isWebhookSecurityVerified: true,
        isObservabilityVerified: true,
        isBackupRestoreVerified: true,
        isEmergencyLockdownVerified: true,
        isIncidentResponseReady: true,
        isCustomerSupportReady: true,
        isPrivacyTermsPublished: true,
        activeEnvironment: 'prod',
        realMoneyEnabled: true,
        platformState: CommercialPlatformState.commercialActive,
      );
      expect(activeConfig.canActivateRealMoney, isTrue);

      // Trigger Emergency Lockdown
      final lockedConfig = activeConfig.copyWith(
        platformState: CommercialPlatformState.emergencyLockdown,
      );
      expect(lockedConfig.platformState.isLockdownActive, isTrue);
      expect(lockedConfig.canActivateRealMoney, isFalse);
    });

    // =========================================================================
    // 3. KYC / AML COMPLIANCE ABSTRACTION
    // =========================================================================
    test(
        'Compliance: KYC status transitions strictly enforce financial eligibility',
        () {
      expect(
          KycVerificationStatus.none.isEligibleForFinancialOperations, isFalse);
      expect(KycVerificationStatus.pending.isEligibleForFinancialOperations,
          isFalse);
      expect(KycVerificationStatus.rejected.isEligibleForFinancialOperations,
          isFalse);
      expect(KycVerificationStatus.expired.isEligibleForFinancialOperations,
          isFalse);
      expect(
          KycVerificationStatus
              .manualReviewRequired.isEligibleForFinancialOperations,
          isFalse);
      expect(KycVerificationStatus.approved.isEligibleForFinancialOperations,
          isTrue);
    });

    // =========================================================================
    // 4. SYMMETRICAL PAIRED FINANCIAL TRUTH (4, 6, 8, 10, 12 MEMBERS)
    // =========================================================================
    test(
        'Financial: Symmetrical Paired 50/50 disbursements verified across even circle sizes',
        () {
      final evenSizes = [4, 6, 8, 10, 12];
      const monthlyMinor = 50000; // $500.00

      for (final size in evenSizes) {
        final totalPool = size * monthlyMinor;
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
          id: 'TEST-CIRC-$size',
          name: '$size-Member Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: monthlyMinor,
          totalPeriods: size,
          totalPoolMinor: totalPool,
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 9, 1),
          organizerName: 'Organizer',
          slots: slots,
        );

        // Verify each position's two 50% disbursements
        for (int s = 1; s <= size; s++) {
          final p1 = circle.primaryPayoutPeriodFor(s);
          final p2 = circle.mirrorPayoutPeriodFor(s);

          expect(p1 + p2, equals(size + 1),
              reason: 'Periods must sum to N + 1');
          expect(circle.payoutAmountForSlotInPeriod(s, p1), equals(halfPayout));
          expect(circle.payoutAmountForSlotInPeriod(s, p2), equals(halfPayout));
          expect(
              circle.payoutAmountForSlotInPeriod(s, p1) +
                  circle.payoutAmountForSlotInPeriod(s, p2),
              equals(totalPool));
        }
      }
    });

    // =========================================================================
    // 5. ODD SIZED CIRCLE IN SYMMETRICAL MODE WITH 100% MID PAYOUT
    // =========================================================================
    test(
        'Invariant: Odd sized circles (3, 5, 7, 9, 11) succeed in Symmetrical mode with Middle Month 100% payout',
        () {
      final oddSizes = [3, 5, 7, 9, 11];

      for (final size in oddSizes) {
        final circle = GameyaCircle(
          id: 'ODD-$size',
          name: 'Odd Circle',
          goalCategory: 'Savings',
          monthlyContributionMinor: 50000,
          totalPeriods: size,
          totalPoolMinor: size * 50000,
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 9, 1),
          organizerName: 'Organizer',
          slots: const [],
        );

        final midSlot = (size + 1) ~/ 2;
        final mid = circle.slots.firstWhere((s) => s.slotNumber == midSlot);
        expect(mid.payoutAmountMinor, equals(circle.totalPoolMinor));
        expect(mid.pairedSlotNumber, isNull);
      }
    });

    // =========================================================================
    // 6. MULTI-CIRCLE RECONCILIATION INTEGRITY ($0.00 VARIANCE)
    // =========================================================================
    test('Reconciliation: Double-entry ledger balance yields \$0.00 variance',
        () {
      final circles = [
        GameyaCircle(
          id: 'C-4',
          name: '4-Member Circle',
          goalCategory: 'Family',
          monthlyContributionMinor: 25000, // $250
          totalPeriods: 4,
          totalPoolMinor: 100000, // $1,000
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 9, 1),
          organizerName: 'Organizer',
          slots: const [],
        ),
        GameyaCircle(
          id: 'C-10',
          name: '10-Member Circle',
          goalCategory: 'Family',
          monthlyContributionMinor: 50000, // $500
          totalPeriods: 10,
          totalPoolMinor: 500000, // $5,000
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          startDate: DateTime(2026, 9, 1),
          organizerName: 'Organizer',
          slots: const [],
        ),
      ];

      int totalInflows = 0;
      int totalOutflows = 0;

      for (final c in circles) {
        for (int p = 1; p <= c.totalPeriods; p++) {
          totalInflows += c.totalPeriods * c.monthlyContributionMinor;
          final activeSlots = c.activePayoutSlotsForPeriod(p);
          for (final s in activeSlots) {
            totalOutflows += c.payoutAmountForSlotInPeriod(s, p);
          }
        }
      }

      expect(totalInflows, equals(totalOutflows));
      expect(totalInflows - totalOutflows, equals(0)); // $0.00 variance
    });
  });
}
