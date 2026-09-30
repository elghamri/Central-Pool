import 'package:flutter/foundation.dart';

/// Firebase Environment Configuration & Runtime Switch.
enum FirebaseEnvironment {
  development,
  staging,
  production;

  String get projectId {
    switch (this) {
      case FirebaseEnvironment.development:
        return 'central-pool-dev';
      case FirebaseEnvironment.staging:
        return 'central-pool-staging';
      case FirebaseEnvironment.production:
        return 'central-pool-production';
    }
  }

  bool get isProduction => this == FirebaseEnvironment.production;
}

/// Authoritative Firebase Runtime Options.
@immutable
class FirebaseAppConfig {
  final FirebaseEnvironment environment;
  final String projectId;
  final bool useEmulators;
  final String authEmulatorHost;
  final String firestoreEmulatorHost;
  final String functionsEmulatorHost;
  final String storageEmulatorHost;
  final bool realMoneyEnabled; // MUST REMAIN FALSE

  const FirebaseAppConfig({
    this.environment = FirebaseEnvironment.development,
    required this.projectId,
    this.useEmulators = true,
    this.authEmulatorHost = 'localhost:9099',
    this.firestoreEmulatorHost = 'localhost:8085',
    this.functionsEmulatorHost = 'localhost:5001',
    this.storageEmulatorHost = 'localhost:9199',
    this.realMoneyEnabled = false,
  });

  bool get isProduction => environment.isProduction;

  static const FirebaseAppConfig development = FirebaseAppConfig(
    environment: FirebaseEnvironment.development,
    projectId: 'central-pool-dev',
    useEmulators: true,
    realMoneyEnabled: false,
  );

  static const FirebaseAppConfig staging = FirebaseAppConfig(
    environment: FirebaseEnvironment.staging,
    projectId: 'central-pool-staging',
    useEmulators: false,
    realMoneyEnabled: false,
  );

  static const FirebaseAppConfig production = FirebaseAppConfig(
    environment: FirebaseEnvironment.production,
    projectId: 'central-pool-production',
    useEmulators: false,
    realMoneyEnabled: false, // Fail-Closed in every environment
  );
}

/// Authoritative Firebase environment resolution logic.
/// INVARIANT: If isRelease is true (kReleaseMode), FirebaseEnvironment.production is ALWAYS returned.
/// No --dart-define=ENV value may override a Release build.
FirebaseEnvironment resolveFirebaseEnvironment({
  bool isRelease = kReleaseMode,
  String env = const String.fromEnvironment('ENV', defaultValue: ''),
}) {
  if (isRelease) {
    return FirebaseEnvironment.production;
  }
  if (env == 'production') {
    return FirebaseEnvironment.production;
  } else if (env == 'staging') {
    return FirebaseEnvironment.staging;
  } else {
    return FirebaseEnvironment.development;
  }
}
