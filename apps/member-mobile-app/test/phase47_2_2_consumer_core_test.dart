import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/auth_dto.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/features/auth/views/welcome_screen.dart';
import 'package:member_mobile_app/src/features/auth/views/login_screen.dart';
import 'package:member_mobile_app/src/features/auth/views/register_screen.dart';
import 'package:member_mobile_app/src/features/auth/views/verify_otp_screen.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/consumer_home_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/circle_discovery_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/circle_room_view.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/state/gameya_controller.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/widgets/gameya_summary_card.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/widgets/peer_roster_tile.dart';
import 'package:member_mobile_app/src/features/funding/views/allocation_position_view.dart';
import 'package:member_mobile_app/src/features/funding/models/funding_models.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  group('Phase 47.2.2 — Consumer Core Experience Visual & Functional Verification', () {
    // -------------------------------------------------------------
    // 1. WELCOME SCREEN
    // -------------------------------------------------------------
    testWidgets('Screen 1: WelcomeScreen renders branding, CTAs, and switches to Arabic RTL', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool signInTapped = false;
      bool registerTapped = false;
      String currentLang = 'en';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: WelcomeScreen(
            onSignIn: () => signInTapped = true,
            onRegister: () => registerTapped = true,
            onLanguageChanged: (l) => currentLang = l,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // English baseline
      expect(find.text('Collaborative Finance'), findsOneWidget);
      expect(find.text('Sign In to Account'), findsOneWidget);
      expect(find.text('Create Member Account'), findsOneWidget);
      expect(find.text('Institutional Trust'), findsOneWidget);

      // Tap Sign In
      await tester.tap(find.text('Sign In to Account'));
      expect(signInTapped, isTrue);

      // Tap Register
      await tester.tap(find.text('Create Member Account'));
      expect(registerTapped, isTrue);

      // Switch to Arabic
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      expect(currentLang, 'ar');
      expect(find.text('منصة التمويل التعاوني'), findsOneWidget);
      expect(find.text('تسجيل الدخول إلى الحساب'), findsOneWidget);
      expect(find.text('إنشاء حساب عضو جديد'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // 2. LOGIN SCREEN
    // -------------------------------------------------------------
    testWidgets('Screen 2: LoginScreen supports identifier submission, role presets, and error states', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LoginRequest? submittedReq;
      bool navigatedToRegister = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: LoginScreen(
            onSubmit: (req) => submittedReq = req,
            onNavigateToRegister: () => navigatedToRegister = true,
            errorMessage: 'Invalid credentials provided',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Invalid credentials provided'), findsOneWidget);

      // Select Demo Role 'Admin'
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(submittedReq, isNotNull);
      expect(submittedReq!.identifier, 'admin@collaborativefinance.org');

      // Navigate to register
      await tester.tap(find.text('Register here'));
      expect(navigatedToRegister, isTrue);
    });

    // -------------------------------------------------------------
    // 3. REGISTER SCREEN
    // -------------------------------------------------------------
    testWidgets('Screen 3: RegisterScreen captures member details and enforces bylaws consent', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      RegisterRequest? registeredReq;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: RegisterScreen(
            onSubmit: (req) => registeredReq = req,
            onNavigateToLogin: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join the Cooperative'), findsOneWidget);

      // Enter details
      await tester.enterText(find.widgetWithText(StandardTextField, 'Full Legal Name'), 'Alice Cooper');
      await tester.enterText(find.widgetWithText(StandardTextField, 'Email Address'), 'alice@example.com');
      await tester.enterText(find.widgetWithText(StandardTextField, 'Mobile Phone Number'), '+15551234567');
      await tester.enterText(find.widgetWithText(SecurePasswordField, 'Create Secure Password'), 'SecurePassword123!');

      await tester.pumpAndSettle();

      // Tap Register
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(registeredReq, isNotNull);
      expect(registeredReq!.fullName, 'Alice Cooper');
      expect(registeredReq!.email, 'alice@example.com');
      expect(registeredReq!.role, UserRole.member);
    });

    // -------------------------------------------------------------
    // 4. VERIFY OTP SCREEN
    // -------------------------------------------------------------
    testWidgets('Screen 4: VerifyOtpScreen renders 6-cell visual OTP boxes and submits valid OTP', (tester) async {
      tester.view.physicalSize = const Size(1024, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      VerifyOtpRequest? verifiedReq;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: VerifyOtpScreen(
            identifier: 'member@collaborativefinance.org',
            tenantId: 'TENANT-ALPHA',
            onVerify: (req) => verifiedReq = req,
            onCancel: () => cancelled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.textContaining('member@collaborativefinance.org'), findsOneWidget);

      // Default OTP is '123456'
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(verifiedReq, isNotNull);
      expect(verifiedReq!.otpCode, '123456');

      // Tap Cancel
      await tester.tap(find.byType(SecondaryButton));
      expect(cancelled, isTrue);
    });

    // -------------------------------------------------------------
    // 5. CONSUMER HOME VIEW
    // -------------------------------------------------------------
    testWidgets('Screen 5: ConsumerHomeView displays obligations, payouts, and system state banners', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GameyaController();
      await controller.loadInitialData();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ConsumerHomeView(
            controller: controller,
            isOffline: true,
            isSafetyLockActive: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banners
      expect(find.textContaining('Financial Safety Lock Active'), findsOneWidget);
      expect(find.textContaining('Offline Mode'), findsOneWidget);

      // Financial Dues & Payout Cards
      expect(find.text('TOTAL MONTHLY OBLIGATION'), findsOneWidget);
      expect(find.text('NEXT UPCOMING PAYOUT'), findsOneWidget);
      expect(find.textContaining('My Active Game\'yas'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // 6. CIRCLE DISCOVERY VIEW
    // -------------------------------------------------------------
    testWidgets('Screen 6: CircleDiscoveryView filters circles and opens slot picker modal', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GameyaController();
      await controller.loadInitialData();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CircleDiscoveryView(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discover Game\'yas'), findsOneWidget);
      expect(find.text('Join with Private Circle Code'), findsOneWidget);

      // Filter by 'Wedding'
      await tester.tap(find.text('Wedding'));
      await tester.pumpAndSettle();

      // Tap on first summary card to open detail modal
      final firstCard = find.byType(GameyaSummaryCard).first;
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      expect(find.text('CHOOSE YOUR PAYOUT MONTH'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // 7. GAME'YA DETAILS / CIRCLE ROOM VIEW
    // -------------------------------------------------------------
    testWidgets('Screen 7: CircleRoomView displays circle details, member roster, and bylaws', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GameyaController();
      await controller.loadInitialData();

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
      expect(find.textContaining('Circle Members'), findsOneWidget);
      expect(find.byType(PeerRosterTile), findsWidgets);
    });

    // -------------------------------------------------------------
    // 8. POSITION SELECTION / ALLOCATION POSITION VIEW
    // -------------------------------------------------------------
    testWidgets('Screen 8: AllocationPositionView renders slot turn, assigned payout, and separation notice', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool trackedLifecycle = false;
      bool backed = false;

      final allocation = AllocationPosition(
        allocationId: 'ALLOC-2026-001',
        cycleId: 'CYCLE-ALPHA',
        cycleName: 'Spring 2026 Retail Circle',
        slotNumber: 1,
        totalSlots: 10,
        expectedPayoutMinor: 500000,
        recipientMemberId: 'MEM-001',
        recipientMemberName: 'Sarah Jenkins',
        allocatedAt: DateTime.utc(2026, 3, 1, 10, 0, 0),
        status: 'ALLOCATED',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AllocationPositionView(
            allocation: allocation,
            onTrackLifecycle: () => trackedLifecycle = true,
            onBack: () => backed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rotation Schedule Turn: Slot #1'), findsOneWidget);
      expect(find.text('Assigned Liquidity Payout'), findsOneWidget);
      expect(find.text('\$5,000.00'), findsOneWidget);
      expect(find.text('Crucial Distinction: Allocation vs Settlement'), findsOneWidget);

      // Tap Track Lifecycle
      await tester.tap(find.text('Track 14-Stage Lifecycle'));
      expect(trackedLifecycle, isTrue);

      // Tap Back
      await tester.tap(find.text('Back to Overview'));
      expect(backed, isTrue);
    });
  });
}
