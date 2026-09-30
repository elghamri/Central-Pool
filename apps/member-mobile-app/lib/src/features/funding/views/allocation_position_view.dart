import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/funding_models.dart';

/// Screen 8: Allocation & Rotation Position View according to Stitch Baseline ("The Rotation").
class AllocationPositionView extends StatelessWidget {
  final AllocationPosition allocation;
  final VoidCallback onTrackLifecycle;
  final VoidCallback onBack;
  final bool isRtl;

  const AllocationPositionView({
    super.key,
    required this.allocation,
    required this.onTrackLifecycle,
    required this.onBack,
    this.isRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAllocated = allocation.status == 'ALLOCATED';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.deepSlate,
        appBar: AppBar(
          title: Text(isRtl ? 'موقع الدور في الجمعية' : 'Allocation & Rotation Position'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: onBack,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingCard,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary Rotation Card
                  SurfaceCard(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isRtl
                                    ? 'دور جدول التناوب: رقم الدور #${allocation.slotNumber}'
                                    : 'Rotation Schedule Turn: Slot #${allocation.slotNumber}',
                                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            StatusBadge(
                              label: allocation.status,
                              type: isAllocated ? StatusBadgeType.success : StatusBadgeType.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(color: AppColors.borderSubtle),
                        const SizedBox(height: AppSpacing.md),

                        // Assigned Liquidity Amount Hero
                        Center(
                          child: Column(
                            children: [
                              Text(
                                isRtl ? 'صرف السيولة المخصص' : 'Assigned Liquidity Payout',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4.0),
                              FinancialAmountText(
                                amountMinor: allocation.expectedPayoutMinor,
                                currency: 'USD',
                                style: AppTypography.financialDisplay.copyWith(
                                  fontSize: 34.0,
                                  color: AppColors.emeraldGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                isRtl
                                    ? 'تخصيص سيولة مضمون وفق خوارزمية التدوير المتكافئة'
                                    : 'Deterministic peer-to-peer liquidity cycle allocation',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Breakdown Rows
                        _buildRow(isRtl ? 'معرف التخصيص' : 'Allocation Identifier', allocation.allocationId),
                        _buildRow(isRtl ? 'الدورة التعاونية' : 'Cooperative Cycle', '${allocation.cycleName} (${allocation.cycleId})'),
                        _buildRow(
                          isRtl ? 'موقع الدور في الدورة' : 'Rotation Slot Position',
                          isRtl
                              ? 'الدور #${allocation.slotNumber} من إجمالي ${allocation.totalSlots}'
                              : 'Slot #${allocation.slotNumber} of ${allocation.totalSlots} (${allocation.slotNumber == 1 ? "First Month" : "Scheduled"})',
                        ),
                        _buildRow(isRtl ? 'العضو المستحق' : 'Recipient Member', '${allocation.recipientMemberName} (${allocation.recipientMemberId})'),
                        _buildRow(
                          isRtl ? 'وقت تسجيل الدور' : 'Allocation Timestamp',
                          '${allocation.allocatedAt.toUtc().toString().substring(0, 19)} UTC',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Financial Invariant & Separation Notice
                  _buildSeparationNotice(isRtl),
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  PrimaryButton(
                    label: isRtl ? 'متابعة مراحل الصرف (14 مرحلة)' : 'Track 14-Stage Lifecycle',
                    icon: Icons.timeline,
                    onPressed: onTrackLifecycle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: isRtl ? 'العودة للوحة التحكم' : 'Back to Overview',
                    onPressed: onBack,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparationNotice(bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.sovereignGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.sovereignGold, size: 22.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl ? 'تنبيه مالي حاسم: التخصيص مقابل التسوية' : 'Crucial Distinction: Allocation vs Settlement',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.sovereignGold, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2.0),
                Text(
                  isRtl
                      ? 'تحدد خطة التخصيص أولوية الدور في الدورة. بينما يتطلب تحويل السيولة الفعلي تفويضاً ثنائياً، وحجزاً في حساب الخزينة، وتسوية مصرفية نهائية غير قابلة للإلغاء.'
                      : 'An Allocation Plan defines round-robin priority. Actual liquidity transfer requires Maker-Checker dual authorization, Treasury pool reservation, and irrevocable FedNow RTGS settlement.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
