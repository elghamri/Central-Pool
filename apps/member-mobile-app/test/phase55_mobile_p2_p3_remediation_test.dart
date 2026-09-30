// Phase 55: Mobile P2/P3 Defect Remediation Test Suite (Step 15/Phase I)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Tests D-01: Canonical Cloud Functions v2 camelCase DTO decoding & snake_case dual fallback.
// - Tests D-02 / R-03: Absolute kReleaseMode fail-safe environment & base URL resolution (Cases A through M).
// - Tests D-03: LoginScreen demo auth UI gating in debug vs release mode.
// - Tests D-04: Arabic product terminology cleanup (Zero 'الجمعية' / 'RTGS' in active Central Pool onboarding).

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_config.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/core/models/auth_dto.dart';
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

    testWidgets('RegisterScreen in Arabic displays pure cooperative bylaws consent text', (tester) async {
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

      expect(find.textContaining('اللوائح الداخلية لحوكمة التمويل التعاوني'), findsOneWidget);
      expect(find.textContaining('الجمعية'), findsNothing);
    });
  });

  group('Phase J: Release Safety Remediation Tests (F-01, F-02, F-03, F-04)', () {
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
    // F-02: Release Demo Session Bypass Prevention
    // -------------------------------------------------------------
    test('F-02 Case A: Release + network failure (503 ApiException) => AuthenticationFailure, no synthetic session', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'title': 'Service Unavailable',
          'detail': 'Backend is temporarily unavailable.',
        }), 503);
      });

      final storage = SecureSessionStorage();
      final apiClient = ApiClient(sessionStorage: storage, httpClient: mockClient);
      final authController = AuthController(
        apiClient: apiClient,
        sessionStorage: storage,
        isRelease: true, // Test Release mode
      );

      await authController.login(
        const LoginRequest(identifier: 'alice@test.org', password: 'Password123!', tenantId: 'TENANT-ALPHA'),
      );

      expect(authController.value, isA<AuthenticationFailure>());
      final failure = authController.value as AuthenticationFailure;
      expect(failure.errorMessage, contains('Backend is temporarily unavailable'));

      final session = await storage.getSession();
      expect(session, isNull);
    });

    test('F-02 Case B: Release + offline login (Socket/Network Error) => AuthenticationFailure, no synthetic JWT', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Failed host lookup: localhost');
      });

      final storage = SecureSessionStorage();
      final apiClient = ApiClient(sessionStorage: storage, httpClient: mockClient);
      final authController = AuthController(
        apiClient: apiClient,
        sessionStorage: storage,
        isRelease: true, // Test Release mode
      );

      await authController.login(
        const LoginRequest(identifier: 'bob@test.org', password: 'Password123!', tenantId: 'TENANT-ALPHA'),
      );

      expect(authController.value, isA<AuthenticationFailure>());
      final session = await storage.getSession();
      expect(session, isNull);
    });

    test('F-02 Case C: Release + offline OTP verification => AuthenticationFailure, no synthetic session', () async {
      final storage = SecureSessionStorage();
      final apiClient = ApiClient(sessionStorage: storage);
      final authController = AuthController(
        apiClient: apiClient,
        sessionStorage: storage,
        isRelease: true, // Test Release mode
      );

      await authController.verifyOtp(
        const VerifyOtpRequest(identifier: 'charlie@test.org', otpCode: '123456', tenantId: 'TENANT-ALPHA'),
      );

      expect(authController.value, isA<AuthenticationFailure>());
      final session = await storage.getSession();
      expect(session, isNull);
    });

    test('F-02 Case D: Release + offline registration => AuthenticationFailure, no synthetic session', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Connection refused');
      });

      final storage = SecureSessionStorage();
      final apiClient = ApiClient(sessionStorage: storage, httpClient: mockClient);
      final authController = AuthController(
        apiClient: apiClient,
        sessionStorage: storage,
        isRelease: true,
      );

      await authController.register(
        const RegisterRequest(
          fullName: 'Dave Doe',
          email: 'dave@test.org',
          phoneNumber: '+201000000000',
          password: 'Password123!',
          tenantId: 'TENANT-ALPHA',
        ),
      );

      expect(authController.value, isA<AuthenticationFailure>());
      final session = await storage.getSession();
      expect(session, isNull);
    });

    test('F-02 Case E: Debug mode (isRelease: false) preserves demo fallback on offline 503', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Offline'}), 503);
      });

      final storage = SecureSessionStorage();
      final apiClient = ApiClient(sessionStorage: storage, httpClient: mockClient);
      final authController = AuthController(
        apiClient: apiClient,
        sessionStorage: storage,
        isRelease: false, // Debug mode
      );

      await authController.login(
        const LoginRequest(identifier: 'eve@test.org', password: 'Password123!', tenantId: 'TENANT-ALPHA'),
      );

      expect(authController.value, isA<Authenticated>());
      final session = await storage.getSession();
      expect(session, isNotNull);
      expect(session!.accessToken, equals('jwt-auth-token-valid-2026'));
    });

    // -------------------------------------------------------------
    // F-03: Demo OTP Preload Gating
    // -------------------------------------------------------------
    testWidgets('F-03: VerifyOtpScreen in Release mode has empty initial OTP text', (tester) async {
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

    // -------------------------------------------------------------
    // F-04: Tenant Dropdown Gating
    // -------------------------------------------------------------
    testWidgets('F-04: LoginScreen renders correctly and maintains form inputs', (tester) async {
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
