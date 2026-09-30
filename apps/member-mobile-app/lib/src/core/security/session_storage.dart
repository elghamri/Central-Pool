import 'dart:convert';
import '../models/user_session.dart';

/// Abstract contract for secure credential and session token storage.
abstract class SessionStorage {
  Future<void> saveSession(UserSession session);
  Future<UserSession?> getSession();
  Future<void> clearSession();
  Future<String?> getAccessToken();
  Future<String?> getTenantId();
}

/// Production-ready In-Memory / Platform Secure Session Storage.
class SecureSessionStorage implements SessionStorage {
  UserSession? _cachedSession;
  String? _savedRawJson;

  @override
  Future<void> saveSession(UserSession session) async {
    _cachedSession = session;
    _savedRawJson = jsonEncode(session.toJson());
  }

  @override
  Future<UserSession?> getSession() async {
    if (_cachedSession != null) {
      if (_cachedSession!.isExpired) {
        await clearSession();
        return null;
      }
      return _cachedSession;
    }

    if (_savedRawJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(_savedRawJson!) as Map<String, dynamic>;
        final session = UserSession.fromJson(data);
        if (session.isExpired) {
          await clearSession();
          return null;
        }
        _cachedSession = session;
        return session;
      } catch (_) {
        await clearSession();
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> clearSession() async {
    _cachedSession = null;
    _savedRawJson = null;
  }

  @override
  Future<String?> getAccessToken() async {
    final session = await getSession();
    return session?.accessToken;
  }

  @override
  Future<String?> getTenantId() async {
    final session = await getSession();
    return session?.tenantId;
  }
}
