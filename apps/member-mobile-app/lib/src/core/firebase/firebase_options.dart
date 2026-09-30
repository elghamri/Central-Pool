import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'firebase_config.dart';

/// Multi-Platform Firebase Options Container.
class FirebaseOptions {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String? storageBucket;
  final String? iosBundleId;

  const FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    this.storageBucket,
    this.iosBundleId,
  });
}

/// Firebase Initialization Bridge.
class Firebase {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initializeApp({required FirebaseOptions options}) async {
    _initialized = true;
  }
}

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Supports isolated environment configurations for dev, staging, and production.
class DefaultFirebaseOptions {
  static FirebaseOptions currentPlatform({FirebaseEnvironment environment = FirebaseEnvironment.development}) {
    if (kIsWeb) {
      return web(environment);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android(environment);
      case TargetPlatform.iOS:
        return ios(environment);
      case TargetPlatform.macOS:
        return macos(environment);
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions web(FirebaseEnvironment env) => FirebaseOptions(
        apiKey: env.isProduction
            ? 'AIzaSyBagGbnuGWUrT_kxlyeaMovYu3A3fWFfhw'
            : 'AIzaSyDemoWebKeyForDevelopmentOnly001',
        appId: env.isProduction
            ? '1:208909995395:web:2e9348853dff740b31bab6'
            : '1:102938475610:web:abcdef1234567890',
        messagingSenderId: env.isProduction ? '208909995395' : '102938475610',
        projectId: env.projectId,
        authDomain: '${env.projectId}.firebaseapp.com',
        storageBucket: env.isProduction
            ? 'central-pool-production.firebasestorage.app'
            : '${env.projectId}.appspot.com',
      );

  static FirebaseOptions android(FirebaseEnvironment env) => FirebaseOptions(
        apiKey: env.isProduction
            ? 'AIzaSyDqQQBsJc9lUINPBlVkTOxL9rc3Fi6Nbh0'
            : 'AIzaSyDemoAndroidKeyForDevelopmentOnly002',
        appId: env.isProduction
            ? '1:208909995395:android:00101353cfc2250031bab6'
            : '1:102938475610:android:abcdef1234567890',
        messagingSenderId: env.isProduction ? '208909995395' : '102938475610',
        projectId: env.projectId,
        storageBucket: env.isProduction
            ? 'central-pool-production.firebasestorage.app'
            : '${env.projectId}.appspot.com',
      );

  static FirebaseOptions ios(FirebaseEnvironment env) => FirebaseOptions(
        apiKey: env.isProduction
            ? 'AIzaSyAMyvT5Ts7HQs6B83HsKM1M71jfEAFrLhg'
            : 'AIzaSyDemoIOSKeyForDevelopmentOnly003',
        appId: env.isProduction
            ? '1:208909995395:ios:3f89369c6cee3b1f31bab6'
            : '1:102938475610:ios:abcdef1234567890',
        messagingSenderId: env.isProduction ? '208909995395' : '102938475610',
        projectId: env.projectId,
        storageBucket: env.isProduction
            ? 'central-pool-production.firebasestorage.app'
            : '${env.projectId}.appspot.com',
        iosBundleId: 'finance.collaborative.centralpool',
      );

  static FirebaseOptions macos(FirebaseEnvironment env) => FirebaseOptions(
        apiKey: 'AIzaSyDemoMacOSKeyForDevelopmentOnly004',
        appId: '1:102938475610:macos:abcdef1234567890',
        messagingSenderId: '102938475610',
        projectId: env.projectId,
        storageBucket: '${env.projectId}.appspot.com',
        iosBundleId: 'finance.collaborative.centralpool.macos',
      );
}
