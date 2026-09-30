import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/platform/state/platform_controller.dart';
import 'package:member_mobile_app/src/features/platform/views/platform_circuit_breaker_view.dart';
import 'package:member_mobile_app/src/features/platform/views/platform_console_shell.dart';
import 'package:member_mobile_app/src/features/platform/views/platform_health_view.dart';
import 'package:member_mobile_app/src/features/platform/views/platform_providers_view.dart';
import 'package:member_mobile_app/src/features/platform/views/platform_security_view.dart';
import 'package:member_mobile_app/src/features/platform/views/platform_tenants_view.dart';
import 'package:ui_components/ui_components.dart';

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

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Slice 7 — Platform Admin & System Health Widget Tests (Screens 36–40)', () {
    testWidgets('Screen 36 (PlatformHealthView) renders health matrix and latency metrics', (tester) async {
      await controller.loadPlatformTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          PlatformHealthView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('System Health & Infrastructure'), findsOneWidget);
      expect(find.text('Platform API Gateway (Ingress)'), findsOneWidget);
      expect(find.text('PostgreSQL Multi-Tenant Cluster'), findsOneWidget);
      expect(find.text('Redis Distributed Lock Cluster'), findsOneWidget);
      expect(find.text('Kafka Outbox & Event Streaming Cluster'), findsOneWidget);
      expect(find.text('8 ms'), findsOneWidget);
      expect(find.text('99.99%'), findsWidgets);
      expect(find.text('HEALTHY'), findsWidgets);

      // Tap filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Degraded'));
      await tester.pumpAndSettle();
      expect(find.text('No matching infrastructure nodes found'), findsOneWidget);
    });

    testWidgets('Screen 37 (PlatformTenantsView) renders tenants and provisioning modal', (tester) async {
      await controller.loadPlatformTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          PlatformTenantsView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Multi-Tenant Registry'), findsOneWidget);
      expect(find.text('Alpha Community Credit Union'), findsOneWidget);
      expect(find.text('Beta Horizon Cooperative'), findsOneWidget);
      expect(find.text('248 Members'), findsOneWidget);
      expect(find.text('15.0%'), findsWidgets);
      expect(find.text(r'$500,000.00'), findsOneWidget);
      expect(find.text('ENFORCED_RLS'), findsWidgets);
      expect(find.text('Provision Tenant'), findsWidgets);

      // Open provision modal
      await tester.tap(find.widgetWithText(PrimaryButton, 'Provision Tenant').first);
      await tester.pumpAndSettle();
      expect(find.text('Provision New Cooperative Tenant'), findsOneWidget);
      expect(find.text('Cooperative Name'), findsOneWidget);
    });

    testWidgets('Screen 38 (PlatformProvidersView) renders clearing rails and masked credentials', (tester) async {
      await controller.loadPlatformTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          PlatformProvidersView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clearing Rails & Gateway Adapters'), findsOneWidget);
      expect(find.text('FedNow Instant Clearing (ISO 20022 Direct)'), findsOneWidget);
      expect(find.text('The Clearing House RTP Network'), findsOneWidget);
      expect(find.text('NACHA FedACH Batch Settlement Engine'), findsOneWidget);
      expect(find.text('500 req/sec'), findsOneWidget);
      expect(find.text('fednow_live_••••••••••••8921'), findsOneWidget);
      expect(find.text('Configure Adapter'), findsWidgets);
    });

    testWidgets('Screen 39 (PlatformSecurityView) renders security events and WORM hash digests', (tester) async {
      await controller.loadPlatformTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          PlatformSecurityView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Security Operations & WORM Audit'), findsOneWidget);
      expect(find.text('100% Cryptographic Ledger Integrity Confirmed'), findsOneWidget);
      expect(find.text('MAKER_CHECKER_DUAL_AUTH_VERIFIED'), findsOneWidget);
      expect(find.text('RECONCILIATION_AUDIT_SEALED'), findsOneWidget);
      expect(find.text('WORM Digest: SHA256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069'), findsOneWidget);
    });

    testWidgets('Screen 40 (PlatformCircuitBreakerView) renders emergency controls', (tester) async {
      await controller.loadPlatformTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          PlatformCircuitBreakerView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emergency Circuit Breakers'), findsOneWidget);
      expect(find.text('Global Platform Write Freeze'), findsOneWidget);
      expect(find.text('Payment Clearing Rails Cutoff'), findsOneWidget);
      expect(find.text('Platform Maintenance Mode'), findsOneWidget);
      expect(find.text('WRITES ENABLED (NORMAL)'), findsOneWidget);
      expect(find.text('Trigger Global Freeze'), findsOneWidget);
    });

    testWidgets('PlatformConsoleShell multi-breakpoint responsive test (360px to 1440px)', (tester) async {
      await controller.loadPlatformTelemetry();

      final viewports = [
        const Size(360, 740),
        const Size(390, 844),
        const Size(430, 932),
        const Size(768, 1024),
        const Size(1024, 768),
        const Size(1280, 800),
        const Size(1440, 900),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            PlatformConsoleShell(
              session: platformAdminSession,
              onSignOut: () {},
              apiClient: apiClient,
              controller: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlatformHealthView), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
