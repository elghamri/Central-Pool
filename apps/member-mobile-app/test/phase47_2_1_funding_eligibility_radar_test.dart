import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/funding/models/funding_models.dart';
import 'package:member_mobile_app/src/features/funding/views/funding_eligibility_view.dart';
import 'package:member_mobile_app/src/features/funding/widgets/funding_eligibility_radar_widget.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  group('Phase 47.2.1C — Final Radar Truthfulness & Data Integrity Tests', () {
    test('Categorical PASS does not manufacture an arbitrary numeric score or radial magnitude', () {
      final eligibility = FundingEligibility(
        status: FundingEligibilityStatus.eligible,
        memberId: 'usr-member-001',
        cycleId: 'CYCLE-2026-LIVE-01',
        isEligible: true,
        criteria: const [
          FundingEligibilityCriterion(
            name: 'Historical Contribution Invariant',
            isSatisfied: true,
            description: 'All 6 cycles paid on-time',
          ),
          FundingEligibilityCriterion(
            name: 'Group Stability & Member Retention',
            isSatisfied: true,
            description: '100% peer retention',
          ),
          FundingEligibilityCriterion(
            name: 'Treasury Pool Reserve Buffer',
            isSatisfied: true,
            description: '15% liquidity reserve confirmed',
          ),
          FundingEligibilityCriterion(
            name: 'KYC & Identity Verification',
            isSatisfied: true,
            description: 'Tier 2 identity document validated',
          ),
          FundingEligibilityCriterion(
            name: 'Circle Health & Solvency Check',
            isSatisfied: true,
            description: 'Zero delinquent peers in pool',
          ),
          FundingEligibilityCriterion(
            name: 'Rotation Schedule Alignment',
            isSatisfied: true,
            description: 'Slot #1 assigned for next disbursement',
          ),
        ],
        evaluatedAt: DateTime.utc(2026, 8, 20),
      );

      final axes = FundingEligibilityRadarMapper.mapToAxes(eligibility);

      expect(axes.length, equals(6));
      for (final axis in axes) {
        expect(axis.state, equals(RadarDimensionState.satisfied));
        expect(axis.isAvailable, isTrue);
        expect(axis.isSatisfied, isTrue);
        // Explicitly verify NO synthetic numeric score or magnitude was created
        expect(axis.authoritativeNumericValue, isNull);
      }
    });

    test('Categorical RESTRICTED remains pure categorical without fractional magnitude', () {
      final eligibility = FundingEligibility(
        status: FundingEligibilityStatus.restricted,
        memberId: 'usr-member-002',
        cycleId: 'CYCLE-2026-LIVE-02',
        isEligible: false,
        criteria: const [
          FundingEligibilityCriterion(
            name: 'KYC & Identity Verification',
            isSatisfied: false,
            description: 'National ID document pending',
            blockingReason: 'National ID expired on 2026-05-01',
          ),
        ],
        evaluatedAt: DateTime.utc(2026, 8, 20),
      );

      final axes = FundingEligibilityRadarMapper.mapToAxes(eligibility);

      expect(axes.length, equals(6));

      // Verification axis is present & restricted
      final kycAxis = axes.firstWhere((a) => a.id == 'verification_status');
      expect(kycAxis.state, equals(RadarDimensionState.restricted));
      expect(kycAxis.isAvailable, isTrue);
      expect(kycAxis.isSatisfied, isFalse);
      expect(kycAxis.statusLabelEn, equals('Pending ID'));
      expect(kycAxis.blockingReason, equals('National ID expired on 2026-05-01'));
      expect(kycAxis.authoritativeNumericValue, isNull);

      // Group stability and circle health are NOT in criteria -> MUST be UNAVAILABLE with null numeric value
      final stabilityAxis = axes.firstWhere((a) => a.id == 'group_stability');
      expect(stabilityAxis.state, equals(RadarDimensionState.unavailable));
      expect(stabilityAxis.isAvailable, isFalse);
      expect(stabilityAxis.authoritativeNumericValue, isNull);
      expect(stabilityAxis.statusLabelEn, equals('Not Available'));
      expect(stabilityAxis.statusLabelAr, equals('غير متوفر'));

      final healthAxis = axes.firstWhere((a) => a.id == 'circle_health');
      expect(healthAxis.state, equals(RadarDimensionState.unavailable));
      expect(healthAxis.isAvailable, isFalse);
      expect(healthAxis.authoritativeNumericValue, isNull);
      expect(healthAxis.statusLabelEn, equals('Not Available'));
      expect(healthAxis.statusLabelAr, equals('غير متوفر'));
    });

    test('Unavailable dimension does not become a low score or fractional magnitude', () {
      final eligibility = FundingEligibility(
        status: FundingEligibilityStatus.pendingReview,
        memberId: 'usr-member-003',
        cycleId: 'CYCLE-2026-LIVE-03',
        isEligible: false,
        criteria: const [],
        evaluatedAt: DateTime.utc(2026, 8, 20),
      );

      final axes = FundingEligibilityRadarMapper.mapToAxes(eligibility);

      for (final axis in axes) {
        expect(axis.state, equals(RadarDimensionState.unavailable));
        expect(axis.isAvailable, isFalse);
        expect(axis.isSatisfied, isFalse);
        expect(axis.authoritativeNumericValue, isNull);
      }
    });

    test('Maps all 6 exact Stitch axis identifiers and labels truthfully', () {
      final eligibility = FundingEligibility(
        status: FundingEligibilityStatus.eligible,
        memberId: 'usr-member-001',
        cycleId: 'CYCLE-2026-LIVE-01',
        isEligible: true,
        criteria: const [],
        evaluatedAt: DateTime.utc(2026, 8, 20),
      );

      final axes = FundingEligibilityRadarMapper.mapToAxes(eligibility);

      expect(axes.map((a) => a.id).toList(), equals([
        'contribution_history',
        'group_stability',
        'payout_readiness',
        'verification_status',
        'circle_health',
        'rotation_progress',
      ]));

      expect(axes[0].labelEn, equals('Contribution History'));
      expect(axes[0].labelAr, equals('تاريخ المساهمة'));

      expect(axes[1].labelEn, equals('Group Stability'));
      expect(axes[1].labelAr, equals('استقرار المجموعة'));

      expect(axes[2].labelEn, equals('Payout Readiness'));
      expect(axes[2].labelAr, equals('جاهزية الصرف'));

      expect(axes[3].labelEn, equals('Verification Status'));
      expect(axes[3].labelAr, equals('حالة التحقق'));

      expect(axes[4].labelEn, equals('Circle Health'));
      expect(axes[4].labelAr, equals('صحة الدائرة'));

      expect(axes[5].labelEn, equals('Rotation Progress'));
      expect(axes[5].labelAr, equals('تقدم الدورة'));
    });
  });

  group('Phase 47.2.1C — Funding Eligibility Radar Widget & Operational State Tests', () {
    Widget createTestableWidget(Widget child, {TextDirection textDirection = TextDirection.ltr}) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Directionality(
          textDirection: textDirection,
          child: child,
        ),
      );
    }

    final fullEligibility = FundingEligibility(
      status: FundingEligibilityStatus.eligible,
      memberId: 'usr-member-001',
      cycleId: 'CYCLE-2026-LIVE-01',
      isEligible: true,
      criteria: const [
        FundingEligibilityCriterion(
          name: 'KYC & Identity Verification',
          isSatisfied: true,
          description: 'Tier 2 Identity Verified',
        ),
        FundingEligibilityCriterion(
          name: 'Delinquency & Arrears Gate',
          isSatisfied: true,
          description: 'Zero delinquent obligations',
        ),
        FundingEligibilityCriterion(
          name: 'Treasury Pool Reserve Buffer',
          isSatisfied: true,
          description: '15% liquidity reserve verified',
        ),
        FundingEligibilityCriterion(
          name: 'Peer Cooperative Standing',
          isSatisfied: true,
          description: '100% on-time record',
        ),
      ],
      evaluatedAt: DateTime.utc(2026, 8, 20),
    );

    testWidgets('Renders Normal State with 6-Axis Radar, Hero Card, and Axis List', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Funding Eligibility Gate'), findsOneWidget);
      expect(find.text('Readiness Overview'), findsOneWidget);
      expect(find.text('Passed All Underwriting Gates'), findsOneWidget);
      expect(find.text('Eligibility & Risk Radar'), findsOneWidget);
      expect(find.byType(FundingEligibilityRadarWidget), findsOneWidget);
      expect(find.text('Axis Breakdown & Criteria'), findsOneWidget);

      // Verify presence of 6 axis labels
      expect(find.text('Contribution History'), findsWidgets);
      expect(find.text('Group Stability'), findsWidgets);
      expect(find.text('Payout Readiness'), findsWidgets);
      expect(find.text('Verification Status'), findsWidgets);
      expect(find.text('Circle Health'), findsWidgets);
      expect(find.text('Rotation Progress'), findsWidgets);
    });

    testWidgets('Renders Loading State correctly', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          isLoading: true,
          onBack: () {},
        ),
      ));

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.text('Evaluating funding eligibility criteria...'), findsOneWidget);
      expect(find.byType(FundingEligibilityRadarWidget), findsNothing);
    });

    testWidgets('Renders Empty State correctly', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          isEmpty: true,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('No Eligibility Data Found'), findsOneWidget);
    });

    testWidgets('Renders Error State with Retry action', (tester) async {
      bool retried = false;
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          errorMessage: 'Underwriting service gateway timeout (504)',
          onRetry: () {
            retried = true;
          },
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorCardWidget), findsOneWidget);
      expect(find.text('Underwriting service gateway timeout (504)'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('Renders Offline State with cached notice banner', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          isOffline: true,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode: Displaying locally cached evaluation records.'), findsOneWidget);
      expect(find.byType(FundingEligibilityRadarWidget), findsOneWidget);
    });

    testWidgets('Renders Permission Denied State', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          isPermissionDenied: true,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('You do not have the required permissions to view detailed underwriting records for this account.'), findsOneWidget);
    });

    testWidgets('Renders Financial Safety Lock circuit breaker banner', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          isSafetyLockActive: true,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Financial Safety Lock Active'), findsOneWidget);
      expect(find.text('System-wide emergency circuit breaker is active. Payout disbursements are halted.'), findsOneWidget);
    });

    testWidgets('Renders Partial Data Banner when fewer than 6 dimensions are populated', (tester) async {
      final partialEligibility = FundingEligibility(
        status: FundingEligibilityStatus.pendingReview,
        memberId: 'usr-member-003',
        cycleId: 'CYCLE-2026-LIVE-03',
        isEligible: false,
        criteria: const [
          FundingEligibilityCriterion(
            name: 'KYC & Identity Verification',
            isSatisfied: true,
            description: 'Identity validated',
          ),
        ],
        evaluatedAt: DateTime.utc(2026, 8, 20),
      );

      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: partialEligibility,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Partial Evaluation: 1 of 6 dimensions available. Missing axes remain unpopulated.'), findsOneWidget);
    });

    testWidgets('Interactive Axis selection updates the selected detail card', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Tap on the 'Verification Status' chip
      final kycChip = find.text('Verification Status').first;
      await tester.ensureVisible(kycChip);
      await tester.tap(kycChip);
      await tester.pumpAndSettle();

      // The detail card should now display Verification Status details
      expect(find.text('Tier 2 Identity Verified'), findsWidgets);
    });

    testWidgets('Renders Arabic RTL Localization correctly', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          onBack: () {},
        ),
        textDirection: TextDirection.rtl,
      ));
      await tester.pumpAndSettle();

      expect(find.text('مراجعة الأهلية'), findsOneWidget);
      expect(find.text('نظرة عامة على الجاهزية'), findsOneWidget);
      expect(find.text('وضع المحاكاة'), findsOneWidget);
      expect(find.text('مؤشرات المخاطر والأهلية'), findsOneWidget);
      expect(find.text('تفاصيل التقييم والمحاور'), findsOneWidget);
      expect(find.text('تاريخ المساهمة'), findsWidgets);
      expect(find.text('حالة التحقق'), findsWidgets);
      expect(find.text('جاهزية الصرف'), findsWidgets);
      expect(find.text('استقرار المجموعة'), findsWidgets);
      expect(find.text('صحة الدائرة'), findsWidgets);
      expect(find.text('تقدم الدورة'), findsWidgets);
    });

    testWidgets('Navigation: onBack callback is invoked on back actions', (tester) async {
      int backCount = 0;
      await tester.pumpWidget(createTestableWidget(
        FundingEligibilityView(
          eligibility: fullEligibility,
          onBack: () {
            backCount++;
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Tap AppBar back button
      await tester.tap(find.byTooltip('Back'));
      expect(backCount, equals(1));

      // Tap bottom SecondaryButton
      final backBtn = find.text('Back to Funding Overview');
      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      expect(backCount, equals(2));
    });
  });
}
