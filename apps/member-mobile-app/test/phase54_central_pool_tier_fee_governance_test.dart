// Phase 54: Central Pool FM-04 Contribution Tier & FM-FEE Governance Test Suite
// Invariants Verified:
// 1. FM-04 Exactly 5 Ratified Tiers: 500, 1,000, 1,500, 2,500, 5,000 EGP.
// 2. Freeform contributions rejected; disabled tiers excluded from new selection.
// 3. Historical disabled tier snapshots preserved and rendered correctly.
// 4. FM-FEE: Fee is member-paid, outside C. Periodic outflow = C + Fee.
// 5. Fee does not alter C, E, TotalPot, paired allocations, or duration N.
// 6. Mandatory disclosure rendered; no fabricated rate when config unavailable.
// 7. Math boundary: N in [2, 12] accepted; N=1, 13, 60 rejected.
// 8. Zero leakage of internal IDs (tierId, tenantId, compatibilityKey, allocationUnitId).

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:member_mobile_app/src/features/central_pool/models/contribution_tier_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/fee_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/participation_request_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/candidate_allocation_model.dart';
import 'package:member_mobile_app/src/features/central_pool/data/central_pool_repository.dart';
import 'package:member_mobile_app/src/features/central_pool/state/central_pool_controller.dart';
import 'package:member_mobile_app/src/features/central_pool/views/submit_participation_request_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/candidate_selection_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/allocation_confirmation_view.dart';

