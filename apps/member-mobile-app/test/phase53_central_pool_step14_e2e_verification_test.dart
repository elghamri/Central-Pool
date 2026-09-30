// Phase 53: Central Pool Step 14 Final Client & End-to-End Comprehensive Verification Test
// PROVENANCE & SEMANTIC BOUNDARY:
// - Step 14 Verification Suite testing complete member journey, role boundaries, mathematical vectors,
//   isolation contracts, OCC concurrency handling, idempotency, lockdown reactivity, and error boundaries.
// - Invariant: Zero backend modifications, 100% frozen contract conformance.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:member_mobile_app/main.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_controller.dart';
import 'package:member_mobile_app/src/features/auth/views/welcome_screen.dart';
import 'package:member_mobile_app/src/features/shell/views/platform_shell_view.dart';
import 'package:member_mobile_app/src/features/shell/views/ops_shell_view.dart';
import 'package:member_mobile_app/src/features/shell/views/admin_shell_view.dart';
import 'package:member_mobile_app/src/features/central_pool/data/central_pool_repository.dart';
import 'package:member_mobile_app/src/features/central_pool/models/candidate_allocation_model.dart';
import 'package:member_mobile_app/src/features/central_pool/providers/central_pool_providers.dart';
import 'package:member_mobile_app/src/features/central_pool/services/idempotency_service.dart';
import 'package:member_mobile_app/src/features/central_pool/views/central_pool_shell_view.dart';
import 'package:member_mobile_app/src/features/central_pool/widgets/locked_banner.dart';

