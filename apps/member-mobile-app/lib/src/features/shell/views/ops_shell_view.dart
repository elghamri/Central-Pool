import 'package:flutter/material.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/session_storage.dart';
import '../../ops/state/ops_controller.dart';
import '../../ops/views/ops_console_shell.dart';

/// Top-level shell view for Operations Users (`treasuryMaker`, `treasuryChecker`, `platformAdmin`).
class OpsShellView extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;
  final ApiClient? apiClient;

  const OpsShellView({
    super.key,
    required this.session,
    required this.onLogout,
    this.apiClient,
  });

  @override
  State<OpsShellView> createState() => _OpsShellViewState();
}

class _OpsShellViewState extends State<OpsShellView> {
  late final ApiClient _apiClient;
  late final OpsController _controller;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient(sessionStorage: SecureSessionStorage());
    _controller = OpsController(
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
    return OpsConsoleShell(
      apiClient: _apiClient,
      session: widget.session,
      onSignOut: widget.onLogout,
      controller: _controller,
    );
  }
}
