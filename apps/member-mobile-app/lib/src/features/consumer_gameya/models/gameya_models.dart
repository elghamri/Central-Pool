import 'package:flutter/foundation.dart';

/// Allocation & Rotation mode for a Game'ya circle.
enum GameyaAllocationMode {
  sequential,
  symmetricalPaired;

  String get displayName {
    switch (this) {
      case GameyaAllocationMode.sequential:
        return 'Sequential Rotation';
      case GameyaAllocationMode.symmetricalPaired:
        return 'Symmetrical Paired Allocation';
    }
  }

  String get shortName {
    switch (this) {
      case GameyaAllocationMode.sequential:
        return 'Sequential';
      case GameyaAllocationMode.symmetricalPaired:
        return 'Paired';
    }
  }
}

/// Lifecycle status of a Game'ya circle.
enum GameyaCircleStatus {
  forming,
  ready,
  active,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case GameyaCircleStatus.forming:
        return 'Forming (Open Slots)';
      case GameyaCircleStatus.ready:
        return 'Ready to Start';
      case GameyaCircleStatus.active:
        return 'Active Circle';
      case GameyaCircleStatus.completed:
        return 'Completed Circle';
      case GameyaCircleStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Individual member payment status for a specific period.
enum SlotPaymentStatus {
  paid,
  pending,
  gracePeriod,
  scheduled;

  String get label {
    switch (this) {
      case SlotPaymentStatus.paid:
        return 'Paid ✓';
      case SlotPaymentStatus.pending:
        return 'Pending ⏳';
      case SlotPaymentStatus.gracePeriod:
        return 'Grace Period ⚠';
      case SlotPaymentStatus.scheduled:
        return 'Scheduled';
    }
  }
}

/// Economic position status of a member in a Game'ya.
enum EconomicPositionType {
  accumulatingSavings,
  repayingAdvancePayout;

  String get title {
    switch (this) {
      case EconomicPositionType.accumulatingSavings:
        return 'Accumulating Savings';
      case EconomicPositionType.repayingAdvancePayout:
        return 'Repaying Advance Payout';
    }
  }

  String get description {
    switch (this) {
      case EconomicPositionType.accumulatingSavings:
        return 'You are building your monthly savings toward your upcoming scheduled payout.';
      case EconomicPositionType.repayingAdvancePayout:
        return 'You received your pooled payout early and are completing your remaining monthly contributions.';
    }
  }
}

/// Individual slot representation in a Game'ya rotation.
@immutable
class GameyaSlot {
  final int slotNumber; // 1..N
  final String? assignedMemberId;
  final String? assignedMemberName;
  final bool isCurrentUser;
  final bool isClaimed;
  final SlotPaymentStatus paymentStatus;
  final int payoutAmountMinor;
  final String scheduledMonthName;
  final int? pairedSlotNumber; // For Symmetrical Paired mode

  const GameyaSlot({
    required this.slotNumber,
    this.assignedMemberId,
    this.assignedMemberName,
    this.isCurrentUser = false,
    this.isClaimed = true,
    this.paymentStatus = SlotPaymentStatus.scheduled,
    required this.payoutAmountMinor,
    required this.scheduledMonthName,
    this.pairedSlotNumber,
  });

  factory GameyaSlot.open({
    required int slotNumber,
    required int payoutAmountMinor,
    required String scheduledMonthName,
    int? pairedSlotNumber,
  }) {
    return GameyaSlot(
      slotNumber: slotNumber,
      isClaimed: false,
      isCurrentUser: false,
      paymentStatus: SlotPaymentStatus.scheduled,
      payoutAmountMinor: payoutAmountMinor,
      scheduledMonthName: scheduledMonthName,
      pairedSlotNumber: pairedSlotNumber,
    );
  }

