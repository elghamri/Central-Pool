// Central Pool Payout Entitlement Model (Step 6/13)
// PROVENANCE & SEMANTIC DEFINITION:
// - Represents a member's mathematical disbursement rights derived from confirmed position.
// - Note: PayoutEntitlement != PayoutSettlement (REAL_MONEY_ENABLED = false).

class FinancialDisbursementSlotModel {
  final int periodNumber;
  final int amountMinor;
  final int basisPoints;
  final bool isCenter;

  const FinancialDisbursementSlotModel({
    required this.periodNumber,
    required this.amountMinor,
    required this.basisPoints,
    required this.isCenter,
  });

  factory FinancialDisbursementSlotModel.fromJson(Map<String, dynamic> json) {
    return FinancialDisbursementSlotModel(
      periodNumber: (json['periodNumber'] ?? json['period_number'] ?? 0) as int,
      amountMinor: (json['amountMinor'] ?? json['amount_minor'] ?? 0) as int,
      basisPoints: (json['basisPoints'] ?? json['basis_points'] ?? 0) as int,
      isCenter: (json['isCenter'] ?? json['is_center'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'periodNumber': periodNumber,
    'amountMinor': amountMinor,
    'basisPoints': basisPoints,
    'isCenter': isCenter,
  };
}

class PayoutEntitlementModel {
  final String payoutEntitlementId;
  final String tenantId;
  final String memberUid;
  final String allocationUnitId;
  final String allocationId;
  final int positionNumber;
  final int totalEntitlementMinor;
  final String currency;
  final List<FinancialDisbursementSlotModel> splits;
  final String status; // 'SCHEDULED'
  final DateTime calculatedAt;
  final int version;

  const PayoutEntitlementModel({
    required this.payoutEntitlementId,
    required this.tenantId,
    required this.memberUid,
    required this.allocationUnitId,
    required this.allocationId,
    required this.positionNumber,
    required this.totalEntitlementMinor,
    required this.currency,
    required this.splits,
    required this.status,
    required this.calculatedAt,
    required this.version,
  });

  factory PayoutEntitlementModel.fromJson(Map<String, dynamic> json) {
    final rawSplits = json['splits'] as List<dynamic>? ?? [];
    return PayoutEntitlementModel(
      payoutEntitlementId: json['payoutEntitlementId'] as String? ?? json['payout_entitlement_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      memberUid: json['memberUid'] as String? ?? json['member_uid'] as String? ?? json['memberId'] as String? ?? '',
      allocationUnitId: json['allocationUnitId'] as String? ?? json['allocation_unit_id'] as String? ?? '',
      allocationId: json['allocationId'] as String? ?? json['allocation_id'] as String? ?? '',
      positionNumber: (json['positionNumber'] ?? json['position_number'] ?? 0) as int,
      totalEntitlementMinor: (json['totalEntitlementMinor'] ?? json['total_entitlement_minor'] ?? 0) as int,
      currency: json['currency'] as String? ?? 'EGP',
      splits: rawSplits
          .map((s) => FinancialDisbursementSlotModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? 'SCHEDULED',
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.parse(json['calculatedAt'] as String)
          : (json['calculated_at'] != null ? DateTime.parse(json['calculated_at'] as String) : DateTime.now()),
      version: (json['version'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'payoutEntitlementId': payoutEntitlementId,
    'tenantId': tenantId,
    'memberUid': memberUid,
    'allocationUnitId': allocationUnitId,
    'allocationId': allocationId,
    'positionNumber': positionNumber,
    'totalEntitlementMinor': totalEntitlementMinor,
    'currency': currency,
    'splits': splits.map((s) => s.toJson()).toList(),
    'status': status,
    'calculatedAt': calculatedAt.toIso8601String(),
    'version': version,
  };
}
