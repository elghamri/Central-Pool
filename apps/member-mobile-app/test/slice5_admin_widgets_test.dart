import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/admin/models/admin_models.dart';
import 'package:member_mobile_app/src/features/admin/state/admin_controller.dart';
import 'package:member_mobile_app/src/features/admin/views/admin_cycle_config_wizard_view.dart';
import 'package:member_mobile_app/src/features/admin/views/admin_cycles_management_view.dart';
import 'package:member_mobile_app/src/features/admin/views/admin_member_detail_view.dart';
import 'package:member_mobile_app/src/features/admin/views/admin_member_directory_view.dart';
import 'package:member_mobile_app/src/features/admin/views/admin_overview_view.dart';
import 'package:member_mobile_app/src/features/admin/views/admin_treasury_reserve_view.dart';
import 'package:member_mobile_app/src/features/admin/views/org_profile_config_view.dart';
import 'package:member_mobile_app/src/features/shell/views/admin_shell_view.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureSessionStorage sessionStorage;
  late ApiClient apiClient;
  late UserSession adminSession;
  late AdminController controller;

  setUp(() {
    sessionStorage = SecureSessionStorage();
    apiClient = ApiClient(sessionStorage: sessionStorage);
    adminSession = UserSession(
      userId: 'usr-admin-001',
      email: 'admin@alphacoop.internal',
      fullName: 'Chief Operations Officer',
      tenantId: 'TENANT-ALPHA',
      role: UserRole.orgAdmin,
      accessToken: 'test-admin-jwt-token',
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
    controller = AdminController(
      apiClient: apiClient,
      session: adminSession,
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

  group('Slice 5 — Business Admin Console Widget Tests (Screens 22–28)', () {
    testWidgets('Screen 22 (AdminOverviewView) renders metrics, governance, and quick actions', (tester) async {
      await controller.loadAdminDashboard();

      await tester.pumpWidget(
        buildTestableWidget(
          AdminOverviewView(
            controller: controller,
            onNavigateTab: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha Cooperative Financial Union'), findsOneWidget);
      expect(find.text('GOOD STANDING'), findsOneWidget);
      expect(find.text('Total Cooperative Capital'), findsOneWidget);
      expect(find.text(r'$500,000.00'), findsOneWidget);
      expect(find.text(r'$50,000.00'), findsWidgets);
      expect(find.text('248'), findsOneWidget);
      expect(find.text(r'$75,000.00'), findsOneWidget);
      expect(find.text('Cooperative Cycle Configuration & Activation'), findsOneWidget);
      expect(find.text('Member Directory & KYC Verification'), findsOneWidget);
      expect(find.text('Treasury Liquidity & 15% Reserve Guardrail'), findsOneWidget);
    });

    testWidgets('Screen 23 (OrgProfileConfigView) renders legal entity and underwriting parameters', (tester) async {
      await controller.loadAdminDashboard();
      final loaded = controller.value as dynamic;

      await tester.pumpWidget(
        buildTestableWidget(
          OrgProfileConfigView(
            profile: loaded.profile,
            overview: loaded.overview,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Organization Profile & Settings'), findsOneWidget);
      expect(find.text('NCUA VERIFIED'), findsOneWidget);
      expect(find.text('Alpha Cooperative Union Inc.'), findsOneWidget);
      expect(find.text('NCUA-COOP-2026-892'), findsOneWidget);
      expect(find.text('TENANT-ALPHA'), findsOneWidget);
      expect(find.text('15.0% (Enforced)'), findsOneWidget);
      expect(find.text('Manhattan Headquarters'), findsOneWidget);
    });

    testWidgets('Screen 24 (AdminMemberDirectoryView) tests search input and filter chips', (tester) async {
      await controller.loadAdminDashboard();

      await tester.pumpWidget(
        buildTestableWidget(
          AdminMemberDirectoryView(
            controller: controller,
            onSelectMember: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cooperative Member Directory'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Michael Chang'), findsOneWidget);

      // Filter by KYC Pending via ChoiceChip finder
      await tester.tap(find.widgetWithText(ChoiceChip, 'PENDING_REVIEW'));
      await tester.pumpAndSettle();

      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsNothing);

      // Clear filter via ChoiceChip finder
      await tester.tap(find.widgetWithText(ChoiceChip, 'ALL'));
      await tester.pumpAndSettle();
      expect(find.text('Sarah Jenkins'), findsOneWidget);
    });

    testWidgets('Screen 25 (AdminMemberDetailView) renders financial standing and verification buttons', (tester) async {
      await controller.loadAdminDashboard();
      final member = (controller.value as dynamic).members.first as AdminMemberListItem;

      await tester.pumpWidget(
        buildTestableWidget(
          AdminMemberDetailView(
            member: member,
            controller: controller,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Member Profile & Standing'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Member ID: usr-member-001 • sarah.jenkins@example.com'), findsOneWidget);
      expect(find.text(r'$500.00'), findsOneWidget);
      expect(find.text(r'$4,500.00'), findsOneWidget);
      expect(find.text('Re-Verify Tier 2 KYC'), findsOneWidget);
      expect(find.text('Flag for Compliance Review'), findsOneWidget);
    });

    testWidgets('Screen 26 (AdminCyclesManagementView) renders active pools and 10-slot roster', (tester) async {
      await controller.loadAdminDashboard();

      await tester.pumpWidget(
        buildTestableWidget(
          AdminCyclesManagementView(
            controller: controller,
            onLaunchNewCycleWizard: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cooperative Cycles'), findsOneWidget);
      expect(find.text('Rotating Pool Alpha-1'), findsOneWidget);
      expect(find.text(r'$50,000.00'), findsWidgets);
      expect(find.text('Slot #1'), findsWidgets);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('DISBURSED'), findsOneWidget);
      expect(find.text('New Cycle'), findsOneWidget);
    });

    testWidgets('Screen 27 (AdminCycleConfigWizardView) calculates dynamic invariants and launches', (tester) async {
      await controller.loadAdminDashboard();

      await tester.pumpWidget(
        buildTestableWidget(
          AdminCycleConfigWizardView(
            controller: controller,
            onCancel: () {},
            onSuccess: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configure New Cycle'), findsOneWidget);
      expect(find.text('Financial Invariants Calculation Preview'), findsOneWidget);
      expect(find.text(r'$5,000.00'), findsOneWidget);
      expect(find.text(r'$50,000.00'), findsWidgets);
      expect(find.text(r'$7,500.00'), findsOneWidget);
      expect(find.text('Launch & Activate Cycle'), findsOneWidget);
    });

    testWidgets('Screen 28 (AdminTreasuryReserveView) renders 15% reserve gauge and rebalance action', (tester) async {
      await controller.loadAdminDashboard();

      await tester.pumpWidget(
        buildTestableWidget(
          AdminTreasuryReserveView(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treasury & Reserve Guard'), findsOneWidget);
      expect(find.text('HEALTHY_GUARDED'), findsOneWidget);
      expect(find.text('15.0% / 15.0% Required'), findsOneWidget);
      expect(find.text(r'$500,000.00'), findsOneWidget);
      expect(find.text(r'$450,000.00'), findsOneWidget);
      expect(find.text(r'$75,000.00'), findsOneWidget);
      expect(find.text('Execute 15% Reserve Rebalance'), findsOneWidget);
      expect(find.text('TREAS-EVT-001'), findsOneWidget);
    });

    testWidgets('AdminShellView end-to-end multi-breakpoint responsive test (360px, 768px, 1280px)', (tester) async {
      final viewports = [
        const Size(360, 740),  // Mobile small
        const Size(390, 844),  // Mobile standard
        const Size(430, 932),  // Mobile large
        const Size(768, 1024), // Tablet
        const Size(1280, 800), // Desktop standard
        const Size(1440, 900), // Desktop large
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            AdminShellView(
              session: adminSession,
              onLogout: () {},
              apiClient: apiClient,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Alpha Cooperative Financial Union'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
