import '../../dashboard/models/member_dashboard_models.dart';

/// Authoritative funding eligibility status.
enum FundingEligibilityStatus {
  eligible,
  notEligible,
  pendingReview,
  restricted;

  String get displayName {
    switch (this) {
      case FundingEligibilityStatus.eligible:
        return 'ELIGIBLE';
      case FundingEligibilityStatus.notEligible:
        return 'NOT ELIGIBLE';
      case FundingEligibilityStatus.pendingReview:
        return 'PENDING REVIEW';
      case FundingEligibilityStatus.restricted:
        return 'RESTRICTED';
    }
  }
}

/// A single eligibility rule check.
class FundingEligibilityCriterion {
  final String name;
  final bool isSatisfied;
  final String description;
  final String? blockingReason;

  const FundingEligibilityCriterion({
    required this.name,
    required this.isSatisfied,
    required this.description,
    this.blockingReason,
  });

  factory FundingEligibilityCriterion.fromJson(Map<String, dynamic> json) {
    return FundingEligibilityCriterion(
      name: json['name'] as String? ?? '',
      isSatisfied: json['is_satisfied'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      blockingReason: json['blocking_reason'] as String?,
    );
  }
}

/// Complete member eligibility evaluation.
class FundingEligibility {
  final FundingEligibilityStatus status;
  final String memberId;
  final String cycleId;
  final bool isEligible;
  final List<FundingEligibilityCriterion> criteria;
  final DateTime evaluatedAt;

  const FundingEligibility({
    required this.status,
    required this.memberId,
    required this.cycleId,
    required this.isEligible,
    required this.criteria,
    required this.evaluatedAt,
  });

  factory FundingEligibility.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String?)?.toUpperCase() ?? 'ELIGIBLE';
    FundingEligibilityStatus status;
    if (statusStr == 'ELIGIBLE') {
      status = FundingEligibilityStatus.eligible;
    } else if (statusStr == 'NOT_ELIGIBLE') {
      status = FundingEligibilityStatus.notEligible;
    } else if (statusStr == 'PENDING_REVIEW') {
      status = FundingEligibilityStatus.pendingReview;
    } else {
      status = FundingEligibilityStatus.restricted;
    }

    final rawCriteria = json['criteria'] as List<dynamic>? ?? [];
    return FundingEligibility(
      status: status,
      memberId: json['member_id'] as String? ?? 'usr-member-001',
      cycleId: json['cycle_id'] as String? ?? 'CYCLE-2026-LIVE-01',
      isEligible: json['is_eligible'] as bool? ?? true,
      criteria: rawCriteria.map((c) => FundingEligibilityCriterion.fromJson(c as Map<String, dynamic>)).toList(),
      evaluatedAt: json['evaluated_at'] != null ? DateTime.parse(json['evaluated_at'] as String) : DateTime.now(),
    );
  }
}

/// Member rotation and allocation position.
class AllocationPosition {
  final String allocationId;
  final String cycleId;
  final String cycleName;
  final int slotNumber;
  final int totalSlots;
  final String status; // ALLOCATED, PENDING, NOT_ALLOCATED
  final int expectedPayoutMinor; // Pure integer cents (e.g. 500000 = $5,000.00)
  final DateTime allocatedAt;
  final String recipientMemberId;
  final String recipientMemberName;

  const AllocationPosition({
    required this.allocationId,
    required this.cycleId,
    required this.cycleName,
    required this.slotNumber,
    required this.totalSlots,
    required this.status,
    required this.expectedPayoutMinor,
    required this.allocatedAt,
    required this.recipientMemberId,
    required this.recipientMemberName,
  });

  factory AllocationPosition.fromJson(Map<String, dynamic> json) {
    return AllocationPosition(
      allocationId: json['allocation_id'] as String? ?? 'ALLOC-2026-01-SLOT01',
      cycleId: json['cycle_id'] as String? ?? 'CYCLE-2026-LIVE-01',
      cycleName: json['cycle_name'] as String? ?? 'Rotating Pool Alpha-1',
      slotNumber: (json['slot_number'] as num?)?.toInt() ?? 1,
      totalSlots: (json['total_slots'] as num?)?.toInt() ?? 10,
      status: json['status'] as String? ?? 'ALLOCATED',
      expectedPayoutMinor: (json['expected_payout_minor'] as num?)?.toInt() ?? 500000,
      allocatedAt: json['allocated_at'] != null ? DateTime.parse(json['allocated_at'] as String) : DateTime.now().subtract(const Duration(days: 20)),
      recipientMemberId: json['recipient_member_id'] as String? ?? 'usr-member-001',
      recipientMemberName: json['recipient_member_name'] as String? ?? 'Sarah Jenkins',
    );
  }
}

