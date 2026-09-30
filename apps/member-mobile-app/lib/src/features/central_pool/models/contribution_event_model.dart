// Central Pool Contribution Event Model (Step 6/13)
// PROVENANCE & SEMANTIC DEFINITION:
// - Represents an internal accounting event indicating a periodic contribution has been recorded.
// - Note: contribution_event != payment_transaction (REAL_MONEY_ENABLED = false).

class ContributionEventModel {
  final String contributionEventId;
  final String tenantId;
  final String memberUid;
  final String obligationId;
  final String allocationUnitId;
  final int periodNumber;
  final int amountMinor;
  final String currency;
  final DateTime recordedAt;
  final String? journalEntryId;
  final String idempotencyId;

  const ContributionEventModel({
    required this.contributionEventId,
    required this.tenantId,
    required this.memberUid,
    required this.obligationId,
    required this.allocationUnitId,
    required this.periodNumber,
    required this.amountMinor,
    required this.currency,
    required this.recordedAt,
    this.journalEntryId,
    required this.idempotencyId,
  });

  factory ContributionEventModel.fromJson(Map<String, dynamic> json) {
    return ContributionEventModel(
      contributionEventId: json['contributionEventId'] as String? ?? json['contribution_event_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      memberUid: json['memberUid'] as String? ?? json['member_uid'] as String? ?? json['memberId'] as String? ?? '',
      obligationId: json['obligationId'] as String? ?? json['obligation_id'] as String? ?? '',
      allocationUnitId: json['allocationUnitId'] as String? ?? json['allocation_unit_id'] as String? ?? '',
      periodNumber: (json['periodNumber'] ?? json['period_number'] ?? 0) as int,
      amountMinor: (json['amountMinor'] ?? json['amount_minor'] ?? 0) as int,
      currency: json['currency'] as String? ?? 'EGP',
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : (json['recorded_at'] != null ? DateTime.parse(json['recorded_at'] as String) : DateTime.now()),
      journalEntryId: json['journalEntryId'] as String? ?? json['journal_entry_id'] as String?,
      idempotencyId: json['idempotencyId'] as String? ?? json['idempotency_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'contributionEventId': contributionEventId,
    'tenantId': tenantId,
    'memberUid': memberUid,
    'obligationId': obligationId,
    'allocationUnitId': allocationUnitId,
    'periodNumber': periodNumber,
    'amountMinor': amountMinor,
    'currency': currency,
    'recordedAt': recordedAt.toIso8601String(),
    if (journalEntryId != null) 'journalEntryId': journalEntryId,
    'idempotencyId': idempotencyId,
  };
}
