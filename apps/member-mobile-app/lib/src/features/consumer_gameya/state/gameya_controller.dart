import 'package:flutter/foundation.dart';
import '../models/gameya_models.dart';
import '../data/gameya_repository.dart';
import '../../../core/network/api_client.dart';

abstract class GameyaState {
  const GameyaState();
}

class GameyaLoading extends GameyaState {
  const GameyaLoading();
}

class GameyaError extends GameyaState {
  final String message;
  final VoidCallback? onRetry;
  const GameyaError(this.message, {this.onRetry});
}

class GameyaEmpty extends GameyaState {
  final String title;
  final String message;
  const GameyaEmpty({required this.title, required this.message});
}

class GameyaOffline extends GameyaState {
  final ConsumerHubSummary cachedSummary;
  const GameyaOffline({required this.cachedSummary});
}

class GameyaLoaded extends GameyaState {
  final ConsumerHubSummary hubSummary;
  final List<GameyaCircle> marketplaceCircles;
  final GameyaCircle? selectedCircleRoom;
  final List<ActivityTimelineItem> activityTimeline;
  final ConsumerProfile profile;
  final String activeFilterTier; // 'ALL', 'TIER_200', 'TIER_500', 'TIER_1000'
  final String? selectedCategoryFilter;
  final int? selectedDurationFilter;
  final String languageCode; // 'en' or 'ar'

  const GameyaLoaded({
    required this.hubSummary,
    required this.marketplaceCircles,
    this.selectedCircleRoom,
    required this.activityTimeline,
    required this.profile,
    this.activeFilterTier = 'ALL',
    this.selectedCategoryFilter,
    this.selectedDurationFilter,
    this.languageCode = 'en',
  });

  bool get isRtl => languageCode == 'ar';

