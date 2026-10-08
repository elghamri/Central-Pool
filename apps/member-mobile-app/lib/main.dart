import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

import 'src/core/firebase/firebase_config.dart';
import 'src/core/firebase/firebase_options.dart';
import 'src/core/firebase/firebase_firestore_service.dart';
import 'src/core/firebase/firebase_auth_service.dart';
import 'src/core/firebase/firebase_gameya_repository.dart';
import 'src/core/models/user_session.dart';
import 'src/core/network/api_client.dart';
import 'src/core/security/session_storage.dart';
import 'src/features/auth/state/auth_controller.dart';
import 'src/features/auth/state/auth_state.dart';
import 'src/features/auth/views/login_screen.dart';
import 'src/features/auth/views/register_screen.dart';
import 'src/features/auth/views/splash_screen.dart';
import 'src/features/auth/views/verify_otp_screen.dart';
import 'src/features/auth/views/welcome_screen.dart';
import 'src/features/consumer_gameya/data/gameya_repository.dart';
import 'src/features/consumer_gameya/views/consumer_gameya_shell_view.dart';
import 'src/features/consumer_gameya/state/gameya_controller.dart';
import 'src/features/central_pool/data/central_pool_repository.dart';
import 'src/features/central_pool/state/central_pool_controller.dart';
import 'src/features/central_pool/providers/central_pool_providers.dart';
import 'src/features/central_pool/views/central_pool_shell_view.dart';
import 'package:flutter/foundation.dart';
import 'src/features/shell/views/admin_shell_view.dart';
import 'src/features/shell/views/ops_shell_view.dart';
import 'src/features/shell/views/platform_shell_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve target environment safely:
  // INVARIANT: In Release mode, targetEnv is ALWAYS FirebaseEnvironment.production.
  // No --dart-define=ENV value may override a Release build.
  final targetEnv = resolveFirebaseEnvironment();

  // Initialize Firebase with isolated environment configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform(
        environment: targetEnv,
      ),
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  final sessionStorage = SecureSessionStorage();
  final firestoreService = FirebaseFirestoreService();
  final authService = FirebaseAuthService();
  final authController = AuthController(
    authService: authService,
    sessionStorage: sessionStorage,
  );

  final gameyaRepository = FirebaseGameyaRepository(
    firestoreService: firestoreService,
    authService: authService,
  );

  // Restore existing session
  await authController.initialize();

  runApp(
    CollaborativeFinanceApp(
      authController: authController,
      gameyaRepository: gameyaRepository,
      enableCentralPoolExperience: true,
    ),
  );
}

/// Root Application Widget for Collaborative Finance Platform.
class CollaborativeFinanceApp extends StatefulWidget {
  final AuthController authController;
  final GameyaRepository? gameyaRepository;
  final CentralPoolRepository? centralPoolRepository;
  final bool enableCentralPoolExperience;

  const CollaborativeFinanceApp({
    super.key,
    required this.authController,
    this.gameyaRepository,
    this.centralPoolRepository,
    this.enableCentralPoolExperience = false,
  });

  @override
  State<CollaborativeFinanceApp> createState() => _CollaborativeFinanceAppState();
}

