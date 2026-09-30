import 'package:flutter/foundation.dart';

/// Health status enum for platform microservices and infrastructure components.
enum SubsystemHealthStatus {
  healthy,
  degraded,
  unavailable,
  unknown;

  String get displayName {
    switch (this) {
      case SubsystemHealthStatus.healthy:
        return 'HEALTHY';
      case SubsystemHealthStatus.degraded:
        return 'DEGRADED';
      case SubsystemHealthStatus.unavailable:
        return 'UNAVAILABLE';
      case SubsystemHealthStatus.unknown:
        return 'UNKNOWN';
    }
  }

  static SubsystemHealthStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'HEALTHY':
      case 'UP':
      case 'READY':
        return SubsystemHealthStatus.healthy;
      case 'DEGRADED':
      case 'WARN':
        return SubsystemHealthStatus.degraded;
      case 'UNAVAILABLE':
      case 'DOWN':
      case 'CRITICAL':
        return SubsystemHealthStatus.unavailable;
      default:
        return SubsystemHealthStatus.unknown;
    }
  }
}

/// Screen 36: Infrastructure microservice or component health node.
@immutable
class SystemHealthNode {
  final String nodeId;
  final String serviceName;
  final SubsystemHealthStatus status;
  final int latencyMs;
  final double uptimePercent;
  final DateTime lastChecked;
  final int errorCount;
  final String details;

  const SystemHealthNode({
    required this.nodeId,
    required this.serviceName,
    required this.status,
    required this.latencyMs,
    required this.uptimePercent,
    required this.lastChecked,
    required this.errorCount,
    required this.details,
  });

  factory SystemHealthNode.fromJson(Map<String, dynamic> json) {
    return SystemHealthNode(
      nodeId: json['node_id'] as String? ?? 'srv-001',
      serviceName: json['service_name'] as String? ?? 'Service',
      status: SubsystemHealthStatus.fromString(json['status'] as String?),
      latencyMs: (json['latency_ms'] as num?)?.toInt() ?? 12,
      uptimePercent: (json['uptime_percent'] as num?)?.toDouble() ?? 99.99,
      lastChecked: json['last_checked'] != null ? DateTime.parse(json['last_checked'] as String) : DateTime.now(),
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      details: json['details'] as String? ?? 'All cluster probes reporting normal.',
    );
  }
}

/// Screen 37: Multi-Tenant & Organization Registry Item.
@immutable
class PlatformTenantItem {
  final String tenantId;
  final String name;
  final String legalEntityName;
  final String charterNumber;
  final String status; // ACTIVE, SUSPENDED, PROVISIONING
  final int memberCount;
  final int reserveRatioBps; // e.g. 1500 = 15.0%
  final int totalCapitalMinor; // 64-bit integer cents (e.g. 50000000 = $500,000.00)
  final DateTime createdAt;
  final String isolationStatus; // ENFORCED_RLS, PROVISIONING

  const PlatformTenantItem({
    required this.tenantId,
    required this.name,
    required this.legalEntityName,
    required this.charterNumber,
    required this.status,
    required this.memberCount,
    required this.reserveRatioBps,
    required this.totalCapitalMinor,
    required this.createdAt,
    required this.isolationStatus,
  });

