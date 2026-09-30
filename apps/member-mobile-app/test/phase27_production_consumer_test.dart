import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/consumer_activity_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/consumer_profile_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/create_gameya_wizard_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/consumer_gameya_shell_view.dart';

void main() {
  group('Phase 27: Consumer Game\'ya Production Suite', () {
    late GameyaController controller;

    setUp(() {
      controller = GameyaController();
    });

    test('Scenario 1: 10 members x \$500 x 10 months mathematical invariance (INV-1, INV-18)', () async {
      await controller.loadInitialData();
      final state = controller.value as GameyaLoaded;
      final familyCircle = state.hubSummary.activeCircles.first;

      expect(familyCircle.totalPeriods, 10);
      expect(familyCircle.monthlyContributionMinor, 50000);
      expect(familyCircle.totalPoolMinor, 500000);

      // Invariant: Total Pool = N x Monthly Dues
      expect(familyCircle.totalPeriods * familyCircle.monthlyContributionMinor, familyCircle.totalPoolMinor);
      expect(familyCircle.slots.length, 10);
    });

    test('Scenario 2: Early payout position (Slot #2 - Repaying Advance Payout)', () async {
      await controller.loadInitialData();
      final state = controller.value as GameyaLoaded;
      final familyCircle = state.hubSummary.activeCircles.first;

      expect(familyCircle.currentUserSlotPosition, 2);
      expect(familyCircle.currentPeriod, 2);
      expect(familyCircle.currentUserEconomicPosition, EconomicPositionType.repayingAdvancePayout);
      expect(familyCircle.currentUserEconomicPosition!.title, 'Repaying Advance Payout');
    });

    test('Scenario 3: Late payout position (Slot #9 - Accumulating Savings)', () async {
      await controller.loadInitialData();
      final state = controller.value as GameyaLoaded;
      final carCircle = state.hubSummary.activeCircles.firstWhere((c) => c.id == 'CIRCLE-CAR-2027');

      expect(carCircle.currentUserSlotPosition, 9);
      expect(carCircle.currentPeriod, 5);
      expect(carCircle.currentUserEconomicPosition, EconomicPositionType.accumulatingSavings);
      expect(carCircle.currentUserEconomicPosition!.title, 'Accumulating Savings');
    });

    test('Scenario 4: Multi-Circle Aggregation strictly sums dues across circles', () async {
      await controller.loadInitialData();
      final state = controller.value as GameyaLoaded;

      // $500 (Family) + $1,000 (Car) = $1,500 (150,000 cents)
      expect(state.hubSummary.totalMonthlyDuesMinor, 150000);
      expect(state.hubSummary.activeCircles.length, 2);
    });

    test('Scenario 5: Sequential vs Symmetrical Paired allocation mode semantics', () async {
      await controller.loadInitialData();
      final state = controller.value as GameyaLoaded;

      final sequentialCircle = state.hubSummary.activeCircles.first;
      final pairedCircle = state.hubSummary.activeCircles.firstWhere((c) => c.id == 'CIRCLE-CAR-2027');

      expect(sequentialCircle.allocationMode, GameyaAllocationMode.sequential);
      expect(pairedCircle.allocationMode, GameyaAllocationMode.symmetricalPaired);

      // Verify symmetrical pair mapping
      expect(pairedCircle.slots[0].pairedSlotNumber, 10);
      expect(pairedCircle.slots[1].pairedSlotNumber, 9);
      expect(pairedCircle.slots[8].pairedSlotNumber, 2);
      expect(pairedCircle.slots[9].pairedSlotNumber, 1);
    });

    test('Scenario 6: Joining an open slot transitions circle to enrolled and updates obligations', () async {
      await controller.loadInitialData();
      final initialCount = (controller.value as GameyaLoaded).hubSummary.activeCircles.length;

      final success = await controller.joinCircleWithSlot(
        circleId: 'CIRCLE-WED-2026',
        slotNumber: 3,
      );

      expect(success, true);
      final updatedState = controller.value as GameyaLoaded;
      expect(updatedState.hubSummary.activeCircles.length, initialCount + 1);

      // Verify that total obligation increased by $500 (50,000 cents)
      expect(updatedState.hubSummary.totalMonthlyDuesMinor, 200000);
    });

    test('Scenario 7: Creating new Game\'ya via draft updates marketplace and timeline', () async {
      await controller.loadInitialData();
      const draft = CreateGameyaDraft(
        name: 'Apartment Renovation Fund',
        goalCategory: 'Home',
        monthlyContributionMinor: 100000,
        totalPeriods: 10,
        allocationMode: GameyaAllocationMode.sequential,
        creatorSlotNumber: 1,
      );

      final created = await controller.createNewGameya(draft);
      expect(created.name, 'Apartment Renovation Fund');
      expect(created.totalPoolMinor, 1000000);
      expect(created.slots.first.isCurrentUser, true);

      final updatedState = controller.value as GameyaLoaded;
      expect(updatedState.marketplaceCircles.any((c) => c.name == 'Apartment Renovation Fund'), true);
      expect(updatedState.activityTimeline.first.title, contains('Created'));
    });

    testWidgets('Widget Test: ConsumerGameyaShellView renders 4 tabs and navigates correctly', (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ConsumerGameyaShellView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Bottom Navigation Bar has 4 tabs
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('My Game\'yas'), findsWidgets);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify Home view elements
      expect(find.text('Hello, Ahmed Mansour 👋'), findsOneWidget);
      expect(find.text('TOTAL MONTHLY OBLIGATION'), findsOneWidget);

      // Tap on Tab 2: Activity
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.byType(ConsumerActivityView), findsOneWidget);
      expect(find.text('Financial Activity & History'), findsOneWidget);

      // Tap on Tab 3: Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ConsumerProfileView), findsOneWidget);
      expect(find.text('Member Profile & Settings'), findsOneWidget);
      expect(find.text('Identity Fully Verified ✓'), findsOneWidget);
    });

    testWidgets('Widget Test: Internationalization toggles Arabic RTL correctly', (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ConsumerGameyaShellView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Profile Tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Tap Arabic (RTL) button
      await tester.tap(find.text('العربية (RTL)'));
      await tester.pumpAndSettle();

      final state = controller.value as GameyaLoaded;
      expect(state.languageCode, 'ar');
      expect(state.isRtl, true);

      // Verify Arabic translation rendered
      expect(find.text('الملف الشخصي والإعدادات'), findsOneWidget);
    });

    testWidgets('Widget Test: Create Game\'ya Wizard completes 5-step creation flow', (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: CreateGameyaWizardView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP 1 OF 5'), findsOneWidget);

      // Step 1 -> Step 2
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 2 OF 5'), findsOneWidget);

      // Step 2 -> Step 3
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 3 OF 5'), findsOneWidget);

      // Step 3 -> Step 4
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 4 OF 5'), findsOneWidget);

      // Step 4 -> Step 5
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 5 OF 5'), findsOneWidget);

      // Agree to bylaws
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Launch circle
      await tester.tap(find.text('Launch Game\'ya Circle 🚀'));
      await tester.pumpAndSettle();

      expect(find.text('INVITE CODE'), findsOneWidget);
    });
  });
}
