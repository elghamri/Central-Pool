import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/contributions/models/contribution_models.dart';
import 'package:member_mobile_app/src/features/contributions/state/contribution_controller.dart';
import 'package:member_mobile_app/src/features/contributions/views/contribution_confirmation_view.dart';
import 'package:member_mobile_app/src/features/contributions/views/contribution_details_view.dart';
import 'package:member_mobile_app/src/features/contributions/views/contribution_flow_coordinator.dart';
import 'package:member_mobile_app/src/features/contributions/views/contribution_processing_view.dart';
import 'package:member_mobile_app/src/features/contributions/views/contribution_receipt_view.dart';
import 'package:member_mobile_app/src/features/contributions/views/contributions_overview_view.dart';
import 'package:member_mobile_app/src/features/contributions/views/payment_method_view.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureSessionStorage sessionStorage;
  late ApiClient apiClient;
  late UserSession testSession;
  late ContributionController controller;

  setUp(() {
    sessionStorage = SecureSessionStorage();
    apiClient = ApiClient(sessionStorage: sessionStorage);
    testSession = UserSession(
      userId: 'usr-member-001',
      tenantId: 'TENANT-ALPHA',
      email: 'sarah.jenkins@example.com',
      fullName: 'Sarah Jenkins',
      role: UserRole.member,
      accessToken: 'jwt-member-mock-token',
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
    controller = ContributionController(
      apiClient: apiClient,
      session: testSession,
    );
  });

  tearDown(() {
    controller.dispose();
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

  group('Slice 3 — Member Monthly Contribution Flow Widget Tests', () {
    testWidgets('Screen 9 (ContributionsOverviewView) renders active due, metric cards, and 10-period history', (tester) async {
      await controller.loadOverview();

      await tester.pumpWidget(createTestWidget(
        ContributionsOverviewView(
          controller: controller,
          onMakeContribution: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // 1. Verify Cycle & Member Context Banner
      expect(find.text('Rotating Pool Alpha-1'), findsOneWidget);
      expect(find.text('SLOT #1 OF 10'), findsOneWidget);

      // 2. Verify Active Due Card
      expect(find.text('Current Contribution Due'), findsOneWidget);
      expect(find.text('Period #2 Monthly Due'), findsNWidgets(2)); // in active card and list
      expect(find.text('\$500.00'), findsWidgets);
      expect(find.text('Make Contribution (\$500.00)'), findsOneWidget);

      // 3. Verify Metric Cards
      expect(find.text('Amount Already Contributed'), findsOneWidget);
      expect(find.text('Remaining Cycle Obligation'), findsOneWidget);
      expect(find.text('Cycle Obligation Target'), findsOneWidget);

      // 4. Verify History List
      expect(find.text('Contribution Schedule & History'), findsOneWidget);
      expect(find.text('10 PERIODS'), findsOneWidget);
      expect(find.text('Period #1 Monthly Due'), findsOneWidget);
    });

    testWidgets('Screen 10 (ContributionDetailsView) renders obligation details and continue action', (tester) async {
      final detail = ContributionDetail(
        periodNumber: 2,
        title: 'Period #2 Monthly Due',
        amountMinor: 50000,
        dueDate: DateTime(2026, 10, 1),
        status: 'DUE',
        cycleId: 'CYCLE-2026-LIVE-01',
        cycleName: 'Rotating Pool Alpha-1',
        memberId: 'usr-member-001',
        memberName: 'Sarah Jenkins',
        slotPosition: 1,
        totalSlots: 10,
        totalContributedMinor: 50000,
        remainingCycleObligationMinor: 450000,
        totalCycleObligationMinor: 500000,
      );

      bool continued = false;
      bool cancelled = false;

      await tester.pumpWidget(createTestWidget(
        ContributionDetailsView(
          detail: detail,
          onContinueToPayment: () => continued = true,
          onBack: () => cancelled = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Contribution Details'), findsOneWidget);
      expect(find.text('Period #2 Monthly Due'), findsOneWidget);
      expect(find.text('\$500.00'), findsOneWidget);
      expect(find.text('Rotating Pool Alpha-1 (CYCLE-2026-LIVE-01)'), findsOneWidget);
      expect(find.text('Sarah Jenkins (usr-member-001)'), findsOneWidget);

      // Tap Continue to Payment
      final continueBtn = find.widgetWithText(PrimaryButton, 'Continue to Payment');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      expect(continued, isTrue);
      expect(cancelled, isFalse);
    });

    testWidgets('Screen 11 (PaymentMethodView) renders available rails and handles selection', (tester) async {
      final methods = PaymentMethodItem.defaultMethods;
      PaymentMethodItem selected = methods.first;

      await tester.pumpWidget(createTestWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return PaymentMethodView(
              methods: methods,
              selectedMethod: selected,
              onSelectMethod: (m) => setState(() => selected = m),
              onProceedToReview: () {},
              onBack: () {},
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('FedNow Instant Bank Transfer'), findsOneWidget);
      expect(find.text('ACH Direct Debit'), findsOneWidget);
      expect(find.text('Sandbox Simulation Rail'), findsOneWidget);
      expect(find.text('Card / International Wire'), findsOneWidget);

      // Select ACH
      await tester.tap(find.text('ACH Direct Debit'));
      await tester.pumpAndSettle();

      expect(selected.id, equals('pm-ach-02'));
    });

    testWidgets('Screen 12 (ContributionConfirmationView) renders review details and handles submit', (tester) async {
      final detail = ContributionDetail(
        periodNumber: 2,
        title: 'Period #2 Monthly Due',
        amountMinor: 50000,
        dueDate: DateTime(2026, 10, 1),
        status: 'DUE',
        cycleId: 'CYCLE-2026-LIVE-01',
        cycleName: 'Rotating Pool Alpha-1',
        memberId: 'usr-member-001',
        memberName: 'Sarah Jenkins',
        slotPosition: 1,
        totalSlots: 10,
        totalContributedMinor: 50000,
        remainingCycleObligationMinor: 450000,
        totalCycleObligationMinor: 500000,
      );
      final method = PaymentMethodItem.defaultMethods.first;
      bool confirmed = false;

      await tester.pumpWidget(createTestWidget(
        ContributionConfirmationView(
          detail: detail,
          paymentMethod: method,
          isSubmitting: false,
          onConfirmPayment: () => confirmed = true,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Contribution'), findsOneWidget);
      expect(find.text('Payment Authorization Summary'), findsOneWidget);
      expect(find.text('\$500.00'), findsOneWidget);
      expect(find.text('FedNow Instant Bank Transfer'), findsOneWidget);

      // Tap Confirm
      final confirmBtn = find.widgetWithText(PrimaryButton, 'Authorize & Pay (\$500.00)');
      expect(confirmBtn, findsOneWidget);
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      expect(confirmed, isTrue);
    });

    testWidgets('Screen 13 (ContributionProcessingView) renders failed and timeout recovery views', (tester) async {
      final detail = ContributionDetail(
        periodNumber: 2,
        title: 'Period #2 Monthly Due',
        amountMinor: 50000,
        dueDate: DateTime(2026, 10, 1),
        status: 'DUE',
        cycleId: 'CYCLE-2026-LIVE-01',
        cycleName: 'Rotating Pool Alpha-1',
        memberId: 'usr-member-001',
        memberName: 'Sarah Jenkins',
        slotPosition: 1,
        totalSlots: 10,
        totalContributedMinor: 50000,
        remainingCycleObligationMinor: 450000,
        totalCycleObligationMinor: 500000,
      );
      final method = PaymentMethodItem.defaultMethods.first;

      // 1. Timeout State
      await tester.pumpWidget(createTestWidget(
        ContributionProcessingView(
          status: 'TIMEOUT',
          message: 'The clearing network did not respond in time.',
          correlationId: 'corr-test-1234',
          detail: detail,
          paymentMethod: method,
          onRetry: () {},
          onChangeMethod: () {},
          onReturnToOverview: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Clearing Network Timeout'), findsOneWidget);
      expect(find.text('TIMEOUT / PENDING'), findsOneWidget);
      expect(find.text('Check Status & Return to Overview'), findsOneWidget);

      // 2. Failed State
      await tester.pumpWidget(createTestWidget(
        ContributionProcessingView(
          status: 'FAILED',
          message: 'Insufficient liquidity on bank rail.',
          errorCode: 'ERR_RAIL_REJECTED',
          detail: detail,
          paymentMethod: method,
          onRetry: () {},
          onChangeMethod: () {},
          onReturnToOverview: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Payment Authorization Failed'), findsOneWidget);
      expect(find.text('ERR_RAIL_REJECTED'), findsOneWidget);
      expect(find.text('Retry Payment (\$500.00)'), findsOneWidget);
      expect(find.text('Select Different Payment Method'), findsOneWidget);
    });

    testWidgets('Screen 14 (ContributionReceiptView) renders settled receipt with WORM audit seal', (tester) async {
      final detail = ContributionDetail(
        periodNumber: 2,
        title: 'Period #2 Monthly Due',
        amountMinor: 50000,
        dueDate: DateTime(2026, 10, 1),
        status: 'DUE',
        cycleId: 'CYCLE-2026-LIVE-01',
        cycleName: 'Rotating Pool Alpha-1',
        memberId: 'usr-member-001',
        memberName: 'Sarah Jenkins',
        slotPosition: 1,
        totalSlots: 10,
        totalContributedMinor: 50000,
        remainingCycleObligationMinor: 450000,
        totalCycleObligationMinor: 500000,
      );

      final result = ContributionSubmissionResult(
        contributionId: 'CONTRIB-2026-PER2-8921',
        status: 'SETTLED',
        amountMinor: 50000,
        periodNumber: 2,
        cycleId: 'CYCLE-2026-LIVE-01',
        settledAt: DateTime(2026, 8, 26, 12, 0, 0),
        transactionReference: 'PAY-RTGS-FEDNOW-002',
        correlationId: 'corr-contrib-9812',
        ledgerJournalId: 'GL-JRNL-2026-002',
        paymentRail: 'FedNow Instant Bank Transfer',
      );

      await tester.pumpWidget(createTestWidget(
        ContributionReceiptView(
          result: result,
          detail: detail,
          onReturnToOverview: () {},
          onGoToDashboard: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Contribution Settled Successfully'), findsOneWidget);
      expect(find.text('Official Financial Receipt'), findsOneWidget);
      expect(find.text('\$500.00'), findsOneWidget);
      expect(find.text('CONTRIB-2026-PER2-8921'), findsOneWidget);
      expect(find.text('PAY-RTGS-FEDNOW-002'), findsOneWidget);
      expect(find.text('GL-JRNL-2026-002'), findsOneWidget);
      expect(find.text('Download Signed Receipt (PDF)'), findsOneWidget);
      expect(find.text('WORM Audit Log Recorded'), findsOneWidget);
    });

    testWidgets('Full End-to-End Flow: Overview -> Details -> Payment Method -> Confirm -> Process -> Receipt', (tester) async {
      await controller.loadOverview();

      await tester.pumpWidget(createTestWidget(
        ContributionFlowCoordinator(
          controller: controller,
          onGoToDashboard: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Step 0: Overview
      expect(find.text('Current Contribution Due'), findsOneWidget);
      final makeContribBtn = find.widgetWithText(PrimaryButton, 'Make Contribution (\$500.00)');
      await tester.tap(makeContribBtn);
      await tester.pumpAndSettle();

      // Step 1: Details
      expect(find.text('Contribution Details'), findsOneWidget);
      final continueBtn = find.widgetWithText(PrimaryButton, 'Continue to Payment');
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 2: Payment Method
      expect(find.text('Select Payment Method'), findsOneWidget);
      final proceedReviewBtn = find.widgetWithText(PrimaryButton, 'Proceed to Review (FedNow Instant Bank Transfer)');
      await tester.ensureVisible(proceedReviewBtn);
      await tester.tap(proceedReviewBtn);
      await tester.pumpAndSettle();

      // Step 3: Confirmation
      expect(find.text('Confirm Contribution'), findsOneWidget);
      final authorizeBtn = find.widgetWithText(PrimaryButton, 'Authorize & Pay (\$500.00)');
      await tester.ensureVisible(authorizeBtn);
      await tester.tap(authorizeBtn);
      await tester.pump(); // Advance to processing

      // Step 4: Processing State
      expect(find.text('Processing Contribution...'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      // Step 5: Receipt State
      expect(find.text('Contribution Settled Successfully'), findsOneWidget);
      expect(find.text('CONTRIB-2026-PER2-8921'), findsOneWidget);
    });

    testWidgets('Multi-breakpoint responsive rendering (360px mobile, 768px tablet, 1280px desktop)', (tester) async {
      final sizes = [
        const Size(360, 800), // Narrow mobile
        const Size(390, 844), // Standard mobile
        const Size(430, 932), // Large mobile
        const Size(768, 1024), // Tablet
        const Size(1280, 800), // Desktop
      ];

      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await controller.loadOverview();

        await tester.pumpWidget(createTestWidget(
          ContributionFlowCoordinator(
            controller: controller,
            onGoToDashboard: () {},
          ),
          size: size,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Current Contribution Due'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