  GameyaSlot copyWith({
    String? assignedMemberId,
    String? assignedMemberName,
    bool? isCurrentUser,
    bool? isClaimed,
    SlotPaymentStatus? paymentStatus,
  }) {
    return GameyaSlot(
      slotNumber: slotNumber,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
      assignedMemberName: assignedMemberName ?? this.assignedMemberName,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      isClaimed: isClaimed ?? this.isClaimed,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      payoutAmountMinor: payoutAmountMinor,
      scheduledMonthName: scheduledMonthName,
      pairedSlotNumber: pairedSlotNumber,
    );
  }
}

/// Full autonomous Game'ya Circle entity.
@immutable
class GameyaCircle {
  final String id;
  final String name;
  final String goalCategory; // e.g. "Family", "Vehicle", "Wedding", "Education", "Home", "Tech"
  final int monthlyContributionMinor; // in 64-bit integer cents (e.g. 50000 = $500.00)
  final int totalPeriods; // N (e.g. 10)
  final int currentPeriod; // 1..N
  final int totalPoolMinor; // N x monthlyContributionMinor (e.g. 500000 = $5,000.00)
  final GameyaAllocationMode allocationMode;
  final GameyaCircleStatus status;
  final DateTime startDate;
  final String organizerName;
  final String organizerId;
  final double organizerTrustRating; // 1.0..5.0
  final bool isPrivate;
  final String? inviteCode;
  final int? currentUserSlotPosition; // 1..N if enrolled
  final List<GameyaSlot> slots;
  final List<String> rulesSummary;

  GameyaCircle({
    required this.id,
    required this.name,
    required this.goalCategory,
    required this.monthlyContributionMinor,
    required this.totalPeriods,
    this.currentPeriod = 1,
    required this.totalPoolMinor,
    this.allocationMode = GameyaAllocationMode.sequential,
    this.status = GameyaCircleStatus.forming,
    required this.startDate,
    required this.organizerName,
    this.organizerId = 'usr-org-01',
    this.organizerTrustRating = 5.0,
    this.isPrivate = false,
    this.inviteCode,
    this.currentUserSlotPosition,
    List<GameyaSlot>? slots,
    this.rulesSummary = const [
      'Zero-interest autonomous circle under standard Game\'ya bylaws.',
      'Monthly contributions are due on the 1st of each calendar month.',
      'Payout disbursements are settled immediately upon pool completion.',
      '3-day grace period applies before circle delinquency protection engages.',
    ],
  }) : slots = (slots != null && slots.isNotEmpty)
            ? slots
            : _generateDefaultSlots(totalPeriods, totalPoolMinor, allocationMode);

  static List<GameyaSlot> _generateDefaultSlots(
    int totalPeriods,
    int totalPoolMinor,
    GameyaAllocationMode allocationMode,
  ) {
    final isPaired = allocationMode == GameyaAllocationMode.symmetricalPaired;
    final isOdd = totalPeriods.isOdd;
    final midMonth = (totalPeriods + 1) ~/ 2;

    return List.generate(totalPeriods, (i) {
      final slotNum = i + 1;
      final isMidSlot = isPaired && isOdd && slotNum == midMonth;

      return GameyaSlot(
        slotNumber: slotNum,
        payoutAmountMinor: (isPaired && !isMidSlot) ? (totalPoolMinor ~/ 2) : totalPoolMinor,
        scheduledMonthName: 'Month $slotNum',
        pairedSlotNumber: isPaired ? (isMidSlot ? null : (totalPeriods + 1 - slotNum)) : null,
      );
    });
  }

  bool get isUserEnrolled => currentUserSlotPosition != null;

  /// Validates organizer authority against the authenticated user ID.
  /// In production, requires exact match with the authenticated session UID.
  bool isOrganizer(String? authenticatedUserId) {
    if (authenticatedUserId != null && authenticatedUserId.isNotEmpty) {
      return organizerId == authenticatedUserId;
    }
    // Fallback only for standalone development mocks
    return organizerId == 'usr-current' || organizerId == 'usr-current-mansour';
  }

  bool get isOrganizerCurrentUser => isOrganizer(null);

  int get claimedSlotsCount => slots.where((s) => s.isClaimed).length;
  int get openSlotsCount => totalPeriods - claimedSlotsCount;
  bool get isFull => claimedSlotsCount >= totalPeriods;

  double get progressFraction => totalPeriods > 0 ? (currentPeriod / totalPeriods).clamp(0.0, 1.0) : 0.0;

  /// Symmetrical pair mapping helpers
  int primaryPayoutPeriodFor(int slotNumber) {
    if (allocationMode == GameyaAllocationMode.sequential) return slotNumber;
    if (totalPeriods.isOdd && slotNumber == (totalPeriods + 1) ~/ 2) {
      return slotNumber;
    }
    return slotNumber <= (totalPeriods ~/ 2) ? slotNumber : (totalPeriods + 1 - slotNumber);
  }

