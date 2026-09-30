// Central Pool Period Projection Models (Step 7/13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Operates strictly on confirmed allocations and existing financial entities.
// - All projections are read-models explicitly classified as DERIVED_PROJECTION.
// - Pure mathematical/simulation projection values (REAL_MONEY_ENABLED = false).

class PeriodContributionDetailModel {
  final int periodNumber;
  final int dueAmountMinor;
  final String status; // 'SCHEDULED' | 'RECORDED'
  final DateTime? recordedAt;
  final String? contributionEventId;

  const PeriodContributionDetailModel({
    required this.periodNumber,
    required this.dueAmountMinor,
    required this.status,
    this.recordedAt,
    this.contributionEventId,
  });

  factory PeriodContributionDetailModel.fromJson(Map<String, dynamic> json) {
    return PeriodContributionDetailModel(
      periodNumber: (json['periodNumber'] ?? json['period_number'] ?? 0) as int,
      dueAmountMinor: (json['dueAmountMinor'] ?? json['due_amount_minor'] ?? 0) as int,
      status: json['status'] as String? ?? 'SCHEDULED',
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : (json['recorded_at'] != null ? DateTime.parse(json['recorded_at'] as String) : null),
      contributionEventId: json['contributionEventId'] as String? ?? json['contribution_event_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'periodNumber': periodNumber,
    'dueAmountMinor': dueAmountMinor,
    'status': status,
    if (recordedAt != null) 'recordedAt': recordedAt!.toIso8601String(),
    if (contributionEventId != null) 'contributionEventId': contributionEventId,
  };
}

class PeriodPayoutSlotModel {
  final int positionNumber;
  final String? memberUid;
  final int amountMinor;
  final int basisPoints;
  final bool isCenter;
  final int? mirrorPosition;

  const PeriodPayoutSlotModel({
    required this.positionNumber,
    this.memberUid,
    required this.amountMinor,
    required this.basisPoints,
    required this.isCenter,
    this.mirrorPosition,
  });

  factory PeriodPayoutSlotModel.fromJson(Map<String, dynamic> json) {
    return PeriodPayoutSlotModel(
      positionNumber: (json['positionNumber'] ?? json['position_number'] ?? 0) as int,
      memberUid: json['memberUid'] as String? ?? json['member_uid'] as String?,
      amountMinor: (json['amountMinor'] ?? json['amount_minor'] ?? 0) as int,
      basisPoints: (json['basisPoints'] ?? json['basis_points'] ?? 0) as int,
      isCenter: (json['isCenter'] ?? json['is_center'] ?? false) as bool,
      mirrorPosition: (json['mirrorPosition'] ?? json['mirror_position']) as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'positionNumber': positionNumber,
    if (memberUid != null) 'memberUid': memberUid,
    'amountMinor': amountMinor,
    'basisPoints': basisPoints,
    'isCenter': isCenter,
    if (mirrorPosition != null) 'mirrorPosition': mirrorPosition,
  };
}

class CyclePeriodSummaryModel {
  final int periodNumber;
  final int expectedContributionPoolMinor;
  final int expectedDisbursementPoolMinor;
  final List<PeriodPayoutSlotModel> payoutSlots;
  final bool isBalanced;

  const CyclePeriodSummaryModel({
    required this.periodNumber,
    required this.expectedContributionPoolMinor,
    required this.expectedDisbursementPoolMinor,
    required this.payoutSlots,
    required this.isBalanced,
  });

  factory CyclePeriodSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['payoutSlots'] as List<dynamic>? ?? json['payout_slots'] as List<dynamic>? ?? [];
    return CyclePeriodSummaryModel(
      periodNumber: (json['periodNumber'] ?? json['period_number'] ?? 0) as int,
      expectedContributionPoolMinor: (json['expectedContributionPoolMinor'] ?? json['expected_contribution_pool_minor'] ?? 0) as int,
      expectedDisbursementPoolMinor: (json['expectedDisbursementPoolMinor'] ?? json['expected_disbursement_pool_minor'] ?? 0) as int,
      payoutSlots: rawSlots
          .map((s) => PeriodPayoutSlotModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      isBalanced: (json['isBalanced'] ?? json['is_balanced'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'periodNumber': periodNumber,
    'expectedContributionPoolMinor': expectedContributionPoolMinor,
    'expectedDisbursementPoolMinor': expectedDisbursementPoolMinor,
    'payoutSlots': payoutSlots.map((s) => s.toJson()).toList(),
    'isBalanced': isBalanced,
  };
}

class CyclePeriodProjectionModel {
  final String projectionId;
  final String tenantId;
  final String allocationUnitId;
  final int memberCount;
  final int periodicContributionMinor;
  final int totalEntitlementMinor;
  final int totalPotMinor;
  final String currency;
  final List<CyclePeriodSummaryModel> periods;
  final List<String>? authorizedMemberUids;
  final bool isProjection;
  final String classification;
  final DateTime generatedAt;

  const CyclePeriodProjectionModel({
    required this.projectionId,
    required this.tenantId,
    required this.allocationUnitId,
    required this.memberCount,
    required this.periodicContributionMinor,
    required this.totalEntitlementMinor,
    required this.totalPotMinor,
    required this.currency,
    required this.periods,
    this.authorizedMemberUids,
    required this.isProjection,
    required this.classification,
    required this.generatedAt,
  });

  factory CyclePeriodProjectionModel.fromJson(Map<String, dynamic> json) {
    final rawPeriods = json['periods'] as List<dynamic>? ?? [];
    final rawUids = json['authorizedMemberUids'] as List<dynamic>? ?? json['authorized_member_uids'] as List<dynamic>?;
    return CyclePeriodProjectionModel(
      projectionId: json['projectionId'] as String? ?? json['projection_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      allocationUnitId: json['allocationUnitId'] as String? ?? json['allocation_unit_id'] as String? ?? '',
      memberCount: (json['memberCount'] ?? json['member_count'] ?? 0) as int,
      periodicContributionMinor: (json['periodicContributionMinor'] ?? json['periodic_contribution_minor'] ?? 0) as int,
      totalEntitlementMinor: (json['totalEntitlementMinor'] ?? json['total_entitlement_minor'] ?? 0) as int,
      totalPotMinor: (json['totalPotMinor'] ?? json['total_pot_minor'] ?? 0) as int,
      currency: json['currency'] as String? ?? 'EGP',
      periods: rawPeriods
          .map((p) => CyclePeriodSummaryModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      authorizedMemberUids: rawUids?.map((e) => e.toString()).toList(),
      isProjection: (json['isProjection'] ?? json['is_projection'] ?? true) as bool,
      classification: json['classification'] as String? ?? 'DERIVED_PROJECTION',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : (json['generated_at'] != null ? DateTime.parse(json['generated_at'] as String) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
    'projectionId': projectionId,
    'tenantId': tenantId,
    'allocationUnitId': allocationUnitId,
    'memberCount': memberCount,
    'periodicContributionMinor': periodicContributionMinor,
    'totalEntitlementMinor': totalEntitlementMinor,
    'totalPotMinor': totalPotMinor,
    'currency': currency,
    'periods': periods.map((p) => p.toJson()).toList(),
    if (authorizedMemberUids != null) 'authorizedMemberUids': authorizedMemberUids,
    'isProjection': isProjection,
    'classification': classification,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

class MemberPeriodPayoutDetailModel {
  final int entitledAmountMinor;
  final int basisPoints;
  final bool isPayoutPeriod;
  final bool isCenter;
  final int? mirrorPeriod;

  const MemberPeriodPayoutDetailModel({
    required this.entitledAmountMinor,
    required this.basisPoints,
    required this.isPayoutPeriod,
    required this.isCenter,
    this.mirrorPeriod,
  });

  factory MemberPeriodPayoutDetailModel.fromJson(Map<String, dynamic> json) {
    return MemberPeriodPayoutDetailModel(
      entitledAmountMinor: (json['entitledAmountMinor'] ?? json['entitled_amount_minor'] ?? 0) as int,
      basisPoints: (json['basisPoints'] ?? json['basis_points'] ?? 0) as int,
      isPayoutPeriod: (json['isPayoutPeriod'] ?? json['is_payout_period'] ?? false) as bool,
      isCenter: (json['isCenter'] ?? json['is_center'] ?? false) as bool,
      mirrorPeriod: (json['mirrorPeriod'] ?? json['mirror_period']) as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'entitledAmountMinor': entitledAmountMinor,
    'basisPoints': basisPoints,
    'isPayoutPeriod': isPayoutPeriod,
    'isCenter': isCenter,
    if (mirrorPeriod != null) 'mirrorPeriod': mirrorPeriod,
  };
}

class MemberPeriodDetailModel {
  final int periodNumber;
  final PeriodContributionDetailModel contribution;
  final MemberPeriodPayoutDetailModel payout;
  final int netEntitlementDeltaMinor;

  const MemberPeriodDetailModel({
    required this.periodNumber,
    required this.contribution,
    required this.payout,
    required this.netEntitlementDeltaMinor,
  });

  factory MemberPeriodDetailModel.fromJson(Map<String, dynamic> json) {
    return MemberPeriodDetailModel(
      periodNumber: (json['periodNumber'] ?? json['period_number'] ?? 0) as int,
      contribution: PeriodContributionDetailModel.fromJson(
        (json['contribution'] as Map<String, dynamic>?) ?? {},
      ),
      payout: MemberPeriodPayoutDetailModel.fromJson(
        (json['payout'] as Map<String, dynamic>?) ?? {},
      ),
      netEntitlementDeltaMinor: (json['netEntitlementDeltaMinor'] ?? json['net_entitlement_delta_minor'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'periodNumber': periodNumber,
    'contribution': contribution.toJson(),
    'payout': payout.toJson(),
    'netEntitlementDeltaMinor': netEntitlementDeltaMinor,
  };
}

class MemberPeriodProjectionModel {
  final String projectionId;
  final String tenantId;
  final String memberUid;
  final String allocationId;
  final String allocationUnitId;
  final int positionNumber;
  final int totalPeriods;
  final int periodicContributionMinor;
  final int totalObligationMinor;
  final int totalEntitlementMinor;
  final String currency;
  final List<MemberPeriodDetailModel> periods;
  final bool isProjection;
  final String classification;
  final DateTime generatedAt;

  const MemberPeriodProjectionModel({
    required this.projectionId,
    required this.tenantId,
    required this.memberUid,
    required this.allocationId,
    required this.allocationUnitId,
    required this.positionNumber,
    required this.totalPeriods,
    required this.periodicContributionMinor,
    required this.totalObligationMinor,
    required this.totalEntitlementMinor,
    required this.currency,
    required this.periods,
    required this.isProjection,
    required this.classification,
    required this.generatedAt,
  });

  factory MemberPeriodProjectionModel.fromJson(Map<String, dynamic> json) {
    final rawPeriods = json['periods'] as List<dynamic>? ?? [];
    return MemberPeriodProjectionModel(
      projectionId: json['projectionId'] as String? ?? json['projection_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      memberUid: json['memberUid'] as String? ?? json['member_uid'] as String? ?? json['memberId'] as String? ?? '',
      allocationId: json['allocationId'] as String? ?? json['allocation_id'] as String? ?? '',
      allocationUnitId: json['allocationUnitId'] as String? ?? json['allocation_unit_id'] as String? ?? '',
      positionNumber: (json['positionNumber'] ?? json['position_number'] ?? 0) as int,
      totalPeriods: (json['totalPeriods'] ?? json['total_periods'] ?? 0) as int,
      periodicContributionMinor: (json['periodicContributionMinor'] ?? json['periodic_contribution_minor'] ?? 0) as int,
      totalObligationMinor: (json['totalObligationMinor'] ?? json['total_obligation_minor'] ?? 0) as int,
      totalEntitlementMinor: (json['totalEntitlementMinor'] ?? json['total_entitlement_minor'] ?? 0) as int,
      currency: json['currency'] as String? ?? 'EGP',
      periods: rawPeriods
          .map((p) => MemberPeriodDetailModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      isProjection: (json['isProjection'] ?? json['is_projection'] ?? true) as bool,
      classification: json['classification'] as String? ?? 'DERIVED_PROJECTION',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : (json['generated_at'] != null ? DateTime.parse(json['generated_at'] as String) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
    'projectionId': projectionId,
    'tenantId': tenantId,
    'memberUid': memberUid,
    'allocationId': allocationId,
    'allocationUnitId': allocationUnitId,
    'positionNumber': positionNumber,
    'totalPeriods': totalPeriods,
    'periodicContributionMinor': periodicContributionMinor,
    'totalObligationMinor': totalObligationMinor,
    'totalEntitlementMinor': totalEntitlementMinor,
    'currency': currency,
    'periods': periods.map((p) => p.toJson()).toList(),
    'isProjection': isProjection,
    'classification': classification,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

class PeriodReadinessModel {
  final int periodNumber;
  final int totalScheduledContributionMinor;
  final int totalRecordedContributionMinor;
  final int totalScheduledPayoutMinor;
  final bool allContributionsRecorded;
  final bool isPoolBalanced;

  const PeriodReadinessModel({
    required this.periodNumber,
    required this.totalScheduledContributionMinor,
    required this.totalRecordedContributionMinor,
    required this.totalScheduledPayoutMinor,
    required this.allContributionsRecorded,
    required this.isPoolBalanced,
  });

  factory PeriodReadinessModel.fromJson(Map<String, dynamic> json) {
    return PeriodReadinessModel(
      periodNumber: (json['periodNumber'] ?? json['period_number'] ?? 0) as int,
      totalScheduledContributionMinor: (json['totalScheduledContributionMinor'] ?? json['total_scheduled_contribution_minor'] ?? 0) as int,
      totalRecordedContributionMinor: (json['totalRecordedContributionMinor'] ?? json['total_recorded_contribution_minor'] ?? 0) as int,
      totalScheduledPayoutMinor: (json['totalScheduledPayoutMinor'] ?? json['total_scheduled_payout_minor'] ?? 0) as int,
      allContributionsRecorded: (json['allContributionsRecorded'] ?? json['all_contributions_recorded'] ?? false) as bool,
      isPoolBalanced: (json['isPoolBalanced'] ?? json['is_pool_balanced'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'periodNumber': periodNumber,
    'totalScheduledContributionMinor': totalScheduledContributionMinor,
    'totalRecordedContributionMinor': totalRecordedContributionMinor,
    'totalScheduledPayoutMinor': totalScheduledPayoutMinor,
    'allContributionsRecorded': allContributionsRecorded,
    'isPoolBalanced': isPoolBalanced,
  };
}
