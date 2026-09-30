import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';
import '../state/gameya_controller.dart';
import '../widgets/rotation_wheel_widget.dart';
import '../widgets/economic_status_card.dart';
import '../widgets/peer_roster_tile.dart';
import '../i18n/gameya_strings.dart';
import 'financial_action_flow_view.dart';

/// Phase 47.2.4: Authoritative Stitch-Approved Game'ya Circle Room & Member Experience.
///
/// Implements the Stitch visual design from Project 13353050789076646822:
/// - Circle Room Header & Identity [Artboard: ade004fe5f1d4aa2b301d19b85c4a93c, 4ea1f9f009f14d46a296bc4ddc3f0ee5]
/// - Member Position, Contribution Obligation & Cycle Progress Bento Cards
/// - Expected Payout & Symmetrical 50/50 Breakdown (50% Early / 50% Later)
/// - Interactive Rotation Wheel with Member Nodes & Bilateral Chords
/// - Single Primary Contextual Action Button
/// - Peer Member Roster (1..N positions, claimed/open slots, payment status)
/// - Scoped Organizer Management Panel (when organizer is current user)
/// - Universal System States: Loading, Empty, Error, Offline, Permission Denied, Safety Lock
class CircleRoomView extends StatefulWidget {
  final GameyaController controller;
  final String circleId;
  final VoidCallback? onBack;
  final bool isOffline;
  final bool isSafetyLockActive;
  final bool isPermissionDenied;
  final String? errorMessage;
  final bool? isRtl;

  const CircleRoomView({
    super.key,
    required this.controller,
    required this.circleId,
    this.onBack,
    this.isOffline = false,
    this.isSafetyLockActive = false,
    this.isPermissionDenied = false,
    this.errorMessage,
    this.isRtl,
  });

  @override
  State<CircleRoomView> createState() => _CircleRoomViewState();
}