  List<GameyaCircle> get filteredMarketplaceCircles {
    return marketplaceCircles.where((c) {
      // Category filter
      if (selectedCategoryFilter != null && selectedCategoryFilter != 'All') {
        if (c.goalCategory.toLowerCase() !=
            selectedCategoryFilter!.toLowerCase()) {
          return false;
        }
      }
      // Duration filter
      if (selectedDurationFilter != null && selectedDurationFilter! > 0) {
        if (c.totalPeriods != selectedDurationFilter) {
          return false;
        }
      }
      // Contribution Tier filter
      if (activeFilterTier != 'ALL') {
        if (activeFilterTier == 'TIER_200' &&
            c.monthlyContributionMinor > 25000) {
          return false;
        }
        if (activeFilterTier == 'TIER_500' &&
            (c.monthlyContributionMinor < 25000 ||
                c.monthlyContributionMinor > 75000)) {
          return false;
        }
        if (activeFilterTier == 'TIER_1000' &&
            c.monthlyContributionMinor < 75000) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  GameyaLoaded copyWith({
    ConsumerHubSummary? hubSummary,
    List<GameyaCircle>? marketplaceCircles,
    GameyaCircle? selectedCircleRoom,
    List<ActivityTimelineItem>? activityTimeline,
    ConsumerProfile? profile,
    String? activeFilterTier,
    String? selectedCategoryFilter,
    int? selectedDurationFilter,
    String? languageCode,
    bool clearCategoryFilter = false,
    bool clearDurationFilter = false,
    bool clearSelectedCircleRoom = false,
  }) {
    return GameyaLoaded(
      hubSummary: hubSummary ?? this.hubSummary,
      marketplaceCircles: marketplaceCircles ?? this.marketplaceCircles,
      selectedCircleRoom: clearSelectedCircleRoom
          ? null
          : (selectedCircleRoom ?? this.selectedCircleRoom),
      activityTimeline: activityTimeline ?? this.activityTimeline,
      profile: profile ?? this.profile,
      activeFilterTier: activeFilterTier ?? this.activeFilterTier,
      selectedCategoryFilter: clearCategoryFilter
          ? null
          : (selectedCategoryFilter ?? this.selectedCategoryFilter),
      selectedDurationFilter: clearDurationFilter
          ? null
          : (selectedDurationFilter ?? this.selectedDurationFilter),
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

/// Central Controller for the Member-Driven Game'ya Consumer Experience.
class GameyaController extends ValueNotifier<GameyaState> {
  final GameyaRepository repository;
  final String? currentUserId;
  bool _isSafetyLockActive = false;

  bool get isSafetyLockActive => _isSafetyLockActive;

  void setSafetyLockActive(bool active) {
    _isSafetyLockActive = active;
  }

  GameyaController({
    ApiClient? apiClient,
    GameyaRepository? repository,
    this.currentUserId,
    bool isSafetyLockActive = false,
    bool autoLoad = true,
  })  : _isSafetyLockActive = isSafetyLockActive,
        repository = repository ?? GameyaRepository(apiClient: apiClient),
        super(_buildInitialSynchronousState(
            repository ?? GameyaRepository(apiClient: apiClient),
            currentUserId)) {
    if (autoLoad) {
      Future.microtask(() => loadInitialData());
    }
  }

  static GameyaLoaded _buildInitialSynchronousState(GameyaRepository repo,
      [String? currentUserId]) {
    final profile = ConsumerProfile(
      id: currentUserId ?? 'usr-current',
      fullName: 'Ahmed Mansour',
      email: 'ahmed.mansour@gameya.eg',
      phone: '+20 100 555 0192',
      isIdentityVerified: true,
      bankAccountName: 'Chase Premier Checking',
      bankAccountMasked: '**** 8812',
      trustScore: 5.0,
      completedCirclesCount: 4,
      activeCirclesCount: 2,
    );

    // Initial summary
    return GameyaLoaded(
      hubSummary: ConsumerHubSummary(
        memberName: profile.fullName,
        activeCircles: [
          // 1. Family Savings 2026
          GameyaCircle(
            id: 'CIRCLE-FAM-2026',
            name: 'Family Savings 2026',
            goalCategory: 'Family',
            monthlyContributionMinor: 50000,
            totalPeriods: 10,
            currentPeriod: 2,
            totalPoolMinor: 500000,
            allocationMode: GameyaAllocationMode.sequential,
            status: GameyaCircleStatus.active,
            startDate: DateTime(2026, 1, 1),
            organizerName: 'Tariq Mansour',
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
          // 2. New Car Fund 2027
          GameyaCircle(
            id: 'CIRCLE-CAR-2027',
            name: 'New Car Fund 2027',
            goalCategory: 'Vehicle',
            monthlyContributionMinor: 100000,
            totalPeriods: 10,
            currentPeriod: 5,
            totalPoolMinor: 1000000,
            allocationMode: GameyaAllocationMode.symmetricalPaired,
            status: GameyaCircleStatus.active,
            startDate: DateTime(2026, 3, 1),
            organizerName: 'Karim Zaki',
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
        ],
        totalMonthlyDuesMinor: 150000,
        nextPaymentDueDate: DateTime.now().add(const Duration(days: 5)),
        nextPaymentDueCircleName: 'Family Savings 2026',
        nextPaymentDueAmountMinor: 50000,
        nextPayoutAmountMinor: 500000,
        nextPayoutDate: DateTime.now().add(const Duration(days: 34)),
        nextPayoutCircleName: 'Family Savings 2026',
      ),
      marketplaceCircles: [
        // 3. Wedding Savings Circle
        GameyaCircle(
          id: 'CIRCLE-WED-2026',
          name: 'Wedding Savings Circle',
          goalCategory: 'Wedding',
          monthlyContributionMinor: 50000,
          totalPeriods: 10,
          currentPeriod: 1,
          totalPoolMinor: 500000,
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          status: GameyaCircleStatus.forming,
          startDate: DateTime(2026, 9, 1),
          organizerName: 'Salma Hegazi',
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
        // 4. Tech Freelancers Equipment Circle
        GameyaCircle(
          id: 'CIRCLE-TECH-2026',
          name: 'Tech Freelancers Equipment Circle',
          goalCategory: 'Tech',
          monthlyContributionMinor: 20000,
          totalPeriods: 5,
          currentPeriod: 1,
          totalPoolMinor: 100000,
          allocationMode: GameyaAllocationMode.sequential,
          status: GameyaCircleStatus.forming,
          startDate: DateTime(2026, 10, 1),
          organizerName: 'Bassem Youssef',
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
      ],
      activityTimeline: [
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
      ],
      profile: profile,
    );
  }

  Future<void> loadInitialData({bool simulateNetworkDelay = false}) async {
    if (simulateNetworkDelay) {
      value = const GameyaLoading();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      final circles = await repository.fetchAllCircles();
      final enrolledCircles = circles.where((c) => c.isUserEnrolled).toList();
      final formingCircles =
          circles.where((c) => c.status == GameyaCircleStatus.forming).toList();
      final timeline = await repository.fetchActivityTimeline();
      final profile = await repository.fetchConsumerProfile();

      int totalMonthlyDues = 0;
      for (final c in enrolledCircles) {
        totalMonthlyDues += c.monthlyContributionMinor;
      }

      final hubSummary = ConsumerHubSummary(
        memberName: profile.fullName,
        activeCircles: enrolledCircles,
        totalMonthlyDuesMinor: totalMonthlyDues,
        nextPaymentDueDate: DateTime.now().add(const Duration(days: 5)),
        nextPaymentDueCircleName:
            enrolledCircles.isNotEmpty ? enrolledCircles.first.name : null,
        nextPaymentDueAmountMinor: enrolledCircles.isNotEmpty
            ? enrolledCircles.first.monthlyContributionMinor
            : 0,
        nextPayoutAmountMinor: 500000,
        nextPayoutDate: DateTime.now().add(const Duration(days: 34)),
        nextPayoutCircleName: 'Family Savings 2026',
      );

      value = GameyaLoaded(
        hubSummary: hubSummary,
        marketplaceCircles: formingCircles,
        selectedCircleRoom:
            enrolledCircles.isNotEmpty ? enrolledCircles.first : null,
        activityTimeline: timeline,
        profile: profile,
      );
    } catch (e) {
      value = GameyaError('Failed to load Game\'ya data: $e',
          onRetry: loadInitialData);
    }
  }

  void selectCircleRoom(String circleId) {
    if (value is! GameyaLoaded) return;
    final state = value as GameyaLoaded;
    final allCircles = [
      ...state.hubSummary.activeCircles,
      ...state.marketplaceCircles
    ];
    final matches = allCircles.where((c) => c.id == circleId);
    final found = matches.isNotEmpty ? matches.first : null;
    value = state.copyWith(
      selectedCircleRoom: found,
      clearSelectedCircleRoom: found == null,
    );
  }

  void setMarketplaceFilter(String tier) {
    if (value is! GameyaLoaded) return;
    final state = value as GameyaLoaded;
    value = state.copyWith(activeFilterTier: tier);
  }

  void setCategoryFilter(String? category) {
    if (value is! GameyaLoaded) return;
    final state = value as GameyaLoaded;
    if (category == null || category == 'All') {
      value = state.copyWith(clearCategoryFilter: true);
    } else {
      value = state.copyWith(selectedCategoryFilter: category);
    }
  }

  void setDurationFilter(int? durationMonths) {
    if (value is! GameyaLoaded) return;
    final state = value as GameyaLoaded;
    if (durationMonths == null || durationMonths == 0) {
      value = state.copyWith(clearDurationFilter: true);
    } else {
      value = state.copyWith(selectedDurationFilter: durationMonths);
    }
  }

  void toggleLanguage(String languageCode) {
    if (value is! GameyaLoaded) return;
    final state = value as GameyaLoaded;
    value = state.copyWith(
      languageCode: languageCode,
      profile: state.profile.copyWith(languageCode: languageCode),
    );
  }

  Future<bool> joinCircleWithSlot(
      {required String circleId, required int slotNumber}) async {
    if (value is! GameyaLoaded) return false;
    final state = value as GameyaLoaded;

    // 1. Authoritative Identity Resolution & Mismatch Protection
    final memberId = currentUserId ??
        (state.profile.id.isNotEmpty ? state.profile.id : null);
    if (memberId == null || memberId.isEmpty) {
      return false; // Fail closed if no authoritative identity
    }
    if (currentUserId != null &&
        state.profile.id.isNotEmpty &&
        state.profile.id != 'usr-current' &&
        state.profile.id != currentUserId) {
      return false; // Identity mismatch protection
    }

    final allAvailable = [
      ...state.marketplaceCircles,
      ...state.hubSummary.activeCircles
    ];
    final match = allAvailable.where((c) => c.id == circleId);
    if (match.isEmpty) return false;
    final targetCircle = match.first;

    // Check if user is already enrolled in this circle in another slot
    if (targetCircle.isUserEnrolled &&
        targetCircle.currentUserSlotPosition != slotNumber) {
      return false;
    }

    // Check if circle is active/locked against new joiners
    if (targetCircle.status == GameyaCircleStatus.active &&
        targetCircle.isFull) {
      return false; // Circle locked
    }

    // Check if requested slot is already claimed by someone else (Concurrency race protection)
    final slotMatch =
        targetCircle.slots.where((s) => s.slotNumber == slotNumber);
    if (slotMatch.isEmpty) return false;
    final targetSlot = slotMatch.first;
    if (targetSlot.isClaimed) {
      return false; // Slot already taken
    }

    // 2. Authoritative Persistence Gate (fail closed on failure or network error)
    try {
      final success = await repository.joinCircleSlot(
          circleId: circleId, slotNumber: slotNumber);
      if (!success) {
        return false;
      }
    } catch (_) {
      return false; // Fail closed on network error or persistence rejection
    }

    // 3. Update the slot to claimed by current user
    final updatedSlots = targetCircle.slots.map((s) {
      if (s.slotNumber == slotNumber) {
        return s.copyWith(
          assignedMemberId: memberId,
          assignedMemberName: state.profile.fullName,
          isCurrentUser: true,
          isClaimed: true,
          paymentStatus: SlotPaymentStatus.scheduled,
        );
      }
      return s;
    }).toList();

    final enrolledCircle = targetCircle.copyWith(
      currentUserSlotPosition: slotNumber,
      status: GameyaCircleStatus.active,
      slots: updatedSlots,
    );

    final updatedActiveCircles = [
      ...state.hubSummary.activeCircles.where((c) => c.id != circleId),
      enrolledCircle,
    ];
    final updatedMarketplace =
        state.marketplaceCircles.where((c) => c.id != circleId).toList();

    int newTotalDues = 0;
    for (final c in updatedActiveCircles) {
      newTotalDues += c.monthlyContributionMinor;
    }

    final newSummary = ConsumerHubSummary(
      memberName: state.hubSummary.memberName,
      activeCircles: updatedActiveCircles,
      totalMonthlyDuesMinor: newTotalDues,
      nextPaymentDueDate: state.hubSummary.nextPaymentDueDate,
      nextPaymentDueCircleName: enrolledCircle.name,
      nextPaymentDueAmountMinor: enrolledCircle.monthlyContributionMinor,
      nextPayoutAmountMinor: enrolledCircle.payoutAmountForSlotInPeriod(
          slotNumber, enrolledCircle.primaryPayoutPeriodFor(slotNumber)),
      nextPayoutDate: DateTime.now().add(Duration(days: slotNumber * 30)),
      nextPayoutCircleName: enrolledCircle.name,
    );

    final newTimelineItem = ActivityTimelineItem(
      id: 'ACT-${DateTime.now().millisecondsSinceEpoch}',
      eventType: ActivityEventType.circleJoined,
      circleId: enrolledCircle.id,
      circleName: enrolledCircle.name,
      title: 'Joined ${enrolledCircle.name}',
      description:
          'Claimed Slot #$slotNumber (${enrolledCircle.slots[slotNumber - 1].scheduledMonthName}). Monthly commitment: \$${(enrolledCircle.monthlyContributionMinor / 100).toStringAsFixed(0)}.',
      timestamp: DateTime.now(),
      isDebit: false,
    );

    value = state.copyWith(
      hubSummary: newSummary,
      marketplaceCircles: updatedMarketplace,
      selectedCircleRoom: enrolledCircle,
      activityTimeline: [newTimelineItem, ...state.activityTimeline],
    );

    return true;
  }

  Future<GameyaCircle> createNewGameya(CreateGameyaDraft draft) async {
    final created = await repository.createNewCircle(draft);

    if (value is GameyaLoaded) {
      final state = value as GameyaLoaded;
      final updatedMarketplace = [created, ...state.marketplaceCircles];

      final newTimelineItem = ActivityTimelineItem(
        id: 'ACT-${DateTime.now().millisecondsSinceEpoch}',
        eventType: ActivityEventType.circleActivated,
        circleId: created.id,
        circleName: created.name,
        title: 'Created ${created.name}',
        description:
            'New circle formed with \$${(created.totalPoolMinor / 100).toStringAsFixed(0)} total pool. Invite code: ${created.inviteCode}',
        timestamp: DateTime.now(),
        isDebit: false,
      );

      value = state.copyWith(
        marketplaceCircles: updatedMarketplace,
        activityTimeline: [newTimelineItem, ...state.activityTimeline],
      );
    }

    return created;
  }

  Future<bool> submitContributionPayment({
    required String circleId,
    required int amountMinor,
    String? idempotencyKey,
    bool? isSafetyLockActive,
  }) async {
    // 1. Financial Safety Lock Guard (Rejection before any mutation or timeline creation)
    if (_isSafetyLockActive || (isSafetyLockActive ?? false)) {
      return false;
    }

    if (value is! GameyaLoaded) return false;
    final state = value as GameyaLoaded;

    // Identity Mismatch Guard
    if (currentUserId != null &&
        state.profile.id.isNotEmpty &&
        state.profile.id != 'usr-current' &&
        state.profile.id != currentUserId) {
      return false; // Mismatched profile ID cannot contribute
    }

    // Deduplication / Idempotency Key check
    if (idempotencyKey != null &&
        state.activityTimeline.any((t) => t.id == idempotencyKey)) {
      return true; // Already processed idempotently
    }

    final matching =
        state.hubSummary.activeCircles.where((c) => c.id == circleId);
    if (matching.isEmpty) return false;
    final targetCircle = matching.first;

    if (!targetCircle.isUserEnrolled) return false;
    if (amountMinor <= 0) return false;

    final updatedSlots = targetCircle.slots.map((s) {
      if (s.isCurrentUser) {
        return s.copyWith(paymentStatus: SlotPaymentStatus.paid);
      }
      return s;
    }).toList();

    final updatedCircle = targetCircle.copyWith(slots: updatedSlots);
    final updatedActive = state.hubSummary.activeCircles
        .map((c) => c.id == circleId ? updatedCircle : c)
        .toList();

    final newTimelineItem = ActivityTimelineItem(
      id: idempotencyKey ?? 'ACT-${DateTime.now().microsecondsSinceEpoch}',
      eventType: ActivityEventType.contributionPaid,
      circleId: circleId,
      circleName: targetCircle.name,
      title: 'Contribution Paid for ${targetCircle.name}',
      description:
          'Month ${targetCircle.currentPeriod} contribution of \$${(amountMinor / 100).toStringAsFixed(0)} settled.',
      amountMinor: amountMinor,
      timestamp: DateTime.now(),
      isDebit: true,
    );

    value = state.copyWith(
      hubSummary: ConsumerHubSummary(
        memberName: state.hubSummary.memberName,
        activeCircles: updatedActive,
        totalMonthlyDuesMinor: state.hubSummary.totalMonthlyDuesMinor,
        nextPaymentDueDate: DateTime.now().add(const Duration(days: 30)),
        nextPaymentDueCircleName: targetCircle.name,
        nextPayoutAmountMinor: state.hubSummary.nextPayoutAmountMinor,
        nextPayoutDate: state.hubSummary.nextPayoutDate,
        nextPayoutCircleName: state.hubSummary.nextPayoutCircleName,
      ),
      selectedCircleRoom: updatedCircle,
      activityTimeline: [newTimelineItem, ...state.activityTimeline],
    );

    return true;
  }

  Future<bool> claimPayoutDisbursement({
    required String circleId,
    required int amountMinor,
    required String destinationAccount,
    String? claimingMemberId,
    bool? isSafetyLockActive,
  }) async {
    // 1. Financial Safety Lock Guard (Rejection before any mutation or timeline creation)
    if (_isSafetyLockActive || (isSafetyLockActive ?? false)) {
      return false;
    }

    if (value is! GameyaLoaded) return false;
    final state = value as GameyaLoaded;
    final resolvedMemberId =
        claimingMemberId ?? currentUserId ?? state.profile.id;
    if (resolvedMemberId.isEmpty) return false;

    // Identity Mismatch Guard
    if (currentUserId != null &&
        state.profile.id.isNotEmpty &&
        state.profile.id != 'usr-current' &&
        state.profile.id != currentUserId) {
      return false; // Mismatched profile ID cannot claim payout
    }
    if (currentUserId != null &&
        claimingMemberId != null &&
        claimingMemberId != currentUserId) {
      return false; // Claiming member ID cannot mismatch authenticated UID
    }

    final matching =
        state.hubSummary.activeCircles.where((c) => c.id == circleId);
    if (matching.isEmpty) return false;
    final targetCircle = matching.first;

    // Guardrail: must be enrolled in this circle
    if (!targetCircle.isUserEnrolled) {
      return false;
    }

    // Guardrail: must be user's scheduled payout turn
    if (!targetCircle.isPayoutDueForUserInPeriod(targetCircle.currentPeriod)) {
      return false;
    }

    // Guardrail: non-empty destination account
    if (destinationAccount.trim().isEmpty) {
      return false;
    }

    final newTimelineItem = ActivityTimelineItem(
      id: 'ACT-${DateTime.now().microsecondsSinceEpoch}',
      eventType: ActivityEventType.payoutReceived,
      circleId: circleId,
      circleName: targetCircle.name,
      title: 'Payout Disbursed for ${targetCircle.name}',
      description:
          'Disbursed \$${(amountMinor / 100).toStringAsFixed(0)} to $destinationAccount.',
      amountMinor: amountMinor,
      timestamp: DateTime.now(),
      isDebit: false,
    );

    value = state.copyWith(
      activityTimeline: [newTimelineItem, ...state.activityTimeline],
    );

    return true;
  }

  Future<bool> sendOrganizerReminder(
      {required String circleId, required int slotNumber}) async {
    if (value is! GameyaLoaded) return false;
    final state = value as GameyaLoaded;

    final matching =
        state.hubSummary.activeCircles.where((c) => c.id == circleId);
    final targetCircle = state.selectedCircleRoom?.id == circleId
        ? state.selectedCircleRoom!
        : (matching.isNotEmpty ? matching.first : null);
    if (targetCircle == null) return false;

    final newTimelineItem = ActivityTimelineItem(
      id: 'ACT-${DateTime.now().microsecondsSinceEpoch}',
      eventType: ActivityEventType.reminderSent,
      circleId: circleId,
      circleName: targetCircle.name,
      title: 'Reminder Sent to Slot #$slotNumber',
      description:
          'Gentle payment reminder sent to member in ${targetCircle.name}.',
      timestamp: DateTime.now(),
      isDebit: false,
    );

    value = state.copyWith(
      activityTimeline: [newTimelineItem, ...state.activityTimeline],
    );

    return true;
  }
}
