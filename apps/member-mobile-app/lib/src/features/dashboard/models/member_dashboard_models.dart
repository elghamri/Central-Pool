/// KYC verification status.
enum KycStatus {
  verified,
  pending,
  rejected,
  unsubmitted;

  static KycStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'VERIFIED':
      case 'APPROVED':
        return KycStatus.verified;
      case 'PENDING':
      case 'IN_REVIEW':
        return KycStatus.pending;
      case 'REJECTED':
        return KycStatus.rejected;
      default:
        return KycStatus.verified; // Default verified for active members
    }
  }
}

/// Severity level for dashboard alerts.
enum AlertSeverity {
  info,
  warning,
  critical,
  success,
}

/// Actionable alert requiring member attention.
class DashboardAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final String? actionLabel;
  final int? targetTabIndex;

  const DashboardAlert({
    required this.id,
    required this.title,
    required this.message,
    this.severity = AlertSeverity.info,
    this.actionLabel,
    this.targetTabIndex,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> json) {
    AlertSeverity sev = AlertSeverity.info;
    switch ((json['severity'] as String?)?.toLowerCase()) {
      case 'warning':
        sev = AlertSeverity.warning;
        break;
      case 'critical':
      case 'danger':
        sev = AlertSeverity.critical;
        break;
      case 'success':
        sev = AlertSeverity.success;
        break;
    }

    return DashboardAlert(
      id: json['id'] as String? ?? 'alert-1',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: sev,
      actionLabel: json['action_label'] as String?,
      targetTabIndex: json['target_tab_index'] as int?,
    );
  }
}

/// Member dashboard summary data model.
class MemberSummary {
  final String memberId;
  final String fullName;
  final String email;
  final String tenantId;
  final KycStatus kycStatus;
  final String currentCycleId;
  final String currentCycleName;
  final String accountStatus; // ACTIVE, IN_GOOD_STANDING, DELINQUENT
  final int totalContributedMinor; // Integer cents
  final int totalPayoutReceivedMinor;
  final int expectedPayoutMinor;
  final int payoutPosition; // 1-indexed slot
  final int totalSlots;
  final int nextContributionDueMinor;
  final DateTime? nextContributionDueDate;
  final int outstandingObligationMinor;
  final int availablePoolLiquidityMinor;
  final int reserveGuardMinor;

  const MemberSummary({
    required this.memberId,
    required this.fullName,
    required this.email,
    required this.tenantId,
    this.kycStatus = KycStatus.verified,
    required this.currentCycleId,
    required this.currentCycleName,
    this.accountStatus = 'ACTIVE',
    required this.totalContributedMinor,
    required this.totalPayoutReceivedMinor,
    required this.expectedPayoutMinor,
    required this.payoutPosition,
    required this.totalSlots,
    required this.nextContributionDueMinor,
    this.nextContributionDueDate,
    required this.outstandingObligationMinor,
    required this.availablePoolLiquidityMinor,
    required this.reserveGuardMinor,
  });

