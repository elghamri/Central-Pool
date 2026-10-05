import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

enum StatusBadgeType {
  success,
  warning,
  error,
  info,
  neutral,
}

/// Pill-shaped status badge indicator.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
  });

  factory StatusBadge.fromStatus(String status) {
    final s = status.toUpperCase();
    if (s == 'SETTLED' || s == 'ACTIVE' || s == 'CURRENT' || s == 'MATCH_CLEAN' || s == 'PAID' || s == 'APPROVED') {
      return StatusBadge(label: status, type: StatusBadgeType.success, icon: Icons.check_circle_outline);
    } else if (s == 'PENDING' || s == 'PROCESSING' || s == 'PENDING_CHECKER' || s == 'STAGE_PENDING_MAKER') {
      return StatusBadge(label: status, type: StatusBadgeType.warning, icon: Icons.schedule);
    } else if (s == 'FAILED' || s == 'DELINQUENT' || s == 'REJECTED' || s == 'DISCREPANCY') {
      return StatusBadge(label: status, type: StatusBadgeType.error, icon: Icons.error_outline);
    } else if (s == 'UNKNOWN') {
      return StatusBadge(label: status, type: StatusBadgeType.info, icon: Icons.help_outline);
    }
    return StatusBadge(label: status, type: StatusBadgeType.neutral);
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    switch (type) {
      case StatusBadgeType.success:
        primaryColor = AppColors.emeraldGreen;
        break;
      case StatusBadgeType.warning:
        primaryColor = AppColors.amberWarning;
        break;
      case StatusBadgeType.error:
        primaryColor = AppColors.crimsonRed;
        break;
      case StatusBadgeType.info:
        primaryColor = AppColors.skyInfo;
        break;
      case StatusBadgeType.neutral:
        primaryColor = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: AppRadii.borderFull,
        border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.0, color: primaryColor),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