  factory PlatformTenantItem.fromJson(Map<String, dynamic> json) {
    return PlatformTenantItem(
      tenantId: json['tenant_id'] as String? ?? 'TENANT-000',
      name: json['name'] as String? ?? 'Cooperative Organization',
      legalEntityName: json['legal_entity_name'] as String? ?? 'Cooperative Legal Entity',
      charterNumber: json['charter_number'] as String? ?? 'NCUA-COOP-000',
      status: json['status'] as String? ?? 'ACTIVE',
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      reserveRatioBps: (json['reserve_ratio_bps'] as num?)?.toInt() ?? 1500,
      totalCapitalMinor: (json['total_capital_minor'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      isolationStatus: json['isolation_status'] as String? ?? 'ENFORCED_RLS',
    );
  }
}

/// Screen 38: Payment Provider & Rail Gateway Configuration.
@immutable
class PaymentProviderConfig {
  final String providerId;
  final String railName; // FedNow, RTP, ACH, Stripe
  final String displayName;
  final SubsystemHealthStatus status;
  final String webhookUrl;
  final int rateLimitPerSec;
  final int timeoutSeconds;
  final bool isSandboxSimMode;
  final String maskedApiKey;

  const PaymentProviderConfig({
    required this.providerId,
    required this.railName,
    required this.displayName,
    required this.status,
    required this.webhookUrl,
    required this.rateLimitPerSec,
    required this.timeoutSeconds,
    required this.isSandboxSimMode,
    required this.maskedApiKey,
  });

  factory PaymentProviderConfig.fromJson(Map<String, dynamic> json) {
    return PaymentProviderConfig(
      providerId: json['provider_id'] as String? ?? 'PROV-000',
      railName: json['rail_name'] as String? ?? 'FEDNOW',
      displayName: json['display_name'] as String? ?? 'Clearing Rail Gateway',
      status: SubsystemHealthStatus.fromString(json['status'] as String?),
      webhookUrl: json['webhook_url'] as String? ?? 'https://api.coopfinance.internal/v1/webhooks/clearing',
      rateLimitPerSec: (json['rate_limit_per_sec'] as num?)?.toInt() ?? 250,
      timeoutSeconds: (json['timeout_seconds'] as num?)?.toInt() ?? 5,
      isSandboxSimMode: json['is_sandbox_sim_mode'] as bool? ?? true,
      maskedApiKey: json['masked_api_key'] as String? ?? 'sk_live_••••••••••••8921',
    );
  }
}

/// Screen 39: Security Center & WORM Audit Trail Event.
@immutable
class SecurityAuditEvent {
  final String eventId;
  final String eventType;
  final String severity; // INFO, WARNING, CRITICAL
  final String actorId;
  final String actorRole;
  final String tenantId;
  final DateTime timestamp;
  final String description;
  final String correlationId;
  final String ipAddress;
  final bool isWormVerified;
  final String wormHash;

  const SecurityAuditEvent({
    required this.eventId,
    required this.eventType,
    required this.severity,
    required this.actorId,
    required this.actorRole,
    required this.tenantId,
    required this.timestamp,
    required this.description,
    required this.correlationId,
    required this.ipAddress,
    required this.isWormVerified,
    required this.wormHash,
  });

  factory SecurityAuditEvent.fromJson(Map<String, dynamic> json) {
    return SecurityAuditEvent(
      eventId: json['event_id'] as String? ?? 'SEC-EVT-000',
      eventType: json['event_type'] as String? ?? 'AUTH_LOGIN_SUCCESS',
      severity: json['severity'] as String? ?? 'INFO',
      actorId: json['actor_id'] as String? ?? 'usr-sys-admin-01',
      actorRole: json['actor_role'] as String? ?? 'platformAdmin',
      tenantId: json['tenant_id'] as String? ?? 'TENANT-GLOBAL',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
      description: json['description'] as String? ?? 'Security event logged.',
      correlationId: json['correlation_id'] as String? ?? 'CORR-SEC-000',
      ipAddress: json['ip_address'] as String? ?? '10.0.4.12',
      isWormVerified: json['is_worm_verified'] as bool? ?? true,
      wormHash: json['worm_hash'] as String? ?? 'SHA256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
    );
  }
}

/// Screen 40: Platform Emergency Circuit Breakers.
@immutable
class PlatformCircuitBreakerState {
  final bool isGlobalFreezeActive;
  final bool isPaymentClearingHalted;
  final bool isMaintenanceModeActive;
  final String? freezeTriggeredBy;
  final DateTime? freezeTriggeredAt;
  final String? freezeReason;
  final String correlationId;

  const PlatformCircuitBreakerState({
    required this.isGlobalFreezeActive,
    required this.isPaymentClearingHalted,
    required this.isMaintenanceModeActive,
    this.freezeTriggeredBy,
    this.freezeTriggeredAt,
    this.freezeReason,
    required this.correlationId,
  });

  factory PlatformCircuitBreakerState.fromJson(Map<String, dynamic> json) {
    return PlatformCircuitBreakerState(
      isGlobalFreezeActive: json['is_global_freeze_active'] as bool? ?? false,
      isPaymentClearingHalted: json['is_payment_clearing_halted'] as bool? ?? false,
      isMaintenanceModeActive: json['is_maintenance_mode_active'] as bool? ?? false,
      freezeTriggeredBy: json['freeze_triggered_by'] as String?,
      freezeTriggeredAt: json['freeze_triggered_at'] != null ? DateTime.parse(json['freeze_triggered_at'] as String) : null,
      freezeReason: json['freeze_reason'] as String?,
      correlationId: json['correlation_id'] as String? ?? 'CORR-BRK-INIT-001',
    );
  }
}