  int mirrorPayoutPeriodFor(int slotNumber) {
    if (allocationMode == GameyaAllocationMode.sequential) return slotNumber;
    if (totalPeriods.isOdd && slotNumber == (totalPeriods + 1) ~/ 2) {
      return slotNumber;
    }
    return totalPeriods + 1 - primaryPayoutPeriodFor(slotNumber);
  }

  bool isFirstHalfPayout(int slotNumber, int period) {
    if (allocationMode != GameyaAllocationMode.symmetricalPaired) return false;
    if (totalPeriods.isOdd && slotNumber == (totalPeriods + 1) ~/ 2) return false;
    return period == primaryPayoutPeriodFor(slotNumber);
  }

  bool isFinalHalfPayout(int slotNumber, int period) {
    if (allocationMode != GameyaAllocationMode.symmetricalPaired) return false;
    if (totalPeriods.isOdd && slotNumber == (totalPeriods + 1) ~/ 2) return false;
    return period == mirrorPayoutPeriodFor(slotNumber);
  }

  String userPayoutStageLabel(int period) {
    if (currentUserSlotPosition == null) return '';
    if (allocationMode == GameyaAllocationMode.sequential) {
      return 'Full Circle Payout';
    }
    if (totalPeriods.isOdd && currentUserSlotPosition == (totalPeriods + 1) ~/ 2) {
      return 'Middle Month Full Payout (100%)';
    }
    if (isFirstHalfPayout(currentUserSlotPosition!, period)) {
      return 'First half of your payout';
    } else if (isFinalHalfPayout(currentUserSlotPosition!, period)) {
      return 'Final half of your payout';
    }
    return 'Scheduled Paired Payout';
  }

  bool isPayoutDueForSlotInPeriod(int slotNumber, int period) {
    if (allocationMode == GameyaAllocationMode.sequential) {
      return slotNumber == period;
    }
    if (totalPeriods.isOdd && slotNumber == (totalPeriods + 1) ~/ 2) {
      return slotNumber == period;
    }
    final p1 = primaryPayoutPeriodFor(slotNumber);
    final p2 = mirrorPayoutPeriodFor(slotNumber);
    return period == p1 || period == p2;
  }

  bool isPayoutDueForUserInPeriod(int period) {
    if (currentUserSlotPosition == null) return false;
    return isPayoutDueForSlotInPeriod(currentUserSlotPosition!, period);
  }

  int payoutAmountForSlotInPeriod(int slotNumber, int period) {
    final matchingSlot = slots.where((s) => s.slotNumber == slotNumber);
    if (matchingSlot.isNotEmpty) {
      return matchingSlot.first.payoutAmountMinor;
    }
    // Fail-closed: missing slot produces 0 entitlement, never fabricating a payout or returning an unrelated slot
    return 0;
  }

  int userPayoutAmountForPeriod(int period) {
    if (currentUserSlotPosition == null) return 0;
    return payoutAmountForSlotInPeriod(currentUserSlotPosition!, period);
  }

  int userPayoutsReceivedMinor(int period) {
    if (currentUserSlotPosition == null) return 0;
    final matchingSlots = slots.where((s) => s.slotNumber == currentUserSlotPosition!);
    if (matchingSlots.isEmpty) return 0;
    final userSlot = matchingSlots.first;
    if (allocationMode == GameyaAllocationMode.sequential || userSlot.pairedSlotNumber == null) {
      return period >= currentUserSlotPosition! ? userSlot.payoutAmountMinor : 0;
    }
    final p1 = primaryPayoutPeriodFor(currentUserSlotPosition!);
    final p2 = mirrorPayoutPeriodFor(currentUserSlotPosition!);
    if (period >= p2) {
      return userSlot.payoutAmountMinor * 2;
    } else if (period >= p1) {
      return userSlot.payoutAmountMinor;
    }
    return 0;
  }

