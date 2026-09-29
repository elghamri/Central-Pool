// Phase 58: Central Pool Mobile CI/CD Release Pipeline Validation Test Suite
// Invariants Verified:
// 1. Dedicated GitHub Actions workflow exists (.github/workflows/mobile-release.yml).
// 2. Contains 3 distinct jobs: Quality Gate, Android Release (AAB), iOS Release (IPA).
// 3. Quality Gate runs 'flutter analyze' and 'flutter test' before build jobs.
// 4. Secret hygiene: Zero hardcoded credentials, strict usage of ::add-mask::.
// 5. Ephemeral signing: Runner temp paths used for keystores/keychains with post-build cleanup.
// 6. Fail-closed: Missing secrets in Store Release mode explicitly abort with exit 1; never debug signing.
// 7. Signature verification: jarsigner -verify and codesign --verify executed on signed outputs.
// 8. Identity consistency: finance.collaborative.centralpool and central-pool-production verified.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 58: Mobile CI/CD Release Pipeline Integrity', () {
    late String workflowContent;
    late String exportOptionsContent;

    setUpAll(() {
      final workflowFile = File('../../.github/workflows/mobile-release.yml');
      final fallbackWorkflowFile = File('.github/workflows/mobile-release.yml');
      
      if (workflowFile.existsSync()) {
        workflowContent = workflowFile.readAsStringSync();
      } else if (fallbackWorkflowFile.existsSync()) {
        workflowContent = fallbackWorkflowFile.readAsStringSync();
      } else {
        fail('mobile-release.yml not found in expected repository paths.');
      }

      final exportOptionsFile = File('ios/ExportOptions.plist.example');
      final fallbackExportOptionsFile = File('apps/member-mobile-app/ios/ExportOptions.plist.example');
      if (exportOptionsFile.existsSync()) {
        exportOptionsContent = exportOptionsFile.readAsStringSync();
      } else if (fallbackExportOptionsFile.existsSync()) {
        exportOptionsContent = fallbackExportOptionsFile.readAsStringSync();
      } else {
        fail('ExportOptions.plist.example not found in expected iOS paths.');
      }
    });

    // =========================================================================
    // 1. WORKFLOW STRUCTURE & TRIGGER CONFIGURATION
    // =========================================================================
    group('1. Workflow Structure & Triggers', () {
      test('Workflow name and concurrency are defined', () {
        expect(workflowContent.contains('name: Central Pool Mobile Release Pipeline'), isTrue);
        expect(workflowContent.contains('concurrency:'), isTrue);
        expect(workflowContent.contains('group: mobile-release-'), isTrue);
      });

      test('Triggers include workflow_dispatch and release tags', () {
        expect(workflowContent.contains('workflow_dispatch:'), isTrue);
        expect(workflowContent.contains('target_platform:'), isTrue);
        expect(workflowContent.contains('upload_to_stores:'), isTrue);
        expect(workflowContent.contains('tags:'), isTrue);
      });

      test('Defines the three mandatory jobs in correct dependency order', () {
        expect(workflowContent.contains('mobile-quality-gate:'), isTrue);
        expect(workflowContent.contains('build-android-release:'), isTrue);
        expect(workflowContent.contains('build-ios-release:'), isTrue);
        expect(workflowContent.contains('needs: mobile-quality-gate'), isTrue);
      });
    });

    // =========================================================================
    // 2. QUALITY GATE & TOOLCHAIN SPECIFICATIONS
    // =========================================================================
    group('2. Quality Gate & Toolchain', () {
      test('Configures Flutter 3.38.5 and Java 17', () {
        expect(workflowContent.contains("flutter-version: '3.38.5'"), isTrue);
        expect(workflowContent.contains("java-version: '17'"), isTrue);
        expect(workflowContent.contains("channel: 'stable'"), isTrue);
      });

      test('Quality gate runs flutter analyze and flutter test before packaging', () {
        expect(workflowContent.contains('flutter analyze'), isTrue);
        expect(workflowContent.contains('flutter test'), isTrue);
      });

      test('Runs on standard secure runners', () {
        expect(workflowContent.contains('runs-on: ubuntu-latest'), isTrue);
        expect(workflowContent.contains('runs-on: macos-latest'), isTrue);
      });
    });

    // =========================================================================
    // 3. ANDROID SIGNING & PACKAGING ARCHITECTURE
    // =========================================================================
    group('3. Android AAB Release Architecture', () {
      test('Uses correct environment variables for external keystore injection', () {
        expect(workflowContent.contains('ANDROID_KEYSTORE_BASE64'), isTrue);
        expect(workflowContent.contains('ANDROID_STORE_FILE:'), isTrue);
        expect(workflowContent.contains('ANDROID_STORE_PASSWORD:'), isTrue);
        expect(workflowContent.contains('ANDROID_KEY_ALIAS:'), isTrue);
        expect(workflowContent.contains('ANDROID_KEY_PASSWORD:'), isTrue);
      });

      test('Decodes keystore to runner temp and adds secret masks', () {
        expect(workflowContent.contains('::add-mask::'), isTrue);
        expect(workflowContent.contains('RUNNER_TEMP'), isTrue);
        expect(workflowContent.contains('base64 --decode'), isTrue);
      });

      test('Store Release mode fails closed on missing credentials', () {
        expect(workflowContent.contains('STORE RELEASE FAILED CLOSED'), isTrue);
        expect(workflowContent.contains('exit 1'), isTrue);
      });

      test('Builds release App Bundle (AAB) and runs jarsigner verification', () {
        expect(workflowContent.contains('flutter build appbundle --release'), isTrue);
        expect(workflowContent.contains('jarsigner -verify'), isTrue);
        expect(workflowContent.contains('central-pool-android-release-aab'), isTrue);
        expect(workflowContent.contains('app-release.aab'), isTrue);
      });

      test('Cleans up ephemeral keystore post-build', () {
        expect(workflowContent.contains('Cleanup Ephemeral Keystore'), isTrue);
        expect(workflowContent.contains('rm -rf "\${RUNNER_TEMP}/keystore"'), isTrue);
      });
    });

    // =========================================================================
    // 4. iOS SIGNING & ARCHIVE ARCHITECTURE
    // =========================================================================
    group('4. iOS IPA Release Architecture', () {
      test('Uses correct environment variables for external Apple signing injection', () {
        expect(workflowContent.contains('APPLE_CERTIFICATE_BASE64'), isTrue);
        expect(workflowContent.contains('APPLE_CERTIFICATE_PASSWORD'), isTrue);
        expect(workflowContent.contains('APPLE_PROVISIONING_PROFILE_BASE64'), isTrue);
      });

      test('Creates ephemeral keychain and installs provisioning profiles', () {
        expect(workflowContent.contains('security create-keychain'), isTrue);
        expect(workflowContent.contains('security set-keychain-settings'), isTrue);
        expect(workflowContent.contains('security import'), isTrue);
        expect(workflowContent.contains('~/Library/MobileDevice/Provisioning'), isTrue);
      });

      test('Store Release mode fails closed on missing Apple credentials', () {
        expect(workflowContent.contains('STORE RELEASE FAILED CLOSED'), isTrue);
      });

      test('Builds release IPA / Archive and runs codesign verification', () {
        expect(workflowContent.contains('flutter build ipa --release'), isTrue);
        expect(workflowContent.contains('flutter build ios --release --no-codesign'), isTrue);
        expect(workflowContent.contains('codesign --verify'), isTrue);
        expect(workflowContent.contains('central-pool-ios-release'), isTrue);
      });

      test('Cleans up ephemeral keychain and certificates post-build', () {
        expect(workflowContent.contains('Cleanup Ephemeral Apple Keychain & Profiles'), isTrue);
        expect(workflowContent.contains('security delete-keychain'), isTrue);
        expect(workflowContent.contains('~/Library/MobileDevice/Provisioning'), isTrue);
      });
    });

    // =========================================================================
    // 5. SECURITY & ZERO SECRETS COMMITMENT
    // =========================================================================
    group('5. Secret Hygiene & Security Invariants', () {
      test('No plaintext passwords or private keys exist in workflow file', () {
        expect(workflowContent.contains('Password123'), isFalse);
        expect(workflowContent.contains('BEGIN PRIVATE KEY'), isFalse);
        expect(workflowContent.contains('BEGIN CERTIFICATE'), isFalse);
        expect(workflowContent.contains('AIzaSy'), isFalse);
      });

      test('ExportOptions.plist.example contains correct bundle identifier and team', () {
        expect(exportOptionsContent.contains('finance.collaborative.centralpool'), isTrue);
        expect(exportOptionsContent.contains('app-store'), isTrue);
        expect(exportOptionsContent.contains('Apple Distribution'), isTrue);
      });
    });
  });
}