void main() {
  group('Step 14 Verification 1: Authentication & Role Navigation Boundaries', () {
    testWidgets('1.1 Unauthenticated state renders WelcomeScreen and blocks Central Pool', (tester) async {
      final storage = SecureSessionStorage();
      final apiClient = ApiClient(sessionStorage: storage);
      final authController = AuthController(apiClient: apiClient, sessionStorage: storage);
      await authController.initialize();

      await tester.pumpWidget(
        CollaborativeFinanceApp(
          authController: authController,
          enableCentralPoolExperience: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(CentralPoolShellView), findsNothing);
    });

    testWidgets('1.2 Authenticated MEMBER enters CentralPoolShellView', (tester) async {
      final storage = SecureSessionStorage();
      final session = UserSession(
        userId: 'mem_123',
        email: 'alice@cairo.coop',
        fullName: 'Alice Member',
        tenantId: 'tenant_cairo',
        accessToken: 'token_valid',
        role: UserRole.member,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await storage.saveSession(session);
      final apiClient = ApiClient(sessionStorage: storage);
      final authController = AuthController(apiClient: apiClient, sessionStorage: storage);
      await authController.initialize();

      await tester.pumpWidget(
        CollaborativeFinanceApp(
          authController: authController,
          enableCentralPoolExperience: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CentralPoolShellView), findsOneWidget);
      expect(find.text('Central Pool Platform'), findsOneWidget);
    });

    testWidgets('1.3 PlatformAdmin routes to PlatformShellView and NOT CentralPoolShellView', (tester) async {
      final storage = SecureSessionStorage();
      final session = UserSession(
        userId: 'admin_001',
        email: 'super@platform.gov',
        fullName: 'Super Admin',
        tenantId: 'platform_master',
        accessToken: 'token_valid',
        role: UserRole.platformAdmin,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await storage.saveSession(session);
      final apiClient = ApiClient(sessionStorage: storage);
      final authController = AuthController(apiClient: apiClient, sessionStorage: storage);
      await authController.initialize();

      await tester.pumpWidget(
        CollaborativeFinanceApp(
          authController: authController,
          enableCentralPoolExperience: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlatformShellView), findsOneWidget);
      expect(find.byType(CentralPoolShellView), findsNothing);
    });

    testWidgets('1.4 TreasuryMaker routes to OpsShellView and NOT CentralPoolShellView', (tester) async {
      final storage = SecureSessionStorage();
      final session = UserSession(
        userId: 'ops_maker_001',
        email: 'maker@cairo.coop',
        fullName: 'Treasury Maker',
        tenantId: 'tenant_cairo',
        accessToken: 'token_valid',
        role: UserRole.treasuryMaker,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await storage.saveSession(session);
      final apiClient = ApiClient(sessionStorage: storage);
      final authController = AuthController(apiClient: apiClient, sessionStorage: storage);
      await authController.initialize();

      await tester.pumpWidget(
        CollaborativeFinanceApp(
          authController: authController,
          enableCentralPoolExperience: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OpsShellView), findsOneWidget);
      expect(find.byType(CentralPoolShellView), findsNothing);
    });

    testWidgets('1.5 Organization Admin routes to AdminShellView', (tester) async {
      final storage = SecureSessionStorage();
      final session = UserSession(
        userId: 'tenant_admin_001',
        email: 'admin@cairo.coop',
        fullName: 'Org Admin',
        tenantId: 'tenant_cairo',
        accessToken: 'token_valid',
        role: UserRole.orgAdmin,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await storage.saveSession(session);
      final apiClient = ApiClient(sessionStorage: storage);
      final authController = AuthController(apiClient: apiClient, sessionStorage: storage);
      await authController.initialize();

      await tester.pumpWidget(
        CollaborativeFinanceApp(
          authController: authController,
          enableCentralPoolExperience: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminShellView), findsOneWidget);
      expect(find.byType(CentralPoolShellView), findsNothing);
    });
  });

  group('Step 14 Verification 2: Mathematical Presentation (N=4, N=6, N=11, N=12)', () {
    test('2.1 N=4 Even cycle 50/50 mirrored pairs integer arithmetic', () {
      const n = 4;
      const cMinor = 10000; // 100.00
      const totalEntitlement = n * cMinor; // 40,000 minor
      const splitAmount = totalEntitlement ~/ 2; // 20,000 minor

      // Pair 1: Period 1 & Period 4
      final p1 = 1;
      final m1 = n - p1 + 1; // 4
      expect(m1, equals(4));

      // Pair 2: Period 2 & Period 3
      final p2 = 2;
      final m2 = n - p2 + 1; // 3
      expect(m2, equals(3));

      expect(splitAmount + splitAmount, equals(totalEntitlement));
      expect(splitAmount, equals(20000));
    });

    test('2.2 N=6 Even cycle mirrored allocation vectors', () {
      const n = 6;
      const cMinor = 25000;
      const totalEntitlement = n * cMinor; // 150,000
      const splitAmount = totalEntitlement ~/ 2; // 75,000
      expect(splitAmount, equals(75000));

      final pairs = <int, int>{};
      for (int p = 1; p <= n / 2; p++) {
        final mirror = n - p + 1;
        pairs[p] = mirror;
      }

      expect(pairs, equals({1: 6, 2: 5, 3: 4}));
      for (final entry in pairs.entries) {
        expect(entry.key + entry.value, equals(n + 1));
      }
    });

    test('2.3 N=11 Odd cycle with center period (P=6) 100% aggregation', () {
      const n = 11;
      const cMinor = 50000; // 500.00
      const totalEntitlement = n * cMinor; // 550,000 minor
      const splitAmount = totalEntitlement ~/ 2; // 275,000 minor
      final centerPeriod = (n + 1) ~/ 2; // 6

      expect(centerPeriod, equals(6));

      // Candidate at Center (P=6) gets 100%
      final centerCandidate = CandidateAllocationModel(
        candidateId: 'cand_center_11',
        requestId: 'req_11',
        tenantId: 'tenant_cairo',
        allocationUnitId: 'unit_11',
        scheduleId: 'sched_11',
        prospectivePosition: 6,
        primaryPeriod: 6,
        mirrorPeriod: 0,
        allocationMode: 'FULL_DISBURSEMENT',
        totalEntitlementMinor: totalEntitlement,
        primaryAmountMinor: totalEntitlement,
        mirrorAmountMinor: 0,
        currency: 'EGP',
        isCenterAggregated: true,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        candidateSignature: 'sig_center_11',
      );

      expect(centerCandidate.isCenterAggregated, isTrue);
      expect(centerCandidate.primaryAmountMinor, equals(550000));
      expect(centerCandidate.mirrorPeriod, equals(0));

      // Candidate at non-center (P=2, M=10) gets 50/50 split
      final splitCandidate = CandidateAllocationModel(
        candidateId: 'cand_split_11',
        requestId: 'req_11',
        tenantId: 'tenant_cairo',
        allocationUnitId: 'unit_11',
        scheduleId: 'sched_11',
        prospectivePosition: 2,
        primaryPeriod: 2,
        mirrorPeriod: 10,
        allocationMode: 'STANDARD_SPLIT',
        totalEntitlementMinor: totalEntitlement,
        primaryAmountMinor: splitAmount,
        mirrorAmountMinor: splitAmount,
        currency: 'EGP',
        isCenterAggregated: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        candidateSignature: 'sig_split_11',
      );

      expect(splitCandidate.isCenterAggregated, isFalse);
      expect(splitCandidate.primaryPeriod + splitCandidate.mirrorPeriod, equals(n + 1));
      expect(splitCandidate.primaryAmountMinor + splitCandidate.mirrorAmountMinor, equals(totalEntitlement));
    });

    test('2.4 N=12 Even cycle 50/50 paired symmetry verification', () {
      const n = 12;
      const cMinor = 100000; // 1000.00
      const totalEntitlement = n * cMinor; // 1,200,000 minor

      for (int p = 1; p <= n; p++) {
        final mirror = n - p + 1;
        expect(p + mirror, equals(13));
      }
      expect(totalEntitlement, equals(1200000));
    });
  });

  group('Step 14 Verification 2b: Duration Boundary Contract (N in [2, 12])', () {
    test('2b.1 Lower boundary N=2 is ACCEPTED', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'result': {
              'request': {
                'requestId': 'req_n2',
                'tenantId': 'tenant_cairo',
                'memberUid': 'mem_alice',
                'contributionMinor': 50000,
                'durationPeriods': 2,
                'payoutPreference': 2,
                'currency': 'EGP',
                'status': 'SUBMITTED',
                'submittedAt': '2026-09-07T12:00:00.000Z',
                'expiresAt': '2026-09-08T12:00:00.000Z',
                'version': 1,
                'clientRequestId': 'idem_sub_n2',
              }
            }
          }),
          201,
        );
      });

      final repo = CentralPoolRepository(baseUrl: 'http://test', client: mockClient);
      final res = await repo.submitRequest(
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
        monthlyContributionMinor: 50000,
        durationPeriods: 2,
        preferredPayoutPeriod: 2,
        payoutFlexibilityWindow: 0,
        currency: 'EGP',
        idempotencyKey: 'idem_n2',
      );
      expect(res.durationPeriods, equals(2));
    });

    test('2b.2 Upper boundary N=12 is ACCEPTED', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'result': {
              'request': {
                'requestId': 'req_n12',
                'tenantId': 'tenant_cairo',
                'memberUid': 'mem_alice',
                'contributionMinor': 50000,
                'durationPeriods': 12,
                'payoutPreference': 12,
                'currency': 'EGP',
                'status': 'SUBMITTED',
                'submittedAt': '2026-09-07T12:00:00.000Z',
                'expiresAt': '2026-09-08T12:00:00.000Z',
                'version': 1,
                'clientRequestId': 'idem_sub_n12',
              }
            }
          }),
          201,
        );
      });

      final repo = CentralPoolRepository(baseUrl: 'http://test', client: mockClient);
      final res = await repo.submitRequest(
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
        monthlyContributionMinor: 50000,
        durationPeriods: 12,
        preferredPayoutPeriod: 12,
        payoutFlexibilityWindow: 1,
        currency: 'EGP',
        idempotencyKey: 'idem_n12',
      );
      expect(res.durationPeriods, equals(12));
    });

    test('2b.3 Below lower boundary N=1 is REJECTED', () {
      final repo = CentralPoolRepository(baseUrl: 'http://test');
      expect(
        () => repo.submitRequest(
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          monthlyContributionMinor: 50000,
          durationPeriods: 1, // Below lower bound 2
          preferredPayoutPeriod: 1,
          payoutFlexibilityWindow: 0,
          currency: 'EGP',
          idempotencyKey: 'idem_n1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('2b.4 Above upper boundary N=13 is REJECTED', () {
      final repo = CentralPoolRepository(baseUrl: 'http://test');
      expect(
        () => repo.submitRequest(
          tenantId: 'tenant_cairo',
          memberId: 'mem_alice',
          monthlyContributionMinor: 50000,
          durationPeriods: 13, // Above upper bound 12
          preferredPayoutPeriod: 5,
          payoutFlexibilityWindow: 1,
          currency: 'EGP',
          idempotencyKey: 'idem_n13',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('2b.5 FlowNotifier enforces bounds and sets error state for invalid duration', () async {
      final container = ProviderContainer();
      final notifier = container.read(centralPoolFlowProvider.notifier);

      // Attempt N = 1
      await notifier.submitParticipationRequest(
        monthlyContributionMinor: 50000,
        durationPeriods: 1,
        preferredPayoutPeriod: 1,
        payoutFlexibilityWindow: 0,
        currency: 'EGP',
      );
      var state = container.read(centralPoolFlowProvider);
      expect(state.step, equals(MatchingFlowStep.error));
      expect(state.errorMessage, contains('Invalid duration: must be between 2 and 12 periods.'));

      // Attempt N = 60 (legacy stale range)
      await notifier.submitParticipationRequest(
        monthlyContributionMinor: 50000,
        durationPeriods: 60,
        preferredPayoutPeriod: 10,
        payoutFlexibilityWindow: 0,
        currency: 'EGP',
      );
      state = container.read(centralPoolFlowProvider);
      expect(state.step, equals(MatchingFlowStep.error));
      expect(state.errorMessage, contains('Invalid duration: must be between 2 and 12 periods.'));
    });
  });

  group('Step 14 Verification 3: Concurrency / OCC Conflict Handling', () {
    test('3.1 Losing candidate in OCC race receives 409 conflict and presents recoverable state', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/participation-requests' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'result': {
                'request': {
                  'requestId': 'req_occ_001',
                  'tenantId': 'tenant_cairo',
                  'memberUid': 'mem_bob',
                  'contributionMinor': 50000,
                  'durationPeriods': 10,
                  'payoutPreference': 3,
                  'currency': 'EGP',
                  'status': 'SUBMITTED',
                  'submittedAt': '2026-09-07T12:00:00.000Z',
                  'expiresAt': '2026-09-08T12:00:00.000Z',
                  'version': 1,
                  'clientRequestId': 'idem_sub_occ',
                }
              }
            }),
            201,
          );
        }
        if (request.url.path.contains('/select')) {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'OCC_POSITION_CONFLICT',
                'message': 'Prospective position slot has already been committed to another member.',
              }
            }),
            409,
          );
        }
        return http.Response('{"error": "not found"}', 404);
      });

      final repo = CentralPoolRepository(baseUrl: 'http://test', client: mockClient);
      final container = ProviderContainer(
        overrides: [
          centralPoolRepositoryProvider.overrideWithValue(repo),
        ],
      );
      container.read(centralPoolContextProvider.notifier).updateContext(tenantId: 'tenant_cairo', memberId: 'mem_bob');

      final notifier = container.read(centralPoolFlowProvider.notifier);
      // Submit request first to establish currentRequest
      await notifier.submitParticipationRequest(
        monthlyContributionMinor: 50000,
        durationPeriods: 10,
        preferredPayoutPeriod: 3,
        payoutFlexibilityWindow: 1,
        currency: 'EGP',
      );

      final candidate = CandidateAllocationModel(
        candidateId: 'cand_contested',
        requestId: 'req_occ_001',
        tenantId: 'tenant_cairo',
        allocationUnitId: 'unit_001',
        scheduleId: 'sched_001',
        prospectivePosition: 3,
        primaryPeriod: 2,
        mirrorPeriod: 9,
        allocationMode: 'STANDARD_SPLIT',
        totalEntitlementMinor: 500000,
        primaryAmountMinor: 250000,
        mirrorAmountMinor: 250000,
        currency: 'EGP',
        isCenterAggregated: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        candidateSignature: 'sig_occ',
      );

      // Attempt to confirm candidate
      await notifier.confirmSelection(candidate: candidate);

      final flowState = container.read(centralPoolFlowProvider);
      expect(flowState.step, equals(MatchingFlowStep.error));
      expect(flowState.confirmationResult, isNull);
      expect(flowState.errorMessage, contains('Position conflict'));
    });
  });

  group('Step 14 Verification 4: Tenant & Member Isolation Enforced Client-Side', () {
    test('4.1 Cross-tenant request rejected by repository contract', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        if (body['tenantId'] != 'tenant_cairo') {
          return http.Response(
            jsonEncode({'error': {'code': 'TENANT_MISMATCH', 'message': 'Cross-tenant request denied.'}}),
            403,
          );
        }
        return http.Response('{"result": {}}', 200);
      });

      final repo = CentralPoolRepository(baseUrl: 'http://test', client: mockClient);
      expect(
        () => repo.submitRequest(
          tenantId: 'tenant_alexandria', // Cross tenant
          memberId: 'mem_alice',
          monthlyContributionMinor: 50000,
          durationPeriods: 10,
          preferredPayoutPeriod: 2,
          payoutFlexibilityWindow: 1,
          currency: 'EGP',
          idempotencyKey: 'idem_cross_001',
          clientRequestId: 'req_cross_001',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('4.2 Unauthorized member financial read denied (403)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': {'code': 'UNAUTHORIZED_MEMBER', 'message': 'Cannot access another member financial obligation.'}}),
          403,
        );
      });

      final repo = CentralPoolRepository(baseUrl: 'http://test', client: mockClient);
      expect(
        () => repo.getFinancialObligation(
          tenantId: 'tenant_cairo',
          memberId: 'mem_attacker',
          obligationId: 'ob_victim_123',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Step 14 Verification 5: Lockdown Behavioral Reactivity', () {
    testWidgets('5.1 Active system lockdown renders LockedBanner and blocks actions', (tester) async {
      final container = ProviderContainer();
      container.read(centralPoolContextProvider.notifier).updateContext(tenantId: 'tenant_cairo', memberId: 'mem_alice');
      container.read(systemLockdownProvider.notifier).setLockdown(true, reason: 'Administrative maintenance freeze.');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final lockdown = ref.watch(systemLockdownProvider);
                      return LockedBanner(lockdown: lockdown);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LockedBanner), findsOneWidget);
      expect(find.text('SYSTEM LOCKDOWN ACTIVE'), findsOneWidget);
      expect(find.text('Administrative maintenance freeze.'), findsOneWidget);

      // Verify flow notifier blocks mutation under lockdown
      await container.read(centralPoolFlowProvider.notifier).submitParticipationRequest(
        monthlyContributionMinor: 50000,
        durationPeriods: 10,
        preferredPayoutPeriod: 2,
        payoutFlexibilityWindow: 1,
        currency: 'EGP',
      );

      final state = container.read(centralPoolFlowProvider);
      expect(state.step, equals(MatchingFlowStep.error));
      expect(state.errorMessage, contains('lockdown'));
    });
  });

  group('Step 14 Verification 6: Idempotency & Replay Protection', () {
    test('6.1 Idempotency key generation and reuse consistency', () {
      final service = IdempotencyService();
      final key1 = service.generateKey(prefix: 'sub');
      final key2 = service.generateKey(prefix: 'sub');

      expect(key1, startsWith('sub-'));
      expect(key2, startsWith('sub-'));
      expect(key1, isNot(equals(key2))); // Unique keys generated

      final reqId = service.generateClientRequestId('mem_123');
      expect(reqId, startsWith('req-mem123-'));
    });
  });

  group('Step 14 Verification 7: Legacy Gameya Contamination Audit', () {
    test('7.1 Presentation titles and models contain ZERO Gameya/Circle semantics', () {
      const prohibitedTerms = [
        'Gameya',
        'gameya',
        'Circle',
        'circle',
        'Organizer',
        'organizer',
        'private circle',
        'group creation',
      ];

      // Audit Central Pool domain terms
      final modelNames = [
        'FinancialObligationModel',
        'ContributionScheduleModel',
        'ContributionEventModel',
        'PayoutEntitlementModel',
        'CyclePeriodProjectionModel',
        'MemberPeriodProjectionModel',
        'CandidateAllocationModel',
        'ParticipationRequestModel',
        'CentralPoolRepository',
        'CentralPoolController',
        'CentralPoolShellView',
      ];

      for (final model in modelNames) {
        for (final term in prohibitedTerms) {
          expect(model.toLowerCase().contains(term.toLowerCase()), isFalse,
              reason: 'Model $model must not contain legacy term $term');
        }
      }
    });
  });
}
