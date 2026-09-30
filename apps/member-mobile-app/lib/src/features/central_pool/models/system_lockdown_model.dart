// Central Pool System Lockdown Event Model (Step 11/12/13)
// PROVENANCE & SEMANTIC DEFINITION:
// - Client-side safety listener model for /system_lockdowns signal.
// - Provides reactive lockdown state to render LockedBanner and disable mutation CTAs.
// - NOT a backend circuit-breaker authority.

class SystemLockdownModel {
  final String lockdownId;
  final String tenantId;
  final bool isLocked;
  final String reason;
  final String? initiatedByUid;
  final DateTime initiatedAt;
  final DateTime? resolvedAt;

  const SystemLockdownModel({
    required this.lockdownId,
    required this.tenantId,
    required this.isLocked,
    required this.reason,
    this.initiatedByUid,
    required this.initiatedAt,
    this.resolvedAt,
  });

  factory SystemLockdownModel.fromJson(Map<String, dynamic> json) {
    return SystemLockdownModel(
      lockdownId: json['lockdownId'] as String? ?? json['lockdown_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String? ?? '',
      isLocked: (json['isLocked'] ?? json['is_locked'] ?? json['active'] ?? false) as bool,
      reason: json['reason'] as String? ?? 'Administrative lockdown active',
      initiatedByUid: json['initiatedByUid'] as String? ?? json['initiated_by_uid'] as String?,
      initiatedAt: json['initiatedAt'] != null
          ? DateTime.parse(json['initiatedAt'] as String)
          : (json['initiated_at'] != null ? DateTime.parse(json['initiated_at'] as String) : DateTime.now()),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : (json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'lockdownId': lockdownId,
    'tenantId': tenantId,
    'isLocked': isLocked,
    'reason': reason,
    if (initiatedByUid != null) 'initiatedByUid': initiatedByUid,
    'initiatedAt': initiatedAt.toIso8601String(),
    if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
  };
}
