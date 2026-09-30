import '../../../core/models/user_session.dart';

/// Exhaustive sealed state hierarchy for Authentication lifecycle.
abstract class AuthState {
  const AuthState();
}

/// Initial state while checking secure storage for active session.
class AuthInitializing extends AuthState {
  const AuthInitializing();
}

/// No active session exists; user must sign in or register.
class Unauthenticated extends AuthState {
  final String? message;
  const Unauthenticated({this.message});
}

/// Authentication or registration request in-flight.
class Authenticating extends AuthState {
  final String message;
  const Authenticating({this.message = 'Verifying credentials...'});
}

/// User has an active, valid, and authenticated session.
class Authenticated extends AuthState {
  final UserSession session;
  const Authenticated(this.session);
}

/// Authentication failed with a specific server/client error.
class AuthenticationFailure extends AuthState {
  final String errorMessage;
  final String? correlationId;
  const AuthenticationFailure(this.errorMessage, {this.correlationId});
}

/// Multi-factor OTP challenge required to complete authentication.
class OtpChallengeRequired extends AuthState {
  final String identifier;
  final String tenantId;
  const OtpChallengeRequired({required this.identifier, required this.tenantId});
}

/// Session has expired; user must re-authenticate.
class SessionExpired extends AuthState {
  const SessionExpired();
}

/// Logout operation in-flight.
class LoggingOut extends AuthState {
  const LoggingOut();
}
