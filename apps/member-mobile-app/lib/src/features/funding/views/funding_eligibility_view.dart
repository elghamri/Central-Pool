import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/funding_models.dart';
import '../widgets/funding_eligibility_radar_widget.dart';

/// Screen 16 (Group 5): Interactive 6-Axis Funding Eligibility Radar & Risk Review View.
/// Redesigned strictly in accordance with Stitch Project 13353050789076646822 (Obsidian Emerald Cooperative).
class FundingEligibilityView extends StatefulWidget {
  final FundingEligibility eligibility;
  final FundingOverview? overview;
  final VoidCallback onBack;
  final bool isLoading;
  final bool isEmpty;
  final String? errorMessage;
  final bool isOffline;
  final bool isPermissionDenied;
  final bool isSafetyLockActive;
  final VoidCallback? onRetry;

  const FundingEligibilityView({
    super.key,
    required this.eligibility,
    this.overview,
    required this.onBack,
    this.isLoading = false,
    this.isEmpty = false,
    this.errorMessage,
    this.isOffline = false,
    this.isPermissionDenied = false,
    this.isSafetyLockActive = false,
    this.onRetry,
  });

  @override
  State<FundingEligibilityView> createState() => _FundingEligibilityViewState();
}

class _FundingEligibilityViewState extends State<FundingEligibilityView> {
  int _selectedAxisIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // 1. Loading State
    if (widget.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.deepSlate,
        appBar: _buildAppBar(context, isRtl),
        body: Center(
          child: AppLoadingIndicator(
            message: isRtl ? 'جاري تقييم أهلية التمويل...' : 'Evaluating funding eligibility criteria...',
          ),
        ),
      );
    }

    // 2. Error State
    if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.deepSlate,
        appBar: _buildAppBar(context, isRtl),
        body: Center(
          child: ErrorCardWidget(
            title: isRtl ? 'تعذر تحميل بيانات الأهلية' : 'Unable to Load Eligibility Data',
            errorMessage: widget.errorMessage!,
            onRetry: widget.onRetry,
          ),
        ),
      );
    }

    // 3. Empty State
    if (widget.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.deepSlate,
        appBar: _buildAppBar(context, isRtl),
        body: Center(
          child: EmptyStateWidget(
            icon: Icons.radar_outlined,
            title: isRtl ? 'لا توجد بيانات أهلية' : 'No Eligibility Data Found',
            description: isRtl
                ? 'لم يتم تسجيل تقييم أهلية لهذا العضو في الدورة الحالية.'
                : 'No underwriting evaluation has been recorded for this member in the active cycle.',
            actionLabel: isRtl ? 'العودة للملخص' : 'Return to Overview',
            onAction: widget.onBack,
          ),
        ),
      );
    }

    // 4. Permission Denied State
    if (widget.isPermissionDenied) {
      return Scaffold(
        backgroundColor: AppColors.deepSlate,
        appBar: _buildAppBar(context, isRtl),
        body: Center(
          child: Container(
            margin: AppSpacing.paddingCard,
            padding: AppSpacing.paddingCard,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.crimsonRed.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: AppColors.crimsonRed, size: 40.0),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isRtl ? 'تم رفض إذن الوصول' : 'Access Restricted',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isRtl
                      ? 'ليس لديك صلاحية لعرض تقرير الأهلية التفصيلي لهذا الحساب.'
                      : 'You do not have the required permissions to view detailed underwriting records for this account.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SecondaryButton(
                  label: isRtl ? 'العودة' : 'Go Back',
                  onPressed: widget.onBack,
                  isFullWidth: false,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 5. Normal & Partial Data Mapping
    final axes = FundingEligibilityRadarMapper.mapToAxes(widget.eligibility, overview: widget.overview);
    final isEligible = widget.eligibility.isEligible;
    final availableCount = axes.where((a) => a.isAvailable).length;
    final satisfiedCount = axes.where((a) => a.isAvailable && a.isSatisfied).length;
    final isPartialData = availableCount < 6;

    return Scaffold(
      backgroundColor: AppColors.deepSlate,
      appBar: _buildAppBar(context, isRtl),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety Lock Banner
            if (widget.isSafetyLockActive) ...[
              _buildSafetyLockBanner(isRtl),
              const SizedBox(height: AppSpacing.md),
            ],

            // Offline Indicator Banner
            if (widget.isOffline) ...[
              _buildOfflineBanner(isRtl),
              const SizedBox(height: AppSpacing.md),
            ],

            // Partial Data Notice Banner
            if (isPartialData) ...[
              _buildPartialDataBanner(isRtl, availableCount),
              const SizedBox(height: AppSpacing.md),
            ],

            // Readiness Overview Hero Card
            _buildReadinessOverviewCard(isRtl, isEligible, satisfiedCount, availableCount),
            const SizedBox(height: AppSpacing.lg),

            // Interactive 6-Axis Radar Visualizer Card
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isRtl ? 'مؤشرات المخاطر والأهلية' : 'Eligibility & Risk Radar',
                          style: AppTypography.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                          borderRadius: AppRadii.borderSm,
                          border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isRtl ? '6 محاور تفاعلية' : '6 Interactive Axes',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.emeraldGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isRtl
                        ? 'انقر على أي محور لعرض التفاصيل والشروط المعلقة.'
                        : 'Tap any axis vertex to inspect criteria details and pending gates.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // The 6-Axis Radar Custom Paint
                  FundingEligibilityRadarWidget(
                    axes: axes,
                    isRtl: isRtl,
                    selectedIndex: _selectedAxisIndex,
                    onAxisSelected: (index) {
                      setState(() {
                        _selectedAxisIndex = index;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Selected Axis Detailed Callout Card
            if (_selectedAxisIndex >= 0 && _selectedAxisIndex < axes.length) ...[
              _buildSelectedAxisDetailCard(isRtl, axes[_selectedAxisIndex]),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Complete Textual Alternative & Axis Breakdown
            Text(
              isRtl ? 'تفاصيل التقييم والمحاور' : 'Axis Breakdown & Criteria',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isRtl
                  ? 'عرض نصي كامل لجميع المحاور الستة لدعم سهولة الوصول.'
                  : 'Complete textual alternative for all 6 dimensions supporting accessibility.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            for (int i = 0; i < axes.length; i++) ...[
              _buildAxisListTile(isRtl, axes[i], isSelected: _selectedAxisIndex == i, onTap: () {
                setState(() {
                  _selectedAxisIndex = i;
                });
              }),
              const SizedBox(height: AppSpacing.sm),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Underwriting Audit Timestamp Stamp
            _buildAuditStamp(isRtl),
            const SizedBox(height: AppSpacing.xl),

            // Return Button
            SecondaryButton(
              label: isRtl ? 'العودة لملخص التمويل' : 'Back to Funding Overview',
              onPressed: widget.onBack,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isRtl) {
    return AppBar(
      backgroundColor: AppColors.deepSlate.withValues(alpha: 0.9),
      elevation: 0,
      leading: IconButton(
        icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: widget.onBack,
        tooltip: isRtl ? 'العودة' : 'Back',
      ),
      title: Text(
        isRtl ? 'مراجعة الأهلية' : 'Funding Eligibility Gate',
        style: AppTypography.titleLarge,
      ),
      centerTitle: false,
    );
  }

  Widget _buildSafetyLockBanner(bool isRtl) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.crimsonRed.withValues(alpha: 0.15),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.crimsonRed, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: AppColors.crimsonRed, size: 28.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl ? 'قفل الأمان المالي نشط' : 'Financial Safety Lock Active',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.crimsonRed, fontWeight: FontWeight.bold),
                ),
                Text(
                  isRtl
                      ? 'تم تفعيل قفل الأمان على مستوى المنظومة. جميع عمليات الصرف متوقفة مؤقتاً.'
                      : 'System-wide emergency circuit breaker is active. Payout disbursements are halted.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(bool isRtl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.15),
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.amberWarning, size: 20.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isRtl
                  ? 'وضع غير متصل: يتم عرض آخر تقييم محفوظ محلياً.'
                  : 'Offline Mode: Displaying locally cached evaluation records.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialDataBanner(bool isRtl, int availableCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.skyInfo.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.skyInfo.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.skyInfo, size: 20.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isRtl
                  ? 'بيانات جزئية: $availableCount من 6 محاور متوفرة. لا يتم اختلاق أي بيانات مفقودة.'
                  : 'Partial Evaluation: $availableCount of 6 dimensions available. Missing axes remain unpopulated.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessOverviewCard(bool isRtl, bool isEligible, int satisfiedCount, int availableCount) {
    final statusColor = isEligible ? AppColors.emeraldGreen : AppColors.crimsonRed;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isRtl ? 'نظرة عامة على الجاهزية' : 'Readiness Overview',
                  style: AppTypography.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Simulation Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.skyInfo.withValues(alpha: 0.15),
                  borderRadius: AppRadii.borderSm,
                  border: Border.all(color: AppColors.skyInfo.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.science, size: 14.0, color: AppColors.skyInfo),
                    const SizedBox(width: 4.0),
                    Text(
                      isRtl ? 'وضع المحاكاة' : 'Simulation Mode',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.skyInfo),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2.0),
                ),
                child: Icon(
                  isEligible ? Icons.check_circle_outline : Icons.gpp_bad_outlined,
                  color: statusColor,
                  size: 28.0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEligible
                          ? (isRtl ? 'مؤهل للصرف بالكامل' : 'Passed All Underwriting Gates')
                          : (isRtl ? 'مقيد - يتطلب استيفاء الشروط' : 'Eligibility Restriction Active'),
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      isEligible
                          ? (isRtl
                              ? 'تم التحقق من $satisfiedCount من أصل $availableCount محاور متوفرة بنجاح.'
                              : '$satisfiedCount of $availableCount evaluated dimensions successfully passed.')
                          : (isRtl
                              ? 'يوجد شروط يجب استيفاؤها قبل الإفراج عن مبالغ الصرف.'
                              : 'Pending criteria must be resolved prior to rotation disbursement.'),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAxisDetailCard(bool isRtl, RadarAxisItem axis) {
    Color badgeColor;
    if (!axis.isAvailable) {
      badgeColor = AppColors.textMuted;
    } else if (axis.isSatisfied) {
      badgeColor = AppColors.emeraldGreen;
    } else {
      badgeColor = AppColors.crimsonRed;
    }

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(axis.icon, color: badgeColor, size: 24.0),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  axis.getLabel(isRtl),
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              StatusBadge(
                label: axis.getStatusLabel(isRtl),
                type: axis.isSatisfied ? StatusBadgeType.success : (!axis.isAvailable ? StatusBadgeType.neutral : StatusBadgeType.error),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            axis.getDescription(isRtl),
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          if (axis.blockingReason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              isRtl ? 'سبب التقييد: ${axis.blockingReason}' : 'Blocking Reason: ${axis.blockingReason}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.crimsonRed, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAxisListTile(bool isRtl, RadarAxisItem axis, {required bool isSelected, required VoidCallback onTap}) {
    Color badgeColor;
    if (!axis.isAvailable) {
      badgeColor = AppColors.textMuted;
    } else if (axis.isSatisfied) {
      badgeColor = AppColors.emeraldGreen;
    } else {
      badgeColor = AppColors.crimsonRed;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.borderSm,
      child: SurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: AppRadii.borderSm,
              ),
              child: Icon(
                axis.icon,
                color: badgeColor,
                size: 20.0,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          axis.getLabel(isRtl),
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? AppColors.emeraldGreen : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      StatusBadge(
                        label: axis.getStatusLabel(isRtl),
                        type: axis.isSatisfied
                            ? StatusBadgeType.success
                            : (!axis.isAvailable ? StatusBadgeType.neutral : StatusBadgeType.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    axis.getDescription(isRtl),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditStamp(bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: AppColors.sovereignGold, size: 20.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl
                      ? 'تم التقييم بواسطة محرك الامتثال الآلي'
                      : 'Evaluated by Automated Underwriting Engine',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.sovereignGold, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Timestamp: ${widget.eligibility.evaluatedAt.toUtc().toString().substring(0, 19)} UTC • Member ID: ${widget.eligibility.memberId}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
