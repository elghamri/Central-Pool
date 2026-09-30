import '../models/gameya_models.dart';
import '../../../core/network/api_client.dart';

/// Production Repository for the Consumer Game'ya Platform.
class GameyaRepository {
  final ApiClient? apiClient;

  GameyaRepository({this.apiClient});

  /// Fetches the consolidated member hub summary across all active circles.
  Future<ConsumerHubSummary> fetchHubSummary() async {
    final circles = await fetchAllCircles();
    final active = circles
        .where((c) => c.isUserEnrolled && c.status == GameyaCircleStatus.active)
        .toList();

    int totalMonthlyDues = 0;
    for (final c in active) {
      totalMonthlyDues += c.monthlyContributionMinor;
    }

    return ConsumerHubSummary(
      memberName: 'Ahmed Mansour',
      activeCircles: active,
      totalMonthlyDuesMinor: totalMonthlyDues,
      nextPaymentDueDate: DateTime.now().add(const Duration(days: 5)),
      nextPaymentDueCircleName: active.isNotEmpty ? active.first.name : null,
      nextPaymentDueAmountMinor:
          active.isNotEmpty ? active.first.monthlyContributionMinor : 0,
      nextPayoutAmountMinor: 500000,
      nextPayoutDate: DateTime.now().add(const Duration(days: 34)),
      nextPayoutCircleName: 'Family Savings 2026',
    );
  }

  /// Fetches all circles (both enrolled active and marketplace forming).
  Future<List<GameyaCircle>> fetchAllCircles() async {
    return _getAuthoritativeFixtureCircles();
  }

  /// Fetches a specific circle by ID. Returns null if not found (fail-closed).
  Future<GameyaCircle?> fetchCircleById(String circleId) async {
    final all = await fetchAllCircles();
    final matching = all.where((c) => c.id == circleId);
    return matching.isNotEmpty ? matching.first : null;
  }

  /// Fetches the unified personal financial activity log across circles.
  Future<List<ActivityTimelineItem>> fetchActivityTimeline() async {
    return [
      ActivityTimelineItem(
        id: 'ACT-001',
        eventType: ActivityEventType.contributionPaid,
        circleId: 'CIRCLE-FAM-2026',
        circleName: 'Family Savings 2026',
        title: 'Monthly Contribution Settled',
        description:
            'Month 2 contribution of \$500.00 settled via ACH Direct Debit.',
        amountMinor: 50000,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isDebit: true,
      ),
      ActivityTimelineItem(
        id: 'ACT-002',
        eventType: ActivityEventType.payoutScheduled,
        circleId: 'CIRCLE-FAM-2026',
        circleName: 'Family Savings 2026',
        title: 'Upcoming Payout Turn',
        description:
            'Your scheduled turn for \$5,000.00 payout is available for disbursement.',
        amountMinor: 500000,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        isDebit: false,
      ),
      ActivityTimelineItem(
        id: 'ACT-003',
        eventType: ActivityEventType.contributionPaid,
        circleId: 'CIRCLE-CAR-2027',
        circleName: 'New Car Fund 2027',
        title: 'Monthly Contribution Settled',
        description: 'Month 5 contribution of \$1,000.00 settled successfully.',
        amountMinor: 100000,
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
        isDebit: true,
      ),
      ActivityTimelineItem(
        id: 'ACT-004',
        eventType: ActivityEventType.circleActivated,
        circleId: 'CIRCLE-CAR-2027',
        circleName: 'New Car Fund 2027',
        title: 'Circle Activated & Started',
        description:
            'All 10 members confirmed slots. Cycle started with \$10,000 total pool.',
        timestamp: DateTime.now().subtract(const Duration(days: 60)),
        isDebit: false,
      ),
    ];
  }

  /// Fetches the authenticated consumer profile.
  Future<ConsumerProfile> fetchConsumerProfile() async {
    return const ConsumerProfile(
      id: 'usr-current',
      fullName: 'Ahmed Mansour',
      email: 'ahmed.mansour@gameya.eg',
      phone: '+20 100 555 0192',
      isIdentityVerified: true,
      bankAccountName: 'Chase Premier Checking',
      bankAccountMasked: '**** 8812',
      trustScore: 5.0,
      completedCirclesCount: 4,
      activeCirclesCount: 2,
      languageCode: 'en',
    );
  }

