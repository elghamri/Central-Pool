import '../../dashboard/models/member_dashboard_models.dart';

extension KycStatusExtension on KycStatus {
  String get displayName {
    switch (this) {
      case KycStatus.verified:
        return 'VERIFIED';
      case KycStatus.pending:
        return 'PENDING_REVIEW';
      case KycStatus.rejected:
        return 'RESTRICTED';
      case KycStatus.unsubmitted:
        return 'UNSUBMITTED';
    }
  }
}

/// Business Organization overview metrics.
class AdminOrgOverview {
  final String orgId;
  final String orgName;
  final String charterId;
  final String tenantId;
  final String status;
  final int totalMembersCount;
  final int activeCyclesCount;
  final int totalCapitalMinor; // e.g. 50000000 = $500,000.00
  final int committedCapitalMinor; // e.g. 5000000 = $50,000.00
  final int availableLiquidityMinor; // e.g. 45000000 = $450,000.00
  final int reserveGuardMinor; // e.g. 7500000 = $75,000.00
  final double delinquencyRate; // 0.0%
  final bool makerCheckerEnabled;
  final DateTime lastAuditTimestamp;

  const AdminOrgOverview({
    required this.orgId,
    required this.orgName,
    required this.charterId,
    required this.tenantId,
    required this.status,
    required this.totalMembersCount,
    required this.activeCyclesCount,
    required this.totalCapitalMinor,
    required this.committedCapitalMinor,
    required this.availableLiquidityMinor,
    required this.reserveGuardMinor,
    required this.delinquencyRate,
    required this.makerCheckerEnabled,
    required this.lastAuditTimestamp,
  });