  factory MemberSummary.fromJson(Map<String, dynamic> json) {
    return MemberSummary(
      memberId: json['member_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Cooperative Member',
      email: json['email'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? 'TENANT-ALPHA',
      kycStatus: KycStatus.fromString(json['kyc_status'] as String?),
      currentCycleId: json['current_cycle_id'] as String? ?? 'CYCLE-2026-LIVE-01',
      currentCycleName: json['current_cycle_name'] as String? ?? 'Rotating Pool Alpha-1',
      accountStatus: json['account_status'] as String? ?? 'IN_GOOD_STANDING',
      totalContributedMinor: (json['total_contributed_minor'] as num?)?.toInt() ?? 50000,
      totalPayoutReceivedMinor: (json['total_payout_received_minor'] as num?)?.toInt() ?? 0,
      expectedPayoutMinor: (json['expected_payout_minor'] as num?)?.toInt() ?? 500000,
      payoutPosition: (json['payout_position'] as num?)?.toInt() ?? 1,
      totalSlots: (json['total_slots'] as num?)?.toInt() ?? 10,
      nextContributionDueMinor: (json['next_contribution_due_minor'] as num?)?.toInt() ?? 50000,
      nextContributionDueDate: json['next_contribution_due_date'] != null
          ? DateTime.tryParse(json['next_contribution_due_date'] as String)
          : DateTime.now().add(const Duration(days: 5)),
      outstandingObligationMinor: (json['outstanding_obligation_minor'] as num?)?.toInt() ?? 450000,
      availablePoolLiquidityMinor: (json['available_pool_liquidity_minor'] as num?)?.toInt() ?? 5000000,
      reserveGuardMinor: (json['reserve_guard_minor'] as num?)?.toInt() ?? 750000,
    );
  }
}

/// Slot allocation details in a live cycle.
class CycleSlotItem {
  final int slotNumber;
  final String memberId;
  final String memberName;
  final bool isCurrentMember;
  final String status; // SETTLED, CURRENT_ALLOCATION, UPCOMING, PENDING
  final int payoutAmountMinor;
  final String scheduledPeriod;
  final DateTime? settlementDate;

  const CycleSlotItem({
    required this.slotNumber,
    required this.memberId,
    required this.memberName,
    required this.isCurrentMember,
    required this.status,
    required this.payoutAmountMinor,
    required this.scheduledPeriod,
    this.settlementDate,
  });

  factory CycleSlotItem.fromJson(Map<String, dynamic> json, {String currentMemberId = ''}) {
    final mId = json['member_id'] as String? ?? '';
    return CycleSlotItem(
      slotNumber: (json['slot_number'] as num?)?.toInt() ?? 1,
      memberId: mId,
      memberName: json['member_name'] as String? ?? 'Member #$mId',
      isCurrentMember: mId == currentMemberId || (json['is_current_member'] as bool? ?? false),
      status: json['status'] as String? ?? 'UPCOMING',
      payoutAmountMinor: (json['payout_amount_minor'] as num?)?.toInt() ?? 500000,
      scheduledPeriod: json['scheduled_period'] as String? ?? 'Month 1',
      settlementDate: json['settlement_date'] != null ? DateTime.tryParse(json['settlement_date'] as String) : null,
    );
  }
}

/// Live pool and cooperative cycle state data model.
class LiveCyclePoolState {
  final String cycleId;
  final String cycleName;
  final String cooperativeId;
  final String status; // ACTIVE, FORMING, COMPLETED, PAUSED
  final int currentPeriod;
  final int totalPeriods;
  final int totalPoolMinor; // $50,000.00
  final int contributionsReceivedMinor; // $5,000.00
  final int contributionsOutstandingMinor; // $45,000.00
  final int reserveGuardMinor; // $7,500.00 (15%)
  final int participatingMemberCount;
  final int currentAllocationSlot;
  final int completedPayoutsCount;
  final int upcomingPayoutsCount;
  final int memberSlotPosition;
  final List<CycleSlotItem> slots;

  const LiveCyclePoolState({
    required this.cycleId,
    required this.cycleName,
    required this.cooperativeId,
    required this.status,
    required this.currentPeriod,
    required this.totalPeriods,
    required this.totalPoolMinor,
    required this.contributionsReceivedMinor,
    required this.contributionsOutstandingMinor,
    required this.reserveGuardMinor,
    required this.participatingMemberCount,
    required this.currentAllocationSlot,
    required this.completedPayoutsCount,
    required this.upcomingPayoutsCount,
    required this.memberSlotPosition,
    required this.slots,
  });

  factory LiveCyclePoolState.fromJson(Map<String, dynamic> json, {String currentMemberId = ''}) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    final slotsList = rawSlots.map((s) => CycleSlotItem.fromJson(s as Map<String, dynamic>, currentMemberId: currentMemberId)).toList();

    return LiveCyclePoolState(
      cycleId: json['cycle_id'] as String? ?? 'CYCLE-2026-LIVE-01',
      cycleName: json['cycle_name'] as String? ?? 'Cooperative Rotating Pool 2026',
      cooperativeId: json['cooperative_id'] as String? ?? 'COOP-ALPHA',
      status: json['status'] as String? ?? 'ACTIVE',
      currentPeriod: (json['current_period'] as num?)?.toInt() ?? 1,
      totalPeriods: (json['total_periods'] as num?)?.toInt() ?? 10,
      totalPoolMinor: (json['total_pool_minor'] as num?)?.toInt() ?? 5000000,
      contributionsReceivedMinor: (json['contributions_received_minor'] as num?)?.toInt() ?? 500000,
      contributionsOutstandingMinor: (json['contributions_outstanding_minor'] as num?)?.toInt() ?? 4500000,
      reserveGuardMinor: (json['reserve_guard_minor'] as num?)?.toInt() ?? 750000,
      participatingMemberCount: (json['participating_member_count'] as num?)?.toInt() ?? 10,
      currentAllocationSlot: (json['current_allocation_slot'] as num?)?.toInt() ?? 1,
      completedPayoutsCount: (json['completed_payouts_count'] as num?)?.toInt() ?? 0,
      upcomingPayoutsCount: (json['upcoming_payouts_count'] as num?)?.toInt() ?? 10,
      memberSlotPosition: (json['member_slot_position'] as num?)?.toInt() ?? 1,
      slots: slotsList,
    );
  }
}

/// Monthly contribution due record.
class ContributionRecord {
  final int periodNumber;
  final String title;
  final int amountMinor; // $500.00 -> 50000
  final String status; // PAID, DUE, UPCOMING, OVERDUE
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? paymentReference;
  final String paymentRail;

