import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/contributions/views/contribution_flow_coordinator.dart';
import 'package:member_mobile_app/src/features/dashboard/state/dashboard_controller.dart';
import 'package:member_mobile_app/src/features/dashboard/views/live_pool_state_view.dart';
import 'package:member_mobile_app/src/features/dashboard/views/member_financial_summary_view.dart';
import 'package:member_mobile_app/src/features/dashboard/views/member_home_view.dart';
import 'package:member_mobile_app/src/features/shell/views/member_shell_view.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  group('Slice 2 — Cooperative Member Dashboard & Live Pool State Tests', () {
    late SessionStorage sessionStorage;
    late ApiClient apiClient;
    late UserSession session;
    late DashboardController controller;

    setUp(() {
      sessionStorage = SecureSessionStorage();
      apiClient = ApiClient(sessionStorage: sessionStorage);
      session = UserSession(
        userId: 'usr-member-001',
        email: 'sarah.member@collaborativefinance.org',
        fullName: 'Sarah Jenkins',
        tenantId: 'TENANT-ALPHA',
        role: UserRole.member,
        accessToken: 'jwt-auth-token-2026',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );
      controller = DashboardController(
        apiClient: apiClient,
        session: session,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('Screen 6 (MemberHomeView) renders hero header, metric cards, and alerts', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        await controller.loadDashboardData();
      });

      int navigatedTab = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: MemberHomeView(
              controller: controller,
              onNavigateTab: (tab) => navigatedTab = tab,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Hero Header
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('KYC VERIFIED'), findsOneWidget);

      // 2. Verify Metric Cards
      expect(find.text('Available Pool Liquidity'), findsOneWidget);
      expect(find.text('\$50,000.00'), findsOneWidget);
      expect(find.text('My Expected Payout'), findsOneWidget);
      expect(find.text('\$5,000.00'), findsOneWidget);
      expect(find.text('Next Contribution Due'), findsOneWidget);
      expect(find.text('Total Contributed'), findsOneWidget);
      expect(find.text('\$500.00'), findsNWidgets(2));

      // 3. Verify Active Cycle Progress
      expect(find.text('Active Cooperative Rotation'), findsOneWidget);
      expect(find.text('CYCLE-2026-LIVE-01'), findsOneWidget);
      expect(find.text('Period 1 of 10 (Current Month)'), findsOneWidget);

      // 4. Verify Recent Activity Section
      expect(find.text('Recent Financial Activity'), findsOneWidget);
      expect(find.text('Period #1 Monthly Contribution'), findsOneWidget);

      // 5. Test Alert banner navigation tap
      expect(find.text('Pay Contribution →'), findsOneWidget);
      await tester.tap(find.text('Pay Contribution →'));
      await tester.pump();
      expect(navigatedTab, 1);
    });

    testWidgets('Screen 7 (LivePoolStateView) renders capital health and 10 slot rotation map with YOU badge', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        await controller.loadDashboardData();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: LivePoolStateView(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Pool Header
      expect(find.text('Rotating Pool Alpha-1'), findsOneWidget);
      expect(find.text('ACTIVE POOL'), findsOneWidget);
      expect(find.text('10 Members'), findsOneWidget);

      // 2. Verify Capital Health
      expect(find.text('Total Pool Capital'), findsOneWidget);
      expect(find.text('Contributions Collected'), findsOneWidget);
      expect(find.text('15% Protected Reserve'), findsOneWidget);

      // 3. Verify Reserve Guard Notice
      expect(find.text('Protected Liquidity & Zero-Loss Guarantee'), findsOneWidget);

      // 4. Verify Slot Roster & YOU badge
      expect(find.text('Rotation Schedule & Allocation Slots'), findsOneWidget);
      expect(find.text('10 SLOTS ASSIGNED'), findsOneWidget);
      expect(find.text('Slot #1'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget); // Member's own slot
      expect(find.text('Slot #10'), findsOneWidget);
      expect(find.text('Kenji Takahashi'), findsOneWidget);
    });

    testWidgets('Screen 8 (MemberFinancialSummaryView) renders dues schedule, pay confirmation, and obligations', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        await controller.loadDashboardData();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: MemberFinancialSummaryView(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Net Position Cards
      expect(find.text('Total Contributed'), findsOneWidget);
      expect(find.text('Payout Received / Allocated'), findsOneWidget);
      expect(find.text('Remaining Net Obligation'), findsOneWidget);

      // 2. Verify Dues Schedule
      expect(find.text('Monthly Contribution Dues'), findsOneWidget);
      expect(find.text('10 PERIODS'), findsOneWidget);
      expect(find.text('Period #1 Monthly Due'), findsOneWidget);
      expect(find.text('Period #2 Monthly Due'), findsOneWidget);

      // 3. Verify Actionable Pay Button & Confirmation Dialog
      expect(find.text('Pay (\$500.00)'), findsOneWidget);
      await tester.tap(find.text('Pay (\$500.00)'));
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog
      expect(find.text('Authorize Monthly Contribution'), findsOneWidget);
      expect(find.text('Authorize \$500.00'), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Authorize Monthly Contribution'), findsNothing);

      // 4. Verify Obligations Section
      expect(find.text('Legal Obligation & Repayment Position'), findsOneWidget);
      expect(find.text('Cycle 2026 Rotating Obligation'), findsOneWidget);
    });

    testWidgets('MemberShellView integration and multi-breakpoint responsive rendering', (tester) async {
      // 1. Mobile Viewport (360x740)
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        await controller.loadDashboardData();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MemberShellView(
            session: session,
            onLogout: () {},
            dashboardController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Mobile BottomNavigationBar
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Dues'), findsOneWidget);
      expect(find.text('Live Pool'), findsOneWidget);

      // Navigate to Tab 2 (Live Pool) via BottomNavigationBar
      await tester.tap(find.text('Live Pool'));
      await tester.pumpAndSettle();
      expect(find.byType(LivePoolStateView), findsOneWidget);

      // Navigate to Tab 1 (Dues) via BottomNavigationBar
      await tester.tap(find.text('Dues'));
      await tester.pumpAndSettle();
      expect(find.byType(ContributionFlowCoordinator), findsOneWidget);

      // 2. Tablet Viewport (768x1024)
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);

      // 3. Desktop Viewport (1280x900)
      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpAndSettle();
      expect(find.text('CollabFinance'), findsOneWidget);
      expect(find.text('Home Dashboard'), findsOneWidget);
    });
  });
}
