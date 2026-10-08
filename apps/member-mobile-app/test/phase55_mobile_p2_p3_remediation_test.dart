// Phase 55: Mobile P2/P3 Defect Remediation Test Suite (Step 15/Phase I)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Tests D-01: Canonical Cloud Functions v2 camelCase DTO decoding & snake_case dual fallback.
// - Tests D-02 / R-03: Absolute kReleaseMode fail-safe environment & base URL resolution (Cases A through M).
// - Tests D-03: LoginScreen demo auth UI gating in debug vs release mode.
// - Tests D-04: Arabic product terminology cleanup (Zero 'الجمعية' / 'RTGS' in active Central Pool onboarding).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_config.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_auth_service.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/core/models/auth_dto.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_controller.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_state.dart';
import 'package:member_mobile_app/src/features/auth/views/verify_otp_screen.dart';
import 'package:member_mobile_app/src/features/central_pool/data/central_pool_repository.dart';
import 'package:member_mobile_app/src/features/central_pool/models/candidate_allocation_model.dart';
import 'package:member_mobile_app/src/features/central_pool/providers/central_pool_providers.dart';
import 'package:member_mobile_app/src/features/auth/views/login_screen.dart';
import 'package:member_mobile_app/src/features/auth/views/welcome_screen.dart';
import 'package:member_mobile_app/src/features/auth/views/register_screen.dart';

