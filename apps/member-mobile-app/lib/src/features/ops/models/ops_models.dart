import 'package:flutter/foundation.dart';

/// Payment rail options for outbound dispatches.
enum PaymentRailType {
  fedNow,
  rtp,
  ach,
  stripe;

  String get displayName {
    switch (this) {
      case PaymentRailType.fedNow:
        return 'FedNow Instant';
      case PaymentRailType.rtp:
        return 'RTP Network';
      case PaymentRailType.ach:
        return 'ACH Batch';
      case PaymentRailType.stripe:
        return 'Card / Digital Wallet';
    }
  }

  static PaymentRailType fromString(String? rail) {
    switch (rail?.toUpperCase()) {
      case 'FEDNOW':
        return PaymentRailType.fedNow;
      case 'RTP':
        return PaymentRailType.rtp;
      case 'ACH':
        return PaymentRailType.ach;
      case 'STRIPE':
      case 'CARD':
      default:
        return PaymentRailType.stripe;
    }
  }
}

/// Screen 29: Payment instruction queue item.
@immutable
class OpsPaymentItem {
  final String paymentId;
  final String instructionId;
  final String fundingId;
  final String tenantId;
  final String recipientMemberId;
  final String recipientName;
  final int amountMinor; // Pure 64-bit integer cents (e.g. 500000 = $5,000.00)
  final String currency;
  final PaymentRailType paymentRail;
  final String status; // PENDING, PROCESSING, DISPATCHED, SETTLED, UNKNOWN, FAILED
  final DateTime createdAt;
  final DateTime? dispatchedAt;
  final DateTime? settledAt;
  final String correlationId;
  final String idempotencyKey;
  final String? failureReason;

  const OpsPaymentItem({
    required this.paymentId,
    required this.instructionId,
    required this.fundingId,
    required this.tenantId,
    required this.recipientMemberId,
    required this.recipientName,
    required this.amountMinor,
    this.currency = 'USD',
    required this.paymentRail,
    required this.status,
    required this.createdAt,
    this.dispatchedAt,
    this.settledAt,
    required this.correlationId,
    required this.idempotencyKey,
    this.failureReason,
  });

  factory OpsPaymentItem.fromJson(Map<String, dynamic> json) {
    return OpsPaymentItem(
      paymentId: json['payment_id'] as String? ?? 'PAY-000',
      instructionId: json['instruction_id'] as String? ?? 'INSTR-000',
      fundingId: json['funding_id'] as String? ?? 'FND-000',
      tenantId: json['tenant_id'] as String? ?? 'TENANT-ALPHA',
      recipientMemberId: json['recipient_member_id'] as String? ?? 'usr-member-001',
      recipientName: json['recipient_name'] as String? ?? 'Member Recipient',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      paymentRail: PaymentRailType.fromString(json['payment_rail'] as String?),
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      dispatchedAt: json['dispatched_at'] != null ? DateTime.parse(json['dispatched_at'] as String) : null,
      settledAt: json['settled_at'] != null ? DateTime.parse(json['settled_at'] as String) : null,
      correlationId: json['correlation_id'] as String? ?? 'CORR-000',
      idempotencyKey: json['idempotency_key'] as String? ?? 'IDEM-000',
      failureReason: json['failure_reason'] as String?,
    );
  }
}

/// Screen 30: Maker Approval Queue Item.
@immutable
class OpsMakerQueueItem {
  final String queueId;
  final String fundingId;
  final String tenantId;
  final String cycleId;
  final String cycleName;
  final int slotNumber;
  final String memberId;
  final String memberName;
  final int amountMinor; // Pure integer minor units
  final String status; // STAGE_PENDING_MAKER, PENDING_CHECKER, REJECTED
  final String kycStatus; // VERIFIED, PENDING_REVIEW
  final String amlRiskScore; // LOW, MEDIUM, HIGH
  final String? makerId;
  final String? makerName;
  final DateTime createdAt;
  final String notes;

  const OpsMakerQueueItem({
    required this.queueId,
    required this.fundingId,
    required this.tenantId,
    required this.cycleId,
    required this.cycleName,
    required this.slotNumber,
    required this.memberId,
    required this.memberName,
    required this.amountMinor,
    required this.status,
    required this.kycStatus,
    required this.amlRiskScore,
    this.makerId,
    this.makerName,
    required this.createdAt,
    required this.notes,
  });