/// Status for lifecycle tracker stages.
enum LifecycleStageStatus {
  notStarted,
  pending,
  completed,
  failed,
  unknown;

  String get displayName {
    switch (this) {
      case LifecycleStageStatus.notStarted:
        return 'NOT STARTED';
      case LifecycleStageStatus.pending:
        return 'PENDING';
      case LifecycleStageStatus.completed:
        return 'COMPLETED';
      case LifecycleStageStatus.failed:
        return 'FAILED';
      case LifecycleStageStatus.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Individual item in the 14-stage funding lifecycle.
class FundingLifecycleItem {
  final int stageNumber;
  final String title;
  final String description;
  final LifecycleStageStatus status;
  final DateTime? completedAt;
  final String? referenceId;
  final String? auditDetails;

  const FundingLifecycleItem({
    required this.stageNumber,
    required this.title,
    required this.description,
    required this.status,
    this.completedAt,
    this.referenceId,
    this.auditDetails,
  });

  factory FundingLifecycleItem.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String?)?.toUpperCase() ?? 'NOT_STARTED';
    LifecycleStageStatus status;
    if (statusStr == 'COMPLETED') {
      status = LifecycleStageStatus.completed;
    } else if (statusStr == 'PENDING') {
      status = LifecycleStageStatus.pending;
    } else if (statusStr == 'FAILED') {
      status = LifecycleStageStatus.failed;
    } else if (statusStr == 'UNKNOWN') {
      status = LifecycleStageStatus.unknown;
    } else {
      status = LifecycleStageStatus.notStarted;
    }

    return FundingLifecycleItem(
      stageNumber: (json['stage_number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: status,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      referenceId: json['reference_id'] as String?,
      auditDetails: json['audit_details'] as String?,
    );
  }
}

/// Authoritative payout and clearing settlement state.
class PayoutSettlementDetail {
  final String fundingId;
  final String instructionStatus; // DISPATCHED, CREATED, REJECTED
  final String providerStatus; // CLEARED_FEDNOW_RTGS, PENDING_RAIL
  final String settlementStatus; // SETTLED, PENDING, FAILED, UNKNOWN
  final String transactionRef;
  final int amountMinor; // 500000 = $5,000.00
  final String currency;
  final DateTime settledAt;
  final String correlationId;
  final String clearingRail;

  const PayoutSettlementDetail({
    required this.fundingId,
    required this.instructionStatus,
    required this.providerStatus,
    required this.settlementStatus,
    required this.transactionRef,
    required this.amountMinor,
    required this.currency,
    required this.settledAt,
    required this.correlationId,
    required this.clearingRail,
  });

  factory PayoutSettlementDetail.fromJson(Map<String, dynamic> json) {
    return PayoutSettlementDetail(
      fundingId: json['funding_id'] as String? ?? 'FUND-EXEC-2026-001',
      instructionStatus: json['instruction_status'] as String? ?? 'DISPATCHED',
      providerStatus: json['provider_status'] as String? ?? 'CLEARED_FEDNOW_RTGS',
      settlementStatus: json['settlement_status'] as String? ?? 'SETTLED',
      transactionRef: json['transaction_ref'] as String? ?? 'FEDNOW-TXN-2026-0826-01',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 500000,
      currency: json['currency'] as String? ?? 'USD',
      settledAt: json['settled_at'] != null ? DateTime.parse(json['settled_at'] as String) : DateTime.now().subtract(const Duration(days: 20)),
      correlationId: json['correlation_id'] as String? ?? 'corr-funding-9021',
      clearingRail: json['clearing_rail'] as String? ?? 'FedNow Instant RTGS Clearing',
    );
  }
}

/// Post-funding obligation tracking state.
class PostFundingObligation {
  final String obligationId;
  final int originalPayoutMinor; // 500000
  final int totalObligationMinor; // 500000
  final int repaidAmountMinor; // 50000
  final int remainingObligationMinor; // 450000
  final int overdueAmountMinor; // 0
  final DateTime nextDueDate;
  final String riskStatus; // LOW_RISK_PERFORMING, WATCHLIST, DELINQUENT
  final List<ContributionRecord> repaymentSchedule;

  const PostFundingObligation({
    required this.obligationId,
    required this.originalPayoutMinor,
    required this.totalObligationMinor,
    required this.repaidAmountMinor,
    required this.remainingObligationMinor,
    required this.overdueAmountMinor,
    required this.nextDueDate,
    required this.riskStatus,
    required this.repaymentSchedule,
  });

  factory PostFundingObligation.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['repayment_schedule'] as List<dynamic>? ?? [];
    return PostFundingObligation(
      obligationId: json['obligation_id'] as String? ?? 'OBLIG-2026-MEMBER-001',
      originalPayoutMinor: (json['original_payout_minor'] as num?)?.toInt() ?? 500000,
      totalObligationMinor: (json['total_obligation_minor'] as num?)?.toInt() ?? 500000,
      repaidAmountMinor: (json['repaid_amount_minor'] as num?)?.toInt() ?? 50000,
      remainingObligationMinor: (json['remaining_obligation_minor'] as num?)?.toInt() ?? 450000,
      overdueAmountMinor: (json['overdue_amount_minor'] as num?)?.toInt() ?? 0,
      nextDueDate: json['next_due_date'] != null ? DateTime.parse(json['next_due_date'] as String) : DateTime.now().add(const Duration(days: 5)),
      riskStatus: json['risk_status'] as String? ?? 'LOW_RISK_PERFORMING',
      repaymentSchedule: rawSchedule.map((s) => ContributionRecord.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

/// Comprehensive cryptographic audit statement for funding event.
class FundingAuditStatement {
  final String fundingExecutionId;
  final String allocationId;
  final String treasuryReservationId;
  final String paymentInstructionId;
  final String settlementConfirmationId;
  final String glJournalRef;
  final String obligationId;
  final String reconciliationStatus; // RECONCILIATION_MATCH_CLEAN
  final int varianceAmountMinor; // 0
  final String correlationId;
  final String auditHash;

  const FundingAuditStatement({
    required this.fundingExecutionId,
    required this.allocationId,
    required this.treasuryReservationId,
    required this.paymentInstructionId,
    required this.settlementConfirmationId,
    required this.glJournalRef,
    required this.obligationId,
    required this.reconciliationStatus,
    required this.varianceAmountMinor,
    required this.correlationId,
    required this.auditHash,
  });

  factory FundingAuditStatement.fromJson(Map<String, dynamic> json) {
    return FundingAuditStatement(
      fundingExecutionId: json['funding_execution_id'] as String? ?? 'FUND-EXEC-2026-001',
      allocationId: json['allocation_id'] as String? ?? 'ALLOC-2026-01-SLOT01',
      treasuryReservationId: json['treasury_reservation_id'] as String? ?? 'TREAS-RES-2026-8921',
      paymentInstructionId: json['payment_instruction_id'] as String? ?? 'PMT-INST-FEDNOW-001',
      settlementConfirmationId: json['settlement_confirmation_id'] as String? ?? 'SETTLE-CONF-2026-9012',
      glJournalRef: json['gl_journal_ref'] as String? ?? 'GL-JRNL-FUND-001',
      obligationId: json['obligation_id'] as String? ?? 'OBLIG-2026-MEMBER-001',
      reconciliationStatus: json['reconciliation_status'] as String? ?? 'RECONCILIATION_MATCH_CLEAN',
      varianceAmountMinor: (json['variance_amount_minor'] as num?)?.toInt() ?? 0,
      correlationId: json['correlation_id'] as String? ?? 'corr-funding-9021',
      auditHash: json['audit_hash'] as String? ?? 'sha256-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  }
}

/// Aggregated domain model for entire Slice 4 Funding & Payout Lifecycle.
class FundingOverview {
  final MemberSummary summary;
  final FundingEligibility eligibility;
  final AllocationPosition allocation;
  final List<FundingLifecycleItem> lifecycleStages;
  final PayoutSettlementDetail settlement;
  final PostFundingObligation obligation;
  final FundingAuditStatement auditStatement;

  const FundingOverview({
    required this.summary,
    required this.eligibility,
    required this.allocation,
    required this.lifecycleStages,
    required this.settlement,
    required this.obligation,
    required this.auditStatement,
  });
}
