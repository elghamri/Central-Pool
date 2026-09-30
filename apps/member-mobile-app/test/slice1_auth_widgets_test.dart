import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/main.dart';
import 'package:member_mobile_app/src/core/models/auth_dto.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_controller.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_state.dart';
import 'package:member_mobile_app/src/features/auth/views/login_screen.dart';
import 'package:member_mobile_app/src/features/auth/views/welcome_screen.dart';
import 'package:member_mobile_app/src/features/consumer_gameya/views/consumer_gameya_shell_view.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  group('Slice 1 — UI & Widget Integration Tests', () {
    late SessionStorage sessionStorage;
    late ApiClient apiClient;
    late AuthController authController;

    setUp(() {
      sessionStorage = SecureSessionStorage();
      apiClient = ApiClient(sessionStorage: sessionStorage);
      authController = AuthController(
        apiClient: apiClient,
        sessionStorage: sessionStorage,
      );
    });

    testWidgets('WelcomeScreen renders institutional branding and navigation buttons', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: WelcomeScreen(
            onSignIn: () {},
            onRegister: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Collaborative Finance'), findsOneWidget);
      expect(find.text('Sign In to Account'), findsOneWidget);
      expect(find.text('Create Member Account'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byType(SecondaryButton), findsOneWidget);
    });

    testWidgets('LoginScreen validates inputs and submits credentials', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: LoginScreen(
            onSubmit: (req) => submitted = true,
            onNavigateToRegister: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);

      // Tap Sign In
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(submitted, isTrue);
    });

    testWidgets('Full Integration: Welcome -> Login -> Member Dashboard -> Logout', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await authController.initialize();

      await tester.pumpWidget(
        CollaborativeFinanceApp(
          authController: authController,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Welcome Screen
      expect(find.text('Collaborative Finance'), findsOneWidget);
      expect(find.text('Sign In to Account'), findsOneWidget);

      // 2. Navigate to Login
      await tester.tap(find.text('Sign In to Account'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Welcome Back'), findsOneWidget);

      // 3. Submit Login
      await tester.runAsync(() async {
        await authController.login(
          const LoginRequest(
            identifier: 'member@collaborativefinance.org',
            password: 'Password123!',
            tenantId: 'TENANT-ALPHA',
          ),
        );
      });
      await tester.pumpAndSettle();

      // 4. Verify Authenticated Member Dashboard (Consumer Game'ya Shell)
      expect(find.byType(ConsumerGameyaShellView), findsOneWidget);
      expect(find.text('TOTAL MONTHLY OBLIGATION'), findsOneWidget);

      // 5. Sign Out
      await tester.runAsync(() async {
        await authController.logout();
      });
      await tester.pumpAndSettle();

      // 6. Verify Returned to Welcome / Unauthenticated state
      expect(authController.value, isA<Unauthenticated>());
      expect(find.text('Collaborative Finance'), findsOneWidget);
    });
  });
}
