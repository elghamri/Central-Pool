import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';
import '../state/gameya_controller.dart';
import '../i18n/gameya_strings.dart';

/// Enum representing the step within the Financial Action Flow.
enum FinancialFlowStep {
  // Contribution Flow (Screens A-D)
  contributionOverview,
  contributionReview,
  contributionAction,
  contributionResult,

  // Payout Flow (Screens E-G)
  payoutOverview,
  payoutReview,
  payoutResult,
}

/// Enum indicating whether we are executing a Contribution or a Payout flow.
enum FinancialActionType {
  contribution,
  payout,
}

/// Phase 47.2.5: Graphic-First, Trustworthy Financial Action Experience.
/// Coordinates Contribution (Screens A-D) and Payout (Screens E-G) flows
/// adhering strictly to Stitch Design Authority (13353050789076646822).
class FinancialActionFlowView extends StatefulWidget {
  final GameyaController controller;
  final String circleId;
  final FinancialActionType actionType;
  final VoidCallback onFinish;
  final bool isOffline;
  final bool isSafetyLockActive;
  final bool isPermissionDenied;

  const FinancialActionFlowView({
    super.key,
    required this.controller,
    required this.circleId,
    required this.actionType,
    required this.onFinish,
    this.isOffline = false,
    this.isSafetyLockActive = false,
    this.isPermissionDenied = false,
  });

  @override
  State<FinancialActionFlowView> createState() => _FinancialActionFlowViewState();
}