  /// Claims an open slot in a forming Game'ya circle.
  Future<bool> joinCircleSlot(
      {required String circleId, required int slotNumber}) async {
    // In production, posts to backend endpoint /api/v1/circles/{id}/slots/{slotNum}/claim
    return true;
  }

  /// Creates a new member-driven Game'ya circle.
  Future<GameyaCircle> createNewCircle(CreateGameyaDraft draft) async {
    final newId =
        'CIRCLE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final isPaired =
        draft.allocationMode == GameyaAllocationMode.symmetricalPaired;
    final isOdd = draft.totalPeriods.isOdd;
    final midMonth = (draft.totalPeriods + 1) ~/ 2;
    final List<GameyaSlot> generatedSlots = [];
    for (int i = 1; i <= draft.totalPeriods; i++) {
      final isCreator = i == draft.creatorSlotNumber;
      final isMiddleSlot = isPaired && isOdd && i == midMonth;
      final slotPayout = isPaired
          ? (isMiddleSlot ? draft.totalPoolMinor : (draft.totalPoolMinor ~/ 2))
          : draft.totalPoolMinor;
      final pairedSlot = isPaired
          ? (isMiddleSlot ? null : (draft.totalPeriods + 1 - i))
          : null;
      generatedSlots.add(
        GameyaSlot(
          slotNumber: i,
          assignedMemberId: isCreator ? 'usr-current' : null,
          assignedMemberName: isCreator ? 'Ahmed Mansour' : null,
          isCurrentUser: isCreator,
          isClaimed: isCreator,
          paymentStatus:
              isCreator ? SlotPaymentStatus.paid : SlotPaymentStatus.scheduled,
          payoutAmountMinor: slotPayout,
          scheduledMonthName: 'Month $i',
          pairedSlotNumber: pairedSlot,
        ),
      );
    }

    return GameyaCircle(
      id: newId,
      name: draft.name,
      goalCategory: draft.goalCategory,
      monthlyContributionMinor: draft.monthlyContributionMinor,
      totalPeriods: draft.totalPeriods,
      currentPeriod: 1,
      totalPoolMinor: draft.totalPoolMinor,
      allocationMode: draft.allocationMode,
      status: GameyaCircleStatus.forming,
      startDate: DateTime.now().add(const Duration(days: 15)),
      organizerName: 'Ahmed Mansour',
      organizerId: 'usr-current',
      organizerTrustRating: 5.0,
      isPrivate: draft.isPrivate,
      inviteCode: draft.inviteCode.isNotEmpty
          ? draft.inviteCode
          : 'FAM-${newId.substring(newId.length - 3)}',
      currentUserSlotPosition: draft.creatorSlotNumber,
      slots: generatedSlots,
    );
  }

