import 'package:flutter/foundation.dart';
import '../models/ops_models.dart';

/// Sealed state hierarchy for Operations Console & Maker-Checker workflows.
@immutable
sealed class OpsState {
  const OpsState();
}

/// Initial loading state when fetching queue telemetry.
class OpsLoading extends OpsState {
  const OpsLoading();
}

/// Fully loaded operations console state with active queue data and filters.
class OpsLoaded extends OpsState {
  final List<OpsPaymentItem> payments;
  final List<OpsMakerQueueItem> makerQueue;
  final List<OpsCheckerQueueItem> checkerQueue;
  final List<OpsDlqRecord> dlqRecords;
  final List<OpsReconciliationAuditItem> reconciliations;
  
  // Selected inspection objects
  final OpsPaymentItem? selectedPayment;
  final OpsMakerQueueItem? selectedMakerItem;
  final OpsCheckerQueueItem? selectedCheckerItem;
  final OpsDlqRecord? selectedDlqRecord;
  final OpsReconciliationAuditItem? selectedReconciliation;

  // Active filter and tab parameters
  final int activeTab; // 0: Payments, 1: Maker, 2: Checker, 3: DLQ, 4: Reconciliation
  final String searchQuery;
  final String railFilter; // 'ALL', 'FEDNOW', 'RTP', 'ACH', 'STRIPE'
  final String statusFilter; // 'ALL', 'PENDING', 'PROCESSING', 'DISPATCHED', 'SETTLED', 'UNKNOWN', 'FAILED'
  
  // Async submission feedback
  final bool isSubmittingAction;
  final String? actionFeedbackMessage;
  final bool isActionFeedbackSuccess;

  const OpsLoaded({
    required this.payments,
    required this.makerQueue,
    required this.checkerQueue,
    required this.dlqRecords,
    required this.reconciliations,
    this.selectedPayment,
    this.selectedMakerItem,
    this.selectedCheckerItem,
    this.selectedDlqRecord,
    this.selectedReconciliation,
    this.activeTab = 0,
    this.searchQuery = '',
    this.railFilter = 'ALL',
    this.statusFilter = 'ALL',
    this.isSubmittingAction = false,
    this.actionFeedbackMessage,
    this.isActionFeedbackSuccess = true,
  });

  /// Filtered payment items based on active search and chip criteria.
  List<OpsPaymentItem> get filteredPayments {
    return payments.where((p) {
      final matchesSearch = searchQuery.isEmpty ||
          p.paymentId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.recipientName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.correlationId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.instructionId.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesRail = railFilter == 'ALL' ||
          p.paymentRail.name.toUpperCase() == railFilter.toUpperCase();

      final matchesStatus = statusFilter == 'ALL' ||
          p.status.toUpperCase() == statusFilter.toUpperCase();

      return matchesSearch && matchesRail && matchesStatus;
    }).toList();
  }

  /// Filtered Maker Queue items.
  List<OpsMakerQueueItem> get filteredMakerQueue {
    return makerQueue.where((item) {
      if (searchQuery.isEmpty) return true;
      return item.queueId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.memberName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.cycleName.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  /// Filtered Checker Queue items.
  List<OpsCheckerQueueItem> get filteredCheckerQueue {
    return checkerQueue.where((item) {
      if (searchQuery.isEmpty) return true;
      return item.queueId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.memberName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.makerName.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  /// Filtered DLQ Records.
  List<OpsDlqRecord> get filteredDlqRecords {
    return dlqRecords.where((item) {
      if (searchQuery.isEmpty) return true;
      return item.dlqId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.eventType.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.correlationId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.errorMessage.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  OpsLoaded copyWith({
    List<OpsPaymentItem>? payments,
    List<OpsMakerQueueItem>? makerQueue,
    List<OpsCheckerQueueItem>? checkerQueue,
    List<OpsDlqRecord>? dlqRecords,
    List<OpsReconciliationAuditItem>? reconciliations,
    OpsPaymentItem? Function()? selectedPayment,
    OpsMakerQueueItem? Function()? selectedMakerItem,
    OpsCheckerQueueItem? Function()? selectedCheckerItem,
    OpsDlqRecord? Function()? selectedDlqRecord,
    OpsReconciliationAuditItem? Function()? selectedReconciliation,
    int? activeTab,
    String? searchQuery,
    String? railFilter,
    String? statusFilter,
    bool? isSubmittingAction,
    String? Function()? actionFeedbackMessage,
    bool? isActionFeedbackSuccess,
  }) {
    return OpsLoaded(
      payments: payments ?? this.payments,
      makerQueue: makerQueue ?? this.makerQueue,
      checkerQueue: checkerQueue ?? this.checkerQueue,
      dlqRecords: dlqRecords ?? this.dlqRecords,
      reconciliations: reconciliations ?? this.reconciliations,
      selectedPayment: selectedPayment != null ? selectedPayment() : this.selectedPayment,
      selectedMakerItem: selectedMakerItem != null ? selectedMakerItem() : this.selectedMakerItem,
      selectedCheckerItem: selectedCheckerItem != null ? selectedCheckerItem() : this.selectedCheckerItem,
      selectedDlqRecord: selectedDlqRecord != null ? selectedDlqRecord() : this.selectedDlqRecord,
      selectedReconciliation: selectedReconciliation != null ? selectedReconciliation() : this.selectedReconciliation,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      railFilter: railFilter ?? this.railFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      actionFeedbackMessage: actionFeedbackMessage != null ? actionFeedbackMessage() : this.actionFeedbackMessage,
      isActionFeedbackSuccess: isActionFeedbackSuccess ?? this.isActionFeedbackSuccess,
    );
  }
}

/// Error state when network/server encounters an unrecoverable failure.
class OpsError extends OpsState {
  final String errorMessage;
  final String correlationId;

  const OpsError({
    required this.errorMessage,
    required this.correlationId,
  });
}
