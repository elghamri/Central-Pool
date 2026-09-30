// Central Pool Contribution Schedule Model (Step 6/13)
// PROVENANCE & SEMANTIC DEFINITION:
// - Represents the sequence of scheduled contribution periods for a Financial Obligation.
// - Status: SCHEDULED | RECORDED

class ScheduledContributionPeriodModel {
  final int periodNumber;
  final int scheduledAmountMinor;
  final String status; // 'SCHEDULED' | 'RECORDED'
  final DateTime? recordedAt;
  final String? contributionEventId;

  const ScheduledContributionPeriodModel({
    required this.periodNumber,
    required this.scheduledAmountMinor,
    required this.status,
    this.recordedAt,
    this.contributionEventId,
  });

  factory ScheduledContributionPeriodModel.fromJson(Map<String, dynamic> json) {
    return ScheduledContributionPeriodModel(
      periodNumber: (json['periodNumber'] ?? json['period_number'] ?? 0) as int,
      scheduledAmountMinor: (json['scheduledAmountMinor'] ?? json['scheduled_amount_minor'] ?? 0) as int,
      status: json['status'] as String? ?? 'SCHEDULED',
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : (json['recorded_at'] != null ? DateTime.parse(json['recorded_at'] as String) : null),
      contributionEventId: json['contributionEventId'] as String? ?? json['contribution_event_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'periodNumber': periodNumber,
    'scheduledAmountMinor': scheduledAmountMinor,
    'status': status,
    if (recordedAt != null) 'recordedAt': recordedAt!.toIso8601String(),
    if (contributionEventId != null) 'contributionEventId': contributionEventId,
  };
}

class ContributionScheduleModel {
  final String scheduleId;
  final String obligationId;
  final String tenantId;
  final String memberUid;
  final String allocationUnitId;
  final int totalPeriods;
  final List<ScheduledContributionPeriodModel> periods;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const ContributionScheduleModel({
    required this.scheduleId,
    required this.obligationId,
    required this.tenantId,
    required this.memberUid,
    required this.allocationUnitId,
    required this.totalPeriods,
    required this.periods,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory ContributionScheduleModel.fromJson(Map<String, dynamic> json) {
    final rawPeriods = json['periods'] as List<dynamic>? ?? [];
    return ContributionScheduleModel(
      scheduleId: json['scheduleId'] as String? ?? json['schedule_id'] as String? ?? '',
      obligationId: json['obligationId'] as String? ?? json['obligation_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      memberUid: json['memberUid'] as String? ?? json['member_uid'] as String? ?? json['memberId'] as String? ?? '',
      allocationUnitId: json['allocationUnitId'] as String? ?? json['allocation_unit_id'] as String? ?? '',
      totalPeriods: (json['totalPeriods'] ?? json['total_periods'] ?? 0) as int,
      periods: rawPeriods
          .map((p) => ScheduledContributionPeriodModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now()),
      version: (json['version'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'scheduleId': scheduleId,
    'obligationId': obligationId,
    'tenantId': tenantId,
    'memberUid': memberUid,
    'allocationUnitId': allocationUnitId,
    'totalPeriods': totalPeriods,
    'periods': periods.map((p) => p.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'version': version,
  };
}
