import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../dashboard/models/member_dashboard_models.dart';
import '../models/funding_models.dart';

/// Authoritative qualitative state of a radar evaluation dimension.
enum RadarDimensionState {
  satisfied,
  restricted,
  unavailable,
}

/// Representation of a single dimension in the 6-Axis Funding Eligibility Qualitative Radar.
/// Contains ZERO synthetic scores, invented percentages, or fractional radial magnitudes.
class RadarAxisItem {
  final String id;
  final String labelEn;
  final String labelAr;
  final RadarDimensionState state;
  final String statusLabelEn;
  final String statusLabelAr;
  final String descriptionEn;
  final String descriptionAr;
  final String? blockingReason;
  final IconData icon;
  final double? authoritativeNumericValue; // Pure pass-through ONLY if real numeric value exists in domain

  const RadarAxisItem({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.state,
    required this.statusLabelEn,
    required this.statusLabelAr,
    required this.descriptionEn,
    required this.descriptionAr,
    this.blockingReason,
    required this.icon,
    this.authoritativeNumericValue,
  });

  bool get isAvailable => state != RadarDimensionState.unavailable;
  bool get isSatisfied => state == RadarDimensionState.satisfied;
  String getLabel(bool isRtl) => isRtl ? labelAr : labelEn;
  String getStatusLabel(bool isRtl) => isRtl ? statusLabelAr : statusLabelEn;
  String getDescription(bool isRtl) => isRtl ? descriptionAr : descriptionEn;
}

