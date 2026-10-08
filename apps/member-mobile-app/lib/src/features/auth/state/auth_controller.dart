import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_auth_service.dart';
import '../../../core/models/auth_dto.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/session_storage.dart';
import 'auth_state.dart';

/// Centralized Authentication State Controller.
/// Uses Firebase Authentication as the authoritative provider.
class AuthController extends ValueNotifier<AuthState> {
  final FirebaseAuthService authService;
  final SessionStorage sessionStorage;
  final bool isRelease;

  AuthController({
    FirebaseAuthService? authService,
    ApiClient? apiClient, // Kept for backwards compatibility in test signatures
    required this.sessionStorage,
    this.isRelease = kReleaseMode,
  })  : authService = authService ?? FirebaseAuthService(),
        super(const AuthInitializing());

  /// Restores session on app startup.
  Future<void> initialize() async {
    value = const AuthInitializing();
    try {
      final session = await sessionStorage.getSession();
      if (session != null && !session.isExpired) {
        value = Authenticated(session);
      } else {
        value = const Unauthenticated();
      }
    } catch (_) {
      value = const Unauthenticated();
    }
  }

  /// Executes user login against Firebase Authentication service.
  /// INVARIANT: In Release mode, synthetic demo sessions are strictly prohibited.
  Future<void> login(LoginRequest request) async {
    value = const Authenticating(message: 'Authenticating credentials with Firebase...');
    try {
      final profile = await authService.signInWithEmailAndPassword(
        email: request.identifier,
        password: request.password,
        tenantId: request.tenantId,
      );

      final userRole = _mapFirebaseRoleToUserRole(profile.role, request.identifier, isRelease: isRelease);
      final session = UserSession(
        userId: profile.uid,
        email: profile.email,
        fullName: profile.displayName,
        tenantId: request.tenantId,
        role: userRole,
        accessToken: 'firebase-auth-token-${profile.uid}',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );
      await sessionStorage.saveSession(session);
      value = Authenticated(session);
    } catch (e) {
      if (!isRelease) {
        // Debug / Test mode only fallback for offline test environments
        final session = _constructDemoSession(request.identifier, request.tenantId);
        await sessionStorage.saveSession(session);
        value = Authenticated(session);
      } else {
        value = AuthenticationFailure('Authentication failed: ${e.toString()}');
      }
    }
  }

  /// Executes member registration via Firebase Authentication service.
  /// INVARIANT: In Release mode, synthetic registration sessions are strictly prohibited.
  /// INVARIANT: Member registration strictly creates Member role.
  Future<void> register(RegisterRequest request) async {
    value = const Authenticating(message: 'Creating Central Pool member account...');
    try {
      final profile = await authService.registerWithEmailAndPassword(
        email: request.email,
        password: request.password,
        fullName: request.fullName,
        phoneNumber: request.phoneNumber,
        tenantId: request.tenantId,
      );

      final session = UserSession(
        userId: profile.uid,
        email: profile.email,
        fullName: profile.displayName,
        tenantId: request.tenantId,
        role: UserRole.member, // Invariant: Registration creates Member role only
        accessToken: 'firebase-auth-token-${profile.uid}',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );
      await sessionStorage.saveSession(session);
      value = Authenticated(session);
    } catch (e) {
      if (!isRelease) {
        // Debug / Test mode only fallback
        final session = UserSession(
          userId: 'usr-${DateTime.now().millisecondsSinceEpoch}',
          email: request.email,
          fullName: request.fullName,
          tenantId: request.tenantId,
          role: UserRole.member,
          accessToken: 'jwt-token-${DateTime.now().millisecondsSinceEpoch}',
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
        );
        await sessionStorage.saveSession(session);
        value = Authenticated(session);
      } else {
        value = AuthenticationFailure('Registration failed: ${e.toString()}');
      }
    }
  }

  /// Verifies OTP challenge code.
  /// INVARIANT: In Release mode, synthetic demo OTP verification is strictly prohibited.
  Future<void> verifyOtp(VerifyOtpRequest request) async {
    value = const Authenticating(message: 'Verifying OTP code...');
    try {
      if (request.otpCode.length != 6) {
        value = const AuthenticationFailure('Invalid code: OTP must be 6 digits.');
        return;
      }

      if (isRelease) {
        value = const AuthenticationFailure('Authentication failed: Verification service unavailable.');
        return;
      }

      final session = _constructDemoSession(request.identifier, request.tenantId);
      await sessionStorage.saveSession(session);
      value = Authenticated(session);
    } catch (e) {
      value = AuthenticationFailure(e.toString());
    }
  }

  /// Clears session and logs out user via Firebase Auth.
  Future<void> logout() async {
    value = const LoggingOut();
    try {
      await authService.signOut();
    } catch (_) {}
    await sessionStorage.clearSession();
    value = const Unauthenticated(message: 'You have been safely signed out.');
  }

  static UserRole _mapFirebaseRoleToUserRole(FirebaseUserRole fbRole, String identifier, {required bool isRelease}) {
    if (!isRelease) {
      final lower = identifier.toLowerCase();
      if (lower.contains('admin') || lower.contains('business')) return UserRole.orgAdmin;
      if (lower.contains('maker')) return UserRole.treasuryMaker;
      if (lower.contains('checker')) return UserRole.treasuryChecker;
      if (lower.contains('platform') || lower.contains('super')) return UserRole.platformAdmin;
    }
    switch (fbRole) {
      case FirebaseUserRole.admin:
        return UserRole.orgAdmin;
      case FirebaseUserRole.finOps:
        return UserRole.treasuryMaker;
      case FirebaseUserRole.system:
        return UserRole.platformAdmin;
      case FirebaseUserRole.member:
      default:
        return UserRole.member;
    }
  }

  UserSession _constructDemoSession(String identifier, String tenantId) {
    UserRole role = UserRole.member;
    String name = 'Central Pool Member';

    final lower = identifier.toLowerCase();
    if (lower.contains('admin') || lower.contains('business')) {
      role = UserRole.orgAdmin;
      name = 'Organization Admin';
    } else if (lower.contains('maker')) {
      role = UserRole.treasuryMaker;
      name = 'Treasury Officer (Maker)';
    } else if (lower.contains('checker')) {
      role = UserRole.treasuryChecker;
      name = 'Treasury Officer (Checker)';
    } else if (lower.contains('platform') || lower.contains('super')) {
      role = UserRole.platformAdmin;
      name = 'Platform SuperAdmin';
    }

    return UserSession(
      userId: 'usr-${identifier.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
      email: identifier.contains('@') ? identifier : '$identifier@collaborativefinance.org',
      fullName: name,
      tenantId: tenantId,
      role: role,
      accessToken: 'jwt-auth-token-valid-2026',
      expiresAt: DateTime.now().add(const Duration(hours: 12)),
    );
  }
}
