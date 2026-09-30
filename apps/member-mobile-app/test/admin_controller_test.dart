import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/admin/models/admin_models.dart';
import 'package:member_mobile_app/src/features/admin/state/admin_controller.dart';
import 'package:member_mobile_app/src/features/admin/state/admin_state.dart';
import 'package:member_mobile_app/src/features/dashboard/models/member_dashboard_models.dart';

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

  group('AdminController — State Machine & Data Authority Tests', () {
    test('initial state is AdminLoading, loadAdminDashboard populates complete state', () async {
      expect(controller.value, isA<AdminLoading>());

      await controller.loadAdminDashboard();

      expect(controller.value, isA<AdminLoaded>());
      final loaded = controller.value as AdminLoaded;

      expect(loaded.overview.orgName, contains('Alpha Cooperative'));
      expect(loaded.overview.totalCapitalMinor, equals(50000000)); // $500,000.00
      expect(loaded.overview.committedCapitalMinor, equals(5000000)); // $50,000.00
      expect(loaded.overview.availableLiquidityMinor, equals(45000000)); // $450,000.00
      expect(loaded.overview.reserveGuardMinor, equals(7500000)); // $75,000.00 (15%)
      expect(loaded.members.length, greaterThanOrEqualTo(5));
      expect(loaded.cycles.length, greaterThanOrEqualTo(2));
      expect(loaded.treasury.reserveRatioPercent, equals(15.0));
    });

    test('searchMembers filters roster by name, email, or ID', () async {
      await controller.loadAdminDashboard();

      controller.searchMembers('Sarah');
      var loaded = controller.value as AdminLoaded;
      expect(loaded.filteredMembers.length, equals(1));
      expect(loaded.filteredMembers.first.fullName, equals('Sarah Jenkins'));

      controller.searchMembers('usr-member-002');
      loaded = controller.value as AdminLoaded;
      expect(loaded.filteredMembers.length, equals(1));
      expect(loaded.filteredMembers.first.memberId, equals('usr-member-002'));

      controller.searchMembers('');
      loaded = controller.value as AdminLoaded;
      expect(loaded.filteredMembers.length, equals(loaded.members.length));
    });

    test('filterMembersByKyc filters roster by KYC status', () async {
      await controller.loadAdminDashboard();

      controller.filterMembersByKyc('PENDING_REVIEW');
      var loaded = controller.value as AdminLoaded;
      expect(loaded.filteredMembers.every((m) => m.kycStatus == KycStatus.pending), isTrue);

      controller.filterMembersByKyc('ALL');
      loaded = controller.value as AdminLoaded;
      expect(loaded.filteredMembers.length, equals(loaded.members.length));
    });

    test('verifyMemberKyc transitions member KYC and updates standing', () async {
      await controller.loadAdminDashboard();

      final success = await controller.verifyMemberKyc('usr-member-003', true);
      expect(success, isTrue);

      final loaded = controller.value as AdminLoaded;
      final updated = loaded.members.firstWhere((m) => m.memberId == 'usr-member-003');
      expect(updated.kycStatus, equals(KycStatus.verified));
      expect(updated.accountStatus, equals('IN_GOOD_STANDING'));
    });

    test('createAndActivateCycle adds new cycle and calculates pure integer invariants', () async {
      await controller.loadAdminDashboard();
      final initialCount = (controller.value as AdminLoaded).cycles.length;

      const req = AdminCycleCreateRequest(
        cycleName: 'Test Circle Alpha',
        tenantId: 'TENANT-ALPHA',
        durationMonths: 10,
        contributionPerPeriodMinor: 50000,
        payoutPerSlotMinor: 500000,
        totalSlots: 10,
      );

      final success = await controller.createAndActivateCycle(req);
      expect(success, isTrue);

      final loaded = controller.value as AdminLoaded;
      expect(loaded.cycles.length, equals(initialCount + 1));
      expect(loaded.cycles.first.cycleName, equals('Test Circle Alpha'));
      expect(loaded.cycles.first.totalPoolCapitalMinor, equals(5000000)); // $50,000.00
      expect(loaded.cycles.first.slots.length, equals(10));
    });

    test('triggerTreasuryRebalance records verified event in audit trail', () async {
      await controller.loadAdminDashboard();
      final initialEvents = (controller.value as AdminLoaded).treasury.rebalanceHistory.length;

      final success = await controller.triggerTreasuryRebalance();
      expect(success, isTrue);

      final loaded = controller.value as AdminLoaded;
      expect(loaded.treasury.rebalanceHistory.length, equals(initialEvents + 1));
      expect(loaded.treasury.rebalanceHistory.first.status, equals('CONFIRMED_CLEAN'));
    });

    test('setActiveTab switches tab and clears selections', () async {
      await controller.loadAdminDashboard();

      controller.selectMember((controller.value as AdminLoaded).members.first);
      expect((controller.value as AdminLoaded).selectedMember, isNotNull);

      controller.setActiveTab(2);
      final loaded = controller.value as AdminLoaded;
      expect(loaded.activeTab, equals(2));
      expect(loaded.selectedMember, isNull);
    });
  });
}
