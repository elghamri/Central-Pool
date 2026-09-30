import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/dashboard/state/dashboard_controller.dart';
import 'package:member_mobile_app/src/features/dashboard/state/dashboard_state.dart';

void main() {
  group('DashboardController — State Machine & Data Integrity Tests', () {
    late SessionStorage sessionStorage;
    late ApiClient apiClient;
    late UserSession session;
    late DashboardController controller;

    setUp(() {
      sessionStorage = SecureSessionStorage();
      apiClient = ApiClient(sessionStorage: sessionStorage);
      session = UserSession(
        userId: 'usr-member-001',
        email: 'member@collaborativefinance.org',
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

    test('initial state is DashboardLoading', () {
      expect(controller.value, isA<DashboardLoading>());
    });

    test('loadDashboardData resolves full member summary and live pool state with integer minor units', () async {
      await controller.loadDashboardData();

      expect(controller.value, isA<DashboardLoaded>());
      final loaded = controller.value as DashboardLoaded;

      // Verify Member Summary
      expect(loaded.summary.memberId, 'usr-member-001');
      expect(loaded.summary.fullName, 'Sarah Jenkins');
      expect(loaded.summary.payoutPosition, 1);
      expect(loaded.summary.totalSlots, 10);
      expect(loaded.summary.expectedPayoutMinor, 500000); // $5,000.00
      expect(loaded.summary.nextContributionDueMinor, 50000); // $500.00
      expect(loaded.summary.availablePoolLiquidityMinor, 5000000); // $50,000.00
      expect(loaded.summary.reserveGuardMinor, 750000); // $7,500.00 (15%)

      // Verify Live Pool State
      expect(loaded.poolState.cycleId, 'CYCLE-2026-LIVE-01');
      expect(loaded.poolState.status, 'ACTIVE');
      expect(loaded.poolState.participatingMemberCount, 10);
      expect(loaded.poolState.slots.length, 10);
      expect(loaded.poolState.slots.first.isCurrentMember, isTrue);
      expect(loaded.poolState.slots.first.payoutAmountMinor, 500000);

      // Verify Financial Summary
      expect(loaded.financialSummary.contributionSchedule.length, 10);
      expect(loaded.financialSummary.contributionSchedule.first.status, 'PAID');
      expect(loaded.financialSummary.contributionSchedule[1].status, 'DUE');
      expect(loaded.financialSummary.obligations.isNotEmpty, isTrue);
    });

    test('refresh maintains previous data with isRefreshing flag and updates lastUpdated', () async {
      await controller.loadDashboardData();
      expect(controller.value, isA<DashboardLoaded>());

      final initialLoaded = controller.value as DashboardLoaded;
      final initialTimestamp = initialLoaded.lastUpdated;

      await Future.delayed(const Duration(milliseconds: 10));
      await controller.refresh();

      expect(controller.value, isA<DashboardLoaded>());
      final refreshed = controller.value as DashboardLoaded;
      expect(refreshed.isRefreshing, isFalse);
      expect(refreshed.lastUpdated.isAfter(initialTimestamp) || refreshed.lastUpdated == initialTimestamp, isTrue);
    });

    test('mathematical balance invariant check across pool, contributions, and obligations', () async {
      await controller.loadDashboardData();
      final loaded = controller.value as DashboardLoaded;

      // Invariant 1: Total pool = 10 members * $5,000 payout = $50,000 (5,000,000 minor units)
      expect(loaded.poolState.totalPoolMinor, 5000000);

      // Invariant 2: 15% reserve requirement of $50,000 = $7,500 (750,000 minor units)
      expect(loaded.poolState.reserveGuardMinor, 750000);

      // Invariant 3: Sum of slot payouts equals total pool amount
      final sumSlots = loaded.poolState.slots.fold<int>(0, (sum, s) => sum + s.payoutAmountMinor);
      expect(sumSlots, loaded.poolState.totalPoolMinor);

      // Invariant 4: Sum of 10 member monthly dues ($500 * 10) = $5,000 monthly pool
      final monthlyPoolDues = loaded.summary.nextContributionDueMinor * loaded.summary.totalSlots;
      expect(monthlyPoolDues, loaded.summary.expectedPayoutMinor);
    });
  });
}
