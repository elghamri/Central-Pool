// Central Pool Member Shell View (Step 13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Primary Flutter Member Shell for Central Pool application.
// - Replaces legacy Gameya navigation with pure Central Pool features:
//   1. Participation & Matching Flow
//   2. Financial Obligation
//   3. Contribution Schedule & Events
//   4. Payout Entitlement
//   5. Member Timeline & Cycle Projections

import 'package:flutter/material.dart';
import '../state/central_pool_controller.dart';
import '../widgets/locked_banner.dart';
import 'submit_participation_request_view.dart';
import 'candidate_selection_view.dart';
import 'allocation_confirmation_view.dart';
import 'financial_obligation_view.dart';
import 'contribution_schedule_view.dart';
import 'payout_entitlement_view.dart';
import 'member_period_timeline_view.dart';
import 'cycle_period_readiness_view.dart';

class CentralPoolShellView extends StatefulWidget {
  final CentralPoolController controller;
  final VoidCallback? onLogout;

  const CentralPoolShellView({
    Key? key,
    required this.controller,
    this.onLogout,
  }) : super(key: key);

  @override
  State<CentralPoolShellView> createState() => _CentralPoolShellViewState();
}

class _CentralPoolShellViewState extends State<CentralPoolShellView> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Central Pool Platform'),
            actions: [
              if (widget.onLogout != null)
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                  onPressed: widget.onLogout,
                ),
            ],
          ),
          body: Column(
            children: [
              if (widget.controller.isSystemLocked)
                LockedBanner(lockdown: widget.controller.lockdown, isLocked: true),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedNavIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.cyanAccent,
            unselectedItemColor: Colors.grey,
            onTap: (index) => setState(() => _selectedNavIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.hub_outlined),
                label: 'Matching',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                label: 'Obligation',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.redeem_outlined),
                label: 'Entitlement',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timeline_outlined),
                label: 'Timeline',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                label: 'Cycle',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildMatchingFlow();
      case 1:
        return FinancialObligationView(controller: widget.controller);
      case 2:
        return ContributionScheduleView(controller: widget.controller);
      case 3:
        return PayoutEntitlementView(controller: widget.controller);
      case 4:
        return MemberPeriodTimelineView(controller: widget.controller);
      case 5:
        return CyclePeriodReadinessView(controller: widget.controller);
      default:
        return _buildMatchingFlow();
    }
  }

  Widget _buildMatchingFlow() {
    switch (widget.controller.step) {
      case CentralPoolFlowStep.form:
        return SubmitParticipationRequestView(controller: widget.controller);
      case CentralPoolFlowStep.matching:
      case CentralPoolFlowStep.candidateList:
        return CandidateSelectionView(controller: widget.controller);
      case CentralPoolFlowStep.confirmed:
        return AllocationConfirmationView(controller: widget.controller);
      case CentralPoolFlowStep.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 54),
                const SizedBox(height: 16),
                const Text(
                  'Operation Failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.controller.errorMessage ?? 'An unexpected error occurred.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => widget.controller.reset(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
    }
  }
}