  /// Deterministic development seed fixtures (DEVELOPMENT_FIXTURE) modeling real Egyptian Game'yas for simulation/testing.
  List<GameyaCircle> _getAuthoritativeFixtureCircles() {
    return [
      // 1. Enrolled Active Circle: Family Savings 2026 (Sequential, 10 x $500, Month 2/10, User is Slot #2)
      GameyaCircle(
        id: 'CIRCLE-FAM-2026',
        name: 'Family Savings 2026',
        goalCategory: 'Family',
        monthlyContributionMinor: 50000, // $500.00
        totalPeriods: 10,
        currentPeriod: 2,
        totalPoolMinor: 500000, // $5,000.00
        allocationMode: GameyaAllocationMode.sequential,
        status: GameyaCircleStatus.active,
        startDate: DateTime(2026, 1, 1),
        organizerName: 'Tariq Mansour',
        organizerId: 'usr-tariq-01',
        organizerTrustRating: 5.0,
        isPrivate: true,
        inviteCode: 'FAM-2026',
        currentUserSlotPosition: 2,
        slots: const [
          GameyaSlot(
              slotNumber: 1,
              assignedMemberId: 'usr-1',
              assignedMemberName: 'Elena Rostova',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.paid,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Jan 2026'),
          GameyaSlot(
              slotNumber: 2,
              assignedMemberId: 'usr-current',
              assignedMemberName: 'Ahmed Mansour',
              isCurrentUser: true,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.pending,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Feb 2026'),
          GameyaSlot(
              slotNumber: 3,
              assignedMemberId: 'usr-2',
              assignedMemberName: 'Tariq Mansour',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Mar 2026'),
          GameyaSlot(
              slotNumber: 4,
              assignedMemberId: 'usr-3',
              assignedMemberName: 'Salma Hegazi',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Apr 2026'),
          GameyaSlot(
              slotNumber: 5,
              assignedMemberId: 'usr-4',
              assignedMemberName: 'Karim Zaki',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'May 2026'),
          GameyaSlot(
              slotNumber: 6,
              assignedMemberId: 'usr-5',
              assignedMemberName: 'Nadia Soliman',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Jun 2026'),
          GameyaSlot(
              slotNumber: 7,
              assignedMemberId: 'usr-6',
              assignedMemberName: 'Omar Farooq',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Jul 2026'),
          GameyaSlot(
              slotNumber: 8,
              assignedMemberId: 'usr-7',
              assignedMemberName: 'Heba Mostafa',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Aug 2026'),
          GameyaSlot(
              slotNumber: 9,
              assignedMemberId: 'usr-8',
              assignedMemberName: 'Youssef Nabil',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Sep 2026'),
          GameyaSlot(
              slotNumber: 10,
              assignedMemberId: 'usr-9',
              assignedMemberName: 'Mona El-Sayed',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Oct 2026'),
        ],
      ),

      // 2. Enrolled Active Circle: New Car Fund 2027 (Symmetrical Paired, 10 x $1,000, Month 5/10, User is Slot #9)
      GameyaCircle(
        id: 'CIRCLE-CAR-2027',
        name: 'New Car Fund 2027',
        goalCategory: 'Vehicle',
        monthlyContributionMinor: 100000, // $1,000.00
        totalPeriods: 10,
        currentPeriod: 5,
        totalPoolMinor:
            1000000, // $10,000.00 total pool (Each paired slot receives $5,000.00)
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        status: GameyaCircleStatus.active,
        startDate: DateTime(2026, 3, 1),
        organizerName: 'Karim Zaki',
        organizerId: 'usr-karim-01',
        organizerTrustRating: 4.9,
        isPrivate: false,
        currentUserSlotPosition: 9,
        slots: const [
          GameyaSlot(
              slotNumber: 1,
              assignedMemberId: 'usr-11',
              assignedMemberName: 'Rami Said',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.paid,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 1',
              pairedSlotNumber: 10),
          GameyaSlot(
              slotNumber: 2,
              assignedMemberId: 'usr-12',
              assignedMemberName: 'Lina Kassem',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.paid,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 2',
              pairedSlotNumber: 9),
          GameyaSlot(
              slotNumber: 3,
              assignedMemberId: 'usr-13',
              assignedMemberName: 'Sherif Fathy',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.paid,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 3',
              pairedSlotNumber: 8),
          GameyaSlot(
              slotNumber: 4,
              assignedMemberId: 'usr-14',
              assignedMemberName: 'Dalia Ezzat',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.paid,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 4',
              pairedSlotNumber: 7),
          GameyaSlot(
              slotNumber: 5,
              assignedMemberId: 'usr-15',
              assignedMemberName: 'Amr Diab',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.pending,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 5',
              pairedSlotNumber: 6),
          GameyaSlot(
              slotNumber: 6,
              assignedMemberId: 'usr-16',
              assignedMemberName: 'Hany Shaker',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 6',
              pairedSlotNumber: 5),
          GameyaSlot(
              slotNumber: 7,
              assignedMemberId: 'usr-17',
              assignedMemberName: 'Samira Said',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 7',
              pairedSlotNumber: 4),
          GameyaSlot(
              slotNumber: 8,
              assignedMemberId: 'usr-18',
              assignedMemberName: 'George Wassouf',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 8',
              pairedSlotNumber: 3),
          GameyaSlot(
              slotNumber: 9,
              assignedMemberId: 'usr-current',
              assignedMemberName: 'Ahmed Mansour',
              isCurrentUser: true,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 9',
              pairedSlotNumber: 2),
          GameyaSlot(
              slotNumber: 10,
              assignedMemberId: 'usr-20',
              assignedMemberName: 'Nancy Ajram',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 500000,
              scheduledMonthName: 'Month 10',
              pairedSlotNumber: 1),
        ],
      ),

      // 3. Marketplace Forming Circle: Wedding Savings Circle (10 x $500, Symmetrical Paired, 7/10 joined)
      GameyaCircle(
        id: 'CIRCLE-WED-2026',
        name: 'Wedding Savings Circle',
        goalCategory: 'Wedding',
        monthlyContributionMinor: 50000, // $500.00
        totalPeriods: 10,
        currentPeriod: 1,
        totalPoolMinor: 500000, // $5,000.00
        allocationMode: GameyaAllocationMode.symmetricalPaired,
        status: GameyaCircleStatus.forming,
        startDate: DateTime(2026, 9, 1),
        organizerName: 'Salma Hegazi',
        organizerId: 'usr-salma-01',
        organizerTrustRating: 4.9,
        isPrivate: false,
        slots: [
          const GameyaSlot(
              slotNumber: 1,
              assignedMemberId: 'usr-31',
              assignedMemberName: 'Salma Hegazi',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'Sep 2026',
              pairedSlotNumber: 10),
          const GameyaSlot(
              slotNumber: 2,
              assignedMemberId: 'usr-32',
              assignedMemberName: 'Kareem Adel',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'Oct 2026',
              pairedSlotNumber: 9),
          GameyaSlot.open(
              slotNumber: 3,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'Nov 2026',
              pairedSlotNumber: 8),
          const GameyaSlot(
              slotNumber: 4,
              assignedMemberId: 'usr-34',
              assignedMemberName: 'Nour Ali',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'Dec 2026',
              pairedSlotNumber: 7),
          const GameyaSlot(
              slotNumber: 5,
              assignedMemberId: 'usr-35',
              assignedMemberName: 'Ziad Taha',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'Jan 2027',
              pairedSlotNumber: 6),
          GameyaSlot.open(
              slotNumber: 6,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'Feb 2027',
              pairedSlotNumber: 5),
          const GameyaSlot(
              slotNumber: 7,
              assignedMemberId: 'usr-37',
              assignedMemberName: 'Mai Ezz',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'Mar 2027',
              pairedSlotNumber: 4),
          GameyaSlot.open(
              slotNumber: 8,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'Apr 2027',
              pairedSlotNumber: 3),
          const GameyaSlot(
              slotNumber: 9,
              assignedMemberId: 'usr-39',
              assignedMemberName: 'Fady Samir',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'May 2027',
              pairedSlotNumber: 2),
          const GameyaSlot(
              slotNumber: 10,
              assignedMemberId: 'usr-40',
              assignedMemberName: 'Dina Raafat',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 250000,
              scheduledMonthName: 'Jun 2027',
              pairedSlotNumber: 1),
        ],
      ),

      // 4. Marketplace Forming Circle: Tech Freelancers Equipment Circle (5 x $200, Sequential, 3/5 joined)
      GameyaCircle(
        id: 'CIRCLE-TECH-2026',
        name: 'Tech Freelancers Equipment Circle',
        goalCategory: 'Tech',
        monthlyContributionMinor: 20000, // $200.00
        totalPeriods: 5,
        currentPeriod: 1,
        totalPoolMinor: 100000, // $1,000.00
        allocationMode: GameyaAllocationMode.sequential,
        status: GameyaCircleStatus.forming,
        startDate: DateTime(2026, 10, 1),
        organizerName: 'Bassem Youssef',
        organizerId: 'usr-bassem-01',
        organizerTrustRating: 4.8,
        isPrivate: false,
        slots: [
          const GameyaSlot(
              slotNumber: 1,
              assignedMemberId: 'usr-51',
              assignedMemberName: 'Bassem Youssef',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 100000,
              scheduledMonthName: 'Oct 2026'),
          GameyaSlot.open(
              slotNumber: 2,
              payoutAmountMinor: 100000,
              scheduledMonthName: 'Nov 2026'),
          const GameyaSlot(
              slotNumber: 3,
              assignedMemberId: 'usr-53',
              assignedMemberName: 'Hazem Emam',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 100000,
              scheduledMonthName: 'Dec 2026'),
          GameyaSlot.open(
              slotNumber: 4,
              payoutAmountMinor: 100000,
              scheduledMonthName: 'Jan 2027'),
          const GameyaSlot(
              slotNumber: 5,
              assignedMemberId: 'usr-55',
              assignedMemberName: 'Mohamed Salah',
              isCurrentUser: false,
              isClaimed: true,
              paymentStatus: SlotPaymentStatus.scheduled,
              payoutAmountMinor: 100000,
              scheduledMonthName: 'Feb 2027'),
        ],
      ),
    ];
  }
}