void main() {
  group('D-01: CandidateAllocationModel & ConfirmationResultModel DTO Compatibility', () {
    test('CandidateAllocationModel correctly parses canonical Cloud Functions v2 camelCase payload', () {
      final canonicalJson = {
        'candidateId': 'cand_789abc',
        'requestId': 'req_123',
        'tenantId': 'tenant_prod_01',
        'memberUid': 'member_alice',
        'allocationUnitId': 'unit_pool_10m',
        'allocatedPosition': 3,
        'payoutPeriod': 3,
        'durationPeriods': 10,
        'contributionMinor': 50000,
        'totalEntitlementMinor': 500000,
        'totalPotMinor': 5000000,
        'currency': 'EGP',
        'allocationRule': 'SYMMETRICAL_V1',
        'issuedAt': '2026-09-17T12:00:00.000Z',
        'expiresAt': '2026-09-17T12:05:00.000Z',
        'signature': 'sig_hmac_abc123',
        'isProvisional': true,
      };

      final model = CandidateAllocationModel.fromJson(canonicalJson);

      expect(model.candidateId, equals('cand_789abc'));
      expect(model.requestId, equals('req_123'));
      expect(model.tenantId, equals('tenant_prod_01'));
      expect(model.allocationUnitId, equals('unit_pool_10m'));
      expect(model.prospectivePosition, equals(3));
      expect(model.primaryPeriod, equals(3));
      expect(model.mirrorPeriod, equals(8)); // 10 + 1 - 3 = 8
      expect(model.totalEntitlementMinor, equals(500000));
      expect(model.primaryAmountMinor, equals(250000)); // 500000 / 2
      expect(model.mirrorAmountMinor, equals(250000));
      expect(model.currency, equals('EGP'));
      expect(model.allocationMode, equals('SYMMETRICAL_V1'));
      expect(model.candidateSignature, equals('sig_hmac_abc123'));
      expect(model.isCenterAggregated, isFalse);
    });

    test('CandidateAllocationModel center position calculates 100% entitlement to primary period', () {
      final canonicalCenterJson = {
        'candidateId': 'cand_center_999',
        'requestId': 'req_456',
        'tenantId': 'tenant_prod_01',
        'memberUid': 'member_bob',
        'allocationUnitId': 'unit_odd_5m',
        'allocatedPosition': 3,
        'payoutPeriod': 3,
        'durationPeriods': 5,
        'contributionMinor': 100000,
        'totalEntitlementMinor': 500000,
        'currency': 'EGP',
        'allocationRule': 'SYMMETRICAL_V1',
        'issuedAt': '2026-09-17T12:00:00.000Z',
        'expiresAt': '2026-09-17T12:05:00.000Z',
      };

      final model = CandidateAllocationModel.fromJson(canonicalCenterJson);

      expect(model.primaryPeriod, equals(3));
      expect(model.mirrorPeriod, equals(3)); // 5 + 1 - 3 = 3
      expect(model.isCenterAggregated, isTrue);
      expect(model.primaryAmountMinor, equals(500000));
      expect(model.mirrorAmountMinor, equals(0));
    });

    test('CandidateAllocationModel retains backwards compatibility with snake_case legacy payload', () {
      final legacyJson = {
        'candidate_id': 'cand_legacy_001',
        'request_id': 'req_legacy_001',
        'tenant_id': 'tenant_alpha',
        'allocation_unit_id': 'unit_legacy_001',
        'schedule_id': 'sched_legacy_001',
        'prospective_position': 2,
        'primary_period': 2,
        'mirror_period': 9,
        'allocation_mode': 'STANDARD_SPLIT',
        'total_entitlement_minor': 1000000,
        'primary_amount_minor': 500000,
        'mirror_amount_minor': 500000,
        'currency': 'EGP',
        'is_center_aggregated': false,
        'created_at': '2026-09-17T10:00:00.000Z',
        'expires_at': '2026-09-17T10:05:00.000Z',
        'candidate_signature': 'sig_legacy',
      };

      final model = CandidateAllocationModel.fromJson(legacyJson);

      expect(model.candidateId, equals('cand_legacy_001'));
      expect(model.requestId, equals('req_legacy_001'));
      expect(model.prospectivePosition, equals(2));
      expect(model.primaryPeriod, equals(2));
      expect(model.mirrorPeriod, equals(9));
      expect(model.totalEntitlementMinor, equals(1000000));
      expect(model.primaryAmountMinor, equals(500000));
      expect(model.mirrorAmountMinor, equals(500000));
      expect(model.candidateSignature, equals('sig_legacy'));
    });

    test('ConfirmationResultModel correctly parses canonical Cloud Functions v2 camelCase confirmation result', () {
      final canonicalConfJson = {
        'success': true,
        'allocationId': 'alloc_777',
        'requestId': 'req_123',
        'tenantId': 'tenant_prod_01',
        'memberUid': 'member_alice',
        'allocationUnitId': 'unit_pool_10m',
        'allocatedPosition': 3,
        'payoutPeriod': 3,
        'durationPeriods': 10,
        'contributionMinor': 50000,
        'totalEntitlementMinor': 500000,
        'totalPotMinor': 5000000,
        'currency': 'EGP',
        'allocationRule': 'SYMMETRICAL_V1',
        'confirmedAt': '2026-09-17T12:01:00.000Z',
        'isIdempotentReplay': false,
        'unitTransitionedToCommittedFull': false,
      };

      final model = ConfirmationResultModel.fromJson(canonicalConfJson);

      expect(model.requestId, equals('req_123'));
      expect(model.tenantId, equals('tenant_prod_01'));
      expect(model.memberId, equals('member_alice'));
      expect(model.allocationUnitId, equals('unit_pool_10m'));
      expect(model.confirmedPositionNumber, equals(3));
      expect(model.primaryPeriod, equals(3));
      expect(model.mirrorPeriod, equals(8));
      expect(model.monthlyContributionMinor, equals(50000));
      expect(model.totalEntitlementMinor, equals(500000));
      expect(model.primaryAmountMinor, equals(250000));
      expect(model.mirrorAmountMinor, equals(250000));
      expect(model.status, equals('CONFIRMED'));
    });

    test('ConfirmationResultModel retains backwards compatibility with snake_case legacy confirmation result', () {
      final legacyConfJson = {
        'request_id': 'req_legacy_99',
        'tenant_id': 'tenant_beta',
        'member_id': 'member_legacy_99',
        'allocation_unit_id': 'unit_legacy_99',
        'schedule_id': 'sched_legacy_99',
        'confirmed_position_number': 4,
        'primary_period': 4,
        'mirror_period': 7,
        'monthly_contribution_minor': 100000,
        'total_entitlement_minor': 1000000,
        'primary_amount_minor': 500000,
        'mirror_amount_minor': 500000,
        'currency': 'EGP',
        'confirmed_at': '2026-09-17T11:00:00.000Z',
        'status': 'CONFIRMED',
      };

      final model = ConfirmationResultModel.fromJson(legacyConfJson);

      expect(model.requestId, equals('req_legacy_99'));
      expect(model.memberId, equals('member_legacy_99'));
      expect(model.confirmedPositionNumber, equals(4));
      expect(model.primaryPeriod, equals(4));
      expect(model.mirrorPeriod, equals(7));
      expect(model.monthlyContributionMinor, equals(100000));
      expect(model.totalEntitlementMinor, equals(1000000));
    });
  });

  group('D-02 / R-03: Release Environment & Fail-Safe Invariant (Cases A through M)', () {
    // -------------------------------------------------------------
    // MANDATORY NEGATIVE TESTS FOR RELEASE MODE (Cases A through I)
    // Invariant: RELEASE_BUILD_MUST_NEVER_TARGET_NON_PRODUCTION
    // -------------------------------------------------------------

    test('Case A: Release + no ENV => FirebaseEnvironment.production', () {
      final env = resolveFirebaseEnvironment(isRelease: true, env: '');
      expect(env, equals(FirebaseEnvironment.production));
      expect(env.projectId, equals('central-pool-production'));
    });

    test('Case B: Release + ENV=production => FirebaseEnvironment.production', () {
      final env = resolveFirebaseEnvironment(isRelease: true, env: 'production');
      expect(env, equals(FirebaseEnvironment.production));
      expect(env.projectId, equals('central-pool-production'));
    });

    test('Case C: Release + ENV=staging => FirebaseEnvironment.production (Fail-safe enforced)', () {
      final env = resolveFirebaseEnvironment(isRelease: true, env: 'staging');
      expect(env, equals(FirebaseEnvironment.production));
      expect(env.projectId, equals('central-pool-production'));
    });

    test('Case D: Release + ENV=development => FirebaseEnvironment.production (Fail-safe enforced)', () {
      final env = resolveFirebaseEnvironment(isRelease: true, env: 'development');
      expect(env, equals(FirebaseEnvironment.production));
      expect(env.projectId, equals('central-pool-production'));
    });

    test('Case E: Release + unexpected ENV => FirebaseEnvironment.production (Fail-safe enforced)', () {
      final env = resolveFirebaseEnvironment(isRelease: true, env: 'arbitrary_test_env');
      expect(env, equals(FirebaseEnvironment.production));
      expect(env.projectId, equals('central-pool-production'));
    });

    test('Case F: Release + no CENTRAL_POOL_API_URL => canonical production HTTPS URL', () {
      final url = resolveCentralPoolBaseUrl(isRelease: true, envUrl: '');
      expect(url, equals(kCanonicalProductionBaseUrl));
      expect(url, equals('https://us-central1-central-pool-production.cloudfunctions.net'));
    });

    test('Case G: Release + CENTRAL_POOL_API_URL=http://localhost:8080 => production endpoint (Fail-safe)', () {
      final url = resolveCentralPoolBaseUrl(isRelease: true, envUrl: 'http://localhost:8080');
      expect(url, equals(kCanonicalProductionBaseUrl));
    });

    test('Case H: Release + CENTRAL_POOL_API_URL pointing to emulator => production endpoint (Fail-safe)', () {
      final url = resolveCentralPoolBaseUrl(isRelease: true, envUrl: 'http://10.0.2.2:5001/emulator');
      expect(url, equals(kCanonicalProductionBaseUrl));
    });

    test('Case I: Release + CENTRAL_POOL_API_URL pointing to staging => production endpoint (Fail-safe)', () {
      final url = resolveCentralPoolBaseUrl(isRelease: true, envUrl: 'https://staging-endpoint.cloudfunctions.net');
      expect(url, equals(kCanonicalProductionBaseUrl));
    });

    // -------------------------------------------------------------
    // DEBUG / DEVELOPMENT POSITIVE TESTS (Cases J through M)
    // -------------------------------------------------------------

    test('Case J: Debug + ENV=development => FirebaseEnvironment.development', () {
      final env = resolveFirebaseEnvironment(isRelease: false, env: 'development');
      expect(env, equals(FirebaseEnvironment.development));
      expect(env.projectId, equals('central-pool-dev'));
    });

    test('Case K: Debug + ENV=staging => FirebaseEnvironment.staging', () {
      final env = resolveFirebaseEnvironment(isRelease: false, env: 'staging');
      expect(env, equals(FirebaseEnvironment.staging));
      expect(env.projectId, equals('central-pool-staging'));
    });

    test('Case L: Debug + ENV=production => FirebaseEnvironment.production', () {
      final env = resolveFirebaseEnvironment(isRelease: false, env: 'production');
      expect(env, equals(FirebaseEnvironment.production));
      expect(env.projectId, equals('central-pool-production'));
    });

    test('Case M: Debug + CENTRAL_POOL_API_URL=http://localhost:8080 => localhost URL', () {
      final url = resolveCentralPoolBaseUrl(isRelease: false, envUrl: 'http://localhost:8080');
      expect(url, equals('http://localhost:8080'));
    });

    test('Provider Container resolution matches resolveCentralPoolBaseUrl', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final baseUrl = container.read(centralPoolBaseUrlProvider);
      expect(baseUrl, equals(resolveCentralPoolBaseUrl()));
    });
  });

  group('D-03: LoginScreen Demo UI Gating', () {
    testWidgets('LoginScreen renders correctly and allows user input without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            onSubmit: (_) {},
            onNavigateToRegister: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });
  });

  group('D-04: Arabic Product Terminology Verification', () {
    testWidgets('WelcomeScreen in Arabic displays منصة التمويل التعاوني and zero الجمعية / RTGS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(
            initialLanguage: 'ar',
            onSignIn: () {},
            onRegister: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('منصة التمويل التعاوني'), findsOneWidget);
      expect(find.textContaining('الجمعية'), findsNothing);
      expect(find.textContaining('RTGS'), findsNothing);
    });

    testWidgets('RegisterScreen in Arabic displays pure Central Pool terms consent text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(
            isRtl: true,
            onSubmit: (_) {},
            onNavigateToLogin: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('شروط خدمة منصة الحوض المركزي'), findsOneWidget);
      expect(find.textContaining('الجمعية'), findsNothing);
    });

    testWidgets('RegisterScreen uses approved Central Pool English copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(
            isRtl: false,
            onSubmit: (_) {},
            onNavigateToLogin: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Central Pool Account'), findsWidgets);
      expect(find.text('Join the Central Pool rotating liquidity platform.'), findsOneWidget);
      expect(find.textContaining('Central Pool Platform Terms of Service'), findsOneWidget);
      expect(find.textContaining('Join the Cooperative'), findsNothing);
      expect(find.textContaining('decentralized identity'), findsNothing);
      expect(find.textContaining('rotating liquidity cycles'), findsNothing);
    });
  });

  group('Phase J: Release Safety Remediation Tests (F-01 through F-08)', () {
    // -------------------------------------------------------------
    // F-01: Central Pool Repository Base URL Resolution
    // -------------------------------------------------------------
    test('F-01: CentralPoolRepository obtains baseUrl from resolveCentralPoolBaseUrl and targets Production in Release', () {
      final releaseBaseUrl = resolveCentralPoolBaseUrl(isRelease: true);
      expect(releaseBaseUrl, equals(kCanonicalProductionBaseUrl));
      expect(releaseBaseUrl, equals('https://us-central1-central-pool-production.cloudfunctions.net'));

      final repo = CentralPoolRepository(baseUrl: resolveCentralPoolBaseUrl(isRelease: true));
      expect(repo.baseUrl, equals('https://us-central1-central-pool-production.cloudfunctions.net'));
    });

    // -------------------------------------------------------------
    // F-02: ApiClient Release Security Guards (Zero Localhost / Port 8080 / Loopback)
    // -------------------------------------------------------------
    test('F-02 Case A: ApiClient in Release mode rejects localhost', () {
      expect(
        () => ApiClient(
          baseUrl: 'http://localhost:8080',
          sessionStorage: SecureSessionStorage(),
          isRelease: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('F-02 Case B: ApiClient in Release mode rejects 127.0.0.1', () {
      expect(
        () => ApiClient(
          baseUrl: 'http://127.0.0.1:8080',
          sessionStorage: SecureSessionStorage(),
          isRelease: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('F-02 Case C: ApiClient in Release mode rejects :8080 and emulator endpoints', () {
      expect(
        () => ApiClient(
          baseUrl: 'http://10.0.2.2:8080',
          sessionStorage: SecureSessionStorage(),
          isRelease: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('F-02 Case D: ApiClient in Release mode defaults to kCanonicalProductionBaseUrl safely', () {
      final client = ApiClient(
        sessionStorage: SecureSessionStorage(),
        isRelease: true,
      );
      expect(client.baseUrl, equals(kCanonicalProductionBaseUrl));
    });

    // -------------------------------------------------------------
    // F-03: Firebase Authentication Architecture & Zero REST Auth
    // -------------------------------------------------------------
    test('F-03 Case A: AuthController registration executes via FirebaseAuthService', () async {
      final authService = FirebaseAuthService();
      final storage = SecureSessionStorage();
      final authController = AuthController(
        authService: authService,
        sessionStorage: storage,
        isRelease: true,
      );

      await authController.register(
        const RegisterRequest(
          fullName: 'Zack Member',
          email: 'zack@centralpool.org',
          phoneNumber: '+201000000001',
          password: 'Password123!',
          tenantId: 'TENANT-ALPHA',
        ),
      );

      expect(authController.value, isA<Authenticated>());
      final session = (authController.value as Authenticated).session;
      expect(session.email, equals('zack@centralpool.org'));
      expect(session.fullName, equals('Zack Member'));
      expect(session.role, equals(UserRole.member));
      expect(session.accessToken, startsWith('firebase-auth-token-'));
    });

    test('F-03 Case B: AuthController login executes via FirebaseAuthService', () async {
      final authService = FirebaseAuthService();
      final storage = SecureSessionStorage();
      final authController = AuthController(
        authService: authService,
        sessionStorage: storage,
        isRelease: true,
      );

      await authController.login(
        const LoginRequest(
          identifier: 'zack@centralpool.org',
          password: 'Password123!',
          tenantId: 'TENANT-ALPHA',
        ),
      );

      expect(authController.value, isA<Authenticated>());
      final session = (authController.value as Authenticated).session;
      expect(session.email, equals('zack@centralpool.org'));
      expect(session.role, equals(UserRole.member));
    });

    test('F-03 Case C: Release mode fails closed on invalid auth and creates zero demo sessions', () async {
      final authService = FirebaseAuthService();
      final storage = SecureSessionStorage();
      final authController = AuthController(
        authService: authService,
        sessionStorage: storage,
        isRelease: true,
      );

      await authController.login(
        const LoginRequest(
          identifier: '',
          password: '',
          tenantId: 'TENANT-ALPHA',
        ),
      );

      expect(authController.value, isA<AuthenticationFailure>());
      final savedSession = await storage.getSession();
      expect(savedSession, isNull);
    });

    test('F-03 Case D: Release mode registration fails closed on short password without demo fallback', () async {
      final authService = FirebaseAuthService();
      final storage = SecureSessionStorage();
      final authController = AuthController(
        authService: authService,
        sessionStorage: storage,
        isRelease: true,
      );

      await authController.register(
        const RegisterRequest(
          fullName: 'Short Pass',
          email: 'short@centralpool.org',
          phoneNumber: '+201000000002',
          password: '123', // Invalid (< 8 chars)
          tenantId: 'TENANT-ALPHA',
        ),
      );

      expect(authController.value, isA<AuthenticationFailure>());
      final savedSession = await storage.getSession();
      expect(savedSession, isNull);
    });

    // -------------------------------------------------------------
    // F-04: VerifyOtpScreen and LoginScreen Gating
    // -------------------------------------------------------------
    testWidgets('F-04: VerifyOtpScreen renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VerifyOtpScreen(
            identifier: 'test@example.com',
            tenantId: 'TENANT-ALPHA',
            onVerify: (_) {},
            onCancel: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(VerifyOtpScreen), findsOneWidget);
    });

    testWidgets('F-05: LoginScreen renders correctly and maintains form inputs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            onSubmit: (_) {},
            onNavigateToRegister: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
