// Central Pool — Phase K Android Release Signing & Packaging Test
// PROVENANCE & SEMANTIC BOUNDARY:
// - Verifies Android Gradle Kotlin DSL release signing configuration.
// - Asserts Fail-Closed Invariant: RELEASE_STORE_SIGNING_MUST_NOT_FALL_BACK_TO_DEBUG.
// - Asserts Gitignore isolation of key.properties and keystore files.
// - Asserts AndroidManifest branding ('Central Pool') and explicit INTERNET permission.
// - Asserts Release environment and API base URL fail-safe wiring.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/core/firebase/firebase_config.dart';
import 'package:member_mobile_app/src/features/central_pool/providers/central_pool_providers.dart';

void main() {
  group('CP-PHASE-K — Android Release Signing & Packaging Invariants', () {
    test('1. build.gradle.kts enforces secure release signing and fail-closed architecture', () {
      final buildGradleFile = File('android/app/build.gradle.kts');
      expect(buildGradleFile.existsSync(), isTrue, reason: 'build.gradle.kts must exist');

      final content = buildGradleFile.readAsStringSync();

      // Invariant: debug fallback prohibited in release
      expect(
        content.contains('signingConfig = signingConfigs.getByName("debug")'),
        isFalse,
        reason: 'Release build MUST NOT use debug signing fallback',
      );

      // Invariant: Application ID matches production
      expect(
        content.contains('applicationId = "finance.collaborative.centralpool"'),
        isTrue,
        reason: 'Android applicationId must match production Firebase registered application',
      );

      // Invariant: Production signing configuration hooks are present
      expect(content.contains('key.properties'), isTrue);
      expect(content.contains('ANDROID_STORE_FILE'), isTrue);
      expect(content.contains('ANDROID_STORE_PASSWORD'), isTrue);
      expect(content.contains('ANDROID_KEY_ALIAS'), isTrue);
      expect(content.contains('ANDROID_KEY_PASSWORD'), isTrue);
      expect(content.contains('hasValidReleaseSigning'), isTrue);
      expect(content.contains('RELEASE_STORE_SIGNING_MUST_NOT_FALL_BACK_TO_DEBUG'), isTrue);
    });

    test('2. AndroidManifest.xml enforces Central Pool branding and INTERNET permission', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'main AndroidManifest.xml must exist');

      final content = manifestFile.readAsStringSync();

      // Invariant: Branding
      expect(
        content.contains('android:label="Central Pool"'),
        isTrue,
        reason: 'Application label in main AndroidManifest must be "Central Pool"',
      );
      expect(
        content.contains('android:label="member_mobile_app"'),
        isFalse,
        reason: 'Legacy placeholder label "member_mobile_app" must be removed',
      );

      // Invariant: Canonical INTERNET permission declared in main release manifest
      expect(
        content.contains('<uses-permission android:name="android.permission.INTERNET"/>'),
        isTrue,
        reason: 'Main AndroidManifest must explicitly declare canonical android.permission.INTERNET',
      );
      expect(
        content.contains('android.intent.permission.INTERNET'),
        isFalse,
        reason: 'Incorrect namespace android.intent.permission.INTERNET must not be present',
      );
    });

    test('3. Secret hygiene: key.properties and keystores are strictly gitignored', () {
      final androidGitignore = File('android/.gitignore');
      expect(androidGitignore.existsSync(), isTrue);
      final androidGitContent = androidGitignore.readAsStringSync();
      expect(androidGitContent.contains('key.properties'), isTrue);
      expect(androidGitContent.contains('*.keystore'), isTrue);
      expect(androidGitContent.contains('*.jks'), isTrue);

      final appGitignore = File('.gitignore');
      expect(appGitignore.existsSync(), isTrue);
      final appGitContent = appGitignore.readAsStringSync();
      expect(appGitContent.contains('key.properties'), isTrue);
      expect(appGitContent.contains('*.keystore'), isTrue);
      expect(appGitContent.contains('*.jks'), isTrue);

      // Verify no real keystore or key.properties exists in repo
      expect(File('android/key.properties').existsSync(), isFalse, reason: 'Real key.properties must never be committed');
      expect(File('android/app/key.properties').existsSync(), isFalse);
    });

    test('4. key.properties.example template exists and contains no secret values', () {
      final exampleFile = File('android/key.properties.example');
      expect(exampleFile.existsSync(), isTrue, reason: 'key.properties.example template must exist');

      final content = exampleFile.readAsStringSync();
      expect(content.contains('storeFile='), isTrue);
      expect(content.contains('storePassword='), isTrue);
      expect(content.contains('keyAlias='), isTrue);
      expect(content.contains('keyPassword='), isTrue);
      expect(content.contains('YOUR_PRODUCTION_STORE_PASSWORD'), isTrue);
    });

    test('5. Release Environment and Central Pool Base URL fail-safes remain active', () {
      // Invariant: In release mode, environment is always production
      final releaseEnv = resolveFirebaseEnvironment(isRelease: true);
      expect(releaseEnv, equals(FirebaseEnvironment.production));
      expect(releaseEnv.projectId, equals('central-pool-production'));

      // Invariant: In release mode, base URL is always production Functions
      final releaseBaseUrl = resolveCentralPoolBaseUrl(isRelease: true);
      expect(
        releaseBaseUrl,
        equals('https://us-central1-central-pool-production.cloudfunctions.net'),
      );
    });
  });
}
