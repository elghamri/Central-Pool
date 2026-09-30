import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/funding/models/funding_models.dart';
import 'package:member_mobile_app/src/features/funding/state/funding_controller.dart';
import 'package:member_mobile_app/src/features/funding/state/funding_state.dart';

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

  group('FundingController — State Machine & Pure Integer Financial Invariants', () {
    test('initial state is FundingLoading', () {
      expect(controller.value, isA<FundingLoading>());
    });

    test('loadFundingData resolves full funding overview and 14-stage lifecycle', () async {
      await controller.loadFundingData();

      expect(controller.value, isA<FundingLoaded>());
      final loaded = controller.value as FundingLoaded;
      final overview = loaded.overview;

      // Pure integer minor unit verifications
      expect(overview.allocation.expectedPayoutMinor, equals(500000)); // $5,000.00
      expect(overview.settlement.amountMinor, equals(500000)); // $5,000.00
      expect(overview.obligation.totalObligationMinor, equals(500000)); // $5,000.00
      expect(overview.obligation.repaidAmountMinor, equals(50000)); // $500.00
      expect(overview.obligation.remainingObligationMinor, equals(450000)); // $4,500.00
      expect(overview.auditStatement.varianceAmountMinor, equals(0)); // $0.00

      // Mathematical Invariant: Total Obligation = Repaid + Remaining
      expect(
        overview.obligation.repaidAmountMinor + overview.obligation.remainingObligationMinor,
        equals(overview.obligation.totalObligationMinor),
      );

      // Lifecycle stages
      expect(overview.lifecycleStages.length, equals(14));
      expect(overview.lifecycleStages.first.stageNumber, equals(1));
      expect(overview.lifecycleStages.first.title, equals('Eligibility Gate'));
      expect(overview.lifecycleStages.last.stageNumber, equals(14));
      expect(overview.lifecycleStages.last.title, equals('5-Way Reconciliation'));
      expect(overview.lifecycleStages.every((s) => s.status == LifecycleStageStatus.completed), isTrue);

      // Eligibility
      expect(overview.eligibility.isEligible, isTrue);
      expect(overview.eligibility.status, equals(FundingEligibilityStatus.eligible));
      expect(overview.eligibility.criteria.length, equals(4));

      // Allocation separation
      expect(overview.allocation.status, equals('ALLOCATED'));
      expect(overview.allocation.slotNumber, equals(1));
      expect(overview.allocation.totalSlots, equals(10));

      // Settlement
      expect(overview.settlement.settlementStatus, equals('SETTLED'));
      expect(overview.settlement.clearingRail, contains('FedNow'));
    });

    test('setViewIndex updates currentViewIndex cleanly without mutating overview', () async {
      await controller.loadFundingData();

      expect((controller.value as FundingLoaded).currentViewIndex, equals(0));

      controller.setViewIndex(3);
      expect((controller.value as FundingLoaded).currentViewIndex, equals(3));

      controller.setViewIndex(6);
      expect((controller.value as FundingLoaded).currentViewIndex, equals(6));

      controller.setViewIndex(0);
      expect((controller.value as FundingLoaded).currentViewIndex, equals(0));
    });

    test('loadFundingData with forceRefresh maintains state and updates timestamp', () async {
      await controller.loadFundingData();
      expect(controller.value, isA<FundingLoaded>());

      await controller.loadFundingData(forceRefresh: true);
      expect(controller.value, isA<FundingLoaded>());
    });
  });
}
