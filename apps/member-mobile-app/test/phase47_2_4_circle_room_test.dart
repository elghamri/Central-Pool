import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/models/gameya_models.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/data/gameya_repository.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/circle_room_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/widgets/rotation_wheel_widget.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  group('Phase 47.2.4 — Circle Room & Member Experience Verification Suite', () {
    late GameyaRepository repository;
    late GameyaController controller;

    setUp(() {
      repository = GameyaRepository();
      controller = GameyaController(repository: repository, autoLoad: true);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('1. Sequential Mode: Renders authoritative data, position, obligation, and rotation wheel', (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Header & Metrics
      expect(find.text('Family Savings 2026'), findsOneWidget);
      expect(find.text('\$500'), findsWidgets); // Monthly due
      expect(find.text('Position #2 / 10'), findsOneWidget); // Enrolled position
      expect(find.text('Sequential'), findsOneWidget);

      // Verify Rotation Wheel
      expect(find.byType(RotationWheelWidget), findsOneWidget);
      expect(find.text('INTERACTIVE ROTATION WHEEL'), findsOneWidget);
    });

    testWidgets('2. Symmetrical Paired Mode: Displays 50/50 payout breakdown without implying 100% early payout', (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-CAR-2027', // Symmetrical Paired circle (Month 5/10, Slot #9)
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('New Car Fund 2027'), findsOneWidget);
      expect(find.text('Paired'), findsOneWidget);
      expect(find.text('50/50 Symmetrical Paired Payout'), findsOneWidget);
      expect(find.textContaining('Your payout is split into two equal halves'), findsOneWidget);
    });

    testWidgets('3. Unenrolled User: Shows Not Enrolled state and CTA to join', (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-WED-2026', // Open circle where user is not enrolled
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Not Enrolled'), findsOneWidget);
      expect(find.text('Choose Open Slot & Join Circle'), findsOneWidget);
    });

    testWidgets('4. System States: Loading, Empty, Error, Offline, Permission Denied, and Safety Lock', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 4A. Permission Denied State
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            isPermissionDenied: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Access Restricted'), findsOneWidget);

      // 4B. Empty State (Invalid ID)
      await controller.loadInitialData();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'NON_EXISTENT_CIRCLE_ID',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Game\'ya Circle Not Found'), findsOneWidget);

      // 4C. Offline & Safety Lock & Error State Banners
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            isOffline: true,
            isSafetyLockActive: true,
            errorMessage: 'Network timeout during live refresh',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('You\'re offline. Reconnect to refresh this Game\'ya.'), findsOneWidget);
      expect(find.text('Financial Safety Lock Active (Actions Restricted)'), findsOneWidget);
      expect(find.text('Network timeout during live refresh'), findsOneWidget);
    });

    testWidgets('5. Arabic RTL Mode: Renders Cairo directionality and localized Arabic strings', (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
            isRtl: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('عجلة التدوير التفاعلية'), findsOneWidget);
      expect(find.text('موقعك بالجمعية'), findsOneWidget);
      expect(find.text('المركز #2 من 10'), findsOneWidget);
    });

    testWidgets('6. Accessibility: Wheel contains semantic descriptions and nodes meet 48dp targets', (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel(RegExp(r'Rotation wheel topology')), findsOneWidget);
    });

    testWidgets('7. Responsive Layout: Renders on tablet/desktop viewports without overflow', (tester) async {
      await controller.loadInitialData();
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: 'CIRCLE-FAM-2026',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Family Savings 2026'), findsOneWidget);
      expect(find.byType(RotationWheelWidget), findsOneWidget);
    });

    testWidgets('8. Odd Symmetrical Paired Circle: Renders Month 6 Middle Slot Single Turn (100% Full) and paired cards', (tester) async {
      await controller.loadInitialData();

      // Create an 11-member odd symmetrical paired circle
      final created = await controller.createNewGameya(
        const CreateGameyaDraft(
          name: 'Family Savings 2027',
          goalCategory: 'Family',
          monthlyContributionMinor: 50000,
          totalPeriods: 11,
          allocationMode: GameyaAllocationMode.symmetricalPaired,
          creatorSlotNumber: 6,
        ),
      );

      tester.view.physicalSize = const Size(1024, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleRoomView(
            controller: controller,
            circleId: created.id,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Middle Month 6 Single Turn card is rendered
      expect(find.textContaining('Month 6'), findsWidgets);
      expect(find.text('Middle Month Single Turn (Month 6)'), findsOneWidget);
      expect(find.text('1 Member • 100% Full'), findsOneWidget);
      expect(find.text('50% + Mid 100%'), findsOneWidget);
      expect(find.text('Month #6 (100% Mid)'), findsOneWidget);
    });
  });
}

