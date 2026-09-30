import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../dashboard/models/member_dashboard_models.dart';
import '../models/admin_models.dart';
import '../state/admin_controller.dart';
import '../state/admin_state.dart';

/// Screen 24: Member Directory & KYC Roster Management View.
class AdminMemberDirectoryView extends StatelessWidget {
  final AdminController controller;
  final ValueChanged<AdminMemberListItem> onSelectMember;

  const AdminMemberDirectoryView({
    super.key,
    required this.controller,
    required this.onSelectMember,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is AdminLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.emeraldGreen));
        }

        if (state is AdminLoaded) {
          return _buildLoadedView(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, AdminLoaded state) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cooperative Member Directory',
              style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Search, inspect financial standing, and manage KYC underwriting for enrolled members.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Search Field
          StandardTextField(
            label: 'Search Members',
            hint: 'Search by full name, email, or member ID...',
            prefixIcon:
                const Icon(Icons.search, color: AppColors.textSecondary),
            onChanged: (q) => controller.searchMembers(q),
          ),
          const SizedBox(height: AppSpacing.md),

          // Filter Chips
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildFilterChip('ALL', state.kycFilter == 'ALL'),
              _buildFilterChip('VERIFIED', state.kycFilter == 'VERIFIED'),
              _buildFilterChip(
                  'PENDING_REVIEW', state.kycFilter == 'PENDING_REVIEW'),
              _buildFilterChip('RESTRICTED', state.kycFilter == 'RESTRICTED'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Member List Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${state.filteredMembers.length} of ${state.members.length} Members',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const StatusBadge(
                  label: 'TENANT-ALPHA ROSTER', type: StatusBadgeType.neutral),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (state.filteredMembers.isEmpty)
            const EmptyStateWidget(
              title: 'No Members Match Query',
              description:
                  'Try adjusting your search query or KYC filter settings.',
              icon: Icons.person_search_outlined,
            )
          else
            for (final member in state.filteredMembers) ...[
              _buildMemberCard(member),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.filterMembersByKyc(label),
      selectedColor: AppColors.emeraldGreen.withValues(alpha: 0.2),
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderFull,
        side: BorderSide(
          color: isSelected ? AppColors.emeraldGreen : AppColors.borderSubtle,
        ),
      ),
    );
  }

  Widget _buildMemberCard(AdminMemberListItem member) {
    return SurfaceCard(
      child: InkWell(
        onTap: () => onSelectMember(member),
        borderRadius: AppRadii.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surfaceElevated,
                    radius: 20.0,
                    child: Text(
                      member.fullName.isNotEmpty
                          ? member.fullName.substring(0, 1)
                          : 'M',
                      style: AppTypography.titleMedium
                          .copyWith(color: AppColors.sovereignGold),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.fullName,
                            style: AppTypography.titleSmall,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2.0),
                        Text(
                          '${member.memberId} • ${member.email}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusBadge(
                    label: member.kycStatus.displayName,
                    type: member.kycStatus == KycStatus.verified
                        ? StatusBadgeType.success
                        : StatusBadgeType.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.borderSubtle, height: 1.0),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12.0,
                runSpacing: 4.0,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.published_with_changes,
                          size: 14.0, color: AppColors.textSecondary),
                      const SizedBox(width: 4.0),
                      Text(
                        '${member.currentCycleName} (Slot #${member.slotNumber})',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Contributed: ',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      FinancialAmountText(
                          amountMinor: member.totalContributedMinor,
                          color: AppColors.emeraldGreen),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
