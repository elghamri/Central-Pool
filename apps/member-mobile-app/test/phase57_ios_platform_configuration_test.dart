// Central Pool — Phase L1 iOS Platform Shell Configuration Test
// PROVENANCE & SEMANTIC BOUNDARY:
// - Verifies Flutter iOS platform directory presence and standard Xcode project structure.
// - Asserts Bundle Identifier: finance.collaborative.centralpool across configurations.
// - Asserts App Branding: CFBundleDisplayName & CFBundleName = Central Pool.
// - Asserts GoogleService-Info.plist presence and production project linkage.
// - Asserts Release environment and API base URL fail-safe wiring on iOS.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_config.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_options.dart';
import 'package:member_mobile_app/src/features/central_pool/providers/central_pool_providers.dart';

void main() {
  group('CP-PHASE-L1 — iOS Platform Provisioning & Configuration Invariants', () {
    test('1. iOS platform directory structure and Xcode project exist', () {
      expect(Directory('ios').existsSync(), isTrue, reason: 'ios/ directory must exist');
      expect(Directory('ios/Runner').existsSync(), isTrue, reason: 'ios/Runner directory must exist');
      expect(Directory('ios/Runner.xcodeproj').existsSync(), isTrue, reason: 'Runner.xcodeproj must exist');
      expect(File('ios/Runner.xcodeproj/project.pbxproj').existsSync(), isTrue, reason: 'project.pbxproj must exist');
      expect(File('ios/Runner/Info.plist').existsSync(), isTrue, reason: 'Info.plist must exist');
      expect(File('ios/Runner/AppDelegate.swift').existsSync(), isTrue, reason: 'AppDelegate.swift must exist');
    });

    test('2. Info.plist enforces Central Pool branding and version metadata', () {
      final infoPlist = File('ios/Runner/Info.plist');
      expect(infoPlist.existsSync(), isTrue);

      final content = infoPlist.readAsStringSync();
      expect(content.contains('<key>CFBundleDisplayName</key>\n\t<string>Central Pool</string>'), isTrue);
      expect(content.contains('<key>CFBundleName</key>\n\t<string>Central Pool</string>'), isTrue);
      expect(content.contains('member_mobile_app'), isFalse, reason: 'Legacy placeholder must be absent');
      expect(content.contains('Gameya'), isFalse, reason: 'Legacy Gameya branding must be absent');
    });

    test('3. project.pbxproj strictly configures canonical bundle identifier', () {
      final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
      expect(pbxproj.existsSync(), isTrue);

      final content = pbxproj.readAsStringSync();
      expect(content.contains('PRODUCT_BUNDLE_IDENTIFIER = finance.collaborative.centralpool;'), isTrue);
      expect(content.contains('finance.collaborative.memberMobileApp'), isFalse, reason: 'Default template bundle ID must be replaced');
    });

    test('4. GoogleService-Info.plist is present and matches production Firebase registration', () {
      final googleServicePlist = File('ios/Runner/GoogleService-Info.plist');
      expect(googleServicePlist.existsSync(), isTrue, reason: 'GoogleService-Info.plist must be present in ios/Runner/');

      final content = googleServicePlist.readAsStringSync();
      expect(content.contains('<key>PROJECT_ID</key>\n\t<string>central-pool-production</string>'), isTrue);
      expect(content.contains('<key>GCM_SENDER_ID</key>\n\t<string>208909995395</string>'), isTrue);
      expect(content.contains('<key>GOOGLE_APP_ID</key>\n\t<string>1:208909995395:ios:3f89369c6cee3b1f31bab6</string>'), isTrue);
      expect(content.contains('<key>BUNDLE_ID</key>\n\t<string>finance.collaborative.centralpool</string>'), isTrue);
    });

    test('5. DefaultFirebaseOptions.ios accurately reflects production configuration', () {
      final prodOptions = DefaultFirebaseOptions.ios(FirebaseEnvironment.production);
      expect(prodOptions.projectId, equals('central-pool-production'));
      expect(prodOptions.appId, equals('1:208909995395:ios:3f89369c6cee3b1f31bab6'));
      expect(prodOptions.messagingSenderId, equals('208909995395'));
      expect(prodOptions.iosBundleId, equals('finance.collaborative.centralpool'));
      expect(prodOptions.storageBucket, equals('central-pool-production.firebasestorage.app'));
    });

    test('6. Release Environment and Central Pool Base URL fail-safes are active for iOS', () {
      // Invariant: In release mode, environment is always production
      final releaseEnv = resolveFirebaseEnvironment(isRelease: true);
      expect(releaseEnv, equals(FirebaseEnvironment.production));
      expect(releaseEnv.projectId, equals('central-pool-production'));

      // Invariant: In release mode, base URL is always production Cloud Functions
      final releaseBaseUrl = resolveCentralPoolBaseUrl(isRelease: true);
      expect(
        releaseBaseUrl,
        equals('https://us-central1-central-pool-production.cloudfunctions.net'),
      );
    });

    test('7. Info.plist contains no unnecessary native permission usage descriptions', () {
      final content = File('ios/Runner/Info.plist').readAsStringSync();
      expect(content.contains('NSCameraUsageDescription'), isFalse);
      expect(content.contains('NSPhotoLibraryUsageDescription'), isFalse);
      expect(content.contains('NSMicrophoneUsageDescription'), isFalse);
      expect(content.contains('NSLocationWhenInUseUsageDescription'), isFalse);
      expect(content.contains('NSContactsUsageDescription'), isFalse);
      expect(content.contains('NSUserTrackingUsageDescription'), isFalse);
    });
  });
}
