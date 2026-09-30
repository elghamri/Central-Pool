import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/consumer_home_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/circle_discovery_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/circle_room_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/consumer_gameya_shell_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/widgets/rotation_wheel_widget.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/widgets/economic_status_card.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/widgets/peer_roster_tile.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  group('Phase 26: Consumer Game\'ya Controller & Domain Model Tests', () {
    test('GameyaController initializes with multiple active Game\'yas and aggregated dues', () async {
      final controller = GameyaController();

      expect(controller.value, isA<GameyaLoaded>());
      final loaded = controller.value as GameyaLoaded;

      // Verify multi-circle support
      expect(loaded.hubSummary.activeCircles.length, 2);
      expect(loaded.hubSummary.activeCircles[0].name, 'Family Savings 2026');
      expect(loaded.hubSummary.activeCircles[1].name, 'New Car Fund 2027');

      // Verify aggregated total monthly dues ($500 + $1,000 = $1,500.00 = 150000 minor)
      expect(loaded.hubSummary.totalMonthlyDuesMinor, 150000);

      // Verify marketplace forming circles
      expect(loaded.marketplaceCircles.length, 2);
      expect(loaded.marketplaceCircles[0].name, 'Wedding Savings Circle');
    });

    test('GameyaController joins an open slot and updates active circles and dues', () async {
      final controller = GameyaController();

      // Join Wedding Savings Circle on Slot #3
      final success = await controller.joinCircleWithSlot(
        circleId: 'CIRCLE-WED-2026',
        slotNumber: 3,
      );

      expect(success, isTrue);
      final loaded = controller.value as GameyaLoaded;

      // Active circles increased from 2 to 3
      expect(loaded.hubSummary.activeCircles.length, 3);
      // Total monthly dues increased by $500 (150000 + 50000 = 200000)
      expect(loaded.hubSummary.totalMonthlyDuesMinor, 200000);
      // Marketplace circles decreased to 1
      expect(loaded.marketplaceCircles.length, 1);
    });
  });

  group('Phase 26: Surface A — Consumer Member Home Widget Tests', () {
    testWidgets('Renders greeting, aggregated dues banner, upcoming payout, and multi-circle cards', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = GameyaController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ConsumerHomeView(controller: controller),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Greeting
      expect(find.textContaining('Hello, Ahmed Mansour'), findsOneWidget);

      // Verify Aggregated Monthly Obligation Banner ($1,500.00)
      expect(find.text('TOTAL MONTHLY OBLIGATION'), findsOneWidget);
      expect(find.text('\$1,500.00'), findsWidgets);

      // Verify Upcoming Payout Hero Card ($5,000.00)
      expect(find.text('NEXT UPCOMING PAYOUT'), findsOneWidget);
      expect(find.text('\$5,000.00'), findsWidgets);

      // Verify Active Circle Cards (Multi-Circle Support)
      expect(find.text('Family Savings 2026'), findsOneWidget);
      expect(find.text('New Car Fund 2027'), findsOneWidget);

      // Verify Quick Action Buttons
      expect(find.text('Discover Circles'), findsOneWidget);
      expect(find.text('+ Create Game\'ya'), findsOneWidget);
    });
  });

  group('Phase 26: Surface B — Game\'ya Discovery & Slot Selection Tests', () {
    testWidgets('Renders open circle marketplace, filter chips, and interactive slot picker modal', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = GameyaController();

      String? openedRoomId;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CircleDiscoveryView(
              controller: controller,
              onCircleJoinedAndOpenRoom: (id) => openedRoomId = id,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Title & Description
      expect(find.text('Discover Game\'yas'), findsOneWidget);

      // Verify Private Invite Code Box
      expect(find.text('Have a private invite code? e.g. FAM-882'), findsOneWidget);

      // Verify Marketplace Cards
      expect(find.text('Wedding Savings Circle'), findsOneWidget);
      expect(find.text('Tech Freelancers Equipment Circle'), findsOneWidget);

      // Tap on Wedding Savings Circle to open Slot Picker bottom sheet
      await tester.tap(find.text('Wedding Savings Circle'));
      // Pump frames for modal slide-in animation
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify Bottom Sheet Opened
      expect(find.text('CHOOSE YOUR PAYOUT MONTH'), findsOneWidget);
      expect(find.text('Month 3'), findsWidgets);

      // Tap on available Month 3 chip by ValueKey
      await tester.tap(find.byKey(const ValueKey('slot_chip_3')));
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify Confirmation text explains rules in plain language
      expect(find.textContaining('You selected: Month 3'), findsOneWidget);
      expect(find.textContaining('You will contribute \$500 each month'), findsOneWidget);

      // Tap Join Game'ya
      await tester.tap(find.textContaining('Join Game\'ya & Claim Month 3'));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(openedRoomId, 'CIRCLE-WED-2026');
    });
  });

  group('Phase 26: Surface C — Game\'ya Circle Room & Rotation Wheel Tests', () {
    testWidgets('Renders Rotation Wheel, Economic Status Card, and Peer Roster', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = GameyaController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Header
      expect(find.text('Family Savings 2026'), findsWidgets);
      expect(find.text('\$500'), findsOneWidget); // Monthly Due
      expect(find.text('\$5,000.00'), findsWidgets); // Total Payout

      // Verify Rotation Wheel Section
      expect(find.text('INTERACTIVE ROTATION WHEEL'), findsOneWidget);
      expect(find.byType(RotationWheelWidget), findsOneWidget);

      // Verify Economic Status Card (User is Slot #2 in Month 2: This Month Payout!)
      expect(find.byType(EconomicStatusCard), findsOneWidget);
      expect(find.text('Repaying Advance Payout'), findsOneWidget);

      // Verify Primary Action Button for Month 2 Payout
      expect(find.textContaining('Claim Your \$5,000 Payout Now'), findsOneWidget);

      // Verify Peer Roster Tiles
      expect(find.byType(PeerRosterTile), findsWidgets);
      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.textContaining('You (Ahmed Mansour)'), findsOneWidget);
      expect(find.text('Tariq Mansour'), findsOneWidget);
    });

    testWidgets('Renders Symmetrical Paired allocation mode correctly', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = GameyaController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-CAR-2027', // Symmetrical Paired Circle
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Car Fund 2027'), findsWidgets);
      expect(find.text('Paired'), findsOneWidget);
      expect(find.text('Pair Payout'), findsOneWidget);
      expect(find.text('\$5,000.00'), findsWidgets); // Half pool of $10k
    });
  });

  group('Phase 26: Consumer Game\'ya Shell Integration Tests', () {
    testWidgets('ConsumerGameyaShellView switches tabs between Home, Discover, and opens Circle Room', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = GameyaController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ConsumerGameyaShellView(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Starts on Tab 0 (Home)
      expect(find.text('TOTAL MONTHLY OBLIGATION'), findsOneWidget);

      // Switch to Tab 1 (Discover)
      await tester.tap(find.text('Discover'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Discover Game\'yas'), findsOneWidget);

      // Switch to Tab 2 (Activity)
      await tester.tap(find.text('Activity'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Financial Activity & History'), findsOneWidget);

      // Switch to Tab 3 (Profile)
      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Member Profile & Settings'), findsOneWidget);
      expect(find.text('Ahmed Mansour'), findsOneWidget);
    });
  });
}
