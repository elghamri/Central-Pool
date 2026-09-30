import '../../dashboard/models/member_dashboard_models.dart';
import '../models/contribution_models.dart';

/// Sealed state hierarchy for Member Monthly Contribution Flow.
abstract class ContributionState {
  const ContributionState();
}

/// Initial or active loading state.
class ContributionOverviewLoading extends ContributionState {
  final String message;

  const ContributionOverviewLoading({this.message = 'Loading contribution schedule & dues...'});
}

/// Fully populated overview with active due and history.
class ContributionOverviewLoaded extends ContributionState {
  final ContributionDetail activeDue;
  final List<ContributionRecord> history;
  final MemberSummary summary;
  final PaymentMethodItem selectedPaymentMethod;
  final List<PaymentMethodItem> paymentMethods;
  final bool isSubmitting;
  final int currentStep; // 0 = Overview, 1 = Details, 2 = Payment Method, 3 = Confirmation

  const ContributionOverviewLoaded({
    required this.activeDue,
    required this.history,
    required this.summary,
    required this.selectedPaymentMethod,
    required this.paymentMethods,
    this.isSubmitting = false,
    this.currentStep = 0,
  });

  ContributionOverviewLoaded copyWith({
    ContributionDetail? activeDue,
    List<ContributionRecord>? history,
    MemberSummary? summary,
    PaymentMethodItem? selectedPaymentMethod,
    List<PaymentMethodItem>? paymentMethods,
    bool? isSubmitting,
    int? currentStep,
  }) {
    return ContributionOverviewLoaded(
      activeDue: activeDue ?? this.activeDue,
      history: history ?? this.history,
      summary: summary ?? this.summary,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// Active in-flight processing state.
class ContributionProcessing extends ContributionState {
  final String stepMessage;
  final String idempotencyKey;
  final ContributionDetail detail;
  final PaymentMethodItem paymentMethod;

  const ContributionProcessing({
    required this.stepMessage,
    required this.idempotencyKey,
    required this.detail,
    required this.paymentMethod,
  });
}

/// Authoritative settlement success.
class ContributionSuccess extends ContributionState {
  final ContributionSubmissionResult result;
  final ContributionDetail detail;

  const ContributionSuccess({
    required this.result,
    required this.detail,
  });
}

/// Asynchronous settlement pending (e.g. ACH clearing).
class ContributionPending extends ContributionState {
  final ContributionSubmissionResult result;
  final ContributionDetail detail;

  const ContributionPending({
    required this.result,
    required this.detail,
  });
}

/// Payment execution failure with recovery path.
class ContributionFailed extends ContributionState {
  final String errorMessage;
  final String? errorCode;
  final ContributionDetail detail;
  final PaymentMethodItem paymentMethod;

  const ContributionFailed({
    required this.errorMessage,
    this.errorCode,
    required this.detail,
    required this.paymentMethod,
  });
}

/// Network or clearing timeout (strictly NOT success).
class ContributionTimeout extends ContributionState {
  final String message;
  final String correlationId;
  final ContributionDetail detail;
  final PaymentMethodItem paymentMethod;

  const ContributionTimeout({
    required this.message,
    required this.correlationId,
    required this.detail,
    required this.paymentMethod,
  });
}

/// Error state when initial schedule or profile cannot be loaded.
class ContributionOverviewError extends ContributionState {
  final String errorMessage;
  final String? correlationId;
  final bool isRetryable;

  const ContributionOverviewError({
    required this.errorMessage,
    this.correlationId,
    this.isRetryable = true,
  });
}
