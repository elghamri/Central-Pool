import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/models/auth_dto.dart';
import 'package:member_mobile_app/src/core/models/user_session.dart';
import 'package:member_mobile_app/src/core/network/api_client.dart';
import 'package:member_mobile_app/src/core/security/session_storage.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_controller.dart';
import 'package:member_mobile_app/src/features/auth/state/auth_state.dart';

void main() {
  group('AuthController — State Machine Tests', () {
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

    test('initial state transitions from AuthInitializing to Unauthenticated when no saved session exists', () async {
      expect(authController.value, isA<AuthInitializing>());

      await authController.initialize();
      expect(authController.value, isA<Unauthenticated>());
    });

    test('restores saved active session into Authenticated state on startup', () async {
      final session = UserSession(
        userId: 'usr-member-001',
        email: 'sarah@example.com',
        fullName: 'Sarah Member',
        tenantId: 'TENANT-ALPHA',
        role: UserRole.member,
        accessToken: 'valid-jwt-token-2026',
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
      );

      await sessionStorage.saveSession(session);
      await authController.initialize();

      expect(authController.value, isA<Authenticated>());
      final active = (authController.value as Authenticated).session;
      expect(active.userId, 'usr-member-001');
      expect(active.role, UserRole.member);
    });

    test('login authenticates user and updates session securely', () async {
      await authController.login(
        const LoginRequest(
          identifier: 'admin@collaborativefinance.org',
          password: 'Password123!',
          tenantId: 'TENANT-ALPHA',
        ),
      );

      expect(authController.value, isA<Authenticated>());
      final session = (authController.value as Authenticated).session;
      expect(session.role, UserRole.orgAdmin);
      expect(session.fullName, 'Organization Admin');
    });

    test('logout clears session storage and resets state to Unauthenticated', () async {
      await authController.login(
        const LoginRequest(
          identifier: 'member@collaborativefinance.org',
          password: 'Password123!',
        ),
      );
      expect(authController.value, isA<Authenticated>());

      await authController.logout();
      expect(authController.value, isA<Unauthenticated>());

      final saved = await sessionStorage.getSession();
      expect(saved, isNull);
    });
  });
}
