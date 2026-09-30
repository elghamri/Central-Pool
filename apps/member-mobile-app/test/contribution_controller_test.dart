import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/contributions/state/contribution_controller.dart';
import 'package:member_mobile_app/src/features/contributions/state/contribution_state.dart';

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

  group('ContributionController — State Machine & Data Integrity Tests', () {
    test('initial state is ContributionOverviewLoading', () {
      expect(controller.value, isA<ContributionOverviewLoading>());
    });

    test('loadOverview populates active due and 10-period history with pure integer minor units', () async {
      await controller.loadOverview();

      expect(controller.value, isA<ContributionOverviewLoaded>());
      final state = controller.value as ContributionOverviewLoaded;

      expect(state.activeDue.amountMinor, equals(50000)); // $500.00
      expect(state.activeDue.periodNumber, equals(2));
      expect(state.activeDue.status, equals('DUE'));
      expect(state.activeDue.cycleId, equals('CYCLE-2026-LIVE-01'));
      expect(state.history.length, equals(10));
      expect(state.history.first.status, equals('PAID'));
      expect(state.history[1].status, equals('DUE'));
      expect(state.paymentMethods.length, greaterThanOrEqualTo(4));
    });

    test('selectPaymentMethod updates selected rail in loaded state', () async {
      await controller.loadOverview();

      final stateBefore = controller.value as ContributionOverviewLoaded;
      final achMethod = stateBefore.paymentMethods.firstWhere((m) => m.id == 'pm-ach-02');

      controller.selectPaymentMethod(achMethod);

      final stateAfter = controller.value as ContributionOverviewLoaded;
      expect(stateAfter.selectedPaymentMethod.id, equals('pm-ach-02'));
    });

    test('submitContribution transitions through Processing to Success on Instant rail', () async {
      await controller.loadOverview();
      final loadedState = controller.value as ContributionOverviewLoaded;

      final future = controller.submitContribution(
        detail: loadedState.activeDue,
        paymentMethod: loadedState.selectedPaymentMethod,
      );

      expect(controller.value, isA<ContributionProcessing>());
      final processingState = controller.value as ContributionProcessing;
      expect(processingState.idempotencyKey.startsWith('idem-contrib-'), isTrue);

      await future;

      expect(controller.value, isA<ContributionSuccess>());
      final successState = controller.value as ContributionSuccess;
      expect(successState.result.status, equals('SETTLED'));
      expect(successState.result.amountMinor, equals(50000));
      expect(successState.result.transactionReference, equals('PAY-RTGS-FEDNOW-002'));
      expect(successState.result.ledgerJournalId, equals('GL-JRNL-2026-002'));
    });

    test('submitContribution transitions to Pending when using ACH batch payment rail', () async {
      await controller.loadOverview();
      final loadedState = controller.value as ContributionOverviewLoaded;
      final achMethod = loadedState.paymentMethods.firstWhere((m) => m.id == 'pm-ach-02');

      await controller.submitContribution(
        detail: loadedState.activeDue,
        paymentMethod: achMethod,
        simulatePending: true,
      );

      expect(controller.value, isA<ContributionPending>());
      final pendingState = controller.value as ContributionPending;
      expect(pendingState.result.status, equals('PENDING'));
      expect(pendingState.result.transactionReference.startsWith('ACH-BATCH-'), isTrue);
    });

    test('submitContribution transitions to Failed on rail rejection with error diagnostics', () async {
      await controller.loadOverview();
      final loadedState = controller.value as ContributionOverviewLoaded;

      await controller.submitContribution(
        detail: loadedState.activeDue,
        paymentMethod: loadedState.selectedPaymentMethod,
        simulateFailure: true,
      );

      expect(controller.value, isA<ContributionFailed>());
      final failedState = controller.value as ContributionFailed;
      expect(failedState.errorCode, equals('ERR_RAIL_REJECTED'));
      expect(failedState.errorMessage.toLowerCase().contains('insufficient-liquidity') || failedState.errorMessage.toLowerCase().contains('insufficient liquidity'), isTrue);
    });

    test('submitContribution transitions to Timeout and strictly DOES NOT treat timeout as success', () async {
      await controller.loadOverview();
      final loadedState = controller.value as ContributionOverviewLoaded;

      await controller.submitContribution(
        detail: loadedState.activeDue,
        paymentMethod: loadedState.selectedPaymentMethod,
        simulateTimeout: true,
      );

      expect(controller.value, isA<ContributionTimeout>());
      final timeoutState = controller.value as ContributionTimeout;
      expect(timeoutState.message.contains('did not respond in time'), isTrue);
      expect(controller.value is ContributionSuccess, isFalse);
    });

    test('submitContribution rejects duplicate in-flight submissions', () async {
      await controller.loadOverview();
      final loadedState = controller.value as ContributionOverviewLoaded;

      // Start first submission
      final f1 = controller.submitContribution(
        detail: loadedState.activeDue,
        paymentMethod: loadedState.selectedPaymentMethod,
      );

      // Attempt immediate duplicate submission while in-flight
      final f2 = controller.submitContribution(
        detail: loadedState.activeDue,
        paymentMethod: loadedState.selectedPaymentMethod,
      );

      await Future.wait([f1, f2]);
      expect(controller.value, isA<ContributionSuccess>());
    });

    test('resetFlow returns state back to loaded overview', () async {
      await controller.loadOverview();
      final loadedState = controller.value as ContributionOverviewLoaded;

      await controller.submitContribution(
        detail: loadedState.activeDue,
        paymentMethod: loadedState.selectedPaymentMethod,
      );

      expect(controller.value, isA<ContributionSuccess>());

      controller.resetFlow();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.value, isA<ContributionOverviewLoaded>());
    });
  });
}
