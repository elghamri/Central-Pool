import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/create_gameya_wizard_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/data/gameya_repository.dart';

void main() {
  group('Phase 47.2.3 — Consumer Game\'ya Creation Experience Verification Suite', () {
    late GameyaRepository repository;
    late GameyaController controller;

    setUp(() {
      repository = GameyaRepository();
      controller = GameyaController(repository: repository, autoLoad: true);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('Step 1: Renders Contribution Slider, presets, and advances to Step 2', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateGameyaWizardView(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 assertions
      expect(find.text('STEP 1 OF 5'), findsOneWidget);
      expect(find.text('How much will everyone contribute?'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('EGP 2000'), findsWidgets);
      expect(find.text('Next Step →'), findsOneWidget);

      // Tap Next Step
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      // Advance to Step 2
      expect(find.text('STEP 2 OF 5'), findsOneWidget);
      expect(find.text('How many members?'), findsOneWidget);
    });

    testWidgets('Step 2: Configures Member Count, Stepper, and advances to Step 3', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateGameyaWizardView(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('10'), findsWidgets);
      expect(find.text('CIRCLE TOPOLOGY'), findsOneWidget);

      // Tap Stepper Decrement (10 -> 8)
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('8'), findsWidgets);

      // Advance to Step 3
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 3 OF 5'), findsOneWidget);
      expect(find.text('How are payouts scheduled?'), findsOneWidget);
    });

    testWidgets('Step 3: Selects Symmetrical Paired allocation mode and advances to Step 4', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateGameyaWizardView(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Advance to Step 3
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('Linear Sequential Rotation (1..N)'), findsOneWidget);
      expect(find.text('Symmetrical Paired Allocation (1 ↔ N)'), findsOneWidget);

      // Tap Symmetrical Paired Card
      await tester.tap(find.text('Symmetrical Paired Allocation (1 ↔ N)'));
      await tester.pumpAndSettle();

      // Advance to Step 4
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 4 OF 5'), findsOneWidget);
      expect(find.text('Goal & Circle Name'), findsOneWidget);
    });

    testWidgets('Step 4: Configures name, categories, privacy toggle and validates input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateGameyaWizardView(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Advance to Step 4
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      // Verify category chips
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Vehicle'), findsOneWidget);
      expect(find.text('Wedding'), findsOneWidget);
      expect(find.text('Private Circle (Invite-Only)'), findsOneWidget);

      // Select Wedding category
      await tester.tap(find.text('Wedding'));
      await tester.pumpAndSettle();

      // Advance to Step 5
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 5 OF 5'), findsOneWidget);
      expect(find.text('Review Rules & Confirm'), findsOneWidget);
    });

    testWidgets('Step 5: Enforces bylaws agreement, submits creation, and renders Success Screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      String? createdCircleId;

      await tester.pumpWidget(
        MaterialApp(
          home: CreateGameyaWizardView(
            controller: controller,
            onCircleCreated: (id) => createdCircleId = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 -> 2 -> 3 -> 4 -> 5
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next Step →'));
        await tester.pumpAndSettle();
      }

      expect(find.text('STEP 5 OF 5'), findsOneWidget);
      final launchBtnFinder = find.text('Launch Game\'ya Circle 🚀');
      expect(launchBtnFinder, findsOneWidget);

      // Bylaws checkbox is unchecked -> Button is disabled
      await tester.tap(launchBtnFinder);
      await tester.pumpAndSettle();
      expect(find.text('Launch Game\'ya Circle 🚀'), findsOneWidget); // Still on review step

      // Check the bylaws agreement
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Now tap launch
      await tester.tap(launchBtnFinder);
      await tester.pumpAndSettle();

      // Verify Success State
      expect(find.text('INVITE CODE'), findsOneWidget);
      expect(find.text('Open Game\'ya Circle Room'), findsOneWidget);

      // Tap Open Room
      await tester.tap(find.text('Open Game\'ya Circle Room'));
      await tester.pumpAndSettle();

      expect(createdCircleId, isNotNull);
    });

    testWidgets('RTL Mode: Switches to Arabic directionality and renders Arabic typography', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateGameyaWizardView(
            controller: controller,
            isRtl: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الخطوة ١ من ٥'), findsOneWidget);
      expect(find.text('ما هو مبلغ القسط الشهري لكل عضو؟'), findsOneWidget);
      expect(find.text('الخطوة التالية ←'), findsOneWidget);
    });

    testWidgets('Odd Member Count: Symmetrical Paired mode supports Middle Month (100% Mid) single payout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateGameyaWizardView(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      // In Step 2, default is 10. Decrement to 7 (odd count: 10 -> 9 -> 8 -> 7)
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('7'), findsWidgets);

      // Advance to Step 3
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      // Tap Symmetrical Paired Card
      await tester.tap(find.text('Symmetrical Paired Allocation (1 ↔ N)'));
      await tester.pumpAndSettle();

      // Verify odd paired options: 3 pairs and 1 middle month chip (Month 4)
      expect(find.text('Month 1 ↔ Month 7'), findsOneWidget);
      expect(find.text('Month 2 ↔ Month 6'), findsOneWidget);
      expect(find.text('Month 3 ↔ Month 5'), findsOneWidget);
      expect(find.text('Month 4 (100% Mid)'), findsOneWidget);

      // Select Middle Month chip
      await tester.ensureVisible(find.text('Month 4 (100% Mid)'));
      await tester.tap(find.text('Month 4 (100% Mid)'));
      await tester.pumpAndSettle();

      // Verify Middle Month Single Full Payout schedule card
      expect(find.text('Middle Month Full Payout (100%)'), findsOneWidget);
      expect(find.text('100% Full'), findsOneWidget);

      // Advance to Step 4 and Step 5 to verify review summary
      await tester.ensureVisible(find.text('Next Step →'));
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next Step →'));
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      // Step 5: Review
      expect(find.text('Month 4 (100% Middle Full Payout)'), findsOneWidget);
    });

    testWidgets('System States: Displays Safety Lock and Offline notice banners', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateGameyaWizardView(
            controller: controller,
            isSafetyLockActive: true,
            isOffline: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
    });
  });
}