/// Helper to map domain [FundingEligibility] to the 6 authoritative Stitch radar axes without fabricating data.
class FundingEligibilityRadarMapper {
  static List<RadarAxisItem> mapToAxes(FundingEligibility eligibility, {FundingOverview? overview}) {
    // 1. Contribution History
    final contribCrit = _findCriterion(eligibility.criteria, ['contribution', 'historical', 'delinquency', 'arrears']);
    final bool hasContribData = contribCrit != null || overview?.summary != null;
    final bool contribSatisfied = contribCrit?.isSatisfied ?? (overview?.summary.accountStatus == 'IN_GOOD_STANDING');
    final contribState = hasContribData
        ? (contribSatisfied ? RadarDimensionState.satisfied : RadarDimensionState.restricted)
        : RadarDimensionState.unavailable;

    final contribAxis = RadarAxisItem(
      id: 'contribution_history',
      labelEn: 'Contribution History',
      labelAr: 'تاريخ المساهمة',
      state: contribState,
      statusLabelEn: hasContribData ? (contribSatisfied ? 'Strong' : 'Action Required') : 'Not Available',
      statusLabelAr: hasContribData ? (contribSatisfied ? 'قوي' : 'إجراء مطلوب') : 'غير متوفر',
      descriptionEn: contribCrit?.description ??
          (hasContribData ? 'Consistent on-time contributions verified in member record.' : 'No contribution history available for this cycle.'),
      descriptionAr: hasContribData
          ? 'تم التحقق من انتظام سداد المساهمات في سجل العضو.'
          : 'لا يتوفر سجل مساهمات لهذه الدورة.',
      blockingReason: contribCrit?.blockingReason,
      icon: Icons.history,
      authoritativeNumericValue: null,
    );

    // 2. Group Stability
    final stabilityCrit = _findCriterion(eligibility.criteria, ['group', 'stability', 'peer', 'cooperative standing', 'retention']);
    final bool hasStabilityData = stabilityCrit != null;
    final bool stabilitySatisfied = stabilityCrit?.isSatisfied ?? false;
    final stabilityState = hasStabilityData
        ? (stabilitySatisfied ? RadarDimensionState.satisfied : RadarDimensionState.restricted)
        : RadarDimensionState.unavailable;

    final stabilityAxis = RadarAxisItem(
      id: 'group_stability',
      labelEn: 'Group Stability',
      labelAr: 'استقرار المجموعة',
      state: stabilityState,
      statusLabelEn: hasStabilityData ? (stabilitySatisfied ? 'Stable' : 'Attention Needed') : 'Not Available',
      statusLabelAr: hasStabilityData ? (stabilitySatisfied ? 'مستقر' : 'يتطلب انتباه') : 'غير متوفر',
      descriptionEn: stabilityCrit?.description ??
          (hasStabilityData ? 'Peer nodes demonstrate strong cooperative retention.' : 'Group stability metrics not evaluated for this circle.'),
      descriptionAr: hasStabilityData
          ? 'أعضاء المجموعة يظهرون استقراراً والتزاماً بالدورة.'
          : 'لم يتم تقييم مؤشرات استقرار المجموعة لهذه الدائرة.',
      blockingReason: stabilityCrit?.blockingReason,
      icon: Icons.group,
      authoritativeNumericValue: null,
    );

    // 3. Payout Readiness
    final payoutCrit = _findCriterion(eligibility.criteria, ['reserve', 'buffer', 'treasury', 'liquidity', 'readiness', 'underwriting']);
    final bool hasPayoutData = payoutCrit != null || overview?.settlement != null;
    final bool payoutSatisfied = payoutCrit?.isSatisfied ?? (overview?.settlement.settlementStatus == 'SETTLED');
    final payoutState = hasPayoutData
        ? (payoutSatisfied ? RadarDimensionState.satisfied : RadarDimensionState.restricted)
        : RadarDimensionState.unavailable;

    final payoutAxis = RadarAxisItem(
      id: 'payout_readiness',
      labelEn: 'Payout Readiness',
      labelAr: 'جاهزية الصرف',
      state: payoutState,
      statusLabelEn: hasPayoutData ? (payoutSatisfied ? 'Ready' : 'Restricted') : 'Not Available',
      statusLabelAr: hasPayoutData ? (payoutSatisfied ? 'جاهز' : 'مقيد') : 'غير متوفر',
      descriptionEn: payoutCrit?.description ??
          (payoutSatisfied ? 'Treasury liquidity guardrail and underwriting conditions cleared.' : 'Payout release is restricted pending gate satisfaction.'),
      descriptionAr: payoutSatisfied
          ? 'تم استيفاء شروط السيولة في الخزينة والموافقة المالية.'
          : 'صرف المستحقات مقيد لحين استيفاء الشروط.',
      blockingReason: payoutCrit?.blockingReason,
      icon: Icons.payments_outlined,
      authoritativeNumericValue: null,
    );

    // 4. Verification Status
    final kycCrit = _findCriterion(eligibility.criteria, ['kyc', 'identity', 'verification', 'tier']);
    final bool hasKycData = kycCrit != null || overview?.summary.kycStatus != null;
    final bool kycSatisfied = kycCrit?.isSatisfied ?? (overview?.summary.kycStatus == KycStatus.verified);
    final kycState = hasKycData
        ? (kycSatisfied ? RadarDimensionState.satisfied : RadarDimensionState.restricted)
        : RadarDimensionState.unavailable;

    final verificationAxis = RadarAxisItem(
      id: 'verification_status',
      labelEn: 'Verification Status',
      labelAr: 'حالة التحقق',
      state: kycState,
      statusLabelEn: hasKycData ? (kycSatisfied ? 'Verified' : 'Pending ID') : 'Not Available',
      statusLabelAr: hasKycData ? (kycSatisfied ? 'موثق' : 'مطلوب إثبات الهوية') : 'غير متوفر',
      descriptionEn: kycCrit?.description ??
          (kycSatisfied ? 'Identity and AML compliance criteria fully validated.' : 'Identity verification document required.'),
      descriptionAr: kycSatisfied
          ? 'تم التحقق من الهوية واستيفاء متطلبات الامتثال بالكامل.'
          : 'مطلوب تقديم وثيقة إثبات الهوية لتفعيل الصرف.',
      blockingReason: kycCrit?.blockingReason,
      icon: Icons.verified_user_outlined,
      authoritativeNumericValue: null,
    );

    // 5. Circle Health
    final healthCrit = _findCriterion(eligibility.criteria, ['circle health', 'health', 'solvency', 'pool']);
    final bool hasHealthData = healthCrit != null;
    final bool healthSatisfied = healthCrit?.isSatisfied ?? false;
    final healthState = hasHealthData
        ? (healthSatisfied ? RadarDimensionState.satisfied : RadarDimensionState.restricted)
        : RadarDimensionState.unavailable;

    final circleHealthAxis = RadarAxisItem(
      id: 'circle_health',
      labelEn: 'Circle Health',
      labelAr: 'صحة الدائرة',
      state: healthState,
      statusLabelEn: hasHealthData ? (healthSatisfied ? 'Optimal' : 'At Risk') : 'Not Available',
      statusLabelAr: hasHealthData ? (healthSatisfied ? 'مثالي' : 'معرض للمخاطر') : 'غير متوفر',
      descriptionEn: healthCrit?.description ??
          (hasHealthData ? 'Pool solvency and liquidity reserves meet governance standards.' : 'Circle health metrics not published for this cycle.'),
      descriptionAr: healthSatisfied
          ? 'ملاءة الصندوق واحتياطي السيولة يتوافقان مع معايير الحوكمة.'
          : 'لم يتم نشر مؤشرات صحة الدائرة لهذه الدورة.',
      blockingReason: healthCrit?.blockingReason,
      icon: Icons.health_and_safety_outlined,
      authoritativeNumericValue: null,
    );

    // 6. Rotation Progress
    final rotationCrit = _findCriterion(eligibility.criteria, ['rotation', 'schedule', 'slot', 'progress']);
    final bool hasRotationData = rotationCrit != null || overview?.allocation != null;
    final bool rotationSatisfied = rotationCrit?.isSatisfied ?? (overview?.allocation.status == 'ALLOCATED');
    final rotationState = hasRotationData
        ? (rotationSatisfied ? RadarDimensionState.satisfied : RadarDimensionState.restricted)
        : RadarDimensionState.unavailable;

    final rotationAxis = RadarAxisItem(
      id: 'rotation_progress',
      labelEn: 'Rotation Progress',
      labelAr: 'تقدم الدورة',
      state: rotationState,
      statusLabelEn: hasRotationData ? (rotationSatisfied ? 'On Track' : 'Delayed') : 'Not Available',
      statusLabelAr: hasRotationData ? (rotationSatisfied ? 'منتظم' : 'متأخر') : 'غير متوفر',
      descriptionEn: rotationCrit?.description ??
          (hasRotationData ? 'Cycle rotation schedule is proceeding without disruption.' : 'Rotation position details not currently available.'),
      descriptionAr: hasRotationData
          ? 'جدول دوران الجمعية يسير بانتظام دون تأخير.'
          : 'تفاصيل دور التوزيع غير متوفرة حالياً.',
      blockingReason: rotationCrit?.blockingReason,
      icon: Icons.autorenew,
      authoritativeNumericValue: null,
    );

    return [
      contribAxis,
      stabilityAxis,
      payoutAxis,
      verificationAxis,
      circleHealthAxis,
      rotationAxis,
    ];
  }

