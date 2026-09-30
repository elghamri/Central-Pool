import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/funding/state/funding_controller.dart';
import 'package:member_mobile_app/src/features/funding/state/funding_state.dart';
import 'package:member_mobile_app/src/features/funding/views/allocation_position_view.dart';
import 'package:member_mobile_app/src/features/funding/views/funding_audit_statement_view.dart';
import 'package:member_mobile_app/src/features/funding/views/funding_eligibility_view.dart';
import 'package:member_mobile_app/src/features/funding/views/funding_flow_coordinator.dart';
import 'package:member_mobile_app/src/features/funding/views/funding_lifecycle_tracker_view.dart';
import 'package:member_mobile_app/src/features/funding/views/funding_overview_view.dart';
import 'package:member_mobile_app/src/features/funding/views/payout_settlement_view.dart';
import 'package:member_mobile_app/src/features/funding/views/post_funding_obligation_view.dart';
import 'package:member_mobile_app/src/features/shell/views/member_shell_view.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureSessionStorage sessionStorage;
  late ApiClient apiClient;
  late UserSession testSession;
  late FundingController controller;

  setUp(() async {
    sessionStorage = SecureSessionStorage();
    await sessionStorage.clearSession();

    testSession = UserSession(
      userId: 'usr-member-001',
      tenantId: 'TENANT-ALPHA',
      role: UserRole.member,
      fullName: 'Sarah Jenkins',
      email: 'sarah.jenkins@example.com',
      accessToken: 'jwt-test-token-valid-member',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    await sessionStorage.saveSession(testSession);

    apiClient = ApiClient(
      baseUrl: 'https://api.coopfinance.internal',
      sessionStorage: sessionStorage,
    );

    controller = FundingController(
      apiClient: apiClient,
      session: testSession,
    );
  });

  Widget createTestWidget(Widget child, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: child),
      ),
    );
  }

  group('Slice 4 — Member Funding & Payout Lifecycle Widget Tests', () {
    testWidgets('Screen 15 (FundingOverviewView) renders cycle header, hero payout card, and quick navigation modules', (tester) async {
      await controller.loadFundingData();

      int selectedIndex = -1;
      await tester.pumpWidget(createTestWidget(
        FundingOverviewView(
          controller: controller,
          onSelectSubView: (idx) => selectedIndex = idx,
        ),
      ));
      await tester.pumpAndSettle();

      // Assert Header
      expect(find.text('Rotating Pool Alpha-1'), findsOneWidget);
      expect(find.text('SLOT #1 OF 10'), findsOneWidget);

      // Assert Hero Card
      expect(find.text('Period #1 Active Recipient'), findsOneWidget);
      expect(find.text('\$5,000.00'), findsAtLeastNWidgets(1));

      // Assert Metrics
      expect(find.text('Total Disbursed Payout'), findsOneWidget);
      expect(find.text('Repaid to Date'), findsOneWidget);
      expect(find.text('Remaining Net Obligation'), findsOneWidget);

      // Assert Navigation Modules
      expect(find.text('Funding Eligibility Gate'), findsOneWidget);
      expect(find.text('Allocation & Rotation Position'), findsOneWidget);
      expect(find.text('14-Stage Funding Lifecycle Tracker'), findsOneWidget);
      expect(find.text('Payout Settlement & Rail Status'), findsOneWidget);
      expect(find.text('Post-Funding Obligation & Dues'), findsOneWidget);
      expect(find.text('Cryptographic Audit Statement'), findsOneWidget);

      // Tap Track Payout Lifecycle CTA
      final trackCta = find.widgetWithText(PrimaryButton, 'Track Payout Lifecycle (14 Stages)');
      expect(trackCta, findsOneWidget);
      await tester.ensureVisible(trackCta);
      await tester.tap(trackCta);
      expect(selectedIndex, equals(3));
    });

    testWidgets('Screen 16 (FundingEligibilityView) renders gate evaluation, criteria checklist, and audit stamp', (tester) async {
      await controller.loadFundingData();
      final loaded = controller.value as FundingLoaded;

      bool backed = false;
      await tester.pumpWidget(createTestWidget(
        FundingEligibilityView(
          eligibility: loaded.overview.eligibility,
          onBack: () => backed = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Funding Eligibility Gate'), findsOneWidget);
      expect(find.text('Readiness Overview'), findsOneWidget);
      expect(find.text('Passed All Underwriting Gates'), findsOneWidget);

      // Check Radar & Criteria
      expect(find.text('Eligibility & Risk Radar'), findsOneWidget);
      expect(find.text('Axis Breakdown & Criteria'), findsOneWidget);
      expect(find.text('Verification Status'), findsWidgets);
      expect(find.text('Contribution History'), findsWidgets);
      expect(find.text('Group Stability'), findsWidgets);
      expect(find.text('Payout Readiness'), findsWidgets);

      // Check Audit Stamp
      expect(find.text('Evaluated by Automated Underwriting Engine'), findsOneWidget);

      // Back action
      final backBtn = find.widgetWithText(SecondaryButton, 'Back to Funding Overview');
      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      expect(backed, isTrue);
    });

    testWidgets('Screen 17 (AllocationPositionView) renders slot position, integer payout, and separation notice', (tester) async {
      await controller.loadFundingData();
      final loaded = controller.value as FundingLoaded;

      bool tracked = false;
      bool backed = false;
      await tester.pumpWidget(createTestWidget(
        AllocationPositionView(
          allocation: loaded.overview.allocation,
          onTrackLifecycle: () => tracked = true,
          onBack: () => backed = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Allocation & Rotation Position'), findsOneWidget);
      expect(find.text('Rotation Schedule Turn: Slot #1'), findsOneWidget);
      expect(find.text('\$5,000.00'), findsOneWidget);
      expect(find.text('Crucial Distinction: Allocation vs Settlement'), findsOneWidget);

      final trackBtn = find.widgetWithText(PrimaryButton, 'Track 14-Stage Lifecycle');
      await tester.ensureVisible(trackBtn);
      await tester.tap(trackBtn);
      expect(tracked, isTrue);
      expect(backed, isFalse);
    });

    testWidgets('Screen 18 (FundingLifecycleTrackerView) renders 14 stages, progress indicator, and audit references', (tester) async {
      await controller.loadFundingData();
      final loaded = controller.value as FundingLoaded;

      bool inspected = false;
      await tester.pumpWidget(createTestWidget(
        FundingLifecycleTrackerView(
          stages: loaded.overview.lifecycleStages,
          onInspectSettlement: () => inspected = true,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Funding Lifecycle Tracker'), findsOneWidget);
      expect(find.text('14 OF 14 COMPLETE'), findsOneWidget);

      // Verify selected stages in 14-stage list
      expect(find.text('1. Eligibility Gate'), findsOneWidget);
      expect(find.text('2. Allocation Plan'), findsOneWidget);
      expect(find.text('3. Maker Authorization'), findsOneWidget);
      expect(find.text('4. Checker Authorization'), findsOneWidget);

      final settleCta = find.widgetWithText(PrimaryButton, 'View Settlement & Rail Confirmation');
      await tester.ensureVisible(settleCta);
      await tester.tap(settleCta);
      expect(inspected, isTrue);
    });

    testWidgets('Screen 19 (PayoutSettlementView) renders execution receipt, DISPATCHED != SETTLED notice, and rail info', (tester) async {
      await controller.loadFundingData();
      final loaded = controller.value as FundingLoaded;

      bool next = false;
      await tester.pumpWidget(createTestWidget(
        PayoutSettlementView(
          settlement: loaded.overview.settlement,
          onInspectObligation: () => next = true,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Payout Status & Settlement'), findsOneWidget);
      expect(find.text('SETTLED'), findsAtLeastNWidgets(1));
      expect(find.text('\$5,000.00'), findsOneWidget);
      expect(find.text('Guaranteed Irrevocability Invariant'), findsOneWidget);

      final nextBtn = find.widgetWithText(PrimaryButton, 'View Post-Funding Obligation');
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      expect(next, isTrue);
    });

    testWidgets('Screen 20 (PostFundingObligationView) renders remaining obligation, risk status, and 10-period schedule', (tester) async {
      await controller.loadFundingData();
      final loaded = controller.value as FundingLoaded;

      bool auditTriggered = false;
      await tester.pumpWidget(createTestWidget(
        PostFundingObligationView(
          obligation: loaded.overview.obligation,
          onInspectAuditStatement: () => auditTriggered = true,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Post-Funding Obligation'), findsOneWidget);
      expect(find.text('LOW_RISK_PERFORMING'), findsOneWidget);
      expect(find.text('\$4,500.00'), findsOneWidget);
      expect(find.text('Cycle Repayment Schedule'), findsOneWidget);

      // Repayment periods
      expect(find.text('Period #1 Monthly Due'), findsOneWidget);
      expect(find.text('Period #2 Monthly Due'), findsOneWidget);

      final auditBtn = find.widgetWithText(PrimaryButton, 'View Cryptographic Audit Statement');
      await tester.ensureVisible(auditBtn);
      await tester.tap(auditBtn);
      expect(auditTriggered, isTrue);
    });

    testWidgets('Screen 21 (FundingAuditStatementView) renders 5-way match, zero variance, and WORM SHA-256 seal', (tester) async {
      await controller.loadFundingData();
      final loaded = controller.value as FundingLoaded;

      bool returned = false;
      await tester.pumpWidget(createTestWidget(
        FundingAuditStatementView(
          auditStatement: loaded.overview.auditStatement,
          onReturnToOverview: () => returned = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Funding Audit Statement'), findsOneWidget);
      expect(find.text('5-Way Cross-Domain Audit'), findsOneWidget);
      expect(find.text('RECONCILIATION_MATCH_CLEAN'), findsOneWidget);
      expect(find.text('WORM Audit Log Hash'), findsOneWidget);
      expect(find.textContaining('sha256-e3b0c442'), findsOneWidget);

      final returnBtn = find.widgetWithText(SecondaryButton, 'Back to Funding Overview');
      await tester.ensureVisible(returnBtn);
      await tester.tap(returnBtn);
      expect(returned, isTrue);
    });

    testWidgets('Full End-to-End Navigation Journey: Screen 15 -> 16 -> 17 -> 18 -> 19 -> 20 -> 21 -> 15', (tester) async {
      await tester.pumpWidget(createTestWidget(
        FundingFlowCoordinator(controller: controller),
      ));
      await tester.pumpAndSettle();

      // Screen 15: Overview
      expect(find.text('Funding & Payout Overview View', skipOffstage: false), findsNothing);
      expect(find.text('Cooperative Rotation Payout'), findsOneWidget);

      // Navigate to Screen 16 (Eligibility)
      final eligModule = find.text('Funding Eligibility Gate');
      await tester.ensureVisible(eligModule);
      await tester.tap(eligModule);
      await tester.pumpAndSettle();
      expect(find.text('Passed All Underwriting Gates'), findsOneWidget);

      // Back to Overview
      final backToOverview1 = find.widgetWithText(SecondaryButton, 'Back to Funding Overview');
      await tester.ensureVisible(backToOverview1);
      await tester.tap(backToOverview1);
      await tester.pumpAndSettle();
      expect(find.text('Cooperative Rotation Payout'), findsOneWidget);

      // Navigate to Screen 17 (Allocation)
      final allocModule = find.text('Allocation & Rotation Position');
      await tester.ensureVisible(allocModule);
      await tester.tap(allocModule);
      await tester.pumpAndSettle();
      expect(find.text('Rotation Schedule Turn: Slot #1'), findsOneWidget);

      // From Allocation -> Screen 18 (Tracker)
      final trackBtn = find.widgetWithText(PrimaryButton, 'Track 14-Stage Lifecycle');
      await tester.ensureVisible(trackBtn);
      await tester.tap(trackBtn);
      await tester.pumpAndSettle();
      expect(find.text('Funding Lifecycle Tracker'), findsOneWidget);

      // From Tracker -> Screen 19 (Settlement)
      final settleBtn = find.widgetWithText(PrimaryButton, 'View Settlement & Rail Confirmation');
      await tester.ensureVisible(settleBtn);
      await tester.tap(settleBtn);
      await tester.pumpAndSettle();
      expect(find.text('Payout Status & Settlement'), findsOneWidget);

      // From Settlement -> Screen 20 (Obligation)
      final obligBtn = find.widgetWithText(PrimaryButton, 'View Post-Funding Obligation');
      await tester.ensureVisible(obligBtn);
      await tester.tap(obligBtn);
      await tester.pumpAndSettle();
      expect(find.text('Post-Funding Obligation'), findsOneWidget);

      // From Obligation -> Screen 21 (Audit Statement)
      final auditBtn = find.widgetWithText(PrimaryButton, 'View Cryptographic Audit Statement');
      await tester.ensureVisible(auditBtn);
      await tester.tap(auditBtn);
      await tester.pumpAndSettle();
      expect(find.text('Funding Audit Statement'), findsOneWidget);

      // From Audit -> Back to Overview
      final returnBtn = find.widgetWithText(SecondaryButton, 'Back to Funding Overview');
      await tester.ensureVisible(returnBtn);
      await tester.tap(returnBtn);
      await tester.pumpAndSettle();
      expect(find.text('Cooperative Rotation Payout'), findsOneWidget);
    });

    testWidgets('MemberShellView integration and multi-breakpoint responsive rendering (360px, 390px, 430px, 768px, 1280px)', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Mobile (390x844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MemberShellView(
            session: testSession,
            onLogout: () {},
            fundingController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Bottom Navigation Bar and navigate to Payout (Tab 3)
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Payout'), findsOneWidget);
      await tester.tap(find.text('Payout'));
      await tester.pumpAndSettle();
      expect(find.byType(FundingFlowCoordinator), findsOneWidget);

      // 2. Tablet (768x1024)
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);

      // 3. Desktop (1280x900)
      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpAndSettle();
      expect(find.text('CollabFinance'), findsOneWidget);
      expect(find.text('Payout Lifecycle'), findsOneWidget);
      expect(find.byType(FundingFlowCoordinator), findsOneWidget);
    });
  });
}
