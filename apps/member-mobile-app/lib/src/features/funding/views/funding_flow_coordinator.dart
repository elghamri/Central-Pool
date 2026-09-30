import 'package:flutter/material.dart';
import '../state/funding_controller.dart';
import '../state/funding_state.dart';
import 'allocation_position_view.dart';
import 'funding_audit_statement_view.dart';
import 'funding_eligibility_view.dart';
import 'funding_lifecycle_tracker_view.dart';
import 'funding_overview_view.dart';
import 'payout_settlement_view.dart';
import 'post_funding_obligation_view.dart';

/// Coordinator managing sub-view navigation for Screens 15 through 21.
class FundingFlowCoordinator extends StatefulWidget {
  final FundingController controller;

  const FundingFlowCoordinator({
    super.key,
    required this.controller,
  });

  @override
  State<FundingFlowCoordinator> createState() => _FundingFlowCoordinatorState();
}

class _FundingFlowCoordinatorState extends State<FundingFlowCoordinator> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadFundingData();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FundingState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        if (state is FundingLoaded) {
          final overview = state.overview;

          switch (state.currentViewIndex) {
            case 1:
              return FundingEligibilityView(
                eligibility: overview.eligibility,
                onBack: () => widget.controller.setViewIndex(0),
              );
            case 2:
              return AllocationPositionView(
                allocation: overview.allocation,
                onTrackLifecycle: () => widget.controller.setViewIndex(3),
                onBack: () => widget.controller.setViewIndex(0),
              );
            case 3:
              return FundingLifecycleTrackerView(
                stages: overview.lifecycleStages,
                onInspectSettlement: () => widget.controller.setViewIndex(4),
                onBack: () => widget.controller.setViewIndex(0),
              );
            case 4:
              return PayoutSettlementView(
                settlement: overview.settlement,
                onInspectObligation: () => widget.controller.setViewIndex(5),
                onBack: () => widget.controller.setViewIndex(3),
              );
            case 5:
              return PostFundingObligationView(
                obligation: overview.obligation,
                onInspectAuditStatement: () => widget.controller.setViewIndex(6),
                onBack: () => widget.controller.setViewIndex(0),
              );
            case 6:
              return FundingAuditStatementView(
                auditStatement: overview.auditStatement,
                onReturnToOverview: () => widget.controller.setViewIndex(0),
              );
            case 0:
            default:
              return FundingOverviewView(
                controller: widget.controller,
                onSelectSubView: (index) => widget.controller.setViewIndex(index),
              );
          }
        }

        return FundingOverviewView(
          controller: widget.controller,
          onSelectSubView: (index) => widget.controller.setViewIndex(index),
        );
      },
    );
  }
}