class _CircleRoomViewState extends State<CircleRoomView> {
  GameyaSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.selectCircleRoom(widget.circleId);
      }
    });
  }

  @override
  void didUpdateWidget(CircleRoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.circleId != oldWidget.circleId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.controller.selectCircleRoom(widget.circleId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameyaState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        // 1. Permission Denied State
        if (widget.isPermissionDenied) {
          return _buildPermissionDeniedScaffold(context);
        }

        // 2. Loading State
        if (state is! GameyaLoaded) {
          return const Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.emeraldGreen),
            ),
          );
        }

        final isRtl = widget.isRtl ?? state.isRtl;
        final strings = GameyaStrings.of(isRtl ? 'ar' : 'en');
        final allCircles = [
          ...state.hubSummary.activeCircles,
          ...state.marketplaceCircles,
        ];
        final circle = (state.selectedCircleRoom != null &&
                state.selectedCircleRoom!.id == widget.circleId)
            ? state.selectedCircleRoom
            : allCircles.cast<GameyaCircle?>().firstWhere(
                  (c) => c?.id == widget.circleId,
                  orElse: () => null,
                );

        // 3. Empty State (Circle not found)
        if (circle == null) {
          return _buildEmptyScaffold(context, strings, isRtl);
        }

        // 4. Main Circle Room View
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.deepSlate,
            appBar: _buildAppBar(circle, strings, isRtl),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // System State Banners
                        if (widget.isSafetyLockActive) ...[
                          _buildSafetyLockBanner(isRtl),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (widget.isOffline) ...[
                          _buildOfflineBanner(isRtl),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (widget.errorMessage != null) ...[
                          AlertBanner(
                            title: isRtl ? 'خطأ في النظام' : 'System Error',
                            message: widget.errorMessage!,
                            color: AppColors.crimsonRed,
                            icon: Icons.error_outline,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 1. Circle Summary Header & Lifecycle Status Card
                        _buildCircleHeaderCard(circle, strings, isRtl),
                        const SizedBox(height: AppSpacing.md),

                        // 2. Member Position & Financial Obligation Bento Grid
                        _buildMemberPositionBentoGrid(circle, strings, isRtl),
                        const SizedBox(height: AppSpacing.md),

                        // 3. Symmetrical Paired 50/50 Explanation Card (If Symmetrical Paired)
                        if (circle.allocationMode == GameyaAllocationMode.symmetricalPaired) ...[
                          _buildSymmetricalPairedExplanationCard(circle, strings, isRtl),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 4. Interactive Rotation Wheel & Topology
                        _buildRotationWheelSection(circle, strings, isRtl),
                        const SizedBox(height: AppSpacing.md),

                        // 5. Economic Status Card (Net Debtor vs Net Creditor)
                        if (circle.isUserEnrolled) ...[
                          EconomicStatusCard(circle: circle),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 6. Primary Contextual Action Button (One Clear Primary CTA)
                        _buildPrimaryActionButton(context, circle, strings, isRtl),

                        // 7. Scoped Organizer Management Panel (If organizer is current user)
                        if (circle.isOrganizer(widget.controller.currentUserId)) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildOrganizerControlCard(context, circle, isRtl),
                        ],

                        const SizedBox(height: AppSpacing.xl),

                        // 8. Section Header: Peer Member Roster
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${strings.circleMembers} (${circle.claimedSlotsCount}/${circle.totalPeriods})',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: circle.allocationMode == GameyaAllocationMode.symmetricalPaired
                                  ? (isRtl ? 'توزيع مقترن ٥٠/٥٠' : 'Paired')
                                  : (isRtl ? 'تدوير تسلسلي' : 'Sequential'),
                              type: StatusBadgeType.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // 9. Roster Tiles / Paired Cards
                        _buildRosterSection(circle, strings, isRtl),

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // APP BAR
  // ===========================================================================
  PreferredSizeWidget _buildAppBar(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    return AppBar(
      backgroundColor: AppColors.deepSlate,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
      ),
      title: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            circle.name,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${circle.goalCategory} • ${circle.totalPeriods} ${isRtl ? "أعضاء" : "Members"}',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.gavel_outlined, color: AppColors.textSecondary),
          tooltip: isRtl ? 'لائحة وقواعد الجمعية' : 'Circle Bylaws & Rules',
          onPressed: () => _showCircleBylawsModal(context, circle, isRtl),
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppColors.emeraldGreen),
          tooltip: isRtl ? 'مشاركة كود ورابط الدعوة' : 'Share Invite Link & Code',
          onPressed: () => _showShareInviteModal(context, circle, isRtl),
        ),
      ],
    );
  }

  String _formatCurrency(int amountMinor) {
    final int dollars = amountMinor ~/ 100;
    return dollars.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // ===========================================================================
  // 1. CIRCLE SUMMARY & PROGRESS HEADER CARD
  // ===========================================================================
  Widget _buildCircleHeaderCard(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    final isPaired = circle.allocationMode == GameyaAllocationMode.symmetricalPaired;
    final int displayPayoutMinor = circle.isUserEnrolled
        ? circle.userPayoutAmountForPeriod(circle.currentPeriod)
        : (circle.slots.isNotEmpty ? circle.slots.first.payoutAmountMinor : 0);

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Monthly Due Metric
              Expanded(
                child: _buildMetricColumn(
                  strings.monthlyDue,
                  '\$${(circle.monthlyContributionMinor / 100).toStringAsFixed(0)}',
                ),
              ),
              // Payout Metric
              Expanded(
                child: _buildMetricColumn(
                  isPaired ? strings.pairPayout : strings.totalPayout,
                  '\$${_formatCurrency(displayPayoutMinor)}',
                  isHighlight: true,
                ),
              ),
              // Cycle Progress Metric
              Expanded(
                child: _buildMetricColumn(
                  strings.cycleProgress,
                  strings.monthProgress(circle.currentPeriod, circle.totalPeriods),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress Bar
          ClipRRect(
            borderRadius: AppRadii.borderSm,
            child: LinearProgressIndicator(
              value: circle.progressFraction,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: isHighlight ? AppColors.emeraldGreen : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. MEMBER POSITION & FINANCIAL OBLIGATION BENTO GRID
  // ===========================================================================
  Widget _buildMemberPositionBentoGrid(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    final isEnrolled = circle.isUserEnrolled;
    final slotPos = circle.currentUserSlotPosition;

    String positionText;
    String positionSubtitle;
    if (isEnrolled && slotPos != null) {
      positionText = isRtl ? 'المركز #$slotPos من ${circle.totalPeriods}' : 'Position #$slotPos / ${circle.totalPeriods}';
      positionSubtitle = isRtl
          ? 'شهر الاستحقاق: شهر $slotPos'
          : 'Payout Turn: Month $slotPos';
    } else {
      positionText = isRtl ? 'غير منضم' : 'Not Enrolled';
      positionSubtitle = isRtl ? 'اختر دوراً شاغراً للانضمام' : 'Choose an open slot to join';
    }

    return Row(
      children: [
        // Member Position Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_outlined, color: AppColors.emeraldGreen, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isRtl ? 'موقعك بالجمعية' : 'Your Position',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  positionText,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isEnrolled ? AppColors.emeraldGreen : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  positionSubtitle,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Obligation & Readiness Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isRtl ? 'حالة القسط' : 'Contribution Due',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FinancialAmountText(
                  amountMinor: circle.monthlyContributionMinor,
                  currency: 'EGP',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  isRtl ? 'يستحق في اليوم الأول من كل شهر' : 'Due on the 1st of each month',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. SYMMETRICAL PAIRED 50/50 EXPLANATION CARD
  // ===========================================================================
  Widget _buildSymmetricalPairedExplanationCard(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    final slotPos = circle.currentUserSlotPosition;
    final isEnrolled = slotPos != null;
    final isOdd = circle.totalPeriods.isOdd;
    final midMonth = (circle.totalPeriods + 1) ~/ 2;
    final isUserInMid = isEnrolled && isOdd && slotPos == midMonth;

    final earlyTurn = isEnrolled ? circle.primaryPayoutPeriodFor(slotPos) : 1;
    final lateTurn = isEnrolled ? circle.mirrorPayoutPeriodFor(slotPos) : circle.totalPeriods;
    final halfPayoutMinor = isEnrolled
        ? circle.userPayoutAmountForPeriod(earlyTurn)
        : (circle.slots.isNotEmpty ? circle.slots.first.payoutAmountMinor : 0);
    final totalPairs = circle.totalPeriods ~/ 2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt, color: AppColors.emeraldGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRtl ? 'نظام التوزيع المقترن (عضوان شهرياً • ٥٠٪ لكل منهما)' : '50/50 Symmetrical Paired Payout',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.emeraldGreen,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOdd ? (isRtl ? '٥٠٪ + أوسط ١٠٠٪' : '50% + Mid 100%') : (isRtl ? '٥٠٪ + ٥٠٪' : '50% + 50%'),
                  style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isUserInMid
                ? (isRtl
                    ? 'تستلم كامل استحقاقك بنسبة ١٠٠٪ في الشهر الأوسط (شهر $midMonth بقيمة ${(circle.totalPoolMinor / 100).toStringAsFixed(0)} ج.م) دفعة واحدة دون تقسيم.'
                    : 'You receive your full 100% payout in the middle month (Month $midMonth at EGP ${(circle.totalPoolMinor / 100).toStringAsFixed(0)}) in a single full disbursement.')
                : (isRtl
                    ? 'يتم تقسيم استحقاق الأعضاء المقترنين إلى دفعتين (٥٠٪ في الشهر $earlyTurn و٥٠٪ في الشهر $lateTurn بقيمة ${(halfPayoutMinor / 100).toStringAsFixed(0)} ج.م لكل دفعة)${isOdd ? '، بينما يستلم الشهر الأوسط (شهر $midMonth) كامل المبلغ ١٠٠٪.' : '.'}'
                    : 'Your payout is split into two equal halves (50% in Month $earlyTurn and 50% in Month $lateTurn at EGP ${(halfPayoutMinor / 100).toStringAsFixed(0)} each)${isOdd ? ', while the middle month (Month $midMonth) receives 100% full payout.' : '.'}'),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 10),

          // Visual Pair Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 1; i <= totalPairs; i++)
                  _buildPairChip(circle, i, slotPos, isRtl),
                if (isOdd)
                  _buildMiddleChip(circle, midMonth, slotPos, isRtl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleChip(GameyaCircle circle, int midMonth, int? userSlotPos, bool isRtl) {
    final isUserMid = userSlotPos == midMonth;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isUserMid
            ? AppColors.amberWarning.withValues(alpha: 0.2)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUserMid ? AppColors.amberWarning : AppColors.amberWarning.withValues(alpha: 0.3),
          width: isUserMid ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUserMid) ...[
            const Icon(Icons.person, size: 12, color: AppColors.amberWarning),
            const SizedBox(width: 4),
          ],
          Text(
            isRtl
                ? 'شهر #$midMonth (١٠٠٪ أوسط)'
                : 'Month #$midMonth (100% Mid)',
            style: TextStyle(
              color: isUserMid ? AppColors.amberWarning : AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: isUserMid ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairChip(GameyaCircle circle, int pairIndex, int? userSlotPos, bool isRtl) {
    final mirror = circle.totalPeriods - pairIndex + 1;
    final isUserPair = userSlotPos == pairIndex || userSlotPos == mirror;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isUserPair
            ? AppColors.emeraldGreen.withValues(alpha: 0.2)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUserPair ? AppColors.emeraldGreen : AppColors.borderSubtle,
          width: isUserPair ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUserPair) ...[
            const Icon(Icons.person, size: 12, color: AppColors.emeraldGreen),
            const SizedBox(width: 4),
          ],
          Text(
            isRtl
                ? 'دور #$pairIndex (٥٠٪) ↔ دور #$mirror (٥٠٪)'
                : 'Slot #$pairIndex (50%) ↔ Slot #$mirror (50%)',
            style: TextStyle(
              color: isUserPair ? AppColors.emeraldGreen : AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: isUserPair ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. INTERACTIVE ROTATION WHEEL SECTION
  // ===========================================================================
  Widget _buildRotationWheelSection(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    final slotPos = circle.currentUserSlotPosition;
    final semanticsLabel = slotPos != null
        ? 'Rotation wheel topology. Position $slotPos of ${circle.totalPeriods}. Current member position.'
        : 'Rotation wheel topology with ${circle.totalPeriods} positions.';

    return Semantics(
      label: semanticsLabel,
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              strings.rotationWheelTitle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            RotationWheelWidget(
              circle: circle,
              selectedSlot: _selectedSlot,
              onSlotTapped: (slot) {
                setState(() => _selectedSlot = slot);
                _showSlotDetailModal(context, circle, slot, isRtl);
              },
            ),
            const SizedBox(height: 8),
            Text(
              strings.wheelSubtitle,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. PRIMARY CONTEXTUAL ACTION BUTTON
  // ===========================================================================
  Widget _buildPrimaryActionButton(BuildContext context, GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    // 1. Financial Safety Lock Gate
    if (widget.isSafetyLockActive) {
      return PrimaryButton(
        label: isRtl ? 'قفل الأمان المالي نشط (المعاملات معطلة)' : 'Financial Safety Lock Active (Actions Restricted)',
        icon: Icons.lock_outline,
        onPressed: null, // Disabled fail-closed
      );
    }

    // 2. Unenrolled User Action
    if (!circle.isUserEnrolled) {
      return PrimaryButton(
        label: isRtl ? 'اختر دوراً شاغراً للانضمام إلى الجمعية' : 'Choose Open Slot & Join Circle',
        icon: Icons.add_circle_outline,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRtl
                    ? 'يرجى اختيار أحد الأدوار الشاغرة من قائمة الأعضاء أدناه.'
                    : 'Please select an available slot from the member roster below to join.',
              ),
              backgroundColor: AppColors.emeraldGreen,
            ),
          );
        },
      );
    }

    // 3. Enrolled User Claim Payout Action
    final isPayoutDueThisMonth = circle.isPayoutDueForUserInPeriod(circle.currentPeriod);
    final payoutDueAmount = circle.userPayoutAmountForPeriod(circle.currentPeriod);

    if (isPayoutDueThisMonth) {
      return PrimaryButton(
        label: isRtl
            ? 'استلم مبلغ القبض (${(payoutDueAmount / 100).toStringAsFixed(0)} ج.م) الآن'
            : 'Claim Your \$${_formatCurrency(payoutDueAmount)} Payout Now',
        icon: Icons.stars_rounded,
        onPressed: () => _showPayoutClaimSheet(context, circle, isRtl),
      );
    }

    // 4. Enrolled User Pay Monthly Due Action
    return PrimaryButton(
      label: strings.payMonthlyDue('EGP ${(circle.monthlyContributionMinor / 100).toStringAsFixed(0)}'),
      icon: Icons.payment,
      onPressed: () => _showContributionCheckoutSheet(context, circle, isRtl),
    );
  }

  // ===========================================================================
  // 6. SCOPED ORGANIZER MANAGEMENT PANEL
  // ===========================================================================
  Widget _buildOrganizerControlCard(BuildContext context, GameyaCircle circle, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, color: AppColors.amberWarning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRtl ? 'لوحة تحكم المنظم (خاصة بهذه الجمعية)' : 'Organizer Panel (Scoped to this Circle)',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.amberWarning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isRtl
                ? 'حالة الجاهزية: ${circle.claimedSlotsCount} من ${circle.totalPeriods} أدوار مكتملة • كود الدعوة: ${circle.inviteCode ?? "N/A"}'
                : 'Circle Readiness: ${circle.claimedSlotsCount}/${circle.totalPeriods} slots filled • Invite code: ${circle.inviteCode ?? "N/A"}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: isRtl ? 'إرسال تذكير' : 'Send Reminders',
                  icon: Icons.notifications_none,
                  isFullWidth: false,
                  onPressed: () async {
                    await widget.controller.sendOrganizerReminder(circleId: circle.id, slotNumber: 1);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isRtl ? 'تم إرسال تذكيرات السداد للأعضاء.' : 'Payment reminders sent to pending members.'),
                          backgroundColor: AppColors.emeraldGreen,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: isRtl ? 'دعوة أعضاء' : 'Invite Peers',
                  icon: Icons.person_add_alt,
                  isFullWidth: false,
                  onPressed: () => _showShareInviteModal(context, circle, isRtl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODALS & BOTTOM SHEETS
  // ===========================================================================

  void _showContributionCheckoutSheet(BuildContext context, GameyaCircle circle, bool isRtl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.deepSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.90,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: FinancialActionFlowView(
              controller: widget.controller,
              circleId: circle.id,
              actionType: FinancialActionType.contribution,
              isOffline: widget.isOffline,
              isSafetyLockActive: widget.isSafetyLockActive,
              isPermissionDenied: widget.isPermissionDenied,
              onFinish: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
      },
    );
  }

  void _showPayoutClaimSheet(BuildContext context, GameyaCircle circle, bool isRtl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.deepSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.90,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: FinancialActionFlowView(
              controller: widget.controller,
              circleId: circle.id,
              actionType: FinancialActionType.payout,
              isOffline: widget.isOffline,
              isSafetyLockActive: widget.isSafetyLockActive,
              isPermissionDenied: widget.isPermissionDenied,
              onFinish: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 8 & 9. ROSTER SECTION & PAIRED CARDS
  // ===========================================================================
  Widget _buildRosterSection(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    if (circle.allocationMode == GameyaAllocationMode.symmetricalPaired) {
      final totalPairs = circle.totalPeriods ~/ 2;
      final isOdd = circle.totalPeriods.isOdd;
      final midMonth = (circle.totalPeriods + 1) ~/ 2;

      return Column(
        children: [
          for (int i = 1; i <= totalPairs; i++) ...[
            _buildPairedSlotCard(circle, i, circle.totalPeriods - i + 1, i, strings, isRtl),
            const SizedBox(height: 12),
          ],
          if (isOdd) ...[
            _buildMiddleSlotCard(circle, midMonth, strings, isRtl),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (final slot in circle.slots) ...[
          PeerRosterTile(
            slot: slot,
            isPairedMode: false,
            isRtl: isRtl,
            onTap: () {
              setState(() => _selectedSlot = slot);
              _showSlotDetailModal(context, circle, slot, isRtl);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMiddleSlotCard(
    GameyaCircle circle,
    int midSlotNum,
    GameyaStrings strings,
    bool isRtl,
  ) {
    final midSlot = circle.slots.firstWhere(
      (s) => s.slotNumber == midSlotNum,
      orElse: () => GameyaSlot.open(
        slotNumber: midSlotNum,
        payoutAmountMinor: circle.totalPoolMinor,
        scheduledMonthName: 'Month $midSlotNum',
        pairedSlotNumber: null,
      ),
    );

    final isUserSlot = midSlot.isCurrentUser;

    return Container(
      decoration: BoxDecoration(
        color: isUserSlot
            ? AppColors.amberWarning.withValues(alpha: 0.08)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUserSlot
              ? AppColors.amberWarning.withValues(alpha: 0.6)
              : AppColors.amberWarning.withValues(alpha: 0.3),
          width: isUserSlot ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isUserSlot
                      ? AppColors.amberWarning.withValues(alpha: 0.25)
                      : AppColors.cardSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_outline_rounded,
                  size: 14,
                  color: AppColors.amberWarning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRtl
                      ? 'الدور الأوسط المستقل (شهر $midSlotNum)'
                      : 'Middle Month Single Turn (Month $midSlotNum)',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUserSlot ? AppColors.amberWarning : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amberWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isRtl ? 'عضو واحد • ١٠٠٪ كامل' : '1 Member • 100% Full',
                  style: const TextStyle(
                    color: AppColors.amberWarning,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Middle Slot Roster Tile
          PeerRosterTile(
            slot: midSlot,
            isPairedMode: false,
            isRtl: isRtl,
            onTap: () {
              setState(() => _selectedSlot = midSlot);
              _showSlotDetailModal(context, circle, midSlot, isRtl);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPairedSlotCard(
    GameyaCircle circle,
    int earlySlotNum,
    int lateSlotNum,
    int pairIndex,
    GameyaStrings strings,
    bool isRtl,
  ) {
    final earlySlot = circle.slots.firstWhere(
      (s) => s.slotNumber == earlySlotNum,
      orElse: () => GameyaSlot.open(
        slotNumber: earlySlotNum,
        payoutAmountMinor: circle.slots.isNotEmpty ? circle.slots.first.payoutAmountMinor : 0,
        scheduledMonthName: 'Month $earlySlotNum',
        pairedSlotNumber: lateSlotNum,
      ),
    );
    final lateSlot = circle.slots.firstWhere(
      (s) => s.slotNumber == lateSlotNum,
      orElse: () => GameyaSlot.open(
        slotNumber: lateSlotNum,
        payoutAmountMinor: circle.slots.isNotEmpty ? circle.slots.first.payoutAmountMinor : 0,
        scheduledMonthName: 'Month $lateSlotNum',
        pairedSlotNumber: earlySlotNum,
      ),
    );

    final isUserInPair = earlySlot.isCurrentUser || lateSlot.isCurrentUser;

    return Container(
      decoration: BoxDecoration(
        color: isUserInPair
            ? AppColors.emeraldGreen.withValues(alpha: 0.08)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUserInPair
              ? AppColors.emeraldGreen.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
          width: isUserInPair ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isUserInPair
                      ? AppColors.emeraldGreen.withValues(alpha: 0.2)
                      : AppColors.cardSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sync_alt,
                  size: 14,
                  color: isUserInPair ? AppColors.emeraldGreen : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRtl
                      ? 'الدور المقترن #$pairIndex (شهر $earlySlotNum ↔ شهر $lateSlotNum)'
                      : 'Paired Turn #$pairIndex (Month $earlySlotNum ↔ Month $lateSlotNum)',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUserInPair ? AppColors.emeraldGreen : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isRtl ? 'عضوان • ٥٠٪ لكل منهما' : '2 Members • 50% Each',
                  style: const TextStyle(
                    color: AppColors.emeraldGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Slot 1 (Early)
          PeerRosterTile(
            slot: earlySlot,
            isPairedMode: true,
            isRtl: isRtl,
            onTap: () {
              setState(() => _selectedSlot = earlySlot);
              _showSlotDetailModal(context, circle, earlySlot, isRtl);
            },
          ),

          // Connecting indicator between the 2 paired members
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_vert, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          isRtl ? 'تقاسم استحقاق شهري ٥٠٪ / ٥٠٪' : '50% / 50% Monthly Pool Split',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
              ],
            ),
          ),

          // Slot 2 (Late)
          PeerRosterTile(
            slot: lateSlot,
            isPairedMode: true,
            isRtl: isRtl,
            onTap: () {
              setState(() => _selectedSlot = lateSlot);
              _showSlotDetailModal(context, circle, lateSlot, isRtl);
            },
          ),
        ],
      ),
    );
  }

  void _showSlotDetailModal(BuildContext context, GameyaCircle circle, GameyaSlot slot, bool isRtl) {
    final isPaired = circle.allocationMode == GameyaAllocationMode.symmetricalPaired;
    final isMidSlot = isPaired && slot.pairedSlotNumber == null;
    final payout = slot.payoutAmountMinor / 100;
    final totalEntitlement = (isPaired && !isMidSlot) ? payout * 2 : payout;

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: AppColors.cardSurface,
            title: Text(
              isRtl ? 'تفاصيل المركز #${slot.slotNumber}' : 'Slot #${slot.slotNumber} Details',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModalRow(isRtl ? 'العضو المعين' : 'Assigned Member', slot.assignedMemberName ?? (isRtl ? 'دور شاغر' : 'Open Slot')),
                _buildModalRow(isRtl ? 'الشهر المجدول' : 'Scheduled Month', slot.scheduledMonthName),
                _buildModalRow(
                  isRtl ? 'مبلغ الدفعة' : 'Disbursement Amount',
                  isPaired
                      ? (isMidSlot ? 'EGP ${payout.toStringAsFixed(0)} (100% Mid)' : 'EGP ${payout.toStringAsFixed(0)} (50%)')
                      : 'EGP ${payout.toStringAsFixed(0)}',
                ),
                if (isPaired) ...[
                  _buildModalRow(
                    isRtl ? 'إجمالي الاستحقاق' : 'Total Entitlement',
                    'EGP ${totalEntitlement.toStringAsFixed(0)} (100%)',
                  ),
                  if (slot.pairedSlotNumber != null)
                    _buildModalRow(
                      isRtl ? 'المركز المقترن' : 'Paired Position',
                      isRtl
                          ? '#${slot.pairedSlotNumber} (شهر ${slot.pairedSlotNumber} - ٥٠٪)'
                          : '#${slot.pairedSlotNumber} (Month ${slot.pairedSlotNumber} - 50%)',
                    ),
                ],
                _buildModalRow(isRtl ? 'حالة السداد' : 'Payment Status', slot.paymentStatus.label),
              ],
            ),
            actions: [
              if (!slot.isClaimed && !circle.isUserEnrolled)
                PrimaryButton(
                  label: isRtl ? 'حجز هذا الدور' : 'Claim This Slot',
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await widget.controller.joinCircleWithSlot(circleId: circle.id, slotNumber: slot.slotNumber);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isRtl ? 'تم الانضمام إلى الجمعية في المركز #${slot.slotNumber} بنجاح!' : 'Joined circle in slot #${slot.slotNumber} successfully!'),
                          backgroundColor: AppColors.emeraldGreen,
                        ),
                      );
                    }
                  },
                ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(isRtl ? 'إغلاق' : 'Close', style: const TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCircleBylawsModal(BuildContext context, GameyaCircle circle, bool isRtl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: AppColors.cardSurface,
            title: Text(
              isRtl ? 'لائحة وقواعد الجمعية' : 'Game\'ya Bylaws & Rules',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: circle.rulesSummary.map((rule) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.emeraldGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rule, style: AppTypography.bodySmall)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(isRtl ? 'فهمت' : 'Understood', style: const TextStyle(color: AppColors.emeraldGreen)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShareInviteModal(BuildContext context, GameyaCircle circle, bool isRtl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: AppColors.cardSurface,
            title: Text(
              isRtl ? 'مشاركة كود الدعوة' : 'Share Circle Invite',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRtl ? 'كود الدعوة الخاص:' : 'Private Invite Code:',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  circle.inviteCode ?? 'FAM-882',
                  style: AppTypography.financialDisplay.copyWith(
                    color: AppColors.emeraldGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            actions: [
              SecondaryButton(
                label: isRtl ? 'نسخ الكود' : 'Copy Code',
                icon: Icons.copy,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRtl ? 'تم نسخ كود الدعوة إلى الحافظة!' : 'Invite code copied to clipboard!'),
                      backgroundColor: AppColors.emeraldGreen,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SYSTEM STATE SCAFFOLDS & BANNERS
  // ===========================================================================

  Widget _buildEmptyScaffold(BuildContext context, GameyaStrings strings, bool isRtl) {
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.deepSlate,
        appBar: AppBar(
          backgroundColor: AppColors.deepSlate,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  isRtl ? 'الجمعية غير موجودة' : 'Game\'ya Circle Not Found',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isRtl ? 'تعذر العثور على بيانات هذه الجمعية. قد تكون اكتملت أو ألغيت.' : 'The requested savings circle could not be retrieved.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSlate,
      appBar: AppBar(
        backgroundColor: AppColors.deepSlate,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 64, color: AppColors.crimsonRed),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.crimsonRed),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have authorization to view this private circle room.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyLockBanner(bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.crimsonRed.withValues(alpha: 0.15),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.crimsonRed.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.crimsonRed, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isRtl
                  ? 'قفل الأمان المالي نشط: تم إيقاف المدفوعات وصرف القبض بقرار حوكمي.'
                  : 'Financial Safety Lock Active: Contributions and payouts are paused by governance policy.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.crimsonRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.15),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.amberWarning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isRtl
                  ? 'أنت غير متصل بالإنترنت. أعد الاتصال لتحديث بيانات الجمعية.'
                  : 'You\'re offline. Reconnect to refresh this Game\'ya.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
