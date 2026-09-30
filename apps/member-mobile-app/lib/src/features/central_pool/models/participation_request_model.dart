// Central Pool Participation Request Model (Phase 1 / FM-04 Option A Ratified)
// Invariant: Pure data container; zero financial calculations on the client.
// Supports Policy TP-B (Request-Time Display Snapshot) with immutable resolved C.

class ParticipationRequestModel {
  final String requestId;
  final String tenantId;
  final String memberId;
  final int monthlyContributionMinor;
  final int durationPeriods;
  final int preferredPayoutPeriod;
  final int payoutFlexibilityWindow;
  final String currency;
  final String status;
  final String? tierId;
  final String? tierDisplayName;
  final String? allocatedScheduleId;
  final int? allocatedPositionNumber;
  final DateTime submittedAt;
  final DateTime expiresAt;
  final DateTime? confirmedAt;
  final int version;
  final String idempotencyKey;

  ParticipationRequestModel({
    required this.requestId,
    required this.tenantId,
    required this.memberId,
    required this.monthlyContributionMinor,
    required this.durationPeriods,
    required this.preferredPayoutPeriod,
    required this.payoutFlexibilityWindow,
    required this.currency,
    required this.status,
    this.tierId,
    this.tierDisplayName,
    this.allocatedScheduleId,
    this.allocatedPositionNumber,
    required this.submittedAt,
    required this.expiresAt,
    this.confirmedAt,
    required this.version,
    required this.idempotencyKey,
  });

  factory ParticipationRequestModel.fromJson(Map<String, dynamic> json) {
    return ParticipationRequestModel(
      requestId: json['requestId'] as String? ?? json['request_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      memberId: json['memberUid'] as String? ?? json['memberId'] as String? ?? json['member_id'] as String? ?? '',
      monthlyContributionMinor: (json['contributionMinor'] ?? json['monthlyContributionMinor'] ?? json['monthly_contribution_minor'] ?? 0) as int,
      durationPeriods: (json['durationPeriods'] ?? json['duration_periods'] ?? 0) as int,
      preferredPayoutPeriod: (json['payoutPreference'] ?? json['preferredPayoutPeriod'] ?? json['preferred_payout_period'] ?? 0) as int,
      payoutFlexibilityWindow: (json['payoutFlexibilityWindow'] ?? json['payout_flexibility_window'] ?? 0) as int,
      currency: json['currency'] as String? ?? 'EGP',
      status: json['status'] as String? ?? 'SUBMITTED',
      tierId: json['tierId'] as String? ?? json['tier_id'] as String?,
      tierDisplayName: json['tierDisplayName'] as String? ?? json['tier_display_name'] as String?,
      allocatedScheduleId: json['allocatedScheduleId'] as String? ?? json['allocated_schedule_id'] as String?,
      allocatedPositionNumber: (json['allocatedPositionNumber'] ?? json['allocated_position_number']) as int?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : (json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String) : DateTime.now()),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : (json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : DateTime.now()),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : (json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at'] as String) : null),
      version: (json['version'] ?? 1) as int,
      idempotencyKey: json['clientRequestId'] as String? ?? json['idempotencyKey'] as String? ?? json['idempotency_key'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'tenant_id': tenantId,
      'member_id': memberId,
      'monthly_contribution_minor': monthlyContributionMinor,
      'duration_periods': durationPeriods,
      'preferred_payout_period': preferredPayoutPeriod,
      'payout_flexibility_window': payoutFlexibilityWindow,
      'currency': currency,
      'status': status,
      'tier_id': tierId,
      'tier_display_name': tierDisplayName,
      'allocated_schedule_id': allocatedScheduleId,
      'allocated_position_number': allocatedPositionNumber,
      'submitted_at': submittedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'version': version,
      'idempotency_key': idempotencyKey,
    };
  }
}
