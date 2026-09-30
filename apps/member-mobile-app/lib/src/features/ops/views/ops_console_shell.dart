import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../state/ops_controller.dart';
import '../state/ops_state.dart';
import 'ops_action_dossier_view.dart';
import 'ops_checker_queue_view.dart';
import 'ops_dlq_exceptions_view.dart';
import 'ops_maker_queue_view.dart';
import 'ops_payment_queue_view.dart';
import 'ops_reconciliation_dashboard_view.dart';
import 'ops_reconciliation_report_view.dart';

/// Screen 29–35: Operations Console Shell & Navigation Coordinator.
class OpsConsoleShell extends StatefulWidget {
  final ApiClient apiClient;
  final UserSession session;
  final VoidCallback onSignOut;
  final OpsController? controller;

  const OpsConsoleShell({
    super.key,
    required this.apiClient,
    required this.session,
    required this.onSignOut,
    this.controller,
  });

  @override
  State<OpsConsoleShell> createState() => _OpsConsoleShellState();
}

class _OpsConsoleShellState extends State<OpsConsoleShell> {
  late final OpsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = OpsController(
        apiClient: widget.apiClient,
        session: widget.session,
      );
      _ownsController = true;
      _controller.loadOpsTelemetry();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutShell(
      mobileBuilder: (context) => _buildMobileLayout(context),
      tabletBuilder: (context) => _buildTabletLayout(context),
      desktopBuilder: (context) => _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ValueListenableBuilder<OpsState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final activeTab = state is OpsLoaded ? state.activeTab : 0;

        return Scaffold(
          backgroundColor: AppColors.deepSlate,
          appBar: _buildAppBar(context),
          body: _buildTabBody(state, activeTab),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: activeTab,
            onTap: (index) => _controller.setActiveTab(index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.cardSurface,
            selectedItemColor: AppColors.emeraldGreen,
            unselectedItemColor: AppColors.textSecondary,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.payments_outlined),
                  activeIcon: Icon(Icons.payments),
                  label: 'Payments'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.edit_note_outlined),
                  activeIcon: Icon(Icons.edit_note),
                  label: 'Maker'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.verified_user_outlined),
                  activeIcon: Icon(Icons.verified_user),
                  label: 'Checker'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.error_outline), label: 'DLQ'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_outlined),
                  label: 'Reconcile'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ValueListenableBuilder<OpsState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final activeTab = state is OpsLoaded ? state.activeTab : 0;

        return Scaffold(
          backgroundColor: AppColors.deepSlate,
          appBar: _buildAppBar(context),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: activeTab,
                onDestinationSelected: (index) =>
                    _controller.setActiveTab(index),
                backgroundColor: AppColors.cardSurface,
                selectedIconTheme:
                    const IconThemeData(color: AppColors.emeraldGreen),
                selectedLabelTextStyle: AppTypography.labelSmall.copyWith(
                    color: AppColors.emeraldGreen, fontWeight: FontWeight.w700),
                unselectedIconTheme:
                    const IconThemeData(color: AppColors.textSecondary),
                unselectedLabelTextStyle: AppTypography.labelSmall
                    .copyWith(color: AppColors.textSecondary),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                      icon: Icon(Icons.payments_outlined),
                      selectedIcon: Icon(Icons.payments),
                      label: Text('Payments')),
                  NavigationRailDestination(
                      icon: Icon(Icons.edit_note_outlined),
                      selectedIcon: Icon(Icons.edit_note),
                      label: Text('Maker')),
                  NavigationRailDestination(
                      icon: Icon(Icons.verified_user_outlined),
                      selectedIcon: Icon(Icons.verified_user),
                      label: Text('Checker')),
                  NavigationRailDestination(
                      icon: Icon(Icons.error_outline), label: Text('DLQ')),
                  NavigationRailDestination(
                      icon: Icon(Icons.account_balance_outlined),
                      label: Text('Reconcile')),
                ],
              ),
              const VerticalDivider(color: AppColors.borderSubtle, width: 1.0),
              Expanded(child: _buildTabBody(state, activeTab)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ValueListenableBuilder<OpsState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final activeTab = state is OpsLoaded ? state.activeTab : 0;

        return Scaffold(
          backgroundColor: AppColors.deepSlate,
          body: Row(
            children: [
              // Permanent Sidebar
              Container(
                width: 260.0,
                color: AppColors.cardSurface,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: AppRadii.borderSm,
                              border: Border.all(
                                  color: AppColors.emeraldGreen
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.settings_suggest,
                                color: AppColors.emeraldGreen, size: 22.0),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Operations Core',
                                    style: AppTypography.titleMedium
                                        .copyWith(fontWeight: FontWeight.w700)),
                                Text(widget.session.tenantId,
                                    style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1.0),

                    // Sidebar Navigation items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        children: [
                          _buildSidebarTile(0, 'Payments Queue',
                              Icons.payments_outlined, activeTab),
                          _buildSidebarTile(1, 'Maker Review',
                              Icons.edit_note_outlined, activeTab),
                          _buildSidebarTile(2, 'Checker Release',
                              Icons.verified_user_outlined, activeTab),
                          _buildSidebarTile(3, 'DLQ Exceptions',
                              Icons.error_outline, activeTab),
                          _buildSidebarTile(4, '5-Way Reconciliation',
                              Icons.account_balance_outlined, activeTab),
                        ],
                      ),
                    ),

                    const Divider(color: AppColors.borderSubtle, height: 1.0),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16.0,
                                backgroundColor: AppColors.surfaceElevated,
                                child: Text(
                                  widget.session.fullName.isNotEmpty
                                      ? widget.session.fullName[0]
                                      : 'O',
                                  style: const TextStyle(
                                      color: AppColors.emeraldGreen,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.session.fullName,
                                        style: AppTypography.titleSmall,
                                        overflow: TextOverflow.ellipsis),
                                    Text(widget.session.role.displayName,
                                        style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SecondaryButton(
                            label: 'Sign Out',
                            icon: Icons.logout,
                            onPressed: widget.onSignOut,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(color: AppColors.borderSubtle, width: 1.0),

              // Main Canvas
              Expanded(
                child: Column(
                  children: [
                    // Desktop Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      decoration: const BoxDecoration(
                        color: AppColors.cardSurface,
                        border: Border(
                            bottom: BorderSide(color: AppColors.borderSubtle)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fiduciary Operations Console',
                              style: AppTypography.titleLarge),
                          Row(
                            children: [
                              const StatusBadge(
                                label: 'SANDBOX SIMULATION ACTIVE',
                                type: StatusBadgeType.warning,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              IconButton(
                                icon: const Icon(Icons.refresh,
                                    color: AppColors.textSecondary),
                                tooltip: 'Refresh Telemetry',
                                onPressed: () => _controller.loadOpsTelemetry(
                                    forceRefresh: true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _buildTabBody(state, activeTab),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cardSurface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Operations Console', style: AppTypography.titleMedium),
          Text(
            widget.session.tenantId,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.emeraldGreen, letterSpacing: 0.5),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          tooltip: 'Refresh',
          onPressed: () => _controller.loadOpsTelemetry(forceRefresh: true),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.textSecondary),
          tooltip: 'Sign Out',
          onPressed: widget.onSignOut,
        ),
      ],
    );
  }

  Widget _buildSidebarTile(
      int index, String title, IconData icon, int activeTab) {
    final isSelected = activeTab == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
        borderRadius: AppRadii.borderSm,
        border: isSelected
            ? Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        leading: Icon(icon,
            color:
                isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
            size: 20.0),
        title: Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.emeraldGreen : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        dense: true,
        onTap: () => _controller.setActiveTab(index),
      ),
    );
  }

  Widget _buildTabBody(OpsState state, int activeTab) {
    if (state is OpsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.emeraldGreen));
    }

    if (state is OpsError) {
      return ErrorCardWidget(
        title: 'Operations Telemetry Error',
        errorMessage: state.errorMessage,
        correlationId: state.correlationId,
        onRetry: () => _controller.loadOpsTelemetry(forceRefresh: true),
      );
    }

    if (state is! OpsLoaded) {
      return const SizedBox.shrink();
    }

    // Check for drilldowns
    if (state.selectedPayment != null ||
        state.selectedMakerItem != null ||
        state.selectedCheckerItem != null) {
      return OpsActionDossierView(
        payment: state.selectedPayment,
        makerItem: state.selectedMakerItem,
        checkerItem: state.selectedCheckerItem,
        onBack: () {
          _controller.selectPayment(null);
          _controller.selectMakerItem(null);
          _controller.selectCheckerItem(null);
        },
      );
    }

    if (state.selectedReconciliation != null) {
      return OpsReconciliationReportView(
        report: state.selectedReconciliation!,
        onBack: () => _controller.selectReconciliation(null),
      );
    }

    switch (activeTab) {
      case 0:
        return OpsPaymentQueueView(
          controller: _controller,
          onSelectPayment: (p) => _controller.selectPayment(p),
        );
      case 1:
        return OpsMakerQueueView(
          controller: _controller,
          onSelectMakerItem: (item) => _controller.selectMakerItem(item),
        );
      case 2:
        return OpsCheckerQueueView(
          controller: _controller,
          onSelectCheckerItem: (item) => _controller.selectCheckerItem(item),
        );
      case 3:
        return OpsDlqExceptionsView(
          controller: _controller,
        );
      case 4:
        return OpsReconciliationDashboardView(
          controller: _controller,
          onSelectReport: (report) => _controller.selectReconciliation(report),
        );
      default:
        return OpsPaymentQueueView(
          controller: _controller,
          onSelectPayment: (p) => _controller.selectPayment(p),
        );
    }
  }
}