  factory AdminOrgOverview.fromJson(Map<String, dynamic> json) {
    return AdminOrgOverview(
      orgId: json['org_id'] as String? ?? 'org-alpha-001',
      orgName: json['org_name'] as String? ?? 'Alpha Cooperative Financial Union',
      charterId: json['charter_id'] as String? ?? 'NCUA-COOP-2026-892',
      tenantId: json['tenant_id'] as String? ?? 'TENANT-ALPHA',
      status: json['status'] as String? ?? 'ACTIVE_GOOD_STANDING',
      totalMembersCount: (json['total_members_count'] as num?)?.toInt() ?? 248,
      activeCyclesCount: (json['active_cycles_count'] as num?)?.toInt() ?? 12,
      totalCapitalMinor: (json['total_capital_minor'] as num?)?.toInt() ?? 50000000,
      committedCapitalMinor: (json['committed_capital_minor'] as num?)?.toInt() ?? 5000000,
      availableLiquidityMinor: (json['available_liquidity_minor'] as num?)?.toInt() ?? 45000000,
      reserveGuardMinor: (json['reserve_guard_minor'] as num?)?.toInt() ?? 7500000,
      delinquencyRate: (json['delinquency_rate'] as num?)?.toDouble() ?? 0.0,
      makerCheckerEnabled: json['maker_checker_enabled'] as bool? ?? true,
      lastAuditTimestamp: json['last_audit_timestamp'] != null
          ? DateTime.parse(json['last_audit_timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// Organization profile & operating parameters.
class AdminOrgProfile {
  final String orgName;
  final String legalEntityName;
  final String taxId;
  final String primaryAddress;
  final String primaryContactEmail;
  final String primaryContactPhone;
  final String baseCurrency;
  final double reserveRequirementPercent;
  final int maxCycleDurationMonths;
  final int maxMemberSlots;
  final List<String> branches;

  const AdminOrgProfile({
    required this.orgName,
    required this.legalEntityName,
    required this.taxId,
    required this.primaryAddress,
    required this.primaryContactEmail,
    required this.primaryContactPhone,
    required this.baseCurrency,
    required this.reserveRequirementPercent,
    required this.maxCycleDurationMonths,
    required this.maxMemberSlots,
    required this.branches,
  });

  factory AdminOrgProfile.fromJson(Map<String, dynamic> json) {
    final rawBranches = json['branches'] as List<dynamic>? ?? [];
    return AdminOrgProfile(
      orgName: json['org_name'] as String? ?? 'Alpha Cooperative Financial Union',
      legalEntityName: json['legal_entity_name'] as String? ?? 'Alpha Cooperative Union Inc.',
      taxId: json['tax_id'] as String? ?? 'XX-XXX8921',
      primaryAddress: json['primary_address'] as String? ?? '100 Financial Way, Suite 400, New York, NY 10005',
      primaryContactEmail: json['primary_contact_email'] as String? ?? 'admin@alphacoop.internal',
      primaryContactPhone: json['primary_contact_phone'] as String? ?? '+1 (800) 555-2667',
      baseCurrency: json['base_currency'] as String? ?? 'USD',
      reserveRequirementPercent: (json['reserve_requirement_percent'] as num?)?.toDouble() ?? 15.0,
      maxCycleDurationMonths: (json['max_cycle_duration_months'] as num?)?.toInt() ?? 24,
      maxMemberSlots: (json['max_member_slots'] as num?)?.toInt() ?? 50,
      branches: rawBranches.map((b) => b.toString()).toList().isNotEmpty
          ? rawBranches.map((b) => b.toString()).toList()
          : const ['Manhattan Headquarters', 'Brooklyn Financial Center', 'Queens Community Branch'],
    );
  }
}

/// Member list entry for admin directory.
class AdminMemberListItem {
  final String memberId;
  final String fullName;
  final String email;
  final KycStatus kycStatus;
  final String accountStatus; // IN_GOOD_STANDING, WATCHLIST, RESTRICTED
  final String currentCycleId;
  final String currentCycleName;
  final int slotNumber;
  final int totalContributedMinor;
  final int outstandingObligationMinor;
  final DateTime joinedDate;

  const AdminMemberListItem({
    required this.memberId,
    required this.fullName,
    required this.email,
    required this.kycStatus,
    required this.accountStatus,
    required this.currentCycleId,
    required this.currentCycleName,
    required this.slotNumber,
    required this.totalContributedMinor,
    required this.outstandingObligationMinor,
    required this.joinedDate,
  });

  factory AdminMemberListItem.fromJson(Map<String, dynamic> json) {
    return AdminMemberListItem(
      memberId: json['member_id'] as String? ?? 'usr-member-001',
      fullName: json['full_name'] as String? ?? 'Sarah Jenkins',
      email: json['email'] as String? ?? 'sarah.jenkins@example.com',
      kycStatus: KycStatus.fromString(json['kyc_status'] as String? ?? 'VERIFIED'),
      accountStatus: json['account_status'] as String? ?? 'IN_GOOD_STANDING',
      currentCycleId: json['current_cycle_id'] as String? ?? 'CYCLE-2026-LIVE-01',
      currentCycleName: json['current_cycle_name'] as String? ?? 'Rotating Pool Alpha-1',
      slotNumber: (json['slot_number'] as num?)?.toInt() ?? 1,
      totalContributedMinor: (json['total_contributed_minor'] as num?)?.toInt() ?? 50000,
      outstandingObligationMinor: (json['outstanding_obligation_minor'] as num?)?.toInt() ?? 450000,
      joinedDate: json['joined_date'] != null ? DateTime.parse(json['joined_date'] as String) : DateTime(2026, 1, 15),
    );
  }
}

/// Individual slot representation in a cooperative cycle.
class AdminCycleSlotItem {
  final int slotNumber;
  final String memberId;
  final String memberName;
  final String status; // DISBURSED, CURRENT, UPCOMING
  final int payoutAmountMinor;
  final DateTime payoutDate;

  const AdminCycleSlotItem({
    required this.slotNumber,
    required this.memberId,
    required this.memberName,
    required this.status,
    required this.payoutAmountMinor,
    required this.payoutDate,
  });

  factory AdminCycleSlotItem.fromJson(Map<String, dynamic> json) {
    return AdminCycleSlotItem(
      slotNumber: (json['slot_number'] as num?)?.toInt() ?? 1,
      memberId: json['member_id'] as String? ?? 'usr-member-001',
      memberName: json['member_name'] as String? ?? 'Member',
      status: json['status'] as String? ?? 'UPCOMING',
      payoutAmountMinor: (json['payout_amount_minor'] as num?)?.toInt() ?? 500000,
      payoutDate: json['payout_date'] != null ? DateTime.parse(json['payout_date'] as String) : DateTime.now(),
    );
  }
}

/// Cooperative cycle summary for admin management.
class AdminCycleSummary {
  final String cycleId;
  final String cycleName;
  final String status; // ACTIVE, PENDING_ACTIVATION, COMPLETED
  final int durationMonths;
  final int contributionPerPeriodMinor; // 50000 = $500.00
  final int payoutPerSlotMinor; // 500000 = $5,000.00
  final int totalPoolCapitalMinor; // 5000000 = $50,000.00
  final int totalSlots;
  final int currentPeriod;
  final DateTime startDate;
  final List<AdminCycleSlotItem> slots;

  const AdminCycleSummary({
    required this.cycleId,
    required this.cycleName,
    required this.status,
    required this.durationMonths,
    required this.contributionPerPeriodMinor,
    required this.payoutPerSlotMinor,
    required this.totalPoolCapitalMinor,
    required this.totalSlots,
    required this.currentPeriod,
    required this.startDate,
    required this.slots,
  });

  factory AdminCycleSummary.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    return AdminCycleSummary(
      cycleId: json['cycle_id'] as String? ?? 'CYCLE-2026-LIVE-01',
      cycleName: json['cycle_name'] as String? ?? 'Rotating Pool Alpha-1',
      status: json['status'] as String? ?? 'ACTIVE',
      durationMonths: (json['duration_months'] as num?)?.toInt() ?? 10,
      contributionPerPeriodMinor: (json['contribution_per_period_minor'] as num?)?.toInt() ?? 50000,
      payoutPerSlotMinor: (json['payout_per_slot_minor'] as num?)?.toInt() ?? 500000,
      totalPoolCapitalMinor: (json['total_pool_capital_minor'] as num?)?.toInt() ?? 5000000,
      totalSlots: (json['total_slots'] as num?)?.toInt() ?? 10,
      currentPeriod: (json['current_period'] as num?)?.toInt() ?? 2,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : DateTime(2026, 8, 1),
      slots: rawSlots.map((s) => AdminCycleSlotItem.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

/// Cycle Creation Request DTO.
class AdminCycleCreateRequest {
  final String cycleName;
  final String tenantId;
  final int durationMonths;
  final int contributionPerPeriodMinor;
  final int payoutPerSlotMinor;
  final int totalSlots;
  final String payoutAlgorithm;

  const AdminCycleCreateRequest({
    required this.cycleName,
    required this.tenantId,
    required this.durationMonths,
    required this.contributionPerPeriodMinor,
    required this.payoutPerSlotMinor,
    required this.totalSlots,
    this.payoutAlgorithm = 'ROUND_ROBIN_FIXED',
  });

  Map<String, dynamic> toJson() => {
        'cycle_name': cycleName,
        'tenant_id': tenantId,
        'duration_months': durationMonths,
        'contribution_per_period_minor': contributionPerPeriodMinor,
        'payout_per_slot_minor': payoutPerSlotMinor,
        'total_slots': totalSlots,
        'payout_algorithm': payoutAlgorithm,
      };
}

/// Treasury rebalance event log item.
class AdminTreasuryRebalanceEvent {
  final String eventId;
  final String eventType;
  final int rebalancedAmountMinor;
  final String status;
  final DateTime timestamp;
  final String correlationId;

  const AdminTreasuryRebalanceEvent({
    required this.eventId,
    required this.eventType,
    required this.rebalancedAmountMinor,
    required this.status,
    required this.timestamp,
    required this.correlationId,
  });

  factory AdminTreasuryRebalanceEvent.fromJson(Map<String, dynamic> json) {
    return AdminTreasuryRebalanceEvent(
      eventId: json['event_id'] as String? ?? 'TREAS-EVT-001',
      eventType: json['event_type'] as String? ?? 'AUTOMATED_15PCT_RESERVE_REBALANCE',
      rebalancedAmountMinor: (json['rebalanced_amount_minor'] as num?)?.toInt() ?? 750000,
      status: json['status'] as String? ?? 'CONFIRMED_CLEAN',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now().subtract(const Duration(hours: 4)),
      correlationId: json['correlation_id'] as String? ?? 'corr-treas-0912',
    );
  }
}

/// Treasury liquidity & reserve guard overview.
class AdminTreasuryOverview {
  final int totalLiquidityMinor; // $500,000.00 = 50000000
  final int committedLiquidityMinor; // $50,000.00 = 5000000
  final int freeLiquidityMinor; // $450,000.00 = 45000000
  final int requiredReserveMinor; // $75,000.00 = 7500000 (15%)
  final double reserveRatioPercent; // 15.0
  final String reserveStatus; // HEALTHY_GUARDED, AT_RISK, BREACHED
  final List<AdminTreasuryRebalanceEvent> rebalanceHistory;

  const AdminTreasuryOverview({
    required this.totalLiquidityMinor,
    required this.committedLiquidityMinor,
    required this.freeLiquidityMinor,
    required this.requiredReserveMinor,
    required this.reserveRatioPercent,
    required this.reserveStatus,
    required this.rebalanceHistory,
  });

  factory AdminTreasuryOverview.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['rebalance_history'] as List<dynamic>? ?? [];
    return AdminTreasuryOverview(
      totalLiquidityMinor: (json['total_liquidity_minor'] as num?)?.toInt() ?? 50000000,
      committedLiquidityMinor: (json['committed_liquidity_minor'] as num?)?.toInt() ?? 5000000,
      freeLiquidityMinor: (json['free_liquidity_minor'] as num?)?.toInt() ?? 45000000,
      requiredReserveMinor: (json['required_reserve_minor'] as num?)?.toInt() ?? 7500000,
      reserveRatioPercent: (json['reserve_ratio_percent'] as num?)?.toDouble() ?? 15.0,
      reserveStatus: json['reserve_status'] as String? ?? 'HEALTHY_GUARDED',
      rebalanceHistory: rawHistory.map((e) => AdminTreasuryRebalanceEvent.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
