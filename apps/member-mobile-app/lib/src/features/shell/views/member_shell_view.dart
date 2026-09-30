import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/session_storage.dart';
import '../../contributions/state/contribution_controller.dart';
import '../../contributions/views/contribution_flow_coordinator.dart';
import '../../dashboard/state/dashboard_controller.dart';
import '../../dashboard/views/live_pool_state_view.dart';
import '../../dashboard/views/member_home_view.dart';
import '../../funding/state/funding_controller.dart';
import '../../funding/views/funding_flow_coordinator.dart';

/// Application Shell for Member Role (Dashboard, Dues, Live Pool, Funding / Statements).
class MemberShellView extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;
  final DashboardController? dashboardController;
  final ContributionController? contributionController;
  final FundingController? fundingController;

  const MemberShellView({
    super.key,
    required this.session,
    required this.onLogout,
    this.dashboardController,
    this.contributionController,
    this.fundingController,
  });

  @override
  State<MemberShellView> createState() => _MemberShellViewState();
}

class _MemberShellViewState extends State<MemberShellView> {
  late final DashboardController _dashboardController;
  late final ContributionController _contributionController;
  late final FundingController _fundingController;
  late final bool _ownsDashboardController;
  late final bool _ownsContributionController;
  late final bool _ownsFundingController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final storage = SecureSessionStorage();
    final apiClient = ApiClient(sessionStorage: storage);

    if (widget.dashboardController != null) {
      _dashboardController = widget.dashboardController!;
      _ownsDashboardController = false;
    } else {
      _dashboardController = DashboardController(
        apiClient: apiClient,
        session: widget.session,
      );
      _ownsDashboardController = true;
    }

    if (widget.contributionController != null) {
      _contributionController = widget.contributionController!;
      _ownsContributionController = false;
    } else {
      _contributionController = ContributionController(
        apiClient: apiClient,
        session: widget.session,
      );
      _ownsContributionController = true;
    }

    if (widget.fundingController != null) {
      _fundingController = widget.fundingController!;
      _ownsFundingController = false;
    } else {
      _fundingController = FundingController(
        apiClient: apiClient,
        session: widget.session,
      );
      _ownsFundingController = true;
    }

    _dashboardController.loadDashboardData();
  }

  @override
  void dispose() {
    if (_ownsDashboardController) {
      _dashboardController.dispose();
    }
    if (_ownsContributionController) {
      _contributionController.dispose();
    }
    if (_ownsFundingController) {
      _fundingController.dispose();
    }
    super.dispose();
  }

  void _onNavigateTab(int index) {
    setState(() => _currentIndex = index);
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
    return Scaffold(
      backgroundColor: AppColors.deepSlate,
      appBar: _buildAppBar(),
      body: _buildCurrentTabBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigateTab,
        backgroundColor: AppColors.cardSurface,
        selectedItemColor: AppColors.emeraldGreen,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.payment_outlined), label: 'Dues'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Live Pool'),
          BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), label: 'Payout'),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSlate,
      appBar: _buildAppBar(),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onNavigateTab,
            backgroundColor: AppColors.cardSurface,
            selectedIconTheme: const IconThemeData(color: AppColors.emeraldGreen),
            unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
            selectedLabelTextStyle: AppTypography.labelSmall.copyWith(color: AppColors.emeraldGreen),
            unselectedLabelTextStyle: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.payment_outlined), label: Text('Dues')),
              NavigationRailDestination(icon: Icon(Icons.pie_chart_outline), label: Text('Live Pool')),
              NavigationRailDestination(icon: Icon(Icons.timeline_outlined), label: Text('Payout')),
            ],
          ),
          const VerticalDivider(color: AppColors.borderSubtle, width: 1.0),
          Expanded(child: _buildCurrentTabBody()),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSlate,
      body: Row(
        children: [
          // Permanent Desktop Sidebar
          Container(
            width: 260.0,
            color: AppColors.cardSurface,
            child: Column(
              children: [
                Container(
                  padding: AppSpacing.paddingCard,
                  child: Row(
                    children: [
                      const Icon(Icons.diversity_3, color: AppColors.emeraldGreen, size: 28.0),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'CollabFinance',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    children: [
                      _buildDesktopNavItem(0, 'Home Dashboard', Icons.dashboard_outlined),
                      _buildDesktopNavItem(1, 'Contribution Dues', Icons.payment_outlined),
                      _buildDesktopNavItem(2, 'Live Pool State', Icons.pie_chart_outline),
                      _buildDesktopNavItem(3, 'Payout Lifecycle', Icons.timeline_outlined),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.surfaceElevated,
                        child: Icon(Icons.person, color: AppColors.sovereignGold, size: 20.0),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.session.fullName, style: AppTypography.labelMedium, overflow: TextOverflow.ellipsis),
                            Text(widget.session.tenantId, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.crimsonRed, size: 20.0),
                        onPressed: widget.onLogout,
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(color: AppColors.borderSubtle, width: 1.0),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(child: _buildCurrentTabBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.session.fullName, style: AppTypography.titleMedium),
          Text(
            '${widget.session.tenantId} • ${widget.session.role.displayName}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.crimsonRed),
          onPressed: widget.onLogout,
          tooltip: 'Sign Out',
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _getTabTitle(_currentIndex),
              style: AppTypography.headlineMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Wrap(
            spacing: 8.0,
            children: [
              StatusBadge(label: widget.session.tenantId, type: StatusBadgeType.info),
              StatusBadge(label: widget.session.role.displayName, type: StatusBadgeType.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavItem(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.emeraldGreen.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: AppRadii.borderMd,
        border: isSelected ? Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary, size: 20.0),
        title: Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.emeraldGreen : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () => _onNavigateTab(index),
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Member Home Dashboard';
      case 1:
        return 'Monthly Contribution Dues';
      case 2:
        return 'Live Pool & Cycle State';
      case 3:
        return 'Funding & Payout Lifecycle';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildCurrentTabBody() {
    switch (_currentIndex) {
      case 0:
        return MemberHomeView(
          controller: _dashboardController,
          onNavigateTab: _onNavigateTab,
        );
      case 1:
        return ContributionFlowCoordinator(
          controller: _contributionController,
          onGoToDashboard: () => _onNavigateTab(0),
        );
      case 2:
        return LivePoolStateView(
          controller: _dashboardController,
          onNavigateTab: _onNavigateTab,
        );
      case 3:
        return FundingFlowCoordinator(
          controller: _fundingController,
        );
      default:
        return MemberHomeView(
          controller: _dashboardController,
          onNavigateTab: _onNavigateTab,
        );
    }
  }
}
