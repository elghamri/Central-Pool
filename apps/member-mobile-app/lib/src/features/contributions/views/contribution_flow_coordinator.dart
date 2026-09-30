import 'package:flutter/material.dart';
import '../state/contribution_controller.dart';
import '../state/contribution_state.dart';
import 'contribution_confirmation_view.dart';
import 'contribution_details_view.dart';
import 'contribution_processing_view.dart';
import 'contribution_receipt_view.dart';
import 'contributions_overview_view.dart';
import 'payment_method_view.dart';

/// Coordinator coordinating navigation through Screens 9 -> 10 -> 11 -> 12 -> 13 -> 14.
class ContributionFlowCoordinator extends StatefulWidget {
  final ContributionController controller;
  final VoidCallback onGoToDashboard;

  const ContributionFlowCoordinator({
    super.key,
    required this.controller,
    required this.onGoToDashboard,
  });

  @override
  State<ContributionFlowCoordinator> createState() => _ContributionFlowCoordinatorState();
}

class _ContributionFlowCoordinatorState extends State<ContributionFlowCoordinator> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ContributionState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        if (state is ContributionProcessing) {
          return ContributionProcessingView(
            status: 'PROCESSING',
            message: state.stepMessage,
            detail: state.detail,
            paymentMethod: state.paymentMethod,
            onRetry: () {},
            onChangeMethod: () {},
            onReturnToOverview: () => widget.controller.resetFlow(),
          );
        }

        if (state is ContributionFailed) {
          return ContributionProcessingView(
            status: 'FAILED',
            message: state.errorMessage,
            errorCode: state.errorCode,
            detail: state.detail,
            paymentMethod: state.paymentMethod,
            onRetry: () => widget.controller.submitContribution(
              detail: state.detail,
              paymentMethod: state.paymentMethod,
            ),
            onChangeMethod: () => widget.controller.setStep(2),
            onReturnToOverview: () => widget.controller.resetFlow(),
          );
        }

        if (state is ContributionTimeout) {
          return ContributionProcessingView(
            status: 'TIMEOUT',
            message: state.message,
            correlationId: state.correlationId,
            detail: state.detail,
            paymentMethod: state.paymentMethod,
            onRetry: () => widget.controller.submitContribution(
              detail: state.detail,
              paymentMethod: state.paymentMethod,
            ),
            onChangeMethod: () => widget.controller.setStep(2),
            onReturnToOverview: () => widget.controller.resetFlow(),
          );
        }

        if (state is ContributionSuccess) {
          return ContributionReceiptView(
            result: state.result,
            detail: state.detail,
            onReturnToOverview: () => widget.controller.resetFlow(),
            onGoToDashboard: widget.onGoToDashboard,
          );
        }

        if (state is ContributionPending) {
          return ContributionReceiptView(
            result: state.result,
            detail: state.detail,
            onReturnToOverview: () => widget.controller.resetFlow(),
            onGoToDashboard: widget.onGoToDashboard,
          );
        }

        if (state is ContributionOverviewLoaded) {
          switch (state.currentStep) {
            case 1:
              return ContributionDetailsView(
                detail: state.activeDue,
                onContinueToPayment: () => widget.controller.setStep(2),
                onBack: () => widget.controller.setStep(0),
              );
            case 2:
              return PaymentMethodView(
                methods: state.paymentMethods,
                selectedMethod: state.selectedPaymentMethod,
                onSelectMethod: (method) => widget.controller.selectPaymentMethod(method),
                onProceedToReview: () => widget.controller.setStep(3),
                onBack: () => widget.controller.setStep(1),
              );
            case 3:
              return ContributionConfirmationView(
                detail: state.activeDue,
                paymentMethod: state.selectedPaymentMethod,
                isSubmitting: state.isSubmitting,
                onConfirmPayment: () => widget.controller.submitContribution(
                  detail: state.activeDue,
                  paymentMethod: state.selectedPaymentMethod,
                ),
                onBack: () => widget.controller.setStep(2),
              );
            case 0:
            default:
              return ContributionsOverviewView(
                controller: widget.controller,
                onMakeContribution: () => widget.controller.setStep(1),
              );
          }
        }

        // Loading or general error
        return ContributionsOverviewView(
          controller: widget.controller,
          onMakeContribution: () => widget.controller.setStep(1),
        );
      },
    );
  }
}