  const ContributionRecord({
    required this.periodNumber,
    required this.title,
    required this.amountMinor,
    required this.status,
    required this.dueDate,
    this.paidDate,
    this.paymentReference,
    this.paymentRail = 'FedNow Instant',
  });

  factory ContributionRecord.fromJson(Map<String, dynamic> json) {
    return ContributionRecord(
      periodNumber: (json['period_number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Period Monthly Due',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 50000,
      status: json['status'] as String? ?? 'UPCOMING',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : DateTime.now(),
      paidDate: json['paid_date'] != null ? DateTime.tryParse(json['paid_date'] as String) : null,
      paymentReference: json['payment_reference'] as String?,
      paymentRail: json['payment_rail'] as String? ?? 'FedNow Instant',
    );
  }
}

/// Member payout record.
class PayoutRecord {
  final int slotNumber;
  final int amountMinor; // $5,000.00 -> 500000
  final String status; // SETTLED, IN_PROGRESS, SCHEDULED
  final String periodLabel;
  final DateTime? settledDate;
  final String? transactionReference;

  const PayoutRecord({
    required this.slotNumber,
    required this.amountMinor,
    required this.status,
    required this.periodLabel,
    this.settledDate,
    this.transactionReference,
  });

  factory PayoutRecord.fromJson(Map<String, dynamic> json) {
    return PayoutRecord(
      slotNumber: (json['slot_number'] as num?)?.toInt() ?? 1,
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 500000,
      status: json['status'] as String? ?? 'SCHEDULED',
      periodLabel: json['period_label'] as String? ?? 'Month 1',
      settledDate: json['settled_date'] != null ? DateTime.tryParse(json['settled_date'] as String) : null,
      transactionReference: json['transaction_reference'] as String?,
    );
  }
}

/// Member legal financial obligation.
class ObligationRecord {
  final String id;
  final String title;
  final int totalAmountMinor;
  final int repaidAmountMinor;
  final int remainingAmountMinor;
  final String status; // CURRENT, SATISFIED, DELINQUENT
  final DateTime maturityDate;

  const ObligationRecord({
    required this.id,
    required this.title,
    required this.totalAmountMinor,
    required this.repaidAmountMinor,
    required this.remainingAmountMinor,
    required this.status,
    required this.maturityDate,
  });

  factory ObligationRecord.fromJson(Map<String, dynamic> json) {
    return ObligationRecord(
      id: json['id'] as String? ?? 'obl-1',
      title: json['title'] as String? ?? 'Post-Payout Capital Obligation',
      totalAmountMinor: (json['total_amount_minor'] as num?)?.toInt() ?? 500000,
      repaidAmountMinor: (json['repaid_amount_minor'] as num?)?.toInt() ?? 50000,
      remainingAmountMinor: (json['remaining_amount_minor'] as num?)?.toInt() ?? 450000,
      status: json['status'] as String? ?? 'CURRENT',
      maturityDate: json['maturity_date'] != null ? DateTime.parse(json['maturity_date'] as String) : DateTime.now().add(const Duration(days: 300)),
    );
  }
}

/// Activity entry for financial movements.
class FinancialActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final int amountMinor;
  final bool isDebit; // true = outgoing contribution, false = incoming payout
  final DateTime timestamp;
  final String status;
  final String category;

  const FinancialActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amountMinor,
    required this.isDebit,
    required this.timestamp,
    required this.status,
    required this.category,
  });