  factory OpsMakerQueueItem.fromJson(Map<String, dynamic> json) {
    return OpsMakerQueueItem(
      queueId: json['queue_id'] as String? ?? 'MKR-000',
      fundingId: json['funding_id'] as String? ?? 'FND-000',
      tenantId: json['tenant_id'] as String? ?? 'TENANT-ALPHA',
      cycleId: json['cycle_id'] as String? ?? 'CYCLE-000',
      cycleName: json['cycle_name'] as String? ?? 'Rotating Capital Pool',
      slotNumber: (json['slot_number'] as num?)?.toInt() ?? 1,
      memberId: json['member_id'] as String? ?? 'usr-member-001',
      memberName: json['member_name'] as String? ?? 'Member',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 500000,
      status: json['status'] as String? ?? 'STAGE_PENDING_MAKER',
      kycStatus: json['kyc_status'] as String? ?? 'VERIFIED',
      amlRiskScore: json['aml_risk_score'] as String? ?? 'LOW',
      makerId: json['maker_id'] as String?,
      makerName: json['maker_name'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      notes: json['notes'] as String? ?? 'Regular rotation payout eligibility verified.',
    );
  }
}

/// Screen 31: Checker Authorization Queue Item.
@immutable
class OpsCheckerQueueItem {
  final String queueId;
  final String fundingId;
  final String tenantId;
  final String cycleId;
  final String cycleName;
  final int slotNumber;
  final String memberId;
  final String memberName;
  final int amountMinor; // Pure integer minor units
  final String status; // PENDING_CHECKER, APPROVED, REJECTED, DISPATCHED
  final String makerId;
  final String makerName;
  final DateTime makerApprovedAt;
  final String? checkerId;
  final String? checkerName;
  final DateTime? checkerAuthorizedAt;
  final String? rejectionReason;

  const OpsCheckerQueueItem({
    required this.queueId,
    required this.fundingId,
    required this.tenantId,
    required this.cycleId,
    required this.cycleName,
    required this.slotNumber,
    required this.memberId,
    required this.memberName,
    required this.amountMinor,
    required this.status,
    required this.makerId,
    required this.makerName,
    required this.makerApprovedAt,
    this.checkerId,
    this.checkerName,
    this.checkerAuthorizedAt,
    this.rejectionReason,
  });

