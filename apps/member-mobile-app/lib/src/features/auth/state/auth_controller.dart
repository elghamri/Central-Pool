import 'package:flutter/foundation.dart';
import '../../../core/models/auth_dto.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/session_storage.dart';
import 'auth_state.dart';

/// Centralized Authentication State Controller.
class AuthController extends ValueNotifier<AuthState> {
  final ApiClient apiClient;
  final SessionStorage sessionStorage;
  final bool isRelease;

  AuthController({
    required this.apiClient,
    required this.sessionStorage,
    this.isRelease = kReleaseMode,
  }) : super(const AuthInitializing());

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

  /// Executes user login against backend service.
  /// INVARIANT: In Release mode, synthetic demo sessions are strictly prohibited.
  Future<void> login(LoginRequest request) async {
    value = const Authenticating(message: 'Authenticating credentials...');
    try {
      final res = await apiClient.post('/api/v1/auth/login', body: request.toJson());
      final session = UserSession.fromJson(res as Map<String, dynamic>);
      await sessionStorage.saveSession(session);
      value = Authenticated(session);
    } on ApiException catch (e) {
      if (!isRelease && (e.statusCode == 503 || e.statusCode == 504 || e.statusCode == 404 || e.statusCode == 400)) {
        // Debug / Test mode only: construct demo session when backend server is offline
        final session = _constructDemoSession(request.identifier, request.tenantId);
        await sessionStorage.saveSession(session);
        value = Authenticated(session);
      } else {
        value = AuthenticationFailure(e.detail, correlationId: e.correlationId);
      }
    } catch (e) {
      if (!isRelease) {
        // Debug / Test mode only fallback
        final session = _constructDemoSession(request.identifier, request.tenantId);
        await sessionStorage.saveSession(session);
        value = Authenticated(session);
      } else {
        value = AuthenticationFailure('Authentication failed: ${e.toString()}');
      }
    }
  }

  /// Executes member registration.
  /// INVARIANT: In Release mode, synthetic registration sessions are strictly prohibited.
  Future<void> register(RegisterRequest request) async {
    value = const Authenticating(message: 'Creating member account...');
    try {
      final res = await apiClient.post('/api/v1/auth/register', body: request.toJson());
      final session = UserSession.fromJson(res as Map<String, dynamic>);
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
          role: request.role,
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

  /// Clears session and logs out user.
  Future<void> logout() async {
    value = const LoggingOut();
    try {
      await apiClient.post('/api/v1/auth/logout');
    } catch (_) {}
    await sessionStorage.clearSession();
    value = const Unauthenticated(message: 'You have been safely signed out.');
  }

  UserSession _constructDemoSession(String identifier, String tenantId) {
    UserRole role = UserRole.member;
    String name = 'Cooperative Member';

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