  int get userRemainingPayoutsToReceiveMinor {
    if (currentUserSlotPosition == null) return 0;
    final matchingSlots = slots.where((s) => s.slotNumber == currentUserSlotPosition!);
    if (matchingSlots.isEmpty) return 0;
    final userSlot = matchingSlots.first;
    final totalEntitlement = (allocationMode == GameyaAllocationMode.symmetricalPaired && userSlot.pairedSlotNumber != null)
        ? userSlot.payoutAmountMinor * 2
        : userSlot.payoutAmountMinor;
    final received = userPayoutsReceivedMinor(currentPeriod);
    return (totalEntitlement - received).clamp(0, totalEntitlement);
  }

  int userContributionsPaidMinor(int period) {
    return period.clamp(0, totalPeriods) * monthlyContributionMinor;
  }

  /// Calculates the paired slot numbers that receive disbursements in a given period.
  List<int> activePayoutSlotsForPeriod(int period) {
    if (allocationMode == GameyaAllocationMode.sequential) {
      return [period];
    }
    if (totalPeriods.isOdd && period == (totalPeriods + 1) ~/ 2) {
      return [period];
    }
    final p1 = period <= (totalPeriods ~/ 2) ? period : (totalPeriods + 1 - period);
    final p2 = totalPeriods + 1 - p1;
    return [p1, p2];
  }

  /// Economic state calculation for current user based on actual cash flow:
  /// (Payouts Received vs Contributions Paid).
  EconomicPositionType? get currentUserEconomicPosition {
    if (currentUserSlotPosition == null) return null;
    final payoutsReceived = userPayoutsReceivedMinor(currentPeriod);
    final contributionsPaid = userContributionsPaidMinor(currentPeriod);
    if (payoutsReceived > contributionsPaid) {
      return EconomicPositionType.repayingAdvancePayout;
    } else {
      return EconomicPositionType.accumulatingSavings;
    }
  }

  /// Calculates remaining monthly contributions for the enrolled user.
  int get userRemainingContributionsCount {
    if (currentUserSlotPosition == null) return totalPeriods;
    return (totalPeriods - currentPeriod).clamp(0, totalPeriods);
  }

  int get userRemainingObligationMinor {
    return userRemainingContributionsCount * monthlyContributionMinor;
  }

  GameyaCircle copyWith({
    String? name,
    GameyaCircleStatus? status,
    int? currentPeriod,
    int? currentUserSlotPosition,
    List<GameyaSlot>? slots,
  }) {
    return GameyaCircle(
      id: id,
      name: name ?? this.name,
      goalCategory: goalCategory,
      monthlyContributionMinor: monthlyContributionMinor,
      totalPeriods: totalPeriods,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      totalPoolMinor: totalPoolMinor,
      allocationMode: allocationMode,
      status: status ?? this.status,
      startDate: startDate,
      organizerName: organizerName,
      organizerId: organizerId,
      organizerTrustRating: organizerTrustRating,
      isPrivate: isPrivate,
      inviteCode: inviteCode,
      currentUserSlotPosition: currentUserSlotPosition ?? this.currentUserSlotPosition,
      slots: slots ?? this.slots,
      rulesSummary: rulesSummary,
    );
  }
}

/// Aggregated multi-circle summary for Member Home.
@immutable
class ConsumerHubSummary {
  final String memberName;
  final List<GameyaCircle> activeCircles;
  final int totalMonthlyDuesMinor; // Consolidated monthly obligation across all active circles
  final DateTime? nextPaymentDueDate;
  final String? nextPaymentDueCircleName;
  final int nextPaymentDueAmountMinor;
  final int nextPayoutAmountMinor;
  final DateTime? nextPayoutDate;
  final String? nextPayoutCircleName;

  const ConsumerHubSummary({
    required this.memberName,
    required this.activeCircles,
    required this.totalMonthlyDuesMinor,
    this.nextPaymentDueDate,
    this.nextPaymentDueCircleName,
    this.nextPaymentDueAmountMinor = 0,
    this.nextPayoutAmountMinor = 0,
    this.nextPayoutDate,
    this.nextPayoutCircleName,
  });
}

/// Types of timeline activity items for consumer financial history.
enum ActivityEventType {
  contributionPaid,
  contributionDue,
  payoutReceived,
  payoutScheduled,
  circleJoined,
  circleActivated,
  circleCompleted,
  memberJoined,
  reminderSent;

