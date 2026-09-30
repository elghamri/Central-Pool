import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../dashboard/models/member_dashboard_models.dart';
import '../models/admin_models.dart';
import '../state/admin_controller.dart';

/// Screen 25: Member Profile & Financial Ledger Inspection View.
class AdminMemberDetailView extends StatelessWidget {
  final AdminMemberListItem member;
  final AdminController controller;
  final VoidCallback onBack;

  const AdminMemberDetailView({
    super.key,
    required this.member,
    required this.controller,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = member.kycStatus == KycStatus.verified;

    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: onBack,
                tooltip: 'Back to Directory',
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Member Profile & Standing',
                  style: AppTypography.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Member Profile Overview Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceElevated,
                      radius: 26.0,
                      child: Text(
                        member.fullName.isNotEmpty
                            ? member.fullName.substring(0, 1)
                            : 'M',
                        style: AppTypography.headlineSmall
                            .copyWith(color: AppColors.sovereignGold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.fullName,
                              style: AppTypography.titleLarge,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2.0),
                          Text(
                            'Member ID: ${member.memberId} • ${member.email}',
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
                      type: isVerified
                          ? StatusBadgeType.success
                          : StatusBadgeType.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.md),
                _buildRow('Account Standing', member.accountStatus),
                _buildRow('Active Rotation Cycle',
                    '${member.currentCycleName} (${member.currentCycleId})'),
                _buildRow('Assigned Rotation Slot',
                    'Slot #${member.slotNumber} of 10'),
                _buildRow('Enrollment Date',
                    '${member.joinedDate.year}-${member.joinedDate.month.toString().padLeft(2, '0')}-${member.joinedDate.day.toString().padLeft(2, '0')}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Financial Ledger Balances
          const Text('Member Financial Balances',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Authoritative positions verified against General Ledger double-entry postings.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth > 600
                  ? (constraints.maxWidth - 16) / 2
                  : double.infinity;

              return Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: SummaryMetricCard(
                      title: 'Total Contributed to Date',
                      valueWidget: FinancialAmountText(
                          amountMinor: member.totalContributedMinor,
                          color: AppColors.emeraldGreen),
                      subtitle: 'Period 1 Settled Clean',
                      icon: Icons.savings_outlined,
                      iconColor: AppColors.emeraldGreen,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryMetricCard(
                      title: 'Remaining Cycle Obligation',
                      valueWidget: FinancialAmountText(
                          amountMinor: member.outstandingObligationMinor,
                          color: AppColors.sovereignGold),
                      subtitle: '9 Scheduled Monthly Dues',
                      icon: Icons.receipt_long_outlined,
                      iconColor: AppColors.sovereignGold,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // KYC Underwriting Actions
          const Text('Underwriting & Verification Actions',
              style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),

          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Member KYC Status',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Admins can verify identity documents or place member accounts on compliance review.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    PrimaryButton(
                      label: isVerified
                          ? 'Re-Verify Tier 2 KYC'
                          : 'Approve Tier 2 Verification',
                      icon: Icons.check_circle_outline,
                      onPressed: () async {
                        final success = await controller.verifyMemberKyc(
                            member.memberId, true);
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${member.fullName} KYC verified successfully.'),
                              backgroundColor: AppColors.emeraldGreen,
                            ),
                          );
                        }
                      },
                    ),
                    SecondaryButton(
                      label: 'Flag for Compliance Review',
                      icon: Icons.flag_outlined,
                      onPressed: () async {
                        final success = await controller.verifyMemberKyc(
                            member.memberId, false);
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${member.fullName} flagged for KYC review.'),
                              backgroundColor: AppColors.amberWarning,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SecondaryButton(
            label: 'Back to Member Directory',
            onPressed: onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTypography.labelMedium
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
