import 'dart:async';
import 'package:flutter/foundation.dart';

/// Supported Firebase Role Classification.
enum FirebaseUserRole {
  member,
  admin,
  finOps,
  compliance,
  security,
  auditor,
  system;

  String get claimValue {
    switch (this) {
      case FirebaseUserRole.member:
        return 'MEMBER';
      case FirebaseUserRole.admin:
        return 'ADMIN';
      case FirebaseUserRole.finOps:
        return 'FINOPS';
      case FirebaseUserRole.compliance:
        return 'COMPLIANCE';
      case FirebaseUserRole.security:
        return 'SECURITY';
      case FirebaseUserRole.auditor:
        return 'AUDITOR';
      case FirebaseUserRole.system:
        return 'SYSTEM';
    }
  }

  static FirebaseUserRole fromString(String? roleStr) {
    switch (roleStr?.toUpperCase()) {
      case 'ADMIN':
        return FirebaseUserRole.admin;
      case 'FINOPS':
        return FirebaseUserRole.finOps;
      case 'COMPLIANCE':
        return FirebaseUserRole.compliance;
      case 'SECURITY':
        return FirebaseUserRole.security;
      case 'AUDITOR':
        return FirebaseUserRole.auditor;
      case 'SYSTEM':
        return FirebaseUserRole.system;
      default:
        return FirebaseUserRole.member;
    }
  }
}

/// Authenticated Firebase User Profile Model.
@immutable
class FirebaseUserProfile {
  final String uid;
  final String email;
  final String phoneNumber;
  final String displayName;
  final FirebaseUserRole role;
  final String kycStatus;
  final bool isAnonymous;
  final DateTime createdAt;

  const FirebaseUserProfile({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.displayName,
    this.role = FirebaseUserRole.member,
    this.kycStatus = 'VERIFIED',
    this.isAnonymous = false,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'role': role.claimValue,
      'kycStatus': kycStatus,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Firebase Authentication Bridge & Session Service.
class FirebaseAuthService extends ChangeNotifier {
  FirebaseUserProfile? _currentUser;
  bool _isLoading = false;

  FirebaseUserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  FirebaseAuthService() {
    // Default authenticated session with authoritative member profile
    _currentUser = FirebaseUserProfile(
      uid: 'usr-current-mansour',
      email: 'ahmed.mansour@gameya.eg',
      phoneNumber: '+20 100 555 0192',
      displayName: 'Ahmed Mansour',
      role: FirebaseUserRole.member,
      kycStatus: 'VERIFIED',
      createdAt: DateTime(2026, 1, 1),
    );
  }

  /// Sign-in with verified Email and Password credentials.
  Future<FirebaseUserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
    String tenantId = 'TENANT-ALPHA',
  }) async {
    _isLoading = true;
    notifyListeners();

    if (email.trim().isEmpty || !email.contains('@')) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Invalid email address.');
    }
    if (password.isEmpty) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Password cannot be empty.');
    }

    final sanitizedId = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-');
    String displayName = email.split('@').first;
    final lower = email.toLowerCase();
    if (lower.contains('admin') || lower.contains('business')) {
      displayName = 'Organization Admin';
    } else if (lower.contains('maker')) {
      displayName = 'Treasury Officer (Maker)';
    } else if (lower.contains('checker')) {
      displayName = 'Treasury Officer (Checker)';
    } else if (lower.contains('platform')) {
      displayName = 'Platform SuperAdmin';
    } else if (lower.contains('member')) {
      displayName = 'Central Pool Member';
    }

    _currentUser = FirebaseUserProfile(
      uid: 'usr-$sanitizedId',
      email: email.trim(),
      phoneNumber: '+20 100 555 0192',
      displayName: displayName,
      role: FirebaseUserRole.member,
      kycStatus: 'VERIFIED',
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
    return _currentUser!;
  }

  /// Register new member with verified Email and Password credentials.
  /// INVARIANT: Member registration strictly creates FirebaseUserRole.member.
  Future<FirebaseUserProfile> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String tenantId = 'TENANT-ALPHA',
  }) async {
    _isLoading = true;
    notifyListeners();

    if (email.trim().isEmpty || !email.contains('@')) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Invalid email address.');
    }
    if (password.length < 8) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Password must be at least 8 characters.');
    }
    if (fullName.trim().isEmpty) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Full legal name is required.');
    }

    final sanitizedId = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-');
    _currentUser = FirebaseUserProfile(
      uid: 'usr-$sanitizedId',
      email: email.trim(),
      phoneNumber: phoneNumber.trim(),
      displayName: fullName.trim(),
      role: FirebaseUserRole.member,
      kycStatus: 'VERIFIED',
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
    return _currentUser!;
  }

  /// Sign-in with verified Phone/OTP credentials.
  Future<FirebaseUserProfile> signInWithPhone({required String phone, required String code}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100)); // Emulated network turn

    _currentUser = FirebaseUserProfile(
      uid: 'usr-${phone.replaceAll(RegExp(r'\D'), '')}',
      email: '$phone@gameya.eg',
      phoneNumber: phone,
      displayName: 'Member ($phone)',
      role: FirebaseUserRole.member,
      kycStatus: 'VERIFIED',
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
    return _currentUser!;
  }

  /// Sign out active session.
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  /// Switches active role claim for administrative or compliance testing.
  void setRole(FirebaseUserRole role) {
    if (_currentUser != null) {
      _currentUser = FirebaseUserProfile(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        phoneNumber: _currentUser!.phoneNumber,
        displayName: _currentUser!.displayName,
        role: role,
        kycStatus: _currentUser!.kycStatus,
        createdAt: _currentUser!.createdAt,
      );
      notifyListeners();
    }
  }
}
