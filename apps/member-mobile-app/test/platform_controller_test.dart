import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/platform/models/platform_models.dart';
import 'package:member_mobile_app/src/features/platform/state/platform_controller.dart';
import 'package:member_mobile_app/src/features/platform/state/platform_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureSessionStorage sessionStorage;
  late ApiClient apiClient;
  late UserSession platformAdminSession;
  late PlatformController controller;

  setUp(() {
    sessionStorage = SecureSessionStorage();
    apiClient = ApiClient(sessionStorage: sessionStorage);
    platformAdminSession = UserSession(
      userId: 'usr-sys-admin-01',
      email: 'admin@coopfinance.internal',
      fullName: 'Chief Platform Administrator',
      tenantId: 'TENANT-GLOBAL',
      role: UserRole.platformAdmin,
      accessToken: 'test-platform-admin-jwt-token',
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
    controller = PlatformController(
      apiClient: apiClient,
      session: platformAdminSession,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('PlatformController — State Machine, Tenant Provisioning & Safety Controls', () {
    test('initial state is PlatformLoading, loadPlatformTelemetry populates complete telemetry', () async {
      expect(controller.value, isA<PlatformLoading>());

      await controller.loadPlatformTelemetry();

      expect(controller.value, isA<PlatformLoaded>());
      final loaded = controller.value as PlatformLoaded;
      expect(loaded.healthNodes.length, equals(8));
      expect(loaded.tenants.length, equals(3));
      expect(loaded.providers.length, equals(4));
      expect(loaded.securityEvents.length, equals(3));
      expect(loaded.circuitBreaker.isGlobalFreezeActive, isFalse);
      expect(loaded.overallPlatformStatus, equals(SubsystemHealthStatus.healthy));
    });

    test('search and filter chips filter health nodes properly', () async {
      await controller.loadPlatformTelemetry();

      // Search by service name
      controller.setSearchQuery('PostgreSQL');
      expect((controller.value as PlatformLoaded).filteredHealthNodes.length, equals(1));
      expect((controller.value as PlatformLoaded).filteredHealthNodes.first.serviceName, contains('PostgreSQL'));

      // Filter by status HEALTHY
      controller.setSearchQuery('');
      controller.setStatusFilter('HEALTHY');
      expect((controller.value as PlatformLoaded).filteredHealthNodes.length, equals(8));
    });

    test('overallPlatformStatus reflects degraded or unavailable subsystems accurately', () async {
      await controller.loadPlatformTelemetry();
      final current = controller.value as PlatformLoaded;

      // When a node is degraded
      final degradedNodes = [
        ...current.healthNodes.sublist(1),
        SystemHealthNode(
          nodeId: 'srv-degraded-test',
          serviceName: 'Degraded Test Service',
          status: SubsystemHealthStatus.degraded,
          latencyMs: 120,
          uptimePercent: 98.5,
          lastChecked: DateTime.now(),
          errorCount: 3,
          details: 'High latency detected',
        ),
      ];

      final degradedState = current.copyWith(healthNodes: degradedNodes);
      expect(degradedState.overallPlatformStatus, equals(SubsystemHealthStatus.degraded));

      // When a node is unavailable
      final unavailableNodes = [
        ...current.healthNodes.sublist(1),
        SystemHealthNode(
          nodeId: 'srv-down-test',
          serviceName: 'Down Test Service',
          status: SubsystemHealthStatus.unavailable,
          latencyMs: 0,
          uptimePercent: 90.0,
          lastChecked: DateTime.now(),
          errorCount: 25,
          details: 'Pod crashed',
        ),
      ];

      final unavailableState = current.copyWith(healthNodes: unavailableNodes);
      expect(unavailableState.overallPlatformStatus, equals(SubsystemHealthStatus.unavailable));
    });

    test('provisionNewTenant adds a new tenant with isolated RLS schema and reserve guardrail', () async {
      await controller.loadPlatformTelemetry();
      final initialCount = (controller.value as PlatformLoaded).tenants.length;

      final success = await controller.provisionNewTenant(
        name: 'Delta Vanguard Mutual',
        legalEntityName: 'Delta Vanguard Federal Credit Society',
        charterNumber: 'NCUA-COOP-2026-992',
        reserveRatioBps: 1500,
      );

      expect(success, isTrue);
      final loaded = controller.value as PlatformLoaded;
      expect(loaded.tenants.length, equals(initialCount + 1));
      expect(loaded.tenants.first.name, equals('Delta Vanguard Mutual'));
      expect(loaded.tenants.first.isolationStatus, equals('ENFORCED_RLS'));
      expect(loaded.isActionSuccess, isTrue);
    });

    test('toggleTenantStatus updates tenant partition status between ACTIVE and SUSPENDED', () async {
      await controller.loadPlatformTelemetry();

      // Suspend tenant
      final suspendSuccess = await controller.toggleTenantStatus('TENANT-ALPHA', suspend: true);
      expect(suspendSuccess, isTrue);
      var loaded = controller.value as PlatformLoaded;
      expect(loaded.tenants.firstWhere((t) => t.tenantId == 'TENANT-ALPHA').status, equals('SUSPENDED'));

      // Reactivate tenant
      final reactivateSuccess = await controller.toggleTenantStatus('TENANT-ALPHA', suspend: false);
      expect(reactivateSuccess, isTrue);
      loaded = controller.value as PlatformLoaded;
      expect(loaded.tenants.firstWhere((t) => t.tenantId == 'TENANT-ALPHA').status, equals('ACTIVE'));
    });

    test('updateProviderConfig modifies payment clearing gateway parameters', () async {
      await controller.loadPlatformTelemetry();

      final success = await controller.updateProviderConfig(
        'PROV-FEDNOW-01',
        rateLimit: 750,
        timeoutSeconds: 8,
        webhookUrl: 'https://api.coopfinance.internal/v1/webhooks/fednow/updated',
      );

      expect(success, isTrue);
      final loaded = controller.value as PlatformLoaded;
      final updatedProvider = loaded.providers.firstWhere((p) => p.providerId == 'PROV-FEDNOW-01');
      expect(updatedProvider.rateLimitPerSec, equals(750));
      expect(updatedProvider.timeoutSeconds, equals(8));
      expect(updatedProvider.webhookUrl, contains('updated'));
    });

    test('toggleCircuitBreaker enforces incident reason and engages emergency controls', () async {
      await controller.loadPlatformTelemetry();

      // Attempt to toggle without reason should fail
      final failAttempt = await controller.toggleCircuitBreaker(
        breakerType: 'GLOBAL_FREEZE',
        enable: true,
        reason: '   ',
      );
      expect(failAttempt, isFalse);

      // Toggle with valid reason succeeds
      final success = await controller.toggleCircuitBreaker(
        breakerType: 'GLOBAL_FREEZE',
        enable: true,
        reason: 'Simulated security test: halting all database writes',
      );

      expect(success, isTrue);
      final loaded = controller.value as PlatformLoaded;
      expect(loaded.circuitBreaker.isGlobalFreezeActive, isTrue);
      expect(loaded.circuitBreaker.freezeTriggeredBy, equals(platformAdminSession.userId));
      expect(loaded.circuitBreaker.freezeReason, contains('Simulated security test'));
    });
  });
}
