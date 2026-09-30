import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/ops/models/ops_models.dart';
import 'package:member_mobile_app/src/features/ops/state/ops_controller.dart';
import 'package:member_mobile_app/src/features/ops/views/ops_action_dossier_view.dart';
import 'package:member_mobile_app/src/features/ops/views/ops_checker_queue_view.dart';
import 'package:member_mobile_app/src/features/ops/views/ops_console_shell.dart';
import 'package:member_mobile_app/src/features/ops/views/ops_dlq_exceptions_view.dart';
import 'package:member_mobile_app/src/features/ops/views/ops_maker_queue_view.dart';
import 'package:member_mobile_app/src/features/ops/views/ops_payment_queue_view.dart';
import 'package:member_mobile_app/src/features/ops/views/ops_reconciliation_dashboard_view.dart';
import 'package:member_mobile_app/src/features/ops/views/ops_reconciliation_report_view.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureSessionStorage sessionStorage;
  late ApiClient apiClient;
  late UserSession checkerSession;
  late OpsController controller;

  setUp(() {
    sessionStorage = SecureSessionStorage();
    apiClient = ApiClient(sessionStorage: sessionStorage);
    checkerSession = UserSession(
      userId: 'usr-checker-officer-02',
      email: 'checker@alphacoop.internal',
      fullName: 'Chief Treasury Checker',
      tenantId: 'TENANT-ALPHA',
      role: UserRole.treasuryChecker,
      accessToken: 'test-checker-jwt-token',
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
    controller = OpsController(
      apiClient: apiClient,
      session: checkerSession,
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

  group('Slice 6 — Operations & Maker-Checker Queue Widget Tests (Screens 29–35)', () {
    testWidgets('Screen 29 (OpsPaymentQueueView) renders payment items and filter chips', (tester) async {
      await controller.loadOpsTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          OpsPaymentQueueView(
            controller: controller,
            onSelectPayment: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Operations Payment Queue'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Michael Chang'), findsOneWidget);
      expect(find.text(r'$5,000.00'), findsWidgets);
      expect(find.text('FedNow Instant'), findsOneWidget);
      expect(find.text('RTP Network'), findsOneWidget);

      // Tap filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'FedNow Instant'));
      await tester.pumpAndSettle();
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Michael Chang'), findsNothing);
    });

    testWidgets('Screen 30 (OpsMakerQueueView) renders pending Maker items and sign-off trigger', (tester) async {
      await controller.loadOpsTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          OpsMakerQueueView(
            controller: controller,
            onSelectMakerItem: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treasury Maker Queue'), findsOneWidget);
      expect(find.text('David Kim'), findsOneWidget);
      expect(find.text('Amina Al-Mansoor'), findsOneWidget);
      expect(find.text('KYC VERIFIED'), findsWidgets);
      expect(find.text('Approve Intent (Maker)'), findsWidgets);
    });

    testWidgets('Screen 31 (OpsCheckerQueueView) renders Maker provenance and release action', (tester) async {
      await controller.loadOpsTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          OpsCheckerQueueView(
            controller: controller,
            onSelectCheckerItem: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treasury Checker Queue'), findsOneWidget);
      expect(find.text('Marcus Vance'), findsOneWidget);
      expect(find.text('Chloe Bennett'), findsOneWidget);
      expect(find.text('Maker Sign-Off: Senior Treasury Maker (usr-maker-officer-01)'), findsOneWidget);
      expect(find.text('Authorize Release'), findsWidgets);
      expect(find.text('Reject'), findsWidgets);
    });

    testWidgets('Screen 32 (OpsActionDossierView) renders full cryptographic audit information', (tester) async {
      await controller.loadOpsTelemetry();
      final payment = (controller.value as dynamic).payments.first as OpsPaymentItem;

      await tester.pumpWidget(
        buildTestableWidget(
          OpsActionDossierView(
            payment: payment,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Instruction Dossier'), findsOneWidget);
      expect(find.text(r'$5,000.00'), findsOneWidget);
      expect(find.text('Sarah Jenkins (usr-member-001)'), findsOneWidget);
      expect(find.text('CORR-FEDNOW-8921-991'), findsOneWidget);
      expect(find.text('IDEM-PAY-001'), findsOneWidget);
      expect(find.text('SANDBOX_SIMULATION (Real-Money Movement Disabled)'), findsOneWidget);
    });

    testWidgets('Screen 33 (OpsDlqExceptionsView) renders failure diagnostics and safe replay', (tester) async {
      await controller.loadOpsTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          OpsDlqExceptionsView(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dead Letter Queue (DLQ)'), findsOneWidget);
      expect(find.text('DISBURSEMENT_DISPATCH_TIMEOUT'), findsOneWidget);
      expect(find.text('HTTP 504 Gateway Timeout during ISO 20022 clearing dispatch'), findsOneWidget);
      expect(find.text('Replay Event Safely'), findsWidgets);
    });

    testWidgets('Screen 34 (OpsReconciliationDashboardView) renders 5-way audit trigger and clean history', (tester) async {
      await controller.loadOpsTelemetry();

      await tester.pumpWidget(
        buildTestableWidget(
          OpsReconciliationDashboardView(
            controller: controller,
            onSelectReport: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5-Way Reconciliation Engine'), findsOneWidget);
      expect(find.text('MATCH CLEAN'), findsOneWidget);
      expect(find.text('Run 5-Way Audit'), findsWidgets);
      expect(find.text('Net Ledger Variance: \$0.00 USD (Zero Discrepancy)'), findsWidgets);
      expect(find.text('Inspect Report'), findsWidgets);
    });

    testWidgets('Screen 35 (OpsReconciliationReportView) renders zero-variance breakdown and WORM seal', (tester) async {
      await controller.loadOpsTelemetry();
      final report = (controller.value as dynamic).reconciliations.first as OpsReconciliationAuditItem;

      await tester.pumpWidget(
        buildTestableWidget(
          OpsReconciliationReportView(
            report: report,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5-Way Ledger Audit Report'), findsOneWidget);
      expect(find.text('Zero Variance Confirmed Across All 5 Ledger Domains'), findsOneWidget);
      expect(find.text('1. Funding Service Disbursed Executions'), findsOneWidget);
      expect(find.text('2. Treasury Committed Liquidity Pool Leases'), findsOneWidget);
      expect(find.text('3. Accounting General Ledger Double-Entry Journals'), findsOneWidget);
      expect(find.text('4. Member Account Obligations & Dues Ledger'), findsOneWidget);
      expect(find.text('5. External Clearing Settlement Confirmations'), findsOneWidget);
      expect(find.text('VERIFIED WORM SEAL'), findsOneWidget);
      expect(find.text('SHA256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069'), findsOneWidget);
    });

    testWidgets('OpsConsoleShell end-to-end multi-breakpoint responsive test (360px to 1440px)', (tester) async {
      await controller.loadOpsTelemetry();

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
            OpsConsoleShell(
              session: checkerSession,
              onSignOut: () {},
              apiClient: apiClient,
              controller: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OpsPaymentQueueView), findsOneWidget);
        expect(find.text('TENANT-ALPHA'), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