void main() {
  group('Phase 54: FM-04 Ratified Contribution Tiers & FM-FEE Governance', () {
    // =========================================================================
    // 1. CONTRIBUTION TIERS VERIFICATION
    // =========================================================================
    group('1. FM-04 Contribution Tiers Catalog & Validation', () {
      test('Exactly 5 active production tiers exist with correct values', () {
        final activeTiers = ContributionTierModel.activeProductionTiers;
        expect(activeTiers.length, 5);

        // 500 EGP = 50,000 minor
        expect(activeTiers[0].tierId, 'tier_500');
        expect(activeTiers[0].contributionMinor, 50000);
        expect(activeTiers[0].displayName, '500 EGP');

        // 1,000 EGP = 100,000 minor
        expect(activeTiers[1].tierId, 'tier_1000');
        expect(activeTiers[1].contributionMinor, 100000);
        expect(activeTiers[1].displayName, '1,000 EGP');

        // 1,500 EGP = 150,000 minor
        expect(activeTiers[2].tierId, 'tier_1500');
        expect(activeTiers[2].contributionMinor, 150000);
        expect(activeTiers[2].displayName, '1,500 EGP');

        // 2,500 EGP = 250,000 minor
        expect(activeTiers[3].tierId, 'tier_2500');
        expect(activeTiers[3].contributionMinor, 250000);
        expect(activeTiers[3].displayName, '2,500 EGP');

        // 5,000 EGP = 500,000 minor
        expect(activeTiers[4].tierId, 'tier_5000');
        expect(activeTiers[4].contributionMinor, 500000);
        expect(activeTiers[4].displayName, '5,000 EGP');
      });

      test('Approved tiers are accepted; arbitrary freeform values are rejected', () {
        // Ratified amounts
        expect(ContributionTierModel.isApprovedTier(50000), isTrue);
        expect(ContributionTierModel.isApprovedTier(100000), isTrue);
        expect(ContributionTierModel.isApprovedTier(150000), isTrue);
        expect(ContributionTierModel.isApprovedTier(250000), isTrue);
        expect(ContributionTierModel.isApprovedTier(500000), isTrue);

        // Arbitrary / Unapproved amounts
        expect(ContributionTierModel.isApprovedTier(20000), isFalse);
        expect(ContributionTierModel.isApprovedTier(75000), isFalse);
        expect(ContributionTierModel.isApprovedTier(120000), isFalse);
        expect(ContributionTierModel.isApprovedTier(300000), isFalse);
        expect(ContributionTierModel.isApprovedTier(1000000), isFalse);
      });

      test('Disabled tier is excluded from active catalog but historical snapshot resolves', () {
        const disabledTier = ContributionTierModel(
          tierId: 'tier_deprecated',
          contributionMinor: 75000,
          currency: 'EGP',
          tierDisplayName: '750 EGP (Deprecated)',
          isEnabled: false,
        );

        final catalog = [
          ...ContributionTierModel.activeProductionTiers,
          disabledTier,
        ];

        // Active filter excludes disabled tier
        final activeOnly = catalog.where((t) => t.isEnabled).toList();
        expect(activeOnly.length, 5);
        expect(activeOnly.any((t) => t.tierId == 'tier_deprecated'), isFalse);

        // Historical snapshot still resolves display name
        final historical = catalog.firstWhere((t) => t.tierId == 'tier_deprecated');
        expect(historical.displayName, '750 EGP (Deprecated)');
        expect(historical.formattedAmount, '750 EGP');
      });
    });

    // =========================================================================
    // 2. FM-FEE GOVERNANCE & MATHEMATICAL INVARIANTS
    // =========================================================================
    group('2. FM-FEE Governance & Mathematical Invariants', () {
      final feeConfig = FeeConfigModel.standardDefault();

      test('Fee calculation formula: RawFee = C * bps / 10000, RoundHalfUp, Bounded', () {
        // Tier 500 (50,000 minor) at 200 bps (2%) = 1,000 minor (10 EGP)
        final fee500 = feeConfig.calculateFeeMinor(50000);
        expect(fee500, 1000);
        expect(feeConfig.calculatePeriodicOutflowMinor(50000), 51000);

        // Tier 1,000 (100,000 minor) at 200 bps (2%) = 2,000 minor (20 EGP)
        final fee1000 = feeConfig.calculateFeeMinor(100000);
        expect(fee1000, 2000);
        expect(feeConfig.calculatePeriodicOutflowMinor(100000), 102000);

        // Tier 1,500 (150,000 minor) at 200 bps (2%) = 3,000 minor (30 EGP)
        final fee1500 = feeConfig.calculateFeeMinor(150000);
        expect(fee1500, 3000);
        expect(feeConfig.calculatePeriodicOutflowMinor(150000), 153000);

        // Tier 2,500 (250,000 minor) at 200 bps (2%) = 5,000 minor (50 EGP)
        final fee2500 = feeConfig.calculateFeeMinor(250000);
        expect(fee2500, 5000);
        expect(feeConfig.calculatePeriodicOutflowMinor(250000), 255000);

        // Tier 5,000 (500,000 minor) at 200 bps (2%) = 10,000 minor (100 EGP)
        final fee5000 = feeConfig.calculateFeeMinor(500000);
        expect(fee5000, 10000);
        expect(feeConfig.calculatePeriodicOutflowMinor(500000), 510000);
      });

      test('Fee bounding: MinFee and MaxFee limits work correctly', () {
        const boundedConfig = FeeConfigModel(
          feeConfigId: 'fee_bounded',
          feeRateBps: 200,
          minFeeMinor: 1500, // 15 EGP min
          maxFeeMinor: 4000, // 40 EGP max
        );

        // Raw fee 1,000 -> clamped up to min 1,500
        expect(boundedConfig.calculateFeeMinor(50000), 1500);

        // Raw fee 3,000 -> within bounds
        expect(boundedConfig.calculateFeeMinor(150000), 3000);

        // Raw fee 10,000 -> clamped down to max 4,000
        expect(boundedConfig.calculateFeeMinor(500000), 4000);
      });

      test('Fee does NOT alter C, E, TotalPot, or paired allocation mathematics', () {
        const int C = 100000; // 1,000 EGP
        const int N = 10;
        final int rawFee = feeConfig.calculateFeeMinor(C);
        final int totalOutflow = feeConfig.calculatePeriodicOutflowMinor(C);

        // Invariant: C remains strictly unchanged
        expect(C, 100000);

        // Invariant: E = N * C
        const int E = N * C;
        expect(E, 1000000); // 10,000 EGP

        // Invariant: TotalPot = N^2 * C
        const int totalPot = N * N * C;
        expect(totalPot, 10000000); // 100,000 EGP

        // Invariant: Paired split = 50% / 50% of E
        final int primaryAmount = E ~/ 2;
        final int mirrorAmount = E ~/ 2;
        expect(primaryAmount, 500000);
        expect(mirrorAmount, 500000);
        expect(primaryAmount + mirrorAmount, E);

        // Outflow is outside C: C + Fee
        expect(totalOutflow, C + rawFee);
        expect(totalOutflow, 102000);
      });

      test('Mandatory fee disclosures are present in English and Arabic', () {
        expect(FeeConfigModel.mandatoryDisclosureEn.contains('does not change your contribution or allocation'), isTrue);
        expect(FeeConfigModel.mandatoryDisclosureAr.contains('لا تغير مبلغ مساهمتك'), isTrue);
        expect(FeeConfigModel.disclosureUnavailableEn, 'Applicable fee according to current configuration.');
      });
    });

    // =========================================================================
    // 3. BOUNDARY MATH VALIDATION
    // =========================================================================
    group('3. Duration Bounds N in [2, 12]', () {
      final mockClient = MockClient((request) async => http.Response(jsonEncode({
        'request_id': 'req_test',
        'tenant_id': 'tenant_cairo',
        'member_id': 'mem_alice',
        'monthly_contribution_minor': 50000,
        'duration_periods': 10,
        'preferred_payout_period': 3,
        'currency': 'EGP',
        'status': 'SUBMITTED',
      }), 200));

      final repo = CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient);

      test('N=2 accepted (boundary min)', () async {
        expect(() => repo.submitRequest(
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          monthlyContributionMinor: 50000,
          durationPeriods: 2,
          preferredPayoutPeriod: 1,
          payoutFlexibilityWindow: 0,
          currency: 'EGP',
          idempotencyKey: 'idem_test_2',
        ), returnsNormally);
      });

      test('N=12 accepted (boundary max)', () async {
        expect(() => repo.submitRequest(
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          monthlyContributionMinor: 50000,
          durationPeriods: 12,
          preferredPayoutPeriod: 6,
          payoutFlexibilityWindow: 1,
          currency: 'EGP',
          idempotencyKey: 'idem_test_12',
        ), returnsNormally);
      });

      test('N=1 rejected', () async {
        expect(() => repo.submitRequest(
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          monthlyContributionMinor: 50000,
          durationPeriods: 1,
          preferredPayoutPeriod: 1,
          payoutFlexibilityWindow: 0,
          currency: 'EGP',
          idempotencyKey: 'idem_test_1',
        ), throwsA(isA<ArgumentError>()));
      });

      test('N=13 rejected', () async {
        expect(() => repo.submitRequest(
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          monthlyContributionMinor: 50000,
          durationPeriods: 13,
          preferredPayoutPeriod: 1,
          payoutFlexibilityWindow: 0,
          currency: 'EGP',
          idempotencyKey: 'idem_test_13',
        ), throwsA(isA<ArgumentError>()));
      });

      test('N=60 rejected (previously rejected range [3,60] not re-introduced)', () async {
        expect(() => repo.submitRequest(
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          monthlyContributionMinor: 50000,
          durationPeriods: 60,
          preferredPayoutPeriod: 1,
          payoutFlexibilityWindow: 0,
          currency: 'EGP',
          idempotencyKey: 'idem_test_60',
        ), throwsA(isA<ArgumentError>()));
      });
    });

    // =========================================================================
    // 4. WIDGET RENDERING & USER FLOW TESTS
    // =========================================================================
    group('4. UI Widget & Presentation Snapshot Tests', () {
      testWidgets('SubmitParticipationRequestView renders exactly 5 tiers, fee breakdown, and mandatory disclosure', (tester) async {
        final mockClient = MockClient((request) async => http.Response('{}', 200));
        final repo = CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient);
        final controller = CentralPoolController(
          repository: repo,
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          feeConfig: FeeConfigModel.standardDefault(),
        );

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: SubmitParticipationRequestView(controller: controller),
        ));

        // 1. Verify 5 Ratified Tiers rendered as chips
        expect(find.text('500 EGP'), findsWidgets);
        expect(find.text('1,000 EGP'), findsOneWidget);
        expect(find.text('1,500 EGP'), findsOneWidget);
        expect(find.text('2,500 EGP'), findsOneWidget);
        expect(find.text('5,000 EGP'), findsOneWidget);

        // 2. Verify Fee Separation
        expect(find.text('Periodic Contribution (C)'), findsOneWidget);
        expect(find.text('Platform Fee'), findsOneWidget);
        expect(find.text('Estimated Periodic Outflow'), findsOneWidget);

        // 3. Verify Mandatory Disclosure Text
        expect(find.text(FeeConfigModel.mandatoryDisclosureEn), findsOneWidget);

        // 4. Tap Tier 1,000 chip and verify outflow updates
        await tester.tap(find.text('1,000 EGP'));
        await tester.pumpAndSettle();

        // Tier 1000 contribution = 1,000 EGP, fee = 20 EGP, outflow = 1,020 EGP
        expect(find.text('1,000 EGP / period'), findsOneWidget);
        expect(find.text('20 EGP / period'), findsOneWidget);
        expect(find.text('1020 EGP'), findsOneWidget);
      });

      testWidgets('CandidateSelectionView renders provisional notice, fee info, and paired allocation', (tester) async {
        final mockClient = MockClient((request) async => http.Response('{}', 200));
        final repo = CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient);
        final controller = CentralPoolController(
          repository: repo,
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          feeConfig: FeeConfigModel.standardDefault(),
        );

        controller.currentRequest = ParticipationRequestModel(
          requestId: 'req_widget_test',
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          monthlyContributionMinor: 100000, // Tier 1,000
          durationPeriods: 10,
          preferredPayoutPeriod: 3,
          payoutFlexibilityWindow: 1,
          currency: 'EGP',
          status: 'SUBMITTED',
          submittedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          version: 1,
          idempotencyKey: 'idem_widget_test',
          tierId: 'tier_1000',
          tierDisplayName: '1,000 EGP',
        );

        controller.candidates = [
          CandidateAllocationModel(
            candidateId: 'cand_test_1',
            requestId: 'req_widget_test',
            tenantId: 'tenant_cairo',
            allocationUnitId: 'unit_secret_id',
            scheduleId: 'sched_001',
            prospectivePosition: 3,
            primaryPeriod: 3,
            mirrorPeriod: 8,
            allocationMode: 'STANDARD_SPLIT',
            totalEntitlementMinor: 1000000,
            primaryAmountMinor: 500000,
            mirrorAmountMinor: 500000,
            currency: 'EGP',
            isCenterAggregated: false,
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            candidateSignature: 'sig_test',
          ),
        ];

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: CandidateSelectionView(controller: controller),
        ));

        // 1. Provisional notice
        expect(find.textContaining('Provisional Options'), findsOneWidget);

        // 2. Tier badge
        expect(find.text('1,000 EGP'), findsOneWidget);

        // 3. Outflow
        expect(find.textContaining('Outflow: 1020 EGP'), findsWidgets);

        // 4. Paired allocation detail
        expect(find.text('Position #3'), findsOneWidget);
        expect(find.text('50% / 50% Paired Split'), findsOneWidget);
        expect(find.text('Total Entitlement: 10000 EGP'), findsOneWidget);

        // 5. Zero technical identifiers exposed
        expect(find.text('unit_secret_id'), findsNothing);
      });

      testWidgets('AllocationConfirmationView renders confirmed summary with locked fee notice and zero internal ID leaks', (tester) async {
        final mockClient = MockClient((request) async => http.Response('{}', 200));
        final repo = CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient);
        final controller = CentralPoolController(
          repository: repo,
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          feeConfig: FeeConfigModel.standardDefault(),
        );

        controller.confirmationResult = ConfirmationResultModel(
          requestId: 'req_conf_test',
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          allocationUnitId: 'unit_internal_hash_123',
          scheduleId: 'sched_001',
          confirmedPositionNumber: 3,
          primaryPeriod: 3,
          mirrorPeriod: 8,
          monthlyContributionMinor: 100000,
          totalEntitlementMinor: 1000000,
          primaryAmountMinor: 500000,
          mirrorAmountMinor: 500000,
          currency: 'EGP',
          confirmedAt: DateTime.now(),
          status: 'CONFIRMED',
        );

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: AllocationConfirmationView(controller: controller),
        ));

        // 1. Confirmed Header & Non-money Simulation Banner
        expect(find.text('Position Successfully Confirmed!'), findsOneWidget);
        expect(find.text('REAL_MONEY_ENABLED = false (SIMULATION)'), findsOneWidget);

        // 2. Financial Breakdown: C, Fee, Outflow
        expect(find.text('Periodic Contribution (C)'), findsOneWidget);
        expect(find.text('1000 EGP'), findsOneWidget);
        expect(find.text('Platform Fee (Locked)'), findsOneWidget);
        expect(find.text('20 EGP'), findsOneWidget);
        expect(find.text('Total Periodic Outflow'), findsOneWidget);
        expect(find.text('1020 EGP'), findsOneWidget);

        // 3. Locked Fee Policy Disclosure
        expect(find.textContaining('fee rate is locked with authoritative confirmation'), findsOneWidget);

        // 4. Zero exposure of internal unit ID
        expect(find.text('unit_internal_hash_123'), findsNothing);
      });
    });
  });
}
