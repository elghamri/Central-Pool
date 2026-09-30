import 'package:flutter/material.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/session_storage.dart';
import '../../platform/state/platform_controller.dart';
import '../../platform/views/platform_console_shell.dart';

/// Top-level shell view for Platform Administrators (`UserRole.platformAdmin`).
class PlatformShellView extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;
  final ApiClient? apiClient;

  const PlatformShellView({
    super.key,
    required this.session,
    required this.onLogout,
    this.apiClient,
  });

  @override
  State<PlatformShellView> createState() => _PlatformShellViewState();
}

class _PlatformShellViewState extends State<PlatformShellView> {
  late final ApiClient _apiClient;
  late final PlatformController _controller;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient(sessionStorage: SecureSessionStorage());
    _controller = PlatformController(
      apiClient: _apiClient,
      session: widget.session,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformConsoleShell(
      apiClient: _apiClient,
      session: widget.session,
      onSignOut: widget.onLogout,
      controller: _controller,
    );
  }
}
