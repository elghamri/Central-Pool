import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/ops/state/ops_controller.dart';
import 'package:member_mobile_app/src/features/ops/state/ops_state.dart';

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

  group('OpsController — State Machine, Maker-Checker & Invariant Safety Tests', () {
    test('initial state is OpsLoading, loadOpsTelemetry populates complete telemetry', () async {
      expect(controller.value, isA<OpsLoading>());

      await controller.loadOpsTelemetry();

      expect(controller.value, isA<OpsLoaded>());
      final loaded = controller.value as OpsLoaded;
      expect(loaded.payments.length, equals(4));
      expect(loaded.makerQueue.length, equals(2));
      expect(loaded.checkerQueue.length, equals(2));
      expect(loaded.dlqRecords.length, equals(2));
      expect(loaded.reconciliations.length, equals(2));
    });

    test('search and filter chips correctly filter payment items', () async {
      await controller.loadOpsTelemetry();

      // Filter by FedNow rail
      controller.setRailFilter('FEDNOW');
      expect((controller.value as OpsLoaded).filteredPayments.length, equals(1));
      expect((controller.value as OpsLoaded).filteredPayments.first.paymentId, equals('PAY-2026-FEDNOW-01'));

      // Filter by status SETTLED
      controller.setRailFilter('ALL');
      controller.setStatusFilter('SETTLED');
      expect((controller.value as OpsLoaded).filteredPayments.length, equals(1));

      // Search by recipient name
      controller.setStatusFilter('ALL');
      controller.setSearchQuery('Marcus');
      expect((controller.value as OpsLoaded).filteredPayments.length, equals(1));
      expect((controller.value as OpsLoaded).filteredPayments.first.recipientName, equals('Marcus Vance'));
    });

    test('submitMakerApproval transitions item from Maker Queue to Checker Queue', () async {
      final makerSession = UserSession(
        userId: 'usr-maker-officer-01',
        email: 'maker@alphacoop.internal',
        fullName: 'Treasury Maker Officer',
        tenantId: 'TENANT-ALPHA',
        role: UserRole.treasuryMaker,
        accessToken: 'test-maker-jwt-token',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );
      final makerController = OpsController(apiClient: apiClient, session: makerSession);
      await makerController.loadOpsTelemetry();

      final initialMakerCount = (makerController.value as OpsLoaded).makerQueue.length;
      final initialCheckerCount = (makerController.value as OpsLoaded).checkerQueue.length;

      final success = await makerController.submitMakerApproval('FND-ALLOC-2026-05', notes: 'Verified KYC milestone.');
      expect(success, isTrue);

      final loaded = makerController.value as OpsLoaded;
      expect(loaded.makerQueue.length, equals(initialMakerCount - 1));
      expect(loaded.checkerQueue.length, equals(initialCheckerCount + 1));
      expect(loaded.checkerQueue.first.makerId, equals('usr-maker-officer-01'));
      expect(loaded.isActionFeedbackSuccess, isTrue);

      makerController.dispose();
    });

    test('authorizeCheckerRelease authorizes release and prevents duplicate processing', () async {
      await controller.loadOpsTelemetry();
      final initialCheckerCount = (controller.value as OpsLoaded).checkerQueue.length;
      final initialPaymentCount = (controller.value as OpsLoaded).payments.length;

      final success = await controller.authorizeCheckerRelease('FND-ALLOC-2026-04', makerId: 'usr-maker-officer-01');
      expect(success, isTrue);

      final loaded = controller.value as OpsLoaded;
      expect(loaded.checkerQueue.length, equals(initialCheckerCount - 1));
      expect(loaded.payments.length, equals(initialPaymentCount + 1));
      expect(loaded.payments.first.status, equals('DISPATCHED'));
      expect(loaded.isActionFeedbackSuccess, isTrue);
    });

    test('MANDATORY INVARIANT INV-15: authorizeCheckerRelease strictly forbids self-approval', () async {
      await controller.loadOpsTelemetry();

      // Attempt to authorize release where Maker ID matches the authenticated Checker session ID
      final success = await controller.authorizeCheckerRelease(
        'FND-ALLOC-2026-04',
        makerId: checkerSession.userId, // Same as session.userId
      );

      expect(success, isFalse);
      final loaded = controller.value as OpsLoaded;
      expect(loaded.isActionFeedbackSuccess, isFalse);
      expect(loaded.actionFeedbackMessage, contains('Self-Approval Forbidden'));
    });

    test('rejectCheckerRelease removes item from queue with required rationale', () async {
      await controller.loadOpsTelemetry();
      final initialCheckerCount = (controller.value as OpsLoaded).checkerQueue.length;

      // Rejection with empty reason fails
      final failAttempt = await controller.rejectCheckerRelease('FND-ALLOC-2026-07', reason: '   ');
      expect(failAttempt, isFalse);

      // Rejection with valid reason succeeds
      final success = await controller.rejectCheckerRelease('FND-ALLOC-2026-07', reason: 'Signature mismatch on KYC document');
      expect(success, isTrue);

      final loaded = controller.value as OpsLoaded;
      expect(loaded.checkerQueue.length, equals(initialCheckerCount - 1));
      expect(loaded.isActionFeedbackSuccess, isTrue);
    });

    test('replayDlqRecord safely re-drives dead letter events', () async {
      await controller.loadOpsTelemetry();

      final success = await controller.replayDlqRecord('DLQ-2026-EVT-001');
      expect(success, isTrue);

      final loaded = controller.value as OpsLoaded;
      final replayed = loaded.dlqRecords.firstWhere((r) => r.dlqId == 'DLQ-2026-EVT-001');
      expect(replayed.status, equals('REPLAYED'));
      expect(replayed.retryCount, equals(4));
    });

    test('run5WayReconciliation executes deterministic audit and produces 0 variance report', () async {
      await controller.loadOpsTelemetry();
      final initialCount = (controller.value as OpsLoaded).reconciliations.length;

      final report = await controller.run5WayReconciliation('CYCLE-2026-LIVE-01');
      expect(report, isNotNull);
      expect(report!.discrepancyAmountMinor, equals(0));
      expect(report.isMatched, isTrue);
      expect(report.status, equals('RECONCILIATION_MATCH_CLEAN'));
      expect(report.fundingDisbursedMinor, equals(report.treasuryCommittedMinor));
      expect(report.fundingDisbursedMinor, equals(report.glJournalTotalMinor));
      expect(report.fundingDisbursedMinor, equals(report.memberObligationMinor));
      expect(report.fundingDisbursedMinor, equals(report.settlementTotalMinor));

      final loaded = controller.value as OpsLoaded;
      expect(loaded.reconciliations.length, equals(initialCount + 1));
      expect(loaded.selectedReconciliation?.reportId, equals(report.reportId));
    });
  });
}
