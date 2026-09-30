import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/gameya_models.dart';
import '../state/gameya_controller.dart';
import '../widgets/gameya_summary_card.dart';
import '../i18n/gameya_strings.dart';

/// Screen 6: Game'ya Circle Discovery & Marketplace Feed according to Stitch Baseline.
class CircleDiscoveryView extends StatefulWidget {
  final GameyaController controller;
  final ValueChanged<String>? onOpenCircleRoom;
  final ValueChanged<String>? onCircleJoinedAndOpenRoom;

  const CircleDiscoveryView({
    super.key,
    required this.controller,
    this.onOpenCircleRoom,
    this.onCircleJoinedAndOpenRoom,
  });

  @override
  State<CircleDiscoveryView> createState() => _CircleDiscoveryViewState();
}

class _CircleDiscoveryViewState extends State<CircleDiscoveryView> {
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameyaState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        if (state is GameyaError) {
          return Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ErrorCardWidget(
                  title: 'Unable to Discover Circles',
                  errorMessage: state.message,
                  onRetry: state.onRetry ?? widget.controller.loadInitialData,
                ),
              ),
            ),
          );
        }

        if (state is! GameyaLoaded) {
          return const Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: Center(
              child: AppLoadingIndicator(
                message: 'Discovering open circles...',
              ),
            ),
          );
        }

        final strings = GameyaStrings.of(state.languageCode);
        final filteredCircles = state.filteredMarketplaceCircles;

        return Directionality(
          textDirection: strings.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.deepSlate,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Discovery Title & Subtitle
                    Text(
                      strings.discoverTitle,
                      style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      strings.discoverSubtitle,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Private Invite Code Entry Card
                    _buildInviteCodeCard(context, strings),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Category Filter Chips
                    _buildCategoryFilterChips(state.selectedCategoryFilter),
                    const SizedBox(height: AppSpacing.sm),

                    // 4. Secondary Filter Chips (Duration & Tier)
                    _buildSecondaryFiltersRow(state),
                    const SizedBox(height: AppSpacing.md),

                    // 5. Circle Marketplace Feed Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${strings.openCirclesForming} (${filteredCircles.length})',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Sorted by Date',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // 6. Circles List
                    if (filteredCircles.isEmpty)
                      _buildNoCirclesFound()
                    else
                      for (final circle in filteredCircles) ...[
                        GameyaSummaryCard(
                          circle: circle,
                          onTap: () => _showCircleDetailAndSlotPicker(context, circle),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInviteCodeCard(BuildContext context, GameyaStrings strings) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, color: AppColors.emeraldGreen, size: 18.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  strings.joinPrivateCode,
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadii.borderSm,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    controller: _inviteCodeController,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: strings.privateCodeHint,
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              PrimaryButton(
                label: strings.joinBtn,
                isFullWidth: false,
                onPressed: () {
                  final code = _inviteCodeController.text.trim();
                  if (code.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Searching for private Game\'ya with code: $code...'),
                        backgroundColor: AppColors.emeraldGreen,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChips(String? activeFilter) {
    final categories = ['All', 'Family', 'Vehicle', 'Wedding', 'Tech'];

    return SizedBox(
      height: 36.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = (activeFilter == null && cat == 'All') || (activeFilter == cat);

          return FilterChip(
            label: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.emeraldGreen,
            backgroundColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.borderSm,
              side: BorderSide(color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle),
            ),
            showCheckmark: false,
            onSelected: (_) {
              widget.controller.setCategoryFilter(cat == 'All' ? null : cat);
            },
          );
        },
      ),
    );
  }

  Widget _buildSecondaryFiltersRow(GameyaLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Duration chips
          _buildFilterPill(
            label: '5 Months',
            isSelected: state.selectedDurationFilter == 5,
            onTap: () => widget.controller.setDurationFilter(state.selectedDurationFilter == 5 ? null : 5),
          ),
          const SizedBox(width: 8.0),
          _buildFilterPill(
            label: '10 Months',
            isSelected: state.selectedDurationFilter == 10,
            onTap: () => widget.controller.setDurationFilter(state.selectedDurationFilter == 10 ? null : 10),
          ),
          const SizedBox(width: 12.0),
          Container(width: 1.0, height: 20.0, color: AppColors.borderSubtle),
          const SizedBox(width: 12.0),
          // Tier chips
          _buildFilterPill(
            label: 'Under \$500/mo',
            isSelected: state.activeFilterTier == 'TIER_200',
            onTap: () => widget.controller.setMarketplaceFilter(state.activeFilterTier == 'TIER_200' ? 'ALL' : 'TIER_200'),
          ),
          const SizedBox(width: 8.0),
          _buildFilterPill(
            label: '\$500 - \$1,000/mo',
            isSelected: state.activeFilterTier == 'TIER_500',
            onTap: () => widget.controller.setMarketplaceFilter(state.activeFilterTier == 'TIER_500' ? 'ALL' : 'TIER_500'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.borderSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : AppColors.cardSurface,
          borderRadius: AppRadii.borderSm,
          border: Border.all(color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
            fontSize: 11.0,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNoCirclesFound() {
    return SurfaceCard(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: AppColors.textMuted, size: 40.0),
          const SizedBox(height: 12.0),
          Text(
            'No matching circles found',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Try switching filters or create your own Game\'ya.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showCircleDetailAndSlotPicker(BuildContext context, GameyaCircle circle) {
    int? selectedSlotNumber;
    final isSymmetrical = circle.allocationMode == GameyaAllocationMode.symmetricalPaired;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18.0,
                right: 18.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grab handle
                    Center(
                      child: Container(
                        width: 40.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Title & Mode Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            circle.name,
                            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        StatusBadge(
                          label: circle.allocationMode == GameyaAllocationMode.symmetricalPaired ? 'Paired' : 'Sequential',
                          type: StatusBadgeType.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Organizer: ${circle.organizerName} • ★ ${circle.organizerTrustRating.toStringAsFixed(1)}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 16.0),
                    const Divider(color: AppColors.borderSubtle),
                    const SizedBox(height: 12.0),

                    // Financial Terms Matrix
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTermItem('Monthly Due', '\$${(circle.monthlyContributionMinor / 100).toStringAsFixed(0)}/mo'),
                        _buildTermItem('Total Payout', '\$${(circle.totalPoolMinor / 100).toStringAsFixed(0)}'),
                        _buildTermItem('Duration', '${circle.totalPeriods} Mos'),
                        _buildTermItem('Open Slots', '${circle.openSlotsCount} Left'),
                      ],
                    ),

                    const SizedBox(height: 18.0),
                    Text(
                      'CHOOSE YOUR PAYOUT MONTH',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Open Slot Choices
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        for (final slot in circle.slots) ...[
                          _buildSlotChoiceChip(
                            slot: slot,
                            isSymmetrical: isSymmetrical,
                            isSelected: selectedSlotNumber == slot.slotNumber,
                            onSelected: slot.isClaimed
                                ? null
                                : () {
                                    setModalState(() => selectedSlotNumber = slot.slotNumber);
                                  },
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16.0),

                    // Selected Slot Confirmation Banner
                    if (selectedSlotNumber != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                          borderRadius: AppRadii.borderSm,
                          border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You selected: Month $selectedSlotNumber',
                              style: AppTypography.labelMedium.copyWith(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              '• You will contribute \$${(circle.monthlyContributionMinor / 100).toStringAsFixed(0)} each month.\n'
                              '• You will receive \$${(circle.totalPoolMinor / 100).toStringAsFixed(0)} during Month $selectedSlotNumber.\n'
                              '• You will continue contributing after receiving your payout until the circle completes.',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Join CTA Button
                    if (selectedSlotNumber != null)
                      PrimaryButton(
                        label: 'Join Game\'ya & Claim Month $selectedSlotNumber',
                        onPressed: () async {
                          final slotNum = selectedSlotNumber!;
                          Navigator.of(ctx).pop();
                          await widget.controller.joinCircleWithSlot(
                            circleId: circle.id,
                            slotNumber: slotNum,
                          );
                          widget.onCircleJoinedAndOpenRoom?.call(circle.id);
                        },
                      )
                    else
                      const SecondaryButton(
                        label: 'Select an Open Month Above',
                        onPressed: null,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTermItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2.0),
          Text(value, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSlotChoiceChip({
    required GameyaSlot slot,
    required bool isSymmetrical,
    required bool isSelected,
    required VoidCallback? onSelected,
  }) {
    final isClaimed = slot.isClaimed;

    Color bgColor = AppColors.surfaceElevated;
    Color borderColor = AppColors.borderSubtle;
    Color textColor = AppColors.textPrimary;

    if (isSelected) {
      bgColor = AppColors.emeraldGreen;
      borderColor = AppColors.emeraldGreen;
      textColor = Colors.black;
    } else if (isClaimed) {
      bgColor = AppColors.cardSurface.withValues(alpha: 0.5);
      borderColor = AppColors.borderSubtle.withValues(alpha: 0.3);
      textColor = AppColors.textMuted;
    }

    return InkWell(
      key: ValueKey('slot_chip_${slot.slotNumber}'),
      onTap: onSelected,
      borderRadius: AppRadii.borderSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadii.borderSm,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Month ${slot.slotNumber}',
              style: TextStyle(
                color: textColor,
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (isClaimed) ...[
              const SizedBox(width: 4.0),
              const Icon(Icons.lock, color: AppColors.textMuted, size: 12.0),
            ],
          ],
        ),
      ),
    );
  }
}