  factory FinancialActivityItem.fromJson(Map<String, dynamic> json) {
    return FinancialActivityItem(
      id: json['id'] as String? ?? 'act-1',
      title: json['title'] as String? ?? 'Payment',
      subtitle: json['subtitle'] as String? ?? '',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 50000,
      isDebit: json['is_debit'] as bool? ?? true,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
      status: json['status'] as String? ?? 'COMPLETED',
      category: json['category'] as String? ?? 'CONTRIBUTION',
    );
  }
}

/// Complete member financial summary data model.
class MemberFinancialSummary {
  final int totalContributedMinor;
  final int totalPayoutReceivedMinor;
  final int remainingObligationsMinor;
  final int upcomingContributionMinor;
  final DateTime? nextContributionDueDate;
  final List<ContributionRecord> contributionSchedule;
  final List<PayoutRecord> payouts;
  final List<ObligationRecord> obligations;
  final List<FinancialActivityItem> recentActivity;

  const MemberFinancialSummary({
    required this.totalContributedMinor,
    required this.totalPayoutReceivedMinor,
    required this.remainingObligationsMinor,
    required this.upcomingContributionMinor,
    this.nextContributionDueDate,
    required this.contributionSchedule,
    required this.payouts,
    required this.obligations,
    required this.recentActivity,
  });

  factory MemberFinancialSummary.fromJson(Map<String, dynamic> json) {
    final rawContribs = json['contribution_schedule'] as List<dynamic>? ?? [];
    final rawPayouts = json['payouts'] as List<dynamic>? ?? [];
    final rawObligations = json['obligations'] as List<dynamic>? ?? [];
    final rawActivity = json['recent_activity'] as List<dynamic>? ?? [];

    return MemberFinancialSummary(
      totalContributedMinor: (json['total_contributed_minor'] as num?)?.toInt() ?? 50000,
      totalPayoutReceivedMinor: (json['total_payout_received_minor'] as num?)?.toInt() ?? 0,
      remainingObligationsMinor: (json['remaining_obligations_minor'] as num?)?.toInt() ?? 450000,
      upcomingContributionMinor: (json['upcoming_contribution_minor'] as num?)?.toInt() ?? 50000,
      nextContributionDueDate: json['next_contribution_due_date'] != null
          ? DateTime.tryParse(json['next_contribution_due_date'] as String)
          : null,
      contributionSchedule: rawContribs.map((c) => ContributionRecord.fromJson(c as Map<String, dynamic>)).toList(),
      payouts: rawPayouts.map((p) => PayoutRecord.fromJson(p as Map<String, dynamic>)).toList(),
      obligations: rawObligations.map((o) => ObligationRecord.fromJson(o as Map<String, dynamic>)).toList(),
      recentActivity: rawActivity.map((a) => FinancialActivityItem.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }
}
