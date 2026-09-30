import 'user_session.dart';

/// Request payload for user login.
class LoginRequest {
  final String identifier; // Email or Username
  final String password;
  final String tenantId;

  const LoginRequest({
    required this.identifier,
    required this.password,
    this.tenantId = 'TENANT-ALPHA',
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
        'tenant_id': tenantId,
      };
}

/// Request payload for member registration.
class RegisterRequest {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String tenantId;
  final UserRole role;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    this.tenantId = 'TENANT-ALPHA',
    this.role = UserRole.member,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
        'tenant_id': tenantId,
        'role': role.name,
      };
}

/// Request payload for OTP verification.
class VerifyOtpRequest {
  final String identifier;
  final String otpCode;
  final String tenantId;

  const VerifyOtpRequest({
    required this.identifier,
    required this.otpCode,
    this.tenantId = 'TENANT-ALPHA',
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'otp_code': otpCode,
        'tenant_id': tenantId,
      };
}
