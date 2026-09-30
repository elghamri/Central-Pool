import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../state/platform_controller.dart';
import '../state/platform_state.dart';
import 'platform_circuit_breaker_view.dart';
import 'platform_health_view.dart';
import 'platform_providers_view.dart';
import 'platform_security_view.dart';
import 'platform_tenants_view.dart';

/// Screen 36–40: Platform Admin Console Shell & Navigation Coordinator.
class PlatformConsoleShell extends StatefulWidget {
  final ApiClient apiClient;
  final UserSession session;
  final VoidCallback onSignOut;
  final PlatformController? controller;

  const PlatformConsoleShell({
    super.key,
    required this.apiClient,
    required this.session,
    required this.onSignOut,
    this.controller,
  });

  @override
  State<PlatformConsoleShell> createState() => _PlatformConsoleShellState();
}

class _PlatformConsoleShellState extends State<PlatformConsoleShell> {
  late final PlatformController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = PlatformController(
        apiClient: widget.apiClient,
        session: widget.session,
      );
      _ownsController = true;
      _controller.loadPlatformTelemetry();
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
    return ValueListenableBuilder<PlatformState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final activeTab = state is PlatformLoaded ? state.activeTab : 0;

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
                  icon: Icon(Icons.monitor_heart_outlined),
                  activeIcon: Icon(Icons.monitor_heart),
                  label: 'Health'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.business_outlined),
                  activeIcon: Icon(Icons.business),
                  label: 'Tenants'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.alt_route_outlined),
                  activeIcon: Icon(Icons.alt_route),
                  label: 'Rails'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.security_outlined),
                  activeIcon: Icon(Icons.security),
                  label: 'Security'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.gavel_outlined), label: 'Controls'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ValueListenableBuilder<PlatformState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final activeTab = state is PlatformLoaded ? state.activeTab : 0;

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
                      icon: Icon(Icons.monitor_heart_outlined),
                      selectedIcon: Icon(Icons.monitor_heart),
                      label: Text('Health')),
                  NavigationRailDestination(
                      icon: Icon(Icons.business_outlined),
                      selectedIcon: Icon(Icons.business),
                      label: Text('Tenants')),
                  NavigationRailDestination(
                      icon: Icon(Icons.alt_route_outlined),
                      selectedIcon: Icon(Icons.alt_route),
                      label: Text('Rails')),
                  NavigationRailDestination(
                      icon: Icon(Icons.security_outlined),
                      selectedIcon: Icon(Icons.security),
                      label: Text('Security')),
                  NavigationRailDestination(
                      icon: Icon(Icons.gavel_outlined),
                      label: Text('Controls')),
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
    return ValueListenableBuilder<PlatformState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final activeTab = state is PlatformLoaded ? state.activeTab : 0;

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
                            child: const Icon(Icons.admin_panel_settings,
                                color: AppColors.emeraldGreen, size: 22.0),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Platform Admin',
                                    style: AppTypography.titleMedium
                                        .copyWith(fontWeight: FontWeight.w700)),
                                Text('System Core Console',
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
                            vertical: 8.0, horizontal: 12.0),
                        children: [
                          _buildSidebarTile(0, 'System Health',
                              Icons.monitor_heart_outlined, activeTab),
                          _buildSidebarTile(1, 'Tenant Registry',
                              Icons.business_outlined, activeTab),
                          _buildSidebarTile(2, 'Clearing Rails',
                              Icons.alt_route_outlined, activeTab),
                          _buildSidebarTile(3, 'Security & WORM',
                              Icons.security_outlined, activeTab),
                          _buildSidebarTile(4, 'Circuit Breakers',
                              Icons.gavel_outlined, activeTab),
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
                                      : 'P',
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

              // Main Content
              Expanded(
                child: Column(
                  children: [
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
                          const Expanded(
                            child: Text(
                              'Platform Administration & System Health',
                              style: AppTypography.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
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
                                onPressed: () => _controller
                                    .loadPlatformTelemetry(forceRefresh: true),
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
          const Text('Platform Admin Console',
              style: AppTypography.titleMedium),
          Text(
            'System Infrastructure',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.emeraldGreen, letterSpacing: 0.5),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          tooltip: 'Refresh',
          onPressed: () =>
              _controller.loadPlatformTelemetry(forceRefresh: true),
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

  Widget _buildTabBody(PlatformState state, int activeTab) {
    if (state is PlatformLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.emeraldGreen));
    }

    if (state is PlatformError) {
      return ErrorCardWidget(
        title: 'Platform Telemetry Error',
        errorMessage: state.errorMessage,
        correlationId: state.correlationId,
        onRetry: () => _controller.loadPlatformTelemetry(forceRefresh: true),
      );
    }

    if (state is! PlatformLoaded) {
      return const SizedBox.shrink();
    }

    switch (activeTab) {
      case 0:
        return PlatformHealthView(controller: _controller);
      case 1:
        return PlatformTenantsView(controller: _controller);
      case 2:
        return PlatformProvidersView(controller: _controller);
      case 3:
        return PlatformSecurityView(controller: _controller);
      case 4:
        return PlatformCircuitBreakerView(controller: _controller);
      default:
        return PlatformHealthView(controller: _controller);
    }
  }
}