class _FinancialActionFlowViewState extends State<FinancialActionFlowView> {
  late FinancialFlowStep _currentStep;
  String? _selectedPaymentMethod = 'bank_8812';
  bool _isProcessing = false;
  String? _errorMessage;
  String? _generatedReceiptId;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.actionType == FinancialActionType.contribution
        ? FinancialFlowStep.contributionOverview
        : FinancialFlowStep.payoutOverview;
  }

  String _formatCurrency(int amountMinor) {
    final int major = amountMinor ~/ 100;
    return major.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Permission Denied System State
    if (widget.isPermissionDenied) {
      return _buildPermissionDeniedScaffold();
    }

    return ValueListenableBuilder<GameyaState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        // 2. Loading State
        if (state is GameyaLoading) {
          return const Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: Center(
              child: AppLoadingIndicator(
                message: 'Loading financial details...',
              ),
            ),
          );
        }

        if (state is! GameyaLoaded) {
          return const Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: Center(
              child: AppLoadingIndicator(message: 'Initializing...'),
            ),
          );
        }

        // Find the target circle from loaded hub or marketplace
        final allCircles = [
          ...state.hubSummary.activeCircles,
          ...state.marketplaceCircles,
        ];
        final matching = allCircles.where((c) => c.id == widget.circleId);
        if (matching.isEmpty) {
          return _buildEmptyScaffold();
        }
        final circle = matching.first;

        final languageCode = state.languageCode;
        final strings = GameyaStrings.of(languageCode);
        final isRtl = strings.isRtl;

        return Directionality(
          textDirection: strings.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.deepSlate,
            appBar: _buildAppBar(circle, strings, isRtl),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Universal Financial Safety Lock Banner
                        if (widget.isSafetyLockActive) ...[
                          _buildSafetyLockBanner(strings, isRtl),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Universal Offline Notice Banner
                        if (widget.isOffline) ...[
                          _buildOfflineBanner(strings, isRtl),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Error Banner
                        if (_errorMessage != null) ...[
                          AlertBanner(
                            title: isRtl ? 'تنبيه' : 'Notice',
                            message: _errorMessage!,
                            color: AppColors.crimsonRed,
                            icon: Icons.error_outline,
                            onDismiss: () => setState(() => _errorMessage = null),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Active Flow Step Switcher
                        _buildStepContent(circle, strings, isRtl),

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
        onPressed: () {
          if (_currentStep == FinancialFlowStep.contributionOverview ||
              _currentStep == FinancialFlowStep.payoutOverview ||
              _currentStep == FinancialFlowStep.contributionResult ||
              _currentStep == FinancialFlowStep.payoutResult) {
            widget.onFinish();
          } else {
            setState(() {
              if (_currentStep == FinancialFlowStep.contributionReview) {
                _currentStep = FinancialFlowStep.contributionOverview;
              } else if (_currentStep == FinancialFlowStep.contributionAction) {
                _currentStep = FinancialFlowStep.contributionReview;
              } else if (_currentStep == FinancialFlowStep.payoutReview) {
                _currentStep = FinancialFlowStep.payoutOverview;
              }
            });
          }
        },
      ),
      title: Text(
        widget.actionType == FinancialActionType.contribution
            ? (isRtl ? 'المساهمة الشهرية' : 'Monthly Contribution')
            : (isRtl ? 'صرف الاستحقاق' : 'Payout Disbursement'),
        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: [
        // Step indicator Pill
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              _getStepIndicatorText(isRtl),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getStepIndicatorText(bool isRtl) {
    switch (_currentStep) {
      case FinancialFlowStep.contributionOverview:
        return isRtl ? '١ من ٤: نظرة عامة' : 'Step 1 of 4: Overview';
      case FinancialFlowStep.contributionReview:
        return isRtl ? '٢ من ٤: مراجعة' : 'Step 2 of 4: Review';
      case FinancialFlowStep.contributionAction:
        return isRtl ? '٣ من ٤: تأكيد' : 'Step 3 of 4: Action';
      case FinancialFlowStep.contributionResult:
        return isRtl ? '٤ من ٤: إيصال' : 'Step 4 of 4: Result';
      case FinancialFlowStep.payoutOverview:
        return isRtl ? '١ من ٣: نظرة عامة' : 'Step 1 of 3: Overview';
      case FinancialFlowStep.payoutReview:
        return isRtl ? '٢ من ٣: مراجعة' : 'Step 2 of 3: Review';
      case FinancialFlowStep.payoutResult:
        return isRtl ? '٣ من ٣: تأكيد' : 'Step 3 of 3: Result';
    }
  }

  // ===========================================================================
  // STEP CONTENT ROUTING
  // ===========================================================================
  Widget _buildStepContent(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    switch (_currentStep) {
      // Contribution Flow
      case FinancialFlowStep.contributionOverview:
        return _buildContributionOverview(circle, strings, isRtl);
      case FinancialFlowStep.contributionReview:
        return _buildContributionReview(circle, strings, isRtl);
      case FinancialFlowStep.contributionAction:
        return _buildContributionAction(circle, strings, isRtl);
      case FinancialFlowStep.contributionResult:
        return _buildContributionResult(circle, strings, isRtl);

      // Payout Flow
      case FinancialFlowStep.payoutOverview:
        return _buildPayoutOverview(circle, strings, isRtl);
      case FinancialFlowStep.payoutReview:
        return _buildPayoutReview(circle, strings, isRtl);
      case FinancialFlowStep.payoutResult:
        return _buildPayoutResult(circle, strings, isRtl);
    }
  }

  // ===========================================================================
  // SCREEN A: CONTRIBUTION OVERVIEW (ffd2c3c221e9412a85eff1f4a37ffb29)
  // ===========================================================================
  Widget _buildContributionOverview(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    final slotPos = circle.currentUserSlotPosition ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Demo Mode Tag
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.skyInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.science_outlined, color: AppColors.skyInfo, size: 14),
                const SizedBox(width: 6),
                Text(
                  'REAL_MONEY_ENABLED = false (SIMULATION)',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.skyInfo,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Hero Due Payment Card (Obsidian Glassmorphism with Emerald Glow)
        SurfaceCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isRtl ? 'القسط الشهري المستحق' : 'Next Due Payment',
                    style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  StatusBadge(
                    label: isRtl ? 'مستحق الآن' : 'DUE',
                    type: StatusBadgeType.warning,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'EGP ${_formatCurrency(circle.monthlyContributionMinor)}',
                style: AppTypography.financialDisplay.copyWith(
                  fontSize: 36,
                  color: AppColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${isRtl ? "الشهر" : "Month"} ${circle.currentPeriod} ${isRtl ? "من" : "of"} ${circle.totalPeriods} • ${circle.name}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Primary CTA
              PrimaryButton(
                label: strings.reviewContribution,
                icon: Icons.arrow_forward,
                onPressed: widget.isSafetyLockActive
                    ? null
                    : () => setState(() => _currentStep = FinancialFlowStep.contributionReview),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Circle Progress Section
        Text(
          isRtl ? 'تقدم الجمعية' : 'Circle Progress',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isRtl ? 'الأشهر المنقضية' : 'Months Completed',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    '${circle.currentPeriod} / ${circle.totalPeriods}',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: AppRadii.borderSm,
                child: LinearProgressIndicator(
                  value: circle.progressFraction,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isRtl
                    ? 'موقعك في الجمعية: الدور #$slotPos من ${circle.totalPeriods}'
                    : 'Your position in this circle: Slot #$slotPos of ${circle.totalPeriods}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SCREEN B: CONTRIBUTION REVIEW (c4920d8e2d9948fdacf802df3e3fbea8)
  // ===========================================================================
  Widget _buildContributionReview(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    final slotPos = circle.currentUserSlotPosition ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Security Icon Header
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.security, color: AppColors.emeraldGreen, size: 32),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            isRtl ? 'مراجعة تفاصيل المساهمة' : 'Review Contribution',
            style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            isRtl ? 'يرجى التحقق من تفاصيل المعاملة قبل المتابعة' : 'Please verify transaction details before proceeding',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Review Details Card
        SurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.confirmContribution,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderSubtle),
              const SizedBox(height: 12),

              _buildDetailRow(isRtl ? 'المبلغ المستحق' : 'Amount Due', 'EGP ${_formatCurrency(circle.monthlyContributionMinor)}', isHighlight: true),
              _buildDetailRow(isRtl ? 'اسم الجمعية' : 'Target Circle', circle.name),
              _buildDetailRow(isRtl ? 'شهر الاستحقاق' : 'Contribution Month', '${isRtl ? "الشهر" : "Month"} ${circle.currentPeriod} ${isRtl ? "من" : "of"} ${circle.totalPeriods}'),
              _buildDetailRow(isRtl ? 'موقع العضو' : 'Member Position', '${isRtl ? "الدور #" : "Slot #"}$slotPos'),
              _buildDetailRow(isRtl ? 'رسوم المعاملة' : 'Transaction Fee', 'EGP 0.00'),

              const SizedBox(height: 16),
              // Safety Invariant Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadii.borderSm,
                  border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.amberWarning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.financialTransactionsDisabledNotice,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Primary Action
        PrimaryButton(
          label: strings.continueAction,
          icon: Icons.arrow_forward,
          onPressed: widget.isSafetyLockActive
              ? null
              : () => setState(() => _currentStep = FinancialFlowStep.contributionAction),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: strings.cancelAction,
          isFullWidth: true,
          onPressed: () => setState(() => _currentStep = FinancialFlowStep.contributionOverview),
        ),
      ],
    );
  }

  // ===========================================================================
  // SCREEN C: CONTRIBUTION ACTION (Payment Method Selection & Fail-Closed Gate)
  // ===========================================================================
  Widget _buildContributionAction(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isRtl ? 'طريقة السداد المعتمدة' : 'Select Clearing Rail',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          isRtl ? 'اختر حساب الخصم أو المحفظة الإلكترونية' : 'Select verified debit account or digital wallet',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        // Option 1: Registered Bank Account
        _buildPaymentOptionTile(
          id: 'bank_8812',
          title: isRtl ? 'حساب بنكي مسجل (**** ٨٨١٢)' : 'Registered Bank Account (**** 8812)',
          subtitle: isRtl ? 'خصم مباشر • البنك الأهلي المصري' : 'Direct Debit • National Bank of Egypt',
          icon: Icons.account_balance,
          isSelected: _selectedPaymentMethod == 'bank_8812',
        ),
        const SizedBox(height: AppSpacing.sm),

        // Option 2: Meeza / Fawry Pay
        _buildPaymentOptionTile(
          id: 'meeza_pay',
          title: isRtl ? 'كارت ميزة / فوري باي' : 'Meeza National Card / Fawry Pay',
          subtitle: isRtl ? 'دفع إلكتروني فوري' : 'Instant Clearing Network',
          icon: Icons.credit_card,
          isSelected: _selectedPaymentMethod == 'meeza_pay',
        ),
        const SizedBox(height: AppSpacing.lg),

        // Fail-Closed Safety Notice Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.skyInfo.withValues(alpha: 0.08),
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: AppColors.skyInfo.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.skyInfo, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'بيئة تجريبية آمنة' : 'Safe Financial Simulation',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.skyInfo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isRtl
                          ? 'نظراً لأن REAL_MONEY_ENABLED=false، لن يتم خصم أي أموال حقيقية من حسابك.'
                          : 'Because REAL_MONEY_ENABLED=false, no real money will be charged from your account.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Submit Action Button
        PrimaryButton(
          label: _isProcessing
              ? (isRtl ? 'جاري المعالجة...' : 'Processing...')
              : (isRtl
                  ? 'تأكيد السداد التجريبي (${(circle.monthlyContributionMinor / 100).toStringAsFixed(0)} ج.م)'
                  : 'Confirm Simulation Payment (EGP ${_formatCurrency(circle.monthlyContributionMinor)})'),
          icon: Icons.check_circle_outline,
          isLoading: _isProcessing,
          onPressed: widget.isSafetyLockActive || _isProcessing
              ? null
              : () async {
                  setState(() => _isProcessing = true);
                  final success = await widget.controller.submitContributionPayment(
                    circleId: circle.id,
                    amountMinor: circle.monthlyContributionMinor,
                    isSafetyLockActive: widget.isSafetyLockActive,
                  );
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                      if (success) {
                        _generatedReceiptId = 'SIM-REC-${DateTime.now().millisecondsSinceEpoch}';
                        _currentStep = FinancialFlowStep.contributionResult;
                      } else {
                        _errorMessage = isRtl
                            ? 'تعذر إتمام المعاملة، يرجى المحاولة مرة أخرى.'
                            : 'Failed to process transaction. Please retry.';
                      }
                    });
                  }
                },
        ),
      ],
    );
  }

  // ===========================================================================
  // SCREEN D: CONTRIBUTION RESULT & RECEIPT
  // ===========================================================================
  Widget _buildContributionResult(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Circle Icon
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emeraldGreen, width: 2),
            ),
            child: const Icon(Icons.check, color: AppColors.emeraldGreen, size: 40),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            isRtl ? 'تم سداد القسط بنجاح!' : 'Contribution Settled!',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.emeraldGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            isRtl ? 'تم تحديث سجل الجمعية وإصدار إيصال السداد' : 'Circle roster updated & receipt generated',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Receipt Card
        SurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isRtl ? 'إيصال سداد إلكتروني (محاكاة)' : 'Electronic Receipt (Simulated)',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusBadge(label: 'SETTLED', type: StatusBadgeType.success),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderSubtle),
              const SizedBox(height: 10),

              _buildDetailRow(isRtl ? 'رقم الإيصال' : 'Receipt ID', _generatedReceiptId ?? 'SIM-REC-001'),
              _buildDetailRow(isRtl ? 'المبلغ المسدد' : 'Amount Paid', 'EGP ${_formatCurrency(circle.monthlyContributionMinor)}', isHighlight: true),
              _buildDetailRow(isRtl ? 'الجمعية' : 'Circle Name', circle.name),
              _buildDetailRow(isRtl ? 'الدورة' : 'Period', '${isRtl ? "الشهر" : "Month"} ${circle.currentPeriod}'),
              _buildDetailRow(isRtl ? 'التاريخ والوقت' : 'Timestamp', DateTime.now().toLocal().toString().split('.')[0]),

              const SizedBox(height: 12),
              Text(
                isRtl
                    ? 'ملاحظة: هذا إيصال محاكاة داخلي تم إنشاؤه لأغراض الاختبار.'
                    : 'Notice: This is an internal simulated receipt generated for validation.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        PrimaryButton(
          label: strings.returnToCircle,
          icon: Icons.check,
          onPressed: widget.onFinish,
        ),
      ],
    );
  }

  // ===========================================================================
  // SCREEN E: PAYOUT OVERVIEW (50/50 Graphic-First Presentation)
  // ===========================================================================
  Widget _buildPayoutOverview(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    final isPaired = circle.allocationMode == GameyaAllocationMode.symmetricalPaired;
    final slotPos = circle.currentUserSlotPosition ?? 1;
    final matchingSlots = circle.slots.where((s) => s.slotNumber == slotPos);
    final assignedSlot = matchingSlots.isNotEmpty
        ? matchingSlots.first
        : GameyaSlot(
            slotNumber: slotPos,
            payoutAmountMinor: 0,
            scheduledMonthName: 'Month $slotPos',
          );
    final pairedSlotPos = assignedSlot.pairedSlotNumber;

    final int halfPayoutMinor = assignedSlot.payoutAmountMinor;
    final int displayPayoutMinor = assignedSlot.payoutAmountMinor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payout Hero Card
        SurfaceCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isPaired
                          ? (isRtl ? 'مستحقات القبض المقترن (٥٠٪)' : '50% Paired Payout Due')
                          : (isRtl ? 'مستحقات القبض الكاملة' : 'Total Full Payout Due'),
                      style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusBadge(label: 'READY TO CLAIM', type: StatusBadgeType.success),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'EGP ${_formatCurrency(displayPayoutMinor)}',
                style: AppTypography.financialDisplay.copyWith(
                  fontSize: 36,
                  color: AppColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${circle.name} • ${isRtl ? "شهر الاستحقاق" : "Disbursement Month"} ${circle.currentPeriod}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: strings.reviewPayout,
                icon: Icons.stars_rounded,
                onPressed: widget.isSafetyLockActive
                    ? null
                    : () => setState(() => _currentStep = FinancialFlowStep.payoutReview),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Symmetrical 50/50 Graphic Explanation Card
        if (isPaired) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync_alt, color: AppColors.emeraldGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isRtl ? 'نظام التوزيع المقترن (٥٠/٥٠)' : '50/50 Symmetrical Paired Structure',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Graphic Pairing Diagram
                Row(
                  children: [
                    // Turn 1 (Early)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: AppRadii.borderSm,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isRtl ? 'الدفعة المبكرة (٥٠٪)' : 'Early Payout (50%)',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'EGP ${_formatCurrency(halfPayoutMinor)}',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                            ),
                            Text(
                              '${isRtl ? "الشهر" : "Month"} $slotPos',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.link, color: AppColors.emeraldGreen),
                    ),
                    // Turn 2 (Later)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: AppRadii.borderSm,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isRtl ? 'الدفعة المقابلة (٥٠٪)' : 'Paired Payout (50%)',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'EGP ${_formatCurrency(halfPayoutMinor)}',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${isRtl ? "الشهر" : "Month"} ${pairedSlotPos ?? (circle.totalPeriods - slotPos + 1)}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  strings.pairedPayoutExplanation,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // SCREEN F: PAYOUT REVIEW & DESTINATION SELECTION
  // ===========================================================================
  Widget _buildPayoutReview(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    final isPaired = circle.allocationMode == GameyaAllocationMode.symmetricalPaired;
    final slotPos = circle.currentUserSlotPosition ?? 1;
    final matchingSlots = circle.slots.where((s) => s.slotNumber == slotPos);
    final assignedSlot = matchingSlots.isNotEmpty
        ? matchingSlots.first
        : GameyaSlot(
            slotNumber: slotPos,
            payoutAmountMinor: 0,
            scheduledMonthName: 'Month $slotPos',
          );
    final int displayPayoutMinor = assignedSlot.payoutAmountMinor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isRtl ? 'مراجعة بيانات صرف القبض' : 'Review Disbursement Details',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          isRtl ? 'حدد الحساب المصرفي المعتمد لتحويل المستحقات' : 'Select verified settlement account for disbursement',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        // Payout Amount Card
        SurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(isRtl ? 'مبلغ الصرف المستحق' : 'Disbursement Due', 'EGP ${_formatCurrency(displayPayoutMinor)}', isHighlight: true),
              _buildDetailRow(isRtl ? 'الجمعية' : 'Circle Name', circle.name),
              _buildDetailRow(isRtl ? 'شهر الصرف' : 'Disbursement Month', '${isRtl ? "الشهر" : "Month"} ${circle.currentPeriod}'),
              _buildDetailRow(isRtl ? 'نوع التوزيع' : 'Allocation Mode', isPaired ? (isRtl ? 'مقترن ٥٠/٥٠' : '50/50 Paired') : (isRtl ? 'تسلسلي' : 'Sequential')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Destination Account
        Text(
          isRtl ? 'حساب استلام المستحقات' : 'DESTINATION ACCOUNT',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionTile(
          id: 'bank_8812',
          title: isRtl ? 'حساب بنكي مسجل (**** ٨٨١٢)' : 'Chase Premier Checking (**** 8812)',
          subtitle: isRtl ? 'تحويل بنكي فوري • الرسوم: ٠.٠٠ ج.م' : 'Direct Clearing Rails • Fee: EGP 0.00',
          icon: Icons.account_balance,
          isSelected: true,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Safety Invariant
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.borderSm,
            border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.amberWarning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.financialTransactionsDisabledNotice,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Submit Action
        PrimaryButton(
          label: _isProcessing
              ? (isRtl ? 'جاري المعالجة...' : 'Processing...')
              : strings.claimPayout,
          icon: Icons.stars_rounded,
          isLoading: _isProcessing,
          onPressed: widget.isSafetyLockActive || _isProcessing
              ? null
              : () async {
                  setState(() => _isProcessing = true);
                  final success = await widget.controller.claimPayoutDisbursement(
                    circleId: circle.id,
                    amountMinor: displayPayoutMinor,
                    destinationAccount: '**** 8812',
                    isSafetyLockActive: widget.isSafetyLockActive,
                  );
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                      if (success) {
                        _generatedReceiptId = 'SIM-PAY-${DateTime.now().millisecondsSinceEpoch}';
                        _currentStep = FinancialFlowStep.payoutResult;
                      } else {
                        _errorMessage = isRtl
                            ? 'تعذر صرف المستحقات، يرجى المحاولة مرة أخرى.'
                            : 'Failed to claim disbursement. Please retry.';
                      }
                    });
                  }
                },
        ),
      ],
    );
  }

  // ===========================================================================
  // SCREEN G: PAYOUT RESULT & CLAIM CONFIRMATION
  // ===========================================================================
  Widget _buildPayoutResult(GameyaCircle circle, GameyaStrings strings, bool isRtl) {
    final slotPos = circle.currentUserSlotPosition ?? 1;
    final matchingSlots = circle.slots.where((s) => s.slotNumber == slotPos);
    final assignedSlot = matchingSlots.isNotEmpty
        ? matchingSlots.first
        : GameyaSlot(
            slotNumber: slotPos,
            payoutAmountMinor: 0,
            scheduledMonthName: 'Month $slotPos',
          );
    final int displayPayoutMinor = assignedSlot.payoutAmountMinor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emeraldGreen, width: 2),
            ),
            child: const Icon(Icons.stars_rounded, color: AppColors.emeraldGreen, size: 40),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            isRtl ? 'تم استلام طلب صرف القبض!' : 'Payout Claim Processed!',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.emeraldGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            isRtl ? 'تم تسجيل المعاملة في سجل النشاط المالي' : 'Disbursement recorded in simulation activity log',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        SurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isRtl ? 'بيانات الصرف المعتمدة (محاكاة)' : 'Disbursement Voucher (Simulated)',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusBadge(label: 'CLAIMED', type: StatusBadgeType.success),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderSubtle),
              const SizedBox(height: 10),

              _buildDetailRow(isRtl ? 'رقم الإشعار' : 'Disbursement ID', _generatedReceiptId ?? 'SIM-PAY-001'),
              _buildDetailRow(isRtl ? 'مبلغ الصرف' : 'Disbursed Amount', 'EGP ${_formatCurrency(displayPayoutMinor)}', isHighlight: true),
              _buildDetailRow(isRtl ? 'الحساب المحول إليه' : 'Destination Account', 'Chase Premier Checking (**** 8812)'),
              _buildDetailRow(isRtl ? 'الجمعية' : 'Circle Name', circle.name),
              _buildDetailRow(isRtl ? 'التاريخ والوقت' : 'Timestamp', DateTime.now().toLocal().toString().split('.')[0]),

              const SizedBox(height: 12),
              Text(
                isRtl
                    ? 'ملاحظة: هذا إشعار صرف تجريبي داخلي تم إنشاؤه لأغراض الاختبار.'
                    : 'Notice: This is a simulated disbursement confirmation voucher.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        PrimaryButton(
          label: strings.returnToCircle,
          icon: Icons.check,
          onPressed: widget.onFinish,
        ),
      ],
    );
  }

  // ===========================================================================
  // WIDGET HELPERS
  // ===========================================================================

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: isHighlight ? AppColors.emeraldGreen : AppColors.textPrimary,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      borderRadius: AppRadii.borderMd,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : AppColors.cardSurface,
          borderRadius: AppRadii.borderMd,
          border: Border.all(
            color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.emeraldGreen : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SYSTEM STATE SCAFFOLDS & BANNERS
  // ===========================================================================

  Widget _buildSafetyLockBanner(GameyaStrings strings, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.crimsonRed.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.crimsonRed.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.crimsonRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.financialSafetyLockNotice,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.crimsonRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(GameyaStrings strings, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.amberWarning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.offlineNotice,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.amberWarning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScaffold() {
    return Scaffold(
      backgroundColor: AppColors.deepSlate,
      appBar: AppBar(
        backgroundColor: AppColors.deepSlate,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: widget.onFinish,
        ),
        title: const Text('Financial Action'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Financial Record Not Found',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested circle or contribution obligation could not be resolved.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Return',
                onPressed: widget.onFinish,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScaffold() {
    return Scaffold(
      backgroundColor: AppColors.deepSlate,
      appBar: AppBar(
        backgroundColor: AppColors.deepSlate,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: widget.onFinish,
        ),
        title: const Text('Access Restricted'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad_outlined, size: 64, color: AppColors.crimsonRed),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.crimsonRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have authorization to perform financial actions for this circle.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Return to Safety',
                onPressed: widget.onFinish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
