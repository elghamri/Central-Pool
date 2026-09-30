import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';
import '../state/gameya_controller.dart';
import '../i18n/gameya_strings.dart';

/// Full-Screen Experience: Stitch-Approved 5-Step Consumer Game'ya Creation Wizard.
///
/// Implements the authoritative visual flows from Stitch Project 13353050789076646822:
/// - Step 1: Contribution Amount (Slider, presets, live pool calculation) [Artboard: 09e1d41cc14747bbaeb570e3daf2e558]
/// - Step 2: Member Topology & Duration (Stepper, radial circle preview) [Artboard: 9901d326efd54649a9ee13c3ddba6f54]
/// - Step 3: Payout Structure & Allocation Mode (Sequential vs Symmetrical Paired) [Artboard: 980d463d35b546ce97c946975eb7889e]
/// - Step 4: Purpose & Community Identity (Category cards, name, privacy) [Artboard: cfbf319b51184d47ba27f92db53cc8eb]
/// - Step 5: Review & Bylaws Agreement [Artboard: a6a39fb717b74b55a440e9459e206c32]
/// - Success & Share View [Artboard: b9e43189c6284963b4e599ab1dc5bf39]
class CreateGameyaWizardView extends StatefulWidget {
  final GameyaController controller;
  final ValueChanged<String>? onCircleCreated;
  final VoidCallback? onCancel;
  final bool isOffline;
  final bool isSafetyLockActive;
  final bool? isRtl;

  const CreateGameyaWizardView({
    super.key,
    required this.controller,
    this.onCircleCreated,
    this.onCancel,
    this.isOffline = false,
    this.isSafetyLockActive = false,
    this.isRtl,
  });

  @override
  State<CreateGameyaWizardView> createState() => _CreateGameyaWizardViewState();
}

class _CreateGameyaWizardViewState extends State<CreateGameyaWizardView> {
  int _currentStep = 0; // 0 to 4 (Wizard sections)

  // Step 1: Contribution State
  int _monthlyContributionMinor = 200000; // 2,000 EGP (200,000 minor units)

  // Step 2: Member Count & Duration State
  int _memberCount = 10; // 4, 6, 8, 10, 12

  // Step 3: Allocation Mode & Turn State
  GameyaAllocationMode _allocationMode = GameyaAllocationMode.sequential;
  int _creatorSlotNumber = 1;

  // Step 4: Community Identity & Privacy State
  final TextEditingController _nameController = TextEditingController(text: 'Mansour Family Savings 2027');
  String _selectedCategory = 'Family';
  bool _isPrivate = false;

  // Step 5: Bylaws Consent & Submission State
  bool _agreedToBylaws = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Final Output Entity
  GameyaCircle? _createdCircle;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _resolvedRtl {
    if (widget.isRtl != null) return widget.isRtl!;
    final state = widget.controller.value;
    if (state is GameyaLoaded) {
      return state.isRtl;
    }
    return false;
  }

  int get _totalPoolMinor => _monthlyContributionMinor * _memberCount;