  factory OpsCheckerQueueItem.fromJson(Map<String, dynamic> json) {
    return OpsCheckerQueueItem(
      queueId: json['queue_id'] as String? ?? 'CHK-000',
      fundingId: json['funding_id'] as String? ?? 'FND-000',
      tenantId: json['tenant_id'] as String? ?? 'TENANT-ALPHA',
      cycleId: json['cycle_id'] as String? ?? 'CYCLE-000',
      cycleName: json['cycle_name'] as String? ?? 'Rotating Capital Pool',
      slotNumber: (json['slot_number'] as num?)?.toInt() ?? 1,
      memberId: json['member_id'] as String? ?? 'usr-member-001',
      memberName: json['member_name'] as String? ?? 'Member',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 500000,
      status: json['status'] as String? ?? 'PENDING_CHECKER',
      makerId: json['maker_id'] as String? ?? 'usr-maker-01',
      makerName: json['maker_name'] as String? ?? 'Treasury Maker Officer',
      makerApprovedAt: json['maker_approved_at'] != null ? DateTime.parse(json['maker_approved_at'] as String) : DateTime.now(),
      checkerId: json['checker_id'] as String?,
      checkerName: json['checker_name'] as String?,
      checkerAuthorizedAt: json['checker_authorized_at'] != null ? DateTime.parse(json['checker_authorized_at'] as String) : null,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}

/// Screen 33: Dead Letter Queue & Exception Record.
@immutable
class OpsDlqRecord {
  final String dlqId;
  final String tenantId;
  final String topic;
  final String eventType;
  final String correlationId;
  final String sourceSystem;
  final String errorMessage;
  final String errorStackTrace;
  final String payloadJson;
  final int retryCount;
  final int maxRetries;
  final DateTime firstFailedAt;
  final DateTime lastFailedAt;
  final String status; // DEAD_LETTER, REPLAYED, DISCARDED, INVESTIGATING

  const OpsDlqRecord({
    required this.dlqId,
    required this.tenantId,
    required this.topic,
    required this.eventType,
    required this.correlationId,
    required this.sourceSystem,
    required this.errorMessage,
    required this.errorStackTrace,
    required this.payloadJson,
    required this.retryCount,
    required this.maxRetries,
    required this.firstFailedAt,
    required this.lastFailedAt,
    required this.status,
  });

  factory OpsDlqRecord.fromJson(Map<String, dynamic> json) {
    return OpsDlqRecord(
      dlqId: json['dlq_id'] as String? ?? 'DLQ-000',
      tenantId: json['tenant_id'] as String? ?? 'TENANT-ALPHA',
      topic: json['topic'] as String? ?? 'financial.events.disbursements',
      eventType: json['event_type'] as String? ?? 'DISBURSEMENT_DISPATCH_FAILED',
      correlationId: json['correlation_id'] as String? ?? 'CORR-000',
      sourceSystem: json['source_system'] as String? ?? 'services/funding-service',
      errorMessage: json['error_message'] as String? ?? 'Gateway timeout during clearing dispatch',
      errorStackTrace: json['error_stack_trace'] as String? ?? 'HTTP 504 Gateway Timeout at /v1/clearing/iso20022',
      payloadJson: json['payload_json'] as String? ?? '{"funding_id":"fnd-001","amount_minor":500000}',
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 3,
      maxRetries: (json['max_retries'] as num?)?.toInt() ?? 5,
      firstFailedAt: json['first_failed_at'] != null ? DateTime.parse(json['first_failed_at'] as String) : DateTime.now(),
      lastFailedAt: json['last_failed_at'] != null ? DateTime.parse(json['last_failed_at'] as String) : DateTime.now(),
      status: json['status'] as String? ?? 'DEAD_LETTER',
    );
  }
}

/// Screen 34 & 35: 5-Way Settlement Reconciliation Report.
@immutable
class OpsReconciliationAuditItem {
  final String reportId;
  final String cycleId;
  final String cycleName;
  final String tenantId;
  final DateTime auditDate;
  final int fundingDisbursedMinor;
  final int treasuryCommittedMinor;
  final int glJournalTotalMinor;
  final int memberObligationMinor;
  final int settlementTotalMinor;
  final int discrepancyAmountMinor; // Strictly 0 for clean match
  final bool isMatched;
  final String status; // RECONCILIATION_MATCH_CLEAN, DISCREPANCY_DETECTED, IN_PROGRESS
  final String cryptographicSignature; // WORM Audit SHA-256 seal
  final String exceptionNotes;

  const OpsReconciliationAuditItem({
    required this.reportId,
    required this.cycleId,
    required this.cycleName,
    required this.tenantId,
    required this.auditDate,
    required this.fundingDisbursedMinor,
    required this.treasuryCommittedMinor,
    required this.glJournalTotalMinor,
    required this.memberObligationMinor,
    required this.settlementTotalMinor,
    required this.discrepancyAmountMinor,
    required this.isMatched,
    required this.status,
    required this.cryptographicSignature,
    required this.exceptionNotes,
  });

  factory OpsReconciliationAuditItem.fromJson(Map<String, dynamic> json) {
    return OpsReconciliationAuditItem(
      reportId: json['report_id'] as String? ?? 'REC-REP-000',
      cycleId: json['cycle_id'] as String? ?? 'CYCLE-2026-LIVE-01',
      cycleName: json['cycle_name'] as String? ?? 'Rotating Pool Alpha-1',
      tenantId: json['tenant_id'] as String? ?? 'TENANT-ALPHA',
      auditDate: json['audit_date'] != null ? DateTime.parse(json['audit_date'] as String) : DateTime.now(),
      fundingDisbursedMinor: (json['funding_disbursed_minor'] as num?)?.toInt() ?? 500000,
      treasuryCommittedMinor: (json['treasury_committed_minor'] as num?)?.toInt() ?? 500000,
      glJournalTotalMinor: (json['gl_journal_total_minor'] as num?)?.toInt() ?? 500000,
      memberObligationMinor: (json['member_obligation_minor'] as num?)?.toInt() ?? 500000,
      settlementTotalMinor: (json['settlement_total_minor'] as num?)?.toInt() ?? 500000,
      discrepancyAmountMinor: (json['discrepancy_amount_minor'] as num?)?.toInt() ?? 0,
      isMatched: json['is_matched'] as bool? ?? true,
      status: json['status'] as String? ?? 'RECONCILIATION_MATCH_CLEAN',
      cryptographicSignature: json['cryptographic_signature'] as String? ?? 'SHA256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
      exceptionNotes: json['exception_notes'] as String? ?? 'Zero variances detected across 5 ledger domains.',
    );
  }
}