class _CollaborativeFinanceAppState extends State<CollaborativeFinanceApp> {
  // Navigation sub-state for unauthenticated flow
  String _unauthRoute = 'welcome'; // 'welcome', 'login', 'register'
  CentralPoolController? _centralPoolController;
  GameyaController? _gameyaController;
  String? _cachedMemberUserId;

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthStateChanged);
    _centralPoolController?.dispose();
    _gameyaController?.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (widget.authController.value is Unauthenticated) {
      _centralPoolController?.dispose();
      _centralPoolController = null;
      _gameyaController?.dispose();
      _gameyaController = null;
      _cachedMemberUserId = null;
      if (mounted && _unauthRoute != 'welcome') {
        setState(() => _unauthRoute = 'welcome');
      }
    }
  }

  CentralPoolController _getOrCreateCentralPoolController(String userId, String tenantId) {
    if (_centralPoolController != null && _cachedMemberUserId == userId) {
      return _centralPoolController!;
    }
    _centralPoolController?.dispose();
    _cachedMemberUserId = userId;
    _centralPoolController = CentralPoolController(
      repository: widget.centralPoolRepository ?? CentralPoolRepository(baseUrl: resolveCentralPoolBaseUrl()),
      tenantId: tenantId,
      memberId: userId,
    );
    return _centralPoolController!;
  }

  GameyaController _getOrCreateGameyaController(String userId) {
    if (_gameyaController != null && _cachedMemberUserId == userId) {
      return _gameyaController!;
    }
    _gameyaController?.dispose();
    _cachedMemberUserId = userId;
    _gameyaController = GameyaController(
      repository: widget.gameyaRepository ??
          FirebaseGameyaRepository(
            firestoreService: FirebaseFirestoreService(),
            authService: FirebaseAuthService(),
          ),
      currentUserId: userId,
    );
    return _gameyaController!;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collaborative Finance Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: ValueListenableBuilder<AuthState>(
        valueListenable: widget.authController,
        builder: (context, state, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _resolveScreenForState(state),
          );
        },
      ),
    );
  }

  Widget _resolveScreenForState(AuthState state) {
    if (state is AuthInitializing) {
      return const SplashScreen(key: ValueKey('splash_screen'));
    }

    if (state is Authenticated) {
      if (state.session.role == UserRole.member) {
        if (widget.enableCentralPoolExperience || widget.centralPoolRepository != null) {
          return CentralPoolShellView(
            key: const ValueKey('central_pool_shell'),
            controller: _getOrCreateCentralPoolController(state.session.userId, state.session.tenantId),
            onLogout: () {
              setState(() => _unauthRoute = 'welcome');
              widget.authController.logout();
            },
          );
        }
        return ConsumerGameyaShellView(
          key: const ValueKey('consumer_gameya_shell'),
          controller: _getOrCreateGameyaController(state.session.userId),
          onLogout: () {
            setState(() => _unauthRoute = 'welcome');
            widget.authController.logout();
          },
        );
      } else if (state.session.role == UserRole.platformAdmin) {
        return PlatformShellView(
          key: const ValueKey('platform_shell'),
          session: state.session,
          onLogout: () {
            setState(() => _unauthRoute = 'welcome');
            widget.authController.logout();
          },
        );
      } else if (state.session.role == UserRole.treasuryMaker ||
          state.session.role == UserRole.treasuryChecker) {
        return OpsShellView(
          key: const ValueKey('ops_shell'),
          session: state.session,
          onLogout: () {
            setState(() => _unauthRoute = 'welcome');
            widget.authController.logout();
          },
        );
      } else {
        return AdminShellView(
          key: const ValueKey('admin_shell'),
          session: state.session,
          onLogout: () {
            setState(() => _unauthRoute = 'welcome');
            widget.authController.logout();
          },
        );
      }
    }

    if (state is OtpChallengeRequired) {
      return VerifyOtpScreen(
        key: const ValueKey('verify_otp_screen'),
        identifier: state.identifier,
        tenantId: state.tenantId,
        onVerify: (req) => widget.authController.verifyOtp(req),
        onCancel: () => widget.authController.logout(),
      );
    }

    final bool isAuthenticating = state is Authenticating;
    final String? errorMessage = state is AuthenticationFailure ? state.errorMessage : null;

    if (_unauthRoute == 'login') {
      return LoginScreen(
        key: const ValueKey('login_screen'),
        isLoading: isAuthenticating,
        errorMessage: errorMessage,
        onSubmit: (req) => widget.authController.login(req),
        onNavigateToRegister: () => setState(() => _unauthRoute = 'register'),
      );
    } else if (_unauthRoute == 'register') {
      return RegisterScreen(
        key: const ValueKey('register_screen'),
        isLoading: isAuthenticating,
        errorMessage: errorMessage,
        onSubmit: (req) => widget.authController.register(req),
        onNavigateToLogin: () => setState(() => _unauthRoute = 'login'),
      );
    } else {
      return WelcomeScreen(
        key: const ValueKey('welcome_screen'),
        onSignIn: () => setState(() => _unauthRoute = 'login'),
        onRegister: () => setState(() => _unauthRoute = 'register'),
      );
    }
  }
}
