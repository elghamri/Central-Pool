/// Supported User Roles in the Collaborative Finance Platform.
enum UserRole {
  member,
  orgAdmin,
  treasuryMaker,
  treasuryChecker,
  platformAdmin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'org_admin':
      case 'orgadmin':
      case 'admin':
        return UserRole.orgAdmin;
      case 'treasury_maker':
      case 'maker':
        return UserRole.treasuryMaker;
      case 'treasury_checker':
      case 'checker':
        return UserRole.treasuryChecker;
      case 'platform_admin':
      case 'superadmin':
        return UserRole.platformAdmin;
      case 'member':
      default:
        return UserRole.member;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.orgAdmin:
        return 'Organization Admin';
      case UserRole.treasuryMaker:
        return 'Treasury Maker';
      case UserRole.treasuryChecker:
        return 'Treasury Checker';
      case UserRole.platformAdmin:
        return 'Platform Admin';
      case UserRole.member:
        return 'Cooperative Member';
    }
  }
}

/// Authenticated user session profile.
class UserSession {
  final String userId;
  final String email;
  final String fullName;
  final String tenantId;
  final UserRole role;
  final String accessToken;
  final DateTime expiresAt;

  const UserSession({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.tenantId,
    required this.role,
    required this.accessToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'email': email,
        'full_name': fullName,
        'tenant_id': tenantId,
        'role': role.name,
        'access_token': accessToken,
        'expires_at': expiresAt.toIso8601String(),
      };

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['user_id'] as String? ?? 'usr-anon',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Member',
      tenantId: json['tenant_id'] as String? ?? 'TENANT-ALPHA',
      role: UserRole.fromString(json['role'] as String?),
      accessToken: json['access_token'] as String? ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(hours: 8)),
    );
  }
}