  @override
  Widget build(BuildContext context) {
    final isRtl = _resolvedRtl;
    final strings = GameyaStrings.of(isRtl ? 'ar' : 'en');

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.deepSlate,
        appBar: AppBar(
          backgroundColor: AppColors.deepSlate,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _currentStep > 0 ? Icons.arrow_back : Icons.close,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              if (_currentStep > 0 && _createdCircle == null) {
                setState(() {
                  _currentStep--;
                  _errorMessage = null;
                });
              } else {
                if (widget.onCancel != null) {
                  widget.onCancel!();
                } else {
                  Navigator.of(context).maybePop();
                }
              }
            },
          ),
          title: Text(
            _createdCircle != null
                ? (isRtl ? 'تم إنشاء الجمعية بنجاح!' : 'Game\'ya Created!')
                : (isRtl ? 'إنشاء جمعية جديدة' : 'Create Gameya'),
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_createdCircle == null)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: AppRadii.borderSm,
                    border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isRtl ? 'خطوة ${_currentStep + 1} من 5' : 'Step ${_currentStep + 1} of 5',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: _createdCircle != null
              ? _buildSuccessAndShareView(isRtl, strings)
              : _buildWizardFlow(isRtl, strings),
        ),
      ),
    );
  }

  Widget _buildWizardFlow(bool isRtl, GameyaStrings strings) {
    return Column(
      children: [
        // 1. Top Glowing Step Progress Bar
        Container(
          width: double.infinity,
          height: 3.0,
          color: AppColors.surfaceElevated,
          child: FractionallySizedBox(
            alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
            widthFactor: (_currentStep + 1) / 5.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.6),
                    blurRadius: 6.0,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Active Screen Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Safety Lock Alert
                if (widget.isSafetyLockActive) ...[
                  _buildSafetyLockBanner(isRtl),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Offline Notice Banner
                if (widget.isOffline) ...[
                  _buildOfflineBanner(isRtl),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Error Banner
                if (_errorMessage != null) ...[
                  AlertBanner(
                    title: isRtl ? 'خطأ في الإدخال' : 'Validation Error',
                    message: _errorMessage!,
                    color: AppColors.crimsonRed,
                    icon: Icons.error_outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Step Content Switcher
                if (_currentStep == 0) _buildStep1Contribution(isRtl, strings),
                if (_currentStep == 1) _buildStep2ScheduleAndTopology(isRtl, strings),
                if (_currentStep == 2) _buildStep3AllocationMode(isRtl, strings),
                if (_currentStep == 3) _buildStep4CommunityIdentity(isRtl, strings),
                if (_currentStep == 4) _buildStep5ReviewAndBylaws(isRtl, strings),

                const SizedBox(height: 32.0),
              ],
            ),
          ),
        ),

        // 3. Bottom Sticky Action Zone
        _buildBottomActionBar(isRtl, strings),
      ],
    );
  }

  // ===========================================================================
  // STEP 1: CONTRIBUTION AMOUNT (Stitch Artboard: 09e1d41cc14747bbaeb570e3daf2e558)
  // ===========================================================================
  Widget _buildStep1Contribution(bool isRtl, GameyaStrings strings) {
    final double amountMainUnits = _monthlyContributionMinor / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepBadge(isRtl ? 'الخطوة ١ من ٥' : 'STEP 1 OF 5'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl ? 'ما هو مبلغ القسط الشهري لكل عضو؟' : 'How much will everyone contribute?',
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl
              ? 'حدد القسط الشهري الثابت الذي سيلتزم به كل عضو في الجمعية.'
              : 'Set the monthly amount each member needs to pay.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Hero Contribution Amount Display with Glowing Aura
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: AppRadii.borderLg,
                  border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                      blurRadius: 24.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'EGP',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      amountMainUnits.toStringAsFixed(0),
                      style: AppTypography.financialDisplay.copyWith(
                        fontSize: 48.0,
                        color: AppColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                isRtl ? 'شهرياً لكل عضو' : 'Per month / member',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Interactive Slider Container
        SurfaceCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.emeraldGreen,
                  inactiveTrackColor: AppColors.surfaceElevated,
                  thumbColor: AppColors.emeraldGreen,
                  overlayColor: AppColors.emeraldGreen.withValues(alpha: 0.2),
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                ),
                child: Slider(
                  value: _monthlyContributionMinor.toDouble(),
                  min: 50000.0, // 500 EGP
                  max: 1000000.0, // 10,000 EGP
                  divisions: 19, // In increments of 500 EGP
                  onChanged: (val) {
                    setState(() {
                      _monthlyContributionMinor = val.toInt();
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('EGP 500', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                    Text('EGP 10,000+', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Quick Preset Chips
        Text(
          isRtl ? 'مبالغ سريعة' : 'Quick Amount Presets',
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [50000, 100000, 200000, 500000, 1000000].map((minorAmt) {
            final isSelected = _monthlyContributionMinor == minorAmt;
            return ChoiceChip(
              label: Text(
                'EGP ${(minorAmt ~/ 100)}',
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.emeraldGreen,
              backgroundColor: AppColors.cardSurface,
              side: BorderSide(
                color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle,
              ),
              onSelected: (_) {
                setState(() => _monthlyContributionMinor = minorAmt);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Projected Monthly Outcome Bento Card
        _buildProjectedOutcomeCard(isRtl),
      ],
    );
  }

  // ===========================================================================
  // STEP 2: MEMBER TOPOLOGY & SCHEDULE (Stitch Artboard: 9901d326efd54649a9ee13c3ddba6f54)
  // ===========================================================================
  Widget _buildStep2ScheduleAndTopology(bool isRtl, GameyaStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepBadge(isRtl ? 'الخطوة ٢ من ٥' : 'STEP 2 OF 5'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl ? 'كم عدد أعضاء الجمعية؟' : 'How many members?',
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl
              ? 'يحدد عدد الأعضاء مدة الجمعية بالأشهر ومبلغ القبض الإجمالي.'
              : 'Define the circle size. Members determine duration in months.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Stepper Control & Bento Box
        SurfaceCard(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRoundStepperBtn(
                    icon: Icons.remove,
                    onPressed: _memberCount > 5
                        ? () {
                            setState(() {
                              _memberCount -= 1;
                              if (_creatorSlotNumber > _memberCount) _creatorSlotNumber = 1;
                            });
                          }
                        : null,
                  ),
                  Column(
                    children: [
                      Text(
                        '$_memberCount',
                        style: AppTypography.financialDisplay.copyWith(
                          fontSize: 44.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isRtl ? 'أعضاء / شهور' : 'Members / Months',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.emeraldGreen,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _buildRoundStepperBtn(
                    icon: Icons.add,
                    onPressed: _memberCount < 15
                        ? () {
                            setState(() {
                              _memberCount += 1;
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick Member Count Preset Chips (5..15)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].map((count) {
                    final isSelected = _memberCount == count;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: ChoiceChip(
                        label: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12.0,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.emeraldGreen,
                        backgroundColor: AppColors.surfaceElevated,
                        side: BorderSide(
                          color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _memberCount = count;
                            if (_creatorSlotNumber > _memberCount) _creatorSlotNumber = 1;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Duration and Total Payout Bento Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: AppRadii.borderMd,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16.0, color: AppColors.textSecondary),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: Text(
                                  isRtl ? 'المدة' : 'Duration',
                                  style: AppTypography.labelSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              isRtl ? '$_memberCount شهور' : '$_memberCount Months',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: AppRadii.borderMd,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, size: 16.0, color: AppColors.emeraldGreen),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: Text(
                                  isRtl ? 'إجمالي القبض' : 'Total Payout',
                                  style: AppTypography.labelSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                            child: FinancialAmountText(
                              amountMinor: _totalPoolMinor,
                              currency: 'EGP',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.emeraldGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Member Topology Radial Preview
        Center(
          child: Column(
            children: [
              Text(
                isRtl ? 'تخطيط دائرة الجمعية' : 'CIRCLE TOPOLOGY',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCircleTopologyPreview(_memberCount),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3: ALLOCATION MODE & TURN (Stitch Artboard: 980d463d35b546ce97c946975eb7889e)
  // ===========================================================================
  Widget _buildStep3AllocationMode(bool isRtl, GameyaStrings strings) {
    final isPaired = _allocationMode == GameyaAllocationMode.symmetricalPaired;
    final halfPayoutMinor = _totalPoolMinor ~/ 2;
    final mirrorSlot = _memberCount + 1 - _creatorSlotNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepBadge(isRtl ? 'الخطوة ٣ من ٥' : 'STEP 3 OF 5'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl ? 'كيف يتم صرف دفعات القبض؟' : 'How are payouts scheduled?',
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl
              ? 'اختر بين التدوير التسلسلي الكلاسيكي أو التوزيع المتكافئ المقترن بنسبة ٥٠/٥٠.'
              : 'Choose between standard linear rotation or 50/50 symmetrical paired distribution.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),

        // 1. Sequential Mode Card
        _buildAllocationCard(
          mode: GameyaAllocationMode.sequential,
          title: isRtl ? 'التدوير التسلسلي (١ إلى N)' : 'Linear Sequential Rotation (1..N)',
          description: isRtl
              ? 'عضو واحد يستلم كامل مبلغ القبض شهرياً بالترتيب.'
              : '1 member receives the full pool amount each month in sequential order.',
          badge: isRtl ? 'كلاسيكي' : 'Classic',
          isSelected: _allocationMode == GameyaAllocationMode.sequential,
          onTap: () {
            setState(() {
              _allocationMode = GameyaAllocationMode.sequential;
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Symmetrical Paired Mode Card
        _buildAllocationCard(
          mode: GameyaAllocationMode.symmetricalPaired,
          title: isRtl ? 'التوزيع المقترن المتكافئ (١ ↔ N)' : 'Symmetrical Paired Allocation (1 ↔ N)',
          description: _memberCount.isOdd
              ? (isRtl
                  ? 'اقتران الأدوار المتقابلة (٥٠٪ + ٥٠٪)، بينما يستلم الشهر الأوسط (شهر ${(_memberCount + 1) ~/ 2}) كامل المبلغ ١٠٠٪ دفعة واحدة في المنتصف.'
                  : 'Opposite slots are paired in 50/50 splits, and the middle month (Month ${(_memberCount + 1) ~/ 2}) receives a single 100% full payout in the middle.')
              : (isRtl
                  ? 'اقتران الأدوار المتقابلة (١ مع N، ٢ مع N-١) وصرف نصف المبلغ لكل منهما في شهرين متباعدين لتقليل المخاطر.'
                  : 'Opposite slots are paired (1 ↔ N, 2 ↔ N-1) splitting the monthly pool in 50% matched payouts.'),
          badge: _memberCount.isOdd
              ? (isRtl ? '٥٠/٥٠ + أوسط ١٠٠٪' : '50/50 + Mid 100%')
              : (isRtl ? 'أمان مضاعف' : 'Low Risk'),
          isSelected: _allocationMode == GameyaAllocationMode.symmetricalPaired,
          isEnabled: true,
          onTap: () {
            setState(() {
              _allocationMode = GameyaAllocationMode.symmetricalPaired;
            });
          },
        ),
        const SizedBox(height: AppSpacing.xl),

        // Organizer Payout Month / Paired Role Selection
        Builder(
          builder: (context) {
            final isOddCircle = _memberCount.isOdd;
            final midMonth = (_memberCount + 1) ~/ 2;
            final isMidSelected = isPaired && isOddCircle && _creatorSlotNumber == midMonth;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isPaired
                            ? (isRtl ? 'اختر دورك (بصفتك المنظم)' : 'Select Your Role (As Organizer)')
                            : (isRtl ? 'اختر شهر استلامك للقبض (بصفتك المنظم)' : 'Select Your Organizer Payout Month'),
                        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(
                      label: isPaired
                          ? (isMidSelected ? (isRtl ? '١٠٠٪ أوسط' : '100% Mid') : (isRtl ? '٥٠٪ + ٥٠٪' : '50% + 50%'))
                          : (isRtl ? '١٠٠٪' : '100%'),
                      type: isMidSelected ? StatusBadgeType.warning : StatusBadgeType.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isPaired
                      ? (isOddCircle
                          ? (isRtl
                              ? 'اختر الزوج المالي المناسب لك (٥٠٪ + ٥٠٪) أو الدور الأوسط المستقل (١٠٠٪ دفعة كاملة في منتصف المدة).'
                              : 'Choose your paired slot (50% + 50%) or the middle pivot slot (100% full payout in the middle).')
                          : (isRtl
                              ? 'اختر الزوج المالي المناسب لك. ستحصل على نصف المبلغ في الشهر الأول والنصف الآخر في الشهر المقابل.'
                              : 'Choose your paired role. You will receive 50% in the early month and 50% in the mirrored late month.'))
                      : (isRtl
                          ? 'اختر الشهر الذي ترغب في استلام كامل مبلغ الجمعية فيه.'
                          : 'Select the single month you wish to receive the full circle payout.'),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),

                // Slot Selector: Conditioned on Allocation Mode
                if (isPaired) ...[
                  // Symmetrical Paired Selection: N/2 paired choices + optional middle slot for odd count
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ...List.generate(_memberCount ~/ 2, (i) {
                        final earlySlot = i + 1;
                        final lateSlot = _memberCount - i;
                        final isSelected = !isMidSelected && (_creatorSlotNumber == earlySlot || _creatorSlotNumber == lateSlot);

                        return ChoiceChip(
                          label: Text(
                            isRtl ? 'شهر $earlySlot ↔ شهر $lateSlot' : 'Month $earlySlot ↔ Month $lateSlot',
                            style: TextStyle(
                              color: isSelected ? Colors.black : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.emeraldGreen,
                          backgroundColor: AppColors.cardSurface,
                          side: BorderSide(
                            color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          onSelected: (_) {
                            setState(() => _creatorSlotNumber = earlySlot);
                          },
                        );
                      }),
                      if (isOddCircle)
                        ChoiceChip(
                          avatar: const Icon(Icons.star, size: 16, color: AppColors.amberWarning),
                          label: Text(
                            isRtl ? 'شهر $midMonth (أوسط ١٠٠٪)' : 'Month $midMonth (100% Mid)',
                            style: TextStyle(
                              color: isMidSelected ? Colors.black : AppColors.amberWarning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isMidSelected,
                          selectedColor: AppColors.amberWarning,
                          backgroundColor: AppColors.cardSurface,
                          side: BorderSide(
                            color: isMidSelected ? AppColors.amberWarning : AppColors.amberWarning.withValues(alpha: 0.5),
                            width: isMidSelected ? 1.5 : 1.0,
                          ),
                          onSelected: (_) {
                            setState(() => _creatorSlotNumber = midMonth);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Detailed Breakdown Card for Paired Mode
                  if (isMidSelected) ...[
                    SurfaceCard(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars, color: AppColors.amberWarning, size: 20.0),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  isRtl ? 'دفعة وسط المدة الكاملة (١٠٠٪)' : 'Middle Month Full Payout (100%)',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.amberWarning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              StatusBadge(
                                label: isRtl ? '١٠٠٪ كاملة' : '100% Full',
                                type: StatusBadgeType.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: AppRadii.borderSm,
                              border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: AppColors.amberWarning, size: 16.0),
                                    const SizedBox(width: 4.0),
                                    Expanded(
                                      child: Text(
                                        isRtl ? 'شهر $midMonth (منتصف مدة الجمعية)' : 'Month $midMonth (Exact Circle Midpoint)',
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6.0),
                                FinancialAmountText(
                                  amountMinor: _totalPoolMinor,
                                  currency: 'EGP',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.amberWarning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  isRtl
                                      ? 'ستستلم كامل مبلغ الجمعية EGP ${(_totalPoolMinor ~/ 100)} دفعة واحدة في الشهر الأوسط، بينما يتم توزيع باقي الشهور كأزواج متقابلة ٥٠/٥٠.'
                                      : 'You will receive 100% of the pool (EGP ${(_totalPoolMinor ~/ 100)}) in one single payout in Month $midMonth, while other months are paired 50/50.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SurfaceCard(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.compare_arrows, color: AppColors.emeraldGreen, size: 20.0),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  isRtl ? 'جدول دفعات المنظم المقترنة' : 'Organizer Paired Payout Schedule',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.emeraldGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              // Early Half Payout
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: AppRadii.borderSm,
                                    border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.bolt, color: AppColors.emeraldGreen, size: 14.0),
                                          const SizedBox(width: 4.0),
                                          Expanded(
                                            child: Text(
                                              isRtl ? 'دفعة ١ (٥٠٪ مبكرة)' : 'Payout 1 (50% Early)',
                                              style: AppTypography.labelSmall.copyWith(fontSize: 10.0, color: AppColors.emeraldGreen),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        isRtl ? 'شهر $_creatorSlotNumber' : 'Month $_creatorSlotNumber',
                                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'EGP ${(halfPayoutMinor ~/ 100)}',
                                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // Late Half Payout
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: AppRadii.borderSm,
                                    border: Border.all(color: AppColors.skyInfo.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.savings, color: AppColors.skyInfo, size: 14.0),
                                          const SizedBox(width: 4.0),
                                          Expanded(
                                            child: Text(
                                              isRtl ? 'دفعة ٢ (٥٠٪ متأخرة)' : 'Payout 2 (50% Late)',
                                              style: AppTypography.labelSmall.copyWith(fontSize: 10.0, color: AppColors.skyInfo),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        isRtl ? 'شهر $mirrorSlot' : 'Month $mirrorSlot',
                                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'EGP ${(halfPayoutMinor ~/ 100)}',
                                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isRtl
                                ? 'إجمالي ما تستلمه: EGP ${(_totalPoolMinor ~/ 100)} كاملة ومقسمة بالتساوي.'
                                : 'Total received: EGP ${(_totalPoolMinor ~/ 100)} full entitlement distributed evenly.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
          // Sequential Selection: Standard 1..N chips
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(_memberCount, (i) {
              final slotNum = i + 1;
              final isSelected = _creatorSlotNumber == slotNum;
              return ChoiceChip(
                label: Text(
                  isRtl ? 'شهر $slotNum' : 'Month $slotNum',
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.emeraldGreen,
                backgroundColor: AppColors.cardSurface,
                side: BorderSide(
                  color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle,
                  width: isSelected ? 1.5 : 1.0,
                ),
                onSelected: (_) {
                  setState(() => _creatorSlotNumber = slotNum);
                },
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sequential Summary Card
          SurfaceCard(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.emeraldGreen, size: 20.0),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl
                            ? 'دفعة واحدة كاملة (١٠٠٪) في شهر $_creatorSlotNumber'
                            : 'Single Full Payout (100%) in Month $_creatorSlotNumber',
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isRtl
                            ? 'ستحصل على كامل مبلغ الجمعية EGP ${(_totalPoolMinor ~/ 100)} في هذا الشهر.'
                            : 'You will receive the entire pool of EGP ${(_totalPoolMinor ~/ 100)} in this month.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  },
),
],
);
}

  // ===========================================================================
  // STEP 4: COMMUNITY IDENTITY & PURPOSE (Stitch Artboard: cfbf319b51184d47ba27f92db53cc8eb)
  // ===========================================================================
  Widget _buildStep4CommunityIdentity(bool isRtl, GameyaStrings strings) {
    final categories = [
      {'name': 'Family', 'labelAr': 'عائلي', 'icon': Icons.family_restroom},
      {'name': 'Vehicle', 'labelAr': 'سيارة', 'icon': Icons.directions_car},
      {'name': 'Wedding', 'labelAr': 'زواج', 'icon': Icons.celebration},
      {'name': 'Education', 'labelAr': 'تعليم', 'icon': Icons.school},
      {'name': 'Home', 'labelAr': 'منزل', 'icon': Icons.home},
      {'name': 'Business', 'labelAr': 'أعمال', 'icon': Icons.storefront},
      {'name': 'Tech', 'labelAr': 'تقنية', 'icon': Icons.devices},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepBadge(isRtl ? 'الخطوة ٤ من ٥' : 'STEP 4 OF 5'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl ? 'اسم وهدف الجمعية' : 'Goal & Circle Name',
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl
              ? 'اختر فئة الادخار وأعطِ الجمعية اسماً واضحاً يسهل التعرف عليه.'
              : 'Select saving goal and give your circle a distinct name.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Circle Name Input Field
        StandardTextField(
          label: isRtl ? 'اسم الجمعية' : 'Circle Name',
          hint: isRtl ? 'مثال: جمعية عائلة منصور ٢٠٢٧' : 'e.g. Mansour Family Savings 2027',
          controller: _nameController,
          prefixIcon: const Icon(Icons.edit_note, color: AppColors.textMuted, size: 22.0),
          validator: (val) => val == null || val.trim().length < 3
              ? (isRtl ? 'يرجى إدخال اسم مكون من 3 أحرف على الأقل' : 'Name must be at least 3 characters')
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Category Selector
        Text(
          isRtl ? 'فئة الادخار' : 'Saving Category',
          style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat['name'];
            return ChoiceChip(
              avatar: Icon(
                cat['icon'] as IconData,
                size: 18.0,
                color: isSelected ? Colors.black : AppColors.emeraldGreen,
              ),
              label: Text(
                isRtl ? (cat['labelAr'] as String) : (cat['name'] as String),
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.emeraldGreen,
              backgroundColor: AppColors.cardSurface,
              side: BorderSide(
                color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle,
              ),
              onSelected: (_) {
                setState(() => _selectedCategory = cat['name'] as String);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Privacy Toggle
        SurfaceCard(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'جمعية خاصة (دعوة فقط)' : 'Private Circle (Invite-Only)',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      isRtl
                          ? 'لن تظهر الجمعية في صفحة الاستكشاف العامة. الانضمام عبر كود الدعوة فقط.'
                          : 'Hidden from public discovery. Members join strictly via invite code.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Switch(
                value: _isPrivate,
                onChanged: (val) => setState(() => _isPrivate = val),
                activeThumbColor: AppColors.emeraldGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 5: REVIEW & BYLAWS (Stitch Artboard: a6a39fb717b74b55a440e9459e206c32)
  // ===========================================================================
  Widget _buildStep5ReviewAndBylaws(bool isRtl, GameyaStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepBadge(isRtl ? 'الخطوة ٥ من ٥' : 'STEP 5 OF 5'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl ? 'مراجعة بيانات الجمعية واللائحة' : 'Review Rules & Confirm',
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRtl
              ? 'راجع كافة الشروط قبل إنشاء ونشر الجمعية لدعوة الأعضاء.'
              : 'Review circle parameters and accept cooperative bylaws before publishing.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Summary Bento Card
        SurfaceCard(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              _buildReviewRow(isRtl ? 'اسم الجمعية' : 'Circle Name', _nameController.text.trim()),
              _buildReviewRow(isRtl ? 'فئة الادخار' : 'Category', _selectedCategory),
              _buildReviewRow(isRtl ? 'القسط الشهري' : 'Monthly Due', 'EGP ${(_monthlyContributionMinor ~/ 100)} / month'),
              _buildReviewRow(isRtl ? 'المدة وعدد الأعضاء' : 'Duration & Members', '$_memberCount Months ($_memberCount Members)'),
              _buildReviewRow(isRtl ? 'إجمالي القبض' : 'Total Pool Amount', 'EGP ${(_totalPoolMinor ~/ 100)}'),
              _buildReviewRow(isRtl ? 'نظام التوزيع' : 'Allocation Mode', _allocationMode.displayName),
              _buildReviewRow(
                isRtl ? 'دور استلامك (المنظم)' : 'Your Payout Turn',
                _allocationMode == GameyaAllocationMode.symmetricalPaired
                    ? (_memberCount.isOdd && _creatorSlotNumber == ((_memberCount + 1) ~/ 2)
                        ? (isRtl
                            ? 'شهر $_creatorSlotNumber (قبض أوسط كامل ١٠٠٪)'
                            : 'Month $_creatorSlotNumber (100% Middle Full Payout)')
                        : (isRtl
                            ? 'شهر $_creatorSlotNumber وشهر ${_memberCount + 1 - _creatorSlotNumber} (٥٠٪ + ٥٠٪)'
                            : 'Month $_creatorSlotNumber & Month ${_memberCount + 1 - _creatorSlotNumber} (50% + 50%)'))
                    : (isRtl ? 'شهر $_creatorSlotNumber (١٠٠٪)' : 'Month $_creatorSlotNumber (100%)'),
              ),
              _buildReviewRow(isRtl ? 'نوع الخصوصية' : 'Privacy', _isPrivate ? (isRtl ? 'خاصة' : 'Private') : (isRtl ? 'عامة' : 'Public')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Bylaws Consent Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreedToBylaws,
              activeColor: AppColors.emeraldGreen,
              checkColor: AppColors.deepSlate,
              onChanged: (val) => setState(() => _agreedToBylaws = val ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  isRtl
                      ? 'أقر بأن هذه الجمعية تعمل كدائرة ادخار مغلقة ومستقلة بدون فوائد ربوية، بدون رسوم إدارية، وبالتزام كامل باللوائح الداخلية للمنصة.'
                      : 'I confirm that this Game\'ya operates as an autonomous closed savings circle with zero interest, zero administrative fees, and full member commitment under platform invariants.',
                  style: AppTypography.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // SUCCESS & SHARE VIEW (Stitch Artboard: b9e43189c6284963b4e599ab1dc5bf39)
  // ===========================================================================
  Widget _buildSuccessAndShareView(bool isRtl, GameyaStrings strings) {
    final circle = _createdCircle!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing Emerald Success Icon Halo
              Container(
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emeraldGreen, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.3),
                      blurRadius: 30.0,
                      spreadRadius: 4.0,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle_outline, color: AppColors.emeraldGreen, size: 56.0),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                isRtl ? 'تم إطلاق جمعية ${circle.name}!' : '${circle.name} is Live!',
                style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isRtl
                    ? 'تم إنشاء الجمعية بنجاح. شارك كود الدعوة مع أصدقائك أو عائلتك للانضمام.'
                    : 'Your Game\'ya has been created. Share your invite code with peers to join.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Invite Code Box
              SurfaceCard(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      isRtl ? 'كود الدعوة للجمعية' : 'INVITE CODE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      circle.inviteCode ?? 'FAM-882',
                      style: AppTypography.financialDisplay.copyWith(
                        color: AppColors.emeraldGreen,
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.borderSubtle),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      label: isRtl ? 'نسخ كود ورابط الدعوة' : 'Copy Invite Link & Code',
                      icon: Icons.copy,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isRtl
                                  ? 'تم نسخ رابط الدعوة لجمعية ${circle.name}!'
                                  : 'Invite link for ${circle.name} copied to clipboard!',
                            ),
                            backgroundColor: AppColors.emeraldGreen,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Primary CTA: Open Circle Room
              PrimaryButton(
                label: isRtl ? 'الدخول إلى غرفة الجمعية' : 'Open Game\'ya Circle Room',
                icon: Icons.meeting_room_outlined,
                onPressed: () {
                  widget.onCircleCreated?.call(circle.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION ACTION BAR
  // ===========================================================================
  Widget _buildBottomActionBar(bool isRtl, GameyaStrings strings) {
    final isLastStep = _currentStep == 4;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.deepSlate,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1.0)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: SecondaryButton(
                label: isRtl ? 'السابق' : 'Back',
                onPressed: () {
                  setState(() {
                    _currentStep--;
                    _errorMessage = null;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            flex: 2,
            child: PrimaryButton(
              label: isLastStep
                  ? (isRtl ? 'إطلاق الجمعية 🚀' : 'Launch Game\'ya Circle 🚀')
                  : (isRtl ? 'الخطوة التالية ←' : 'Next Step →'),
              isLoading: _isSubmitting,
              onPressed: (isLastStep && !_agreedToBylaws) ? null : _handleNextStep,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextStep() async {
    if (_currentStep == 3) {
      if (_nameController.text.trim().length < 3) {
        setState(() {
          _errorMessage = _resolvedRtl
              ? 'يرجى إدخال اسم صالح للجمعية (3 أحرف على الأقل)'
              : 'Please enter a valid circle name (at least 3 characters)';
        });
        return;
      }
    }

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _errorMessage = null;
      });
    } else {
      // Step 5: Submit creation request
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final draft = CreateGameyaDraft(
          name: _nameController.text.trim(),
          goalCategory: _selectedCategory,
          monthlyContributionMinor: _monthlyContributionMinor,
          totalPeriods: _memberCount,
          allocationMode: _allocationMode,
          creatorSlotNumber: _creatorSlotNumber,
          isPrivate: _isPrivate,
        );

        final created = await widget.controller.createNewGameya(draft);
        if (mounted) {
          setState(() {
            _createdCircle = created;
            _isSubmitting = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================

  Widget _buildStepBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.emeraldGreen,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildProjectedOutcomeCard(bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet, color: AppColors.emeraldGreen, size: 22.0),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl ? 'إجمالي القبض المتوقع ($_memberCount أعضاء)' : 'Estimated Total Pool ($_memberCount members)',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2.0),
                FinancialAmountText(
                  amountMinor: _totalPoolMinor,
                  currency: 'EGP',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundStepperBtn({required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(28.0),
      child: Container(
        width: 52.0,
        height: 52.0,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(
            color: onPressed != null ? AppColors.emeraldGreen : AppColors.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? AppColors.emeraldGreen : AppColors.textMuted,
          size: 24.0,
        ),
      ),
    );
  }

  Widget _buildCircleTopologyPreview(int memberCount) {
    const double size = 180.0;
    const double radius = size / 2.0 - 20.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed Outer Ring
          Container(
            width: size - 24.0,
            height: size - 24.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.5,
              ),
            ),
          ),

          // Central Hub
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.groups, color: AppColors.emeraldGreen, size: 22.0),
          ),

          // Orbital Nodes
          for (int i = 0; i < memberCount; i++) ...[
            Builder(
              builder: (_) {
                final angle = (i * 2.0 * math.pi / memberCount) - (math.pi / 2.0);
                final dx = radius * math.cos(angle);
                final dy = radius * math.sin(angle);
                final isPairedMode = _allocationMode == GameyaAllocationMode.symmetricalPaired;
                final mirrorSlot = memberCount - _creatorSlotNumber + 1;
                final isCreatorPrimary = (i + 1) == _creatorSlotNumber;
                final isCreatorMirror = isPairedMode && (i + 1) == mirrorSlot;
                final isCreator = isCreatorPrimary || isCreatorMirror;

                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Container(
                    width: 22.0,
                    height: 22.0,
                    decoration: BoxDecoration(
                      color: isCreator ? AppColors.emeraldGreen : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCreator ? Colors.white : AppColors.borderSubtle,
                        width: isCreator ? 2.0 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: isCreator ? Colors.black : AppColors.textSecondary,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllocationCard({
    required GameyaAllocationMode mode,
    required String title,
    required String description,
    required String badge,
    required bool isSelected,
    bool isEnabled = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.borderMd,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.65,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.emeraldGreen.withValues(alpha: 0.12) : AppColors.cardSurface,
            borderRadius: AppRadii.borderMd,
            border: Border.all(
              color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected ? Icons.check_circle : (isEnabled ? Icons.radio_button_unchecked : Icons.block),
                color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
                size: 22.0,
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
                            title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        StatusBadge(
                          label: badge,
                          type: isSelected
                              ? StatusBadgeType.success
                              : (isEnabled ? StatusBadgeType.neutral : StatusBadgeType.warning),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4.0),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyLockBanner(bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.crimsonRed.withValues(alpha: 0.15),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.crimsonRed.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.crimsonRed, size: 22.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isRtl
                  ? 'قفل الأمان المالي نشط: تم إيقاف إنشاء وتعديل الجمعيات بقرار حوكمي.'
                  : 'Financial Safety Lock Active: Circle creations are paused by governance policy.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.crimsonRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.15),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.amberWarning, size: 20.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isRtl
                  ? 'وضع عدم الاتصال: سيتطلب إطلاق الجمعية استعادة الاتصال بالإنترنت.'
                  : 'Offline Mode: Launching a circle requires active network connection.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
