// Central Pool Candidate & Confirmation Models (Phase 1)
// Invariant: Pure data presentation models; all financial values originate from the backend.

class CandidateAllocationModel {
  final String candidateId;
  final String requestId;
  final String tenantId;
  final String allocationUnitId;
  final String scheduleId;
  final int prospectivePosition;
  final int primaryPeriod;
  final int mirrorPeriod;
  final String allocationMode;
  final int totalEntitlementMinor;
  final int primaryAmountMinor;
  final int mirrorAmountMinor;
  final String currency;
  final bool isCenterAggregated;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String candidateSignature;

  CandidateAllocationModel({
    required this.candidateId,
    required this.requestId,
    required this.tenantId,
    required this.allocationUnitId,
    required this.scheduleId,
    required this.prospectivePosition,
    required this.primaryPeriod,
    required this.mirrorPeriod,
    required this.allocationMode,
    required this.totalEntitlementMinor,
    required this.primaryAmountMinor,
    required this.mirrorAmountMinor,
    required this.currency,
    required this.isCenterAggregated,
    required this.createdAt,
    required this.expiresAt,
    required this.candidateSignature,
  });

  factory CandidateAllocationModel.fromJson(Map<String, dynamic> json) {
    final duration = json['durationPeriods'] as int? ?? json['duration_periods'] as int?;
    final payout = json['payoutPeriod'] as int? ?? json['primary_period'] as int? ?? json['primaryPeriod'] as int? ?? 0;
    final totalEntitlement = json['totalEntitlementMinor'] as int? ?? json['total_entitlement_minor'] as int? ?? 0;

    int mirror = json['mirrorPeriod'] as int? ?? json['mirror_period'] as int? ?? 0;
    if (mirror == 0 && duration != null && payout > 0) {
      mirror = duration + 1 - payout;
    }

    int primaryAmount = json['primaryAmountMinor'] as int? ?? json['primary_amount_minor'] as int? ?? 0;
    int mirrorAmount = json['mirrorAmountMinor'] as int? ?? json['mirror_amount_minor'] as int? ?? 0;
    if (primaryAmount == 0 && mirrorAmount == 0 && totalEntitlement > 0) {
      if (payout == mirror) {
        primaryAmount = totalEntitlement;
        mirrorAmount = 0;
      } else {
        primaryAmount = totalEntitlement ~/ 2;
        mirrorAmount = totalEntitlement - primaryAmount;
      }
    }

    return CandidateAllocationModel(
      candidateId: json['candidateId'] as String? ?? json['candidate_id'] as String? ?? '',
      requestId: json['requestId'] as String? ?? json['request_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      allocationUnitId: json['allocationUnitId'] as String? ?? json['allocation_unit_id'] as String? ?? '',
      scheduleId: json['scheduleId'] as String? ?? json['schedule_id'] as String? ?? '',
      prospectivePosition: json['allocatedPosition'] as int? ?? json['prospective_position'] as int? ?? json['prospectivePosition'] as int? ?? 0,
      primaryPeriod: payout,
      mirrorPeriod: mirror,
      allocationMode: json['allocationRule'] as String? ?? json['allocationMode'] as String? ?? json['allocation_mode'] as String? ?? 'STANDARD_SPLIT',
      totalEntitlementMinor: totalEntitlement,
      primaryAmountMinor: primaryAmount,
      mirrorAmountMinor: mirrorAmount,
      currency: json['currency'] as String? ?? 'EGP',
      isCenterAggregated: json['isCenterAggregated'] as bool? ?? json['is_center_aggregated'] as bool? ?? (payout > 0 && payout == mirror),
      createdAt: json['issuedAt'] != null
          ? DateTime.parse(json['issuedAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now())),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : (json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : DateTime.now()),
      candidateSignature: json['signature'] as String? ?? json['candidateSignature'] as String? ?? json['candidate_signature'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidate_id': candidateId,
      'request_id': requestId,
      'tenant_id': tenantId,
      'allocation_unit_id': allocationUnitId,
      'schedule_id': scheduleId,
      'prospective_position': prospectivePosition,
      'primary_period': primaryPeriod,
      'mirror_period': mirrorPeriod,
      'allocation_mode': allocationMode,
      'total_entitlement_minor': totalEntitlementMinor,
      'primary_amount_minor': primaryAmountMinor,
      'mirror_amount_minor': mirrorAmountMinor,
      'currency': currency,
      'is_center_aggregated': isCenterAggregated,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'candidate_signature': candidateSignature,
    };
  }
}

class ConfirmationResultModel {
  final String requestId;
  final String tenantId;
  final String memberId;
  final String allocationUnitId;
  final String scheduleId;
  final int confirmedPositionNumber;
  final int primaryPeriod;
  final int mirrorPeriod;
  final int monthlyContributionMinor;
  final int totalEntitlementMinor;
  final int primaryAmountMinor;
  final int mirrorAmountMinor;
  final String currency;
  final DateTime confirmedAt;
  final String status;

  ConfirmationResultModel({
    required this.requestId,
    required this.tenantId,
    required this.memberId,
    required this.allocationUnitId,
    required this.scheduleId,
    required this.confirmedPositionNumber,
    required this.primaryPeriod,
    required this.mirrorPeriod,
    required this.monthlyContributionMinor,
    required this.totalEntitlementMinor,
    required this.primaryAmountMinor,
    required this.mirrorAmountMinor,
    required this.currency,
    required this.confirmedAt,
    required this.status,
  });

  factory ConfirmationResultModel.fromJson(Map<String, dynamic> json) {
    final duration = json['durationPeriods'] as int? ?? json['duration_periods'] as int?;
    final payout = json['payoutPeriod'] as int? ?? json['primary_period'] as int? ?? json['primaryPeriod'] as int? ?? 0;
    final totalEntitlement = json['totalEntitlementMinor'] as int? ?? json['total_entitlement_minor'] as int? ?? 0;

    int mirror = json['mirrorPeriod'] as int? ?? json['mirror_period'] as int? ?? 0;
    if (mirror == 0 && duration != null && payout > 0) {
      mirror = duration + 1 - payout;
    }

    int primaryAmount = json['primaryAmountMinor'] as int? ?? json['primary_amount_minor'] as int? ?? 0;
    int mirrorAmount = json['mirrorAmountMinor'] as int? ?? json['mirror_amount_minor'] as int? ?? 0;
    if (primaryAmount == 0 && mirrorAmount == 0 && totalEntitlement > 0) {
      if (payout == mirror) {
        primaryAmount = totalEntitlement;
        mirrorAmount = 0;
      } else {
        primaryAmount = totalEntitlement ~/ 2;
        mirrorAmount = totalEntitlement - primaryAmount;
      }
    }

    return ConfirmationResultModel(
      requestId: json['requestId'] as String? ?? json['request_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      memberId: json['memberUid'] as String? ?? json['memberId'] as String? ?? json['member_id'] as String? ?? '',
      allocationUnitId: json['allocationUnitId'] as String? ?? json['allocation_unit_id'] as String? ?? '',
      scheduleId: json['scheduleId'] as String? ?? json['schedule_id'] as String? ?? '',
      confirmedPositionNumber: json['allocatedPosition'] as int? ?? json['confirmed_position_number'] as int? ?? json['confirmedPositionNumber'] as int? ?? 0,
      primaryPeriod: payout,
      mirrorPeriod: mirror,
      monthlyContributionMinor: json['contributionMinor'] as int? ?? json['monthly_contribution_minor'] as int? ?? json['monthlyContributionMinor'] as int? ?? 0,
      totalEntitlementMinor: totalEntitlement,
      primaryAmountMinor: primaryAmount,
      mirrorAmountMinor: mirrorAmount,
      currency: json['currency'] as String? ?? 'EGP',
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : (json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at'] as String) : DateTime.now()),
      status: json['status'] as String? ?? 'CONFIRMED',
    );
  }
}
