import 'package:flutter/material.dart';

/// Available payment rails for cooperative contributions.
class PaymentMethodItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAvailable;
  final bool isSandbox;
  final String? disabledReason;
  final String? badgeLabel;

  const PaymentMethodItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isAvailable = true,
    this.isSandbox = false,
    this.disabledReason,
    this.badgeLabel,
  });

  static List<PaymentMethodItem> get defaultMethods => [
        const PaymentMethodItem(
          id: 'pm-fednow-01',
          title: 'FedNow Instant Bank Transfer',
          subtitle: 'Chase Bank (****4821) • Instant RTGS Clearing',
          icon: Icons.account_balance,
          isAvailable: true,
          badgeLabel: 'RECOMMENDED',
        ),
        const PaymentMethodItem(
          id: 'pm-ach-02',
          title: 'ACH Direct Debit',
          subtitle: 'Chase Bank (****4821) • 1-2 Business Days Settlement',
          icon: Icons.sync_alt,
          isAvailable: true,
        ),
        const PaymentMethodItem(
          id: 'pm-sandbox-03',
          title: 'Sandbox Simulation Rail',
          subtitle: 'Instant Simulated Settlement • Real Funds Disabled',
          icon: Icons.developer_mode,
          isAvailable: true,
          isSandbox: true,
          badgeLabel: 'TEST ONLY',
        ),
        const PaymentMethodItem(
          id: 'pm-card-wire-04',
          title: 'Card / International Wire',
          subtitle: 'Requires KYC Tier 3 Verification',
          icon: Icons.credit_card,
          isAvailable: false,
          disabledReason: 'Pending KYC Tier 3 Review',
        ),
      ];
}

/// Detailed context for a single monthly contribution obligation.
class ContributionDetail {
  final int periodNumber;
  final String title;
  final int amountMinor; // Pure integer cents (e.g. 50000 = $500.00)
  final DateTime dueDate;
  final String status; // DUE, PAID, UPCOMING, OVERDUE
  final String cycleId;
  final String cycleName;
  final String memberId;
  final String memberName;
  final int slotPosition;
  final int totalSlots;
  final int totalContributedMinor;
  final int remainingCycleObligationMinor;
  final int totalCycleObligationMinor;

  const ContributionDetail({
    required this.periodNumber,
    required this.title,
    required this.amountMinor,
    required this.dueDate,
    required this.status,
    required this.cycleId,
    required this.cycleName,
    required this.memberId,
    required this.memberName,
    required this.slotPosition,
    required this.totalSlots,
    required this.totalContributedMinor,
    required this.remainingCycleObligationMinor,
    required this.totalCycleObligationMinor,
  });

  factory ContributionDetail.fromJson(Map<String, dynamic> json) {
    return ContributionDetail(
      periodNumber: (json['period_number'] as num?)?.toInt() ?? 2,
      title: json['title'] as String? ?? 'Period #2 Monthly Due',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 50000,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now().add(const Duration(days: 5)),
      status: json['status'] as String? ?? 'DUE',
      cycleId: json['cycle_id'] as String? ?? 'CYCLE-2026-LIVE-01',
      cycleName: json['cycle_name'] as String? ?? 'Rotating Pool Alpha-1',
      memberId: json['member_id'] as String? ?? 'usr-member-001',
      memberName: json['member_name'] as String? ?? 'Sarah Jenkins',
      slotPosition: (json['slot_position'] as num?)?.toInt() ?? 1,
      totalSlots: (json['total_slots'] as num?)?.toInt() ?? 10,
      totalContributedMinor: (json['total_contributed_minor'] as num?)?.toInt() ?? 50000,
      remainingCycleObligationMinor: (json['remaining_cycle_obligation_minor'] as num?)?.toInt() ?? 450000,
      totalCycleObligationMinor: (json['total_cycle_obligation_minor'] as num?)?.toInt() ?? 500000,
    );
  }

  Map<String, dynamic> toJson() => {
        'period_number': periodNumber,
        'title': title,
        'amount_minor': amountMinor,
        'due_date': dueDate.toIso8601String(),
        'status': status,
        'cycle_id': cycleId,
        'cycle_name': cycleName,
        'member_id': memberId,
        'member_name': memberName,
        'slot_position': slotPosition,
        'total_slots': totalSlots,
        'total_contributed_minor': totalContributedMinor,
        'remaining_cycle_obligation_minor': remainingCycleObligationMinor,
        'total_cycle_obligation_minor': totalCycleObligationMinor,
      };
}

/// Request payload for submitting a contribution payment.
class ContributionSubmissionRequest {
  final int periodNumber;
  final int amountMinor;
  final String paymentMethodId;
  final String cycleId;
  final String memberId;
  final String idempotencyKey;

  const ContributionSubmissionRequest({
    required this.periodNumber,
    required this.amountMinor,
    required this.paymentMethodId,
    required this.cycleId,
    required this.memberId,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() => {
        'period_number': periodNumber,
        'amount_minor': amountMinor,
        'payment_method_id': paymentMethodId,
        'cycle_id': cycleId,
        'member_id': memberId,
        'idempotency_key': idempotencyKey,
      };
}

/// Final outcome or receipt record after contribution submission.
class ContributionSubmissionResult {
  final String contributionId;
  final String status; // SETTLED, PENDING, FAILED
  final int amountMinor;
  final int periodNumber;
  final String cycleId;
  final DateTime settledAt;
  final String transactionReference;
  final String correlationId;
  final String ledgerJournalId;
  final String paymentRail;
  final String? errorMessage;

  const ContributionSubmissionResult({
    required this.contributionId,
    required this.status,
    required this.amountMinor,
    required this.periodNumber,
    required this.cycleId,
    required this.settledAt,
    required this.transactionReference,
    required this.correlationId,
    required this.ledgerJournalId,
    required this.paymentRail,
    this.errorMessage,
  });

  factory ContributionSubmissionResult.fromJson(Map<String, dynamic> json) {
    return ContributionSubmissionResult(
      contributionId: json['contribution_id'] as String? ?? 'CONTRIB-2026-PER2-8921',
      status: json['status'] as String? ?? 'SETTLED',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 50000,
      periodNumber: (json['period_number'] as num?)?.toInt() ?? 2,
      cycleId: json['cycle_id'] as String? ?? 'CYCLE-2026-LIVE-01',
      settledAt: json['settled_at'] != null
          ? DateTime.parse(json['settled_at'] as String)
          : DateTime.now(),
      transactionReference: json['transaction_reference'] as String? ?? 'PAY-RTGS-FEDNOW-002',
      correlationId: json['correlation_id'] as String? ?? 'corr-contrib-9812',
      ledgerJournalId: json['ledger_journal_id'] as String? ?? 'GL-JRNL-2026-002',
      paymentRail: json['payment_rail'] as String? ?? 'FedNow Instant Clearing',
      errorMessage: json['error_message'] as String?,
    );
  }
}
