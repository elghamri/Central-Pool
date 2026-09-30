import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../state/gameya_controller.dart';
import '../i18n/gameya_strings.dart';
import 'consumer_home_view.dart';
import 'circle_discovery_view.dart';
import 'circle_room_view.dart';
import 'consumer_activity_view.dart';
import 'consumer_profile_view.dart';
import 'create_gameya_wizard_view.dart';

/// Full Production Consumer Shell hosting all 4 Primary Tabs & Full-Screen Routes.
class ConsumerGameyaShellView extends StatefulWidget {
  final GameyaController controller;
  final VoidCallback? onLogout;

  const ConsumerGameyaShellView({
    super.key,
    required this.controller,
    this.onLogout,
  });

  @override
  State<ConsumerGameyaShellView> createState() => _ConsumerGameyaShellViewState();
}

class _ConsumerGameyaShellViewState extends State<ConsumerGameyaShellView> {
  int _currentTabIndex = 0;
  String? _activeCircleRoomId;
  bool _isCreatingCircle = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameyaState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        final languageCode = state is GameyaLoaded ? state.languageCode : 'en';
        final strings = GameyaStrings.of(languageCode);

        // 1. Full-Screen Route: Create Game'ya Wizard (/create-circle)
        if (_isCreatingCircle) {
          return CreateGameyaWizardView(
            controller: widget.controller,
            onCancel: () => setState(() => _isCreatingCircle = false),
            onCircleCreated: (circleId) {
              setState(() {
                _isCreatingCircle = false;
                _activeCircleRoomId = circleId;
              });
            },
          );
        }

        // 2. Full-Screen Route: Circle Room (/circle/:id)
        if (_activeCircleRoomId != null) {
          return CircleRoomView(
            controller: widget.controller,
            circleId: _activeCircleRoomId!,
            onBack: () => setState(() => _activeCircleRoomId = null),
          );
        }

        // 3. Primary 4-Tab Navigation Shell
        return Directionality(
          textDirection: strings.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: SafeArea(
              child: IndexedStack(
                index: _currentTabIndex,
                children: [
                  // Tab 0: Home (Surface A)
                  ConsumerHomeView(
                    controller: widget.controller,
                    onNavigateTab: (index) => setState(() => _currentTabIndex = index),
                    onOpenCircleRoom: (circleId) => setState(() => _activeCircleRoomId = circleId),
                    onOpenCreateCircle: () => setState(() => _isCreatingCircle = true),
                  ),

                  // Tab 1: Discover (Surface B)
                  CircleDiscoveryView(
                    controller: widget.controller,
                    onOpenCircleRoom: (circleId) => setState(() => _activeCircleRoomId = circleId),
                    onCircleJoinedAndOpenRoom: (circleId) {
                      setState(() => _activeCircleRoomId = circleId);
                    },
                  ),

                  // Tab 2: Activity (Surface C)
                  ConsumerActivityView(
                    controller: widget.controller,
                  ),

                  // Tab 3: Profile (Surface D)
                  ConsumerProfileView(
                    controller: widget.controller,
                    onLogout: widget.onLogout,
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentTabIndex,
                onTap: (index) => setState(() => _currentTabIndex = index),
                backgroundColor: AppColors.cardSurface,
                selectedItemColor: AppColors.emeraldGreen,
                unselectedItemColor: AppColors.textSecondary,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.savings_outlined),
                    activeIcon: const Icon(Icons.savings),
                    label: strings.tabHome,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.explore_outlined),
                    activeIcon: const Icon(Icons.explore),
                    label: strings.tabDiscover,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.receipt_long_outlined),
                    activeIcon: const Icon(Icons.receipt_long),
                    label: strings.tabActivity,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    activeIcon: const Icon(Icons.person),
                    label: strings.tabProfile,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