  String get displayName {
    switch (this) {
      case ActivityEventType.contributionPaid:
        return 'Contribution Settled';
      case ActivityEventType.contributionDue:
        return 'Contribution Due';
      case ActivityEventType.payoutReceived:
        return 'Payout Disbursed';
      case ActivityEventType.payoutScheduled:
        return 'Payout Scheduled';
      case ActivityEventType.circleJoined:
        return 'Joined Circle';
      case ActivityEventType.circleActivated:
        return 'Circle Activated';
      case ActivityEventType.circleCompleted:
        return 'Circle Completed';
      case ActivityEventType.memberJoined:
        return 'Member Joined';
      case ActivityEventType.reminderSent:
        return 'Payment Reminder';
    }
  }
}

/// Timeline item in the unified personal financial activity log.
@immutable
class ActivityTimelineItem {
  final String id;
  final ActivityEventType eventType;
  final String circleId;
  final String circleName;
  final String title;
  final String description;
  final int? amountMinor;
  final DateTime timestamp;
  final bool isDebit; // true for payments made, false for payouts received

  const ActivityTimelineItem({
    required this.id,
    required this.eventType,
    required this.circleId,
    required this.circleName,
    required this.title,
    required this.description,
    this.amountMinor,
    required this.timestamp,
    this.isDebit = true,
  });
}

/// Consumer Profile & Verified Identity information.
@immutable
class ConsumerProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final bool isIdentityVerified;
  final String bankAccountName;
  final String bankAccountMasked;
  final double trustScore; // 1.0..5.0
  final int completedCirclesCount;
  final int activeCirclesCount;
  final String languageCode; // 'en' or 'ar'
  final bool pushNotificationsEnabled;
  final bool smsAlertsEnabled;

  const ConsumerProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.isIdentityVerified = true,
    required this.bankAccountName,
    required this.bankAccountMasked,
    this.trustScore = 5.0,
    this.completedCirclesCount = 4,
    this.activeCirclesCount = 2,
    this.languageCode = 'en',
    this.pushNotificationsEnabled = true,
    this.smsAlertsEnabled = true,
  });

  ConsumerProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    bool? isIdentityVerified,
    String? bankAccountName,
    String? bankAccountMasked,
    String? languageCode,
    bool? pushNotificationsEnabled,
    bool? smsAlertsEnabled,
  }) {
    return ConsumerProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountMasked: bankAccountMasked ?? this.bankAccountMasked,
      trustScore: trustScore,
      completedCirclesCount: completedCirclesCount,
      activeCirclesCount: activeCirclesCount,
      languageCode: languageCode ?? this.languageCode,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      smsAlertsEnabled: smsAlertsEnabled ?? this.smsAlertsEnabled,
    );
  }
}

/// Draft data model for the 9-step Create Game'ya Wizard.
@immutable
class CreateGameyaDraft {
  final String name;
  final String goalCategory;
  final int monthlyContributionMinor;
  final int totalPeriods;
  final GameyaAllocationMode allocationMode;
  final int creatorSlotNumber;
  final bool isPrivate;
  final String inviteCode;

  const CreateGameyaDraft({
    this.name = '',
    this.goalCategory = 'Family',
    this.monthlyContributionMinor = 50000,
    this.totalPeriods = 10,
    this.allocationMode = GameyaAllocationMode.sequential,
    this.creatorSlotNumber = 1,
    this.isPrivate = false,
    this.inviteCode = '',
  });

  int get totalPoolMinor => monthlyContributionMinor * totalPeriods;

  CreateGameyaDraft copyWith({
    String? name,
    String? goalCategory,
    int? monthlyContributionMinor,
    int? totalPeriods,
    GameyaAllocationMode? allocationMode,
    int? creatorSlotNumber,
    bool? isPrivate,
    String? inviteCode,
  }) {
    return CreateGameyaDraft(
      name: name ?? this.name,
      goalCategory: goalCategory ?? this.goalCategory,
      monthlyContributionMinor: monthlyContributionMinor ?? this.monthlyContributionMinor,
      totalPeriods: totalPeriods ?? this.totalPeriods,
      allocationMode: allocationMode ?? this.allocationMode,
      creatorSlotNumber: creatorSlotNumber ?? this.creatorSlotNumber,
      isPrivate: isPrivate ?? this.isPrivate,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}
