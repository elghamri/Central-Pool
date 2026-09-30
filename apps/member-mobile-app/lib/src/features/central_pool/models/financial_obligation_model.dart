// Central Pool Financial Obligation Model (Step 6/13)
// PROVENANCE & SEMANTIC DEFINITION:
// - Meaning A: Internal simulation/accounting expected contribution obligation.
// - NOT legal liability, custody, external debt, or real-money settlement (FM-02 unresolved).

class FinancialObligationModel {
  final String obligationId;
  final String tenantId;
  final String memberUid;
  final String allocationUnitId;
  final String allocationId;
  final int positionNumber;
  final int totalObligationMinor;
  final int contributionMinor;
  final int totalPeriods;
  final int fulfilledAmountMinor;
  final String currency;
  final String status; // 'ACTIVE' | 'FULFILLED'
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const FinancialObligationModel({
    required this.obligationId,
    required this.tenantId,
    required this.memberUid,
    required this.allocationUnitId,
    required this.allocationId,
    required this.positionNumber,
    required this.totalObligationMinor,
    required this.contributionMinor,
    required this.totalPeriods,
    required this.fulfilledAmountMinor,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory FinancialObligationModel.fromJson(Map<String, dynamic> json) {
    return FinancialObligationModel(
      obligationId: json['obligationId'] as String? ?? json['obligation_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      memberUid: json['memberUid'] as String? ?? json['member_uid'] as String? ?? json['memberId'] as String? ?? '',
      allocationUnitId: json['allocationUnitId'] as String? ?? json['allocation_unit_id'] as String? ?? '',
      allocationId: json['allocationId'] as String? ?? json['allocation_id'] as String? ?? '',
      positionNumber: (json['positionNumber'] ?? json['position_number'] ?? 0) as int,
      totalObligationMinor: (json['totalObligationMinor'] ?? json['total_obligation_minor'] ?? 0) as int,
      contributionMinor: (json['contributionMinor'] ?? json['contribution_minor'] ?? 0) as int,
      totalPeriods: (json['totalPeriods'] ?? json['total_periods'] ?? 0) as int,
      fulfilledAmountMinor: (json['fulfilledAmountMinor'] ?? json['fulfilled_amount_minor'] ?? 0) as int,
      currency: json['currency'] as String? ?? 'EGP',
      status: json['status'] as String? ?? 'ACTIVE',
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
    'obligationId': obligationId,
    'tenantId': tenantId,
    'memberUid': memberUid,
    'allocationUnitId': allocationUnitId,
    'allocationId': allocationId,
    'positionNumber': positionNumber,
    'totalObligationMinor': totalObligationMinor,
    'contributionMinor': contributionMinor,
    'totalPeriods': totalPeriods,
    'fulfilledAmountMinor': fulfilledAmountMinor,
    'currency': currency,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'version': version,
  };
}
