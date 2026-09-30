import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../state/admin_controller.dart';
import '../state/admin_state.dart';
import 'admin_cycle_config_wizard_view.dart';
import 'admin_cycles_management_view.dart';
import 'admin_member_detail_view.dart';
import 'admin_member_directory_view.dart';
import 'admin_overview_view.dart';
import 'admin_treasury_reserve_view.dart';
import 'org_profile_config_view.dart';

/// Screen 22–28: Business Admin Console Shell & Navigation Coordinator.
class AdminConsoleShell extends StatefulWidget {
  final ApiClient apiClient;
  final UserSession session;
  final VoidCallback onSignOut;
  final AdminController? controller;

  const AdminConsoleShell({
    super.key,
    required this.apiClient,
    required this.session,
    required this.onSignOut,
    this.controller,
  });

  @override
  State<AdminConsoleShell> createState() => _AdminConsoleShellState();
}

class _AdminConsoleShellState extends State<AdminConsoleShell> {
  late final AdminController _controller;
  late final bool _ownsController;
  bool _isWizardOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = AdminController(
        apiClient: widget.apiClient,
        session: widget.session,
      );
      _ownsController = true;
      _controller.loadAdminDashboard();
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
    return ValueListenableBuilder<AdminState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final activeTab = state is AdminLoaded ? state.activeTab : 0;

        return Scaffold(
          backgroundColor: AppColors.deepSlate,
          appBar: _buildAppBar(context),
          body: _buildTabBody(state, activeTab),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: activeTab,
            onTap: (index) {
              setState(() => _isWizardOpen = false);
              _controller.setActiveTab(index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.cardSurface,
            selectedItemColor: AppColors.emeraldGreen,
            unselectedItemColor: AppColors.textSecondary,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Overview'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Members'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.published_with_changes), label: 'Cycles'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_outlined),
                  label: 'Treasury'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  label: 'Settings'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ValueListenableBuilder<AdminState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final activeTab = state is AdminLoaded ? state.activeTab : 0;

        return Scaffold(
          backgroundColor: AppColors.deepSlate,
          appBar: _buildAppBar(context),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: activeTab,
                onDestinationSelected: (index) {
                  setState(() => _isWizardOpen = false);
                  _controller.setActiveTab(index);
                },
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
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Overview')),
                  NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Members')),
                  NavigationRailDestination(
                      icon: Icon(Icons.published_with_changes),
                      label: Text('Cycles')),
                  NavigationRailDestination(
                      icon: Icon(Icons.account_balance_outlined),
                      label: Text('Treasury')),
                  NavigationRailDestination(
                      icon: Icon(Icons.admin_panel_settings_outlined),
                      label: Text('Settings')),
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
    return ValueListenableBuilder<AdminState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final activeTab = state is AdminLoaded ? state.activeTab : 0;

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
                                  color: AppColors.sovereignGold
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.shield_outlined,
                                color: AppColors.sovereignGold, size: 22.0),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Business Admin',
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
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 8.0),
                        children: [
                          _buildDesktopNavItem(0, 'Operations Overview',
                              Icons.dashboard_outlined, activeTab),
                          _buildDesktopNavItem(1, 'Member Directory & KYC',
                              Icons.people_outline, activeTab),
                          _buildDesktopNavItem(2, 'Cooperative Cycles',
                              Icons.published_with_changes, activeTab),
                          _buildDesktopNavItem(3, 'Treasury & Reserve Guard',
                              Icons.account_balance_outlined, activeTab),
                          _buildDesktopNavItem(4, 'Organization Settings',
                              Icons.admin_panel_settings_outlined, activeTab),
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
                            radius: 18.0,
                            child: Icon(Icons.person,
                                color: AppColors.sovereignGold, size: 18.0),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.session.fullName,
                                    style: AppTypography.labelMedium,
                                    overflow: TextOverflow.ellipsis),
                                Text(widget.session.role.displayName,
                                    style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout,
                                color: AppColors.crimsonRed, size: 18.0),
                            onPressed: widget.onSignOut,
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
                    _buildDesktopHeader(context),
                    Expanded(child: _buildTabBody(state, activeTab)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopNavItem(
      int index, String title, IconData icon, int activeTab) {
    final isSelected = activeTab == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.emeraldGreen.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: AppRadii.borderMd,
        border: isSelected
            ? Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4))
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
        onTap: () {
          setState(() => _isWizardOpen = false);
          _controller.setActiveTab(index);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.borderSm,
              border: Border.all(
                  color: AppColors.sovereignGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.sovereignGold, size: 16.0),
                const SizedBox(width: 4.0),
                Text('ORG ADMIN',
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.sovereignGold,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.session.tenantId,
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          tooltip: 'Refresh Administrative Data',
          onPressed: () => _controller.loadAdminDashboard(forceRefresh: true),
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: AppColors.crimsonRed),
          tooltip: 'Sign Out of Admin Console',
          onPressed: widget.onSignOut,
        ),
      ],
      backgroundColor: AppColors.cardSurface,
      elevation: 0,
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
            bottom: BorderSide(color: AppColors.borderSubtle, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              StatusBadge(label: 'TENANT: ALPHA', type: StatusBadgeType.info),
              SizedBox(width: AppSpacing.sm),
              StatusBadge(
                  label: 'GOVERNANCE: DUAL-AUTH ACTIVE',
                  type: StatusBadgeType.success),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Refresh Dashboard',
            onPressed: () => _controller.loadAdminDashboard(forceRefresh: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(AdminState state, int activeTab) {
    if (state is AdminLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.emeraldGreen));
    }

    if (state is AdminError) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingCard,
          child: ErrorCardWidget(
            title: 'Admin Console Error',
            errorMessage: state.errorMessage,
            correlationId: state.correlationId,
            onRetry: () => _controller.loadAdminDashboard(forceRefresh: true),
          ),
        ),
      );
    }

    if (state is AdminLoaded) {
      switch (activeTab) {
        case 0:
          return AdminOverviewView(
            controller: _controller,
            onNavigateTab: (tab) {
              setState(() => _isWizardOpen = false);
              _controller.setActiveTab(tab);
            },
          );
        case 1:
          if (state.selectedMember != null) {
            return AdminMemberDetailView(
              member: state.selectedMember!,
              controller: _controller,
              onBack: () => _controller.selectMember(null),
            );
          }
          return AdminMemberDirectoryView(
            controller: _controller,
            onSelectMember: (m) => _controller.selectMember(m),
          );
        case 2:
          if (_isWizardOpen) {
            return AdminCycleConfigWizardView(
              controller: _controller,
              onCancel: () => setState(() => _isWizardOpen = false),
              onSuccess: () => setState(() => _isWizardOpen = false),
            );
          }
          return AdminCyclesManagementView(
            controller: _controller,
            onLaunchNewCycleWizard: () => setState(() => _isWizardOpen = true),
          );
        case 3:
          return AdminTreasuryReserveView(controller: _controller);
        case 4:
          return OrgProfileConfigView(
            profile: state.profile,
            overview: state.overview,
            onBack: () => _controller.setActiveTab(0),
          );
        default:
          return AdminOverviewView(
            controller: _controller,
            onNavigateTab: (tab) => _controller.setActiveTab(tab),
          );
      }
    }

    return const SizedBox.shrink();
  }
}