  static FundingEligibilityCriterion? _findCriterion(List<FundingEligibilityCriterion> criteria, List<String> keywords) {
    for (final crit in criteria) {
      final nameLower = crit.name.toLowerCase();
      final descLower = crit.description.toLowerCase();
      for (final kw in keywords) {
        if (nameLower.contains(kw) || descLower.contains(kw)) {
          return crit;
        }
      }
    }
    return null;
  }
}

/// Interactive 6-Axis Funding Eligibility Qualitative Radar Visualizer.
/// Visualizes governance clearance states across 6 dimensions without quantitative magnitude fabrications.
class FundingEligibilityRadarWidget extends StatefulWidget {
  final List<RadarAxisItem> axes;
  final bool isRtl;
  final ValueChanged<int>? onAxisSelected;
  final int selectedIndex;

  const FundingEligibilityRadarWidget({
    super.key,
    required this.axes,
    this.isRtl = false,
    this.onAxisSelected,
    this.selectedIndex = 0,
  });

  @override
  State<FundingEligibilityRadarWidget> createState() => _FundingEligibilityRadarWidgetState();
}

class _FundingEligibilityRadarWidgetState extends State<FundingEligibilityRadarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _entranceAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _entranceAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = widget.axes.where((a) => a.isAvailable).length;
    final satisfiedCount = widget.axes.where((a) => a.isAvailable && a.isSatisfied).length;

    return Semantics(
      label: widget.isRtl
          ? 'مخطط رادار أهلية التمويل النوعي: تم استيفاء $satisfiedCount من $availableCount محاور متوفرة'
          : 'Funding Eligibility Qualitative Radar: $satisfiedCount of $availableCount available dimensions satisfied',
      container: true,
      child: Column(
        children: [
          // Radar Graphic Canvas
          Center(
            child: SizedBox(
              width: 320.0,
              height: 320.0,
              child: AnimatedBuilder(
                animation: _entranceAnim,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(320.0, 320.0),
                    painter: _RadarChartPainter(
                      axes: widget.axes,
                      isRtl: widget.isRtl,
                      selectedIndex: widget.selectedIndex,
                      entranceProgress: _entranceAnim.value,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Quick Interactive Vertex Buttons for Accessibility & Touch Targets
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 0; i < widget.axes.length; i++) ...[
                _buildAxisChip(i),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAxisChip(int index) {
    final axis = widget.axes[index];
    final isSelected = widget.selectedIndex == index;

    Color badgeColor;
    if (!axis.isAvailable) {
      badgeColor = AppColors.textMuted;
    } else if (axis.isSatisfied) {
      badgeColor = AppColors.emeraldGreen;
    } else {
      badgeColor = AppColors.crimsonRed;
    }

    return InkWell(
      onTap: () {
        if (widget.onAxisSelected != null) {
          widget.onAxisSelected!(index);
        }
      },
      borderRadius: AppRadii.borderSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withValues(alpha: 0.2) : AppColors.surfaceElevated,
          borderRadius: AppRadii.borderSm,
          border: Border.all(
            color: isSelected ? badgeColor : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(axis.icon, size: 14.0, color: badgeColor),
            const SizedBox(width: 4.0),
            Text(
              axis.getLabel(widget.isRtl),
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<RadarAxisItem> axes;
  final bool isRtl;
  final int selectedIndex;
  final double entranceProgress;

  _RadarChartPainter({
    required this.axes,
    required this.isRtl,
    required this.selectedIndex,
    required this.entranceProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) - 48.0;
    const numAxes = 6;

    // 1. Structural Perimeter Frame
    final framePaint = Paint()
      ..color = AppColors.emeraldGreen.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final outerPath = Path();
    final List<Offset> outerEndpoints = [];
    for (int i = 0; i < numAxes; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / numAxes);
      final pt = Offset(
        center.dx + maxRadius * math.cos(angle),
        center.dy + maxRadius * math.sin(angle),
      );
      outerEndpoints.add(pt);
      if (i == 0) {
        outerPath.moveTo(pt.dx, pt.dy);
      } else {
        outerPath.lineTo(pt.dx, pt.dy);
      }
    }
    outerPath.close();
    canvas.drawPath(outerPath, framePaint);

    // 2. Dimensional Spokes & State Segments
    for (int i = 0; i < numAxes; i++) {
      final axis = axes[i];
      final endPoint = outerEndpoints[i];

      Color spokeColor;
      double spokeWidth;
      if (axis.state == RadarDimensionState.satisfied) {
        spokeColor = AppColors.emeraldGreen.withValues(alpha: 0.60 * entranceProgress);
        spokeWidth = 2.0;
      } else if (axis.state == RadarDimensionState.restricted) {
        spokeColor = AppColors.crimsonRed.withValues(alpha: 0.70 * entranceProgress);
        spokeWidth = 2.0;
      } else {
        spokeColor = AppColors.textMuted.withValues(alpha: 0.20);
        spokeWidth = 1.0;
      }

      final spokePaint = Paint()
        ..color = spokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = spokeWidth;

      canvas.drawLine(center, endPoint, spokePaint);
    }

    // 3. Sector Clearance Fill between adjacent satisfied dimensions
    final satisfiedFillPath = Path();
    bool hasSatisfiedSectors = false;

    for (int i = 0; i < numAxes; i++) {
      final nextIdx = (i + 1) % numAxes;
      if (axes[i].state == RadarDimensionState.satisfied && axes[nextIdx].state == RadarDimensionState.satisfied) {
        satisfiedFillPath.moveTo(center.dx, center.dy);
        satisfiedFillPath.lineTo(outerEndpoints[i].dx, outerEndpoints[i].dy);
        satisfiedFillPath.lineTo(outerEndpoints[nextIdx].dx, outerEndpoints[nextIdx].dy);
        satisfiedFillPath.close();
        hasSatisfiedSectors = true;
      }
    }

    if (hasSatisfiedSectors) {
      final sectorFillPaint = Paint()
        ..color = AppColors.emeraldGreen.withValues(alpha: 0.15 * entranceProgress)
        ..style = PaintingStyle.fill;
      canvas.drawPath(satisfiedFillPath, sectorFillPaint);
    }

    // 4. Central Hub Gate Status Indicator
    final allAvailableSatisfied = axes.every((a) => !a.isAvailable || a.isSatisfied);
    final hubColor = allAvailableSatisfied ? AppColors.emeraldGreen : AppColors.crimsonRed;

    final hubBgPaint = Paint()
      ..color = AppColors.deepSlate
      ..style = PaintingStyle.fill;
    final hubBorderPaint = Paint()
      ..color = hubColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 14.0, hubBgPaint);
    canvas.drawCircle(center, 14.0, hubBorderPaint);

    final hubDotPaint = Paint()
      ..color = hubColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.0, hubDotPaint);

    // 5. Dimensional Endpoints at Structural Radius R
    for (int i = 0; i < numAxes; i++) {
      final axis = axes[i];
      final pt = outerEndpoints[i];
      final isSelected = selectedIndex == i;

      if (axis.state == RadarDimensionState.satisfied) {
        // Satisfied Dimension: Solid Emerald node with halo ring
        final nodePaint = Paint()
          ..color = AppColors.emeraldGreen
          ..style = PaintingStyle.fill;
        final ringPaint = Paint()
          ..color = AppColors.emeraldGreen.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawCircle(pt, 5.0, nodePaint);
        canvas.drawCircle(pt, 9.0, ringPaint);

        if (isSelected) {
          final activeGlowPaint = Paint()
            ..color = AppColors.emeraldGreen.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5;
          canvas.drawCircle(pt, 14.0, activeGlowPaint);
        }
      } else if (axis.state == RadarDimensionState.restricted) {
        // Restricted Dimension: Solid Crimson node with warning ring
        final nodePaint = Paint()
          ..color = AppColors.crimsonRed
          ..style = PaintingStyle.fill;
        final ringPaint = Paint()
          ..color = AppColors.crimsonRed.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawCircle(pt, 5.0, nodePaint);
        canvas.drawCircle(pt, 9.0, ringPaint);

        if (isSelected) {
          final activeGlowPaint = Paint()
            ..color = AppColors.crimsonRed.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5;
          canvas.drawCircle(pt, 14.0, activeGlowPaint);
        }
      } else {
        // Unavailable Dimension: Neutral dashed circle
        final unavailablePaint = Paint()
          ..color = AppColors.textMuted.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(pt, 4.0, unavailablePaint);

        if (isSelected) {
          final activeGlowPaint = Paint()
            ..color = AppColors.textMuted.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawCircle(pt, 10.0, activeGlowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.entranceProgress != entranceProgress ||
        oldDelegate.isRtl != isRtl ||
        oldDelegate.axes != axes;
  }
}
