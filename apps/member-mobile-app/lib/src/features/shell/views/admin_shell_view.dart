import 'package:flutter/material.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/session_storage.dart';
import '../../admin/views/admin_console_shell.dart';

/// Screen 22–28: Application Shell for Business Admin Console.
class AdminShellView extends StatelessWidget {
  final UserSession session;
  final VoidCallback onLogout;
  final ApiClient? apiClient;

  const AdminShellView({
    super.key,
    required this.session,
    required this.onLogout,
    this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    final client = apiClient ?? ApiClient(sessionStorage: SecureSessionStorage());
    return AdminConsoleShell(
      apiClient: client,
      session: session,
      onSignOut: onLogout,
    );
  }
}
