import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/admin/state/admin_controller.dart';
import 'package:member_mobile_app/src/features/admin/views/admin_console_shell.dart';
import 'package:member_mobile_app/src/features/auth/views/register_screen.dart';
import 'package:member_mobile_app/src/features/auth/views/verify_otp_screen.dart';
import 'package:member_mobile_app/src/features/auth/views/welcome_screen.dart';
import 'package:member_mobile_app/src/features/contributions/state/contribution_controller.dart';
import 'package:member_mobile_app/src/features/dashboard/state/dashboard_controller.dart';
import 'package:member_mobile_app/src/features/funding/state/funding_controller.dart';
import 'package:member_mobile_app/src/features/ops/state/ops_controller.dart';
import 'package:member_mobile_app/src/features/ops/views/ops_console_shell.dart';
import 'package:member_mobile_app/src/features/platform/state/platform_controller.dart';
import 'package:member_mobile_app/src/features/platform/views/platform_console_shell.dart';
import 'package:member_mobile_app/src/features/shell/views/member_shell_view.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureSessionStorage sessionStorage;
  late ApiClient apiClient;

  setUp(() {
    sessionStorage = SecureSessionStorage();
    apiClient = ApiClient(sessionStorage: sessionStorage);
  });

  Widget buildTestApp(Widget home) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: home,
    );
  }

  group('Phase 21 — End-to-End User Journeys A through F Validation', () {
    testWidgets('Journey A: New Member Onboarding Flow (Welcome -> Register -> OTP -> Authenticated)', (tester) async {
      // 1. Welcome Screen
      bool navigateToRegister = false;
      await tester.pumpWidget(
        buildTestApp(
          WelcomeScreen(
            onSignIn: () {},
            onRegister: () => navigateToRegister = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Collaborative Finance'), findsOneWidget);
      final welcomeButton = find.text('Create Member Account');
      expect(welcomeButton, findsOneWidget);

      await tester.ensureVisible(welcomeButton);
      await tester.tap(welcomeButton);
      await tester.pumpAndSettle();
      expect(navigateToRegister, isTrue);

      // 2. Register Screen
      bool registerSubmitted = false;
      await tester.pumpWidget(
        buildTestApp(
          RegisterScreen(
            isLoading: false,
            errorMessage: null,
            onSubmit: (req) {
              registerSubmitted = true;
            },
            onNavigateToLogin: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'John Member');
      await tester.enterText(find.byType(TextField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextField).at(2), '+15551234567');
      await tester.enterText(find.byType(TextField).at(3), 'SecureP@ss123');
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(PrimaryButton, 'Create Member Account');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(registerSubmitted, isTrue);

      // 3. OTP Verification Screen
      bool otpVerified = false;
      await tester.pumpWidget(
        buildTestApp(
          VerifyOtpScreen(
            identifier: 'john@example.com',
            tenantId: 'TENANT-ALPHA',
            onVerify: (req) async {
              otpVerified = true;
            },
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter Verification Code'), findsOneWidget);
      final verifyButton = find.widgetWithText(PrimaryButton, 'Verify & Sign In');
      expect(verifyButton, findsOneWidget);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      await tester.tap(verifyButton);
      await tester.pumpAndSettle();
      expect(otpVerified, isTrue);
    });

    testWidgets('Journey B: Existing Member Operations (Dashboard -> Pool -> Contributions -> Funding Lifecycle)', (tester) async {
      final memberSession = UserSession(
        userId: 'usr-member-01',
        email: 'member@coop.org',
        fullName: 'Elena Rostova',
        tenantId: 'TENANT-ALPHA',
        role: UserRole.member,
        accessToken: 'test-jwt',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );

      final dashCtrl = DashboardController(apiClient: apiClient, session: memberSession);
      final contribCtrl = ContributionController(apiClient: apiClient, session: memberSession);
      final fundCtrl = FundingController(apiClient: apiClient, session: memberSession);

      await dashCtrl.loadDashboardData();
      await contribCtrl.loadOverview();
      await fundCtrl.loadFundingData();

      await tester.pumpWidget(
        buildTestApp(
          MemberShellView(
            session: memberSession,
            onLogout: () {},
            dashboardController: dashCtrl,
            contributionController: contribCtrl,
            fundingController: fundCtrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dashboard verification
      expect(find.text('Elena Rostova'), findsWidgets);
      expect(find.text(r'$50,000.00'), findsWidgets); // Available Liquidity

      // Navigate to Dues
      await tester.tap(find.byIcon(Icons.payment_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Period #2 Monthly Due'), findsWidgets);

      // Navigate to Live Pool
      await tester.tap(find.byIcon(Icons.pie_chart_outline));
      await tester.pumpAndSettle();
      expect(find.text('ACTIVE POOL'), findsOneWidget);

      // Navigate to Funding & Payout Lifecycle
      await tester.tap(find.byIcon(Icons.timeline_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Funding Lifecycle Navigation'), findsOneWidget);
    });

    testWidgets('Journey C: Business Administrator Console (Overview -> Members -> Cycles -> Treasury -> Settings)', (tester) async {
      final orgAdminSession = UserSession(
        userId: 'usr-org-admin-01',
        email: 'admin@alpha-cu.org',
        fullName: 'Marcus Vance',
        tenantId: 'TENANT-ALPHA',
        role: UserRole.orgAdmin,
        accessToken: 'test-admin-jwt',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );

      final adminCtrl = AdminController(apiClient: apiClient, session: orgAdminSession);
      await adminCtrl.loadAdminDashboard();

      await tester.pumpWidget(
        buildTestApp(
          AdminConsoleShell(
            session: orgAdminSession,
            onSignOut: () {},
            apiClient: apiClient,
            controller: adminCtrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ORG ADMIN'), findsOneWidget);
      expect(find.text('Administrative Quick Actions'), findsOneWidget);

      // Navigate to Member Directory
      await tester.tap(find.byIcon(Icons.people_outline).first);
      await tester.pumpAndSettle();
      expect(find.text('Cooperative Member Directory'), findsOneWidget);

      // Navigate to Cycles Management
      await tester.tap(find.byIcon(Icons.published_with_changes).first);
      await tester.pumpAndSettle();
      expect(find.text('Cooperative Cycles'), findsOneWidget);

      // Navigate to Treasury Reserve
      await tester.tap(find.byIcon(Icons.account_balance_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Regulatory Reserve Ratio (INV-12)'), findsOneWidget);

      // Navigate to Settings (Org Profile)
      await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Organization Profile & Settings'), findsOneWidget);
    });

    testWidgets('Journey D: Treasury Maker Staging Workflow', (tester) async {
      final makerSession = UserSession(
        userId: 'usr-maker-01',
        email: 'maker@coop.org',
        fullName: 'Treasury Maker Officer',
        tenantId: 'TENANT-ALPHA',
        role: UserRole.treasuryMaker,
        accessToken: 'test-maker-jwt',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );

      final opsCtrl = OpsController(apiClient: apiClient, session: makerSession);
      await opsCtrl.loadOpsTelemetry();

      await tester.pumpWidget(
        buildTestApp(
          OpsConsoleShell(
            session: makerSession,
            onSignOut: () {},
            apiClient: apiClient,
            controller: opsCtrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Operations Console'), findsOneWidget);
      expect(find.text('Operations Payment Queue'), findsOneWidget);

      // Navigate to Maker Queue
      await tester.tap(find.byIcon(Icons.edit_note_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Treasury Maker Queue'), findsOneWidget);
    });

    testWidgets('Journey E: Treasury Checker Release & INV-15 Self-Approval Prevention', (tester) async {
      final checkerSession = UserSession(
        userId: 'usr-checker-02',
        email: 'checker@coop.org',
        fullName: 'Treasury Checker Officer',
        tenantId: 'TENANT-ALPHA',
        role: UserRole.treasuryChecker,
        accessToken: 'test-checker-jwt',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );

      final opsCtrl = OpsController(apiClient: apiClient, session: checkerSession);
      await opsCtrl.loadOpsTelemetry();

      // Test INV-15: Attempt to self-approve an item created by the same actor
      final selfApprovalBlocked = await opsCtrl.authorizeCheckerRelease(
        'FND-ALLOC-2026-04',
        makerId: 'usr-checker-02', // Same as checkerSession.userId
      );
      expect(selfApprovalBlocked, isFalse);

      // Independent approval succeeds
      final independentApproval = await opsCtrl.authorizeCheckerRelease(
        'FND-ALLOC-2026-04',
        makerId: 'usr-maker-01', // Different from checkerSession.userId
      );
      expect(independentApproval, isTrue);
    });

    testWidgets('Journey F: Platform Administrator Infrastructure & High-Risk Safeguards', (tester) async {
      final platformSession = UserSession(
        userId: 'usr-sys-admin-01',
        email: 'sysadmin@platform.internal',
        fullName: 'Chief Platform Administrator',
        tenantId: 'TENANT-GLOBAL',
        role: UserRole.platformAdmin,
        accessToken: 'test-sys-jwt',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );

      final platCtrl = PlatformController(apiClient: apiClient, session: platformSession);
      await platCtrl.loadPlatformTelemetry();

      await tester.pumpWidget(
        buildTestApp(
          PlatformConsoleShell(
            session: platformSession,
            onSignOut: () {},
            apiClient: apiClient,
            controller: platCtrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Platform Admin Console'), findsOneWidget);
      expect(find.text('System Health & Infrastructure'), findsOneWidget);

      // Navigate to Tenants
      await tester.tap(find.byIcon(Icons.business_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Multi-Tenant Registry'), findsOneWidget);

      // Navigate to Rails
      await tester.tap(find.byIcon(Icons.alt_route_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Clearing Rails & Gateway Adapters'), findsOneWidget);

      // Navigate to Security
      await tester.tap(find.byIcon(Icons.security_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Security Operations & WORM Audit'), findsOneWidget);

      // Navigate to Controls
      await tester.tap(find.byIcon(Icons.gavel_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Emergency Circuit Breakers'), findsOneWidget);
    });
  });
}
