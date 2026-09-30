import 'package:flutter/foundation.dart';
import '../models/platform_models.dart';

/// Sealed state hierarchy for Platform Admin Console and System Health.
@immutable
sealed class PlatformState {
  const PlatformState();
}

/// Loading state while fetching platform metrics and cluster status.
class PlatformLoading extends PlatformState {
  const PlatformLoading();
}

/// Loaded state containing complete telemetry across all 5 platform administration domains.
class PlatformLoaded extends PlatformState {
  final List<SystemHealthNode> healthNodes;
  final List<PlatformTenantItem> tenants;
  final List<PaymentProviderConfig> providers;
  final List<SecurityAuditEvent> securityEvents;
  final PlatformCircuitBreakerState circuitBreaker;

  // Selected details
  final PlatformTenantItem? selectedTenant;
  final SecurityAuditEvent? selectedSecurityEvent;

  // Navigation and filter parameters
  final int activeTab; // 0: Health, 1: Tenants, 2: Providers, 3: Security, 4: CircuitBreaker
  final String searchQuery;
  final String statusFilter; // ALL, HEALTHY, DEGRADED, UNAVAILABLE

  // Action status
  final bool isExecutingAction;
  final String? actionFeedback;
  final bool isActionSuccess;

  const PlatformLoaded({
    required this.healthNodes,
    required this.tenants,
    required this.providers,
    required this.securityEvents,
    required this.circuitBreaker,
    this.selectedTenant,
    this.selectedSecurityEvent,
    this.activeTab = 0,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.isExecutingAction = false,
    this.actionFeedback,
    this.isActionSuccess = true,
  });

  /// Filtered health nodes based on search and status.
  List<SystemHealthNode> get filteredHealthNodes {
    return healthNodes.where((node) {
      final matchesSearch = searchQuery.isEmpty ||
          node.serviceName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          node.nodeId.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus = statusFilter == 'ALL' ||
          node.status.displayName.toUpperCase() == statusFilter.toUpperCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  /// Filtered tenants list.
  List<PlatformTenantItem> get filteredTenants {
    return tenants.where((tenant) {
      if (searchQuery.isEmpty) return true;
      return tenant.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          tenant.tenantId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          tenant.charterNumber.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  /// Filtered security events.
  List<SecurityAuditEvent> get filteredSecurityEvents {
    return securityEvents.where((event) {
      if (searchQuery.isEmpty) return true;
      return event.eventId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          event.eventType.toLowerCase().contains(searchQuery.toLowerCase()) ||
          event.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          event.actorId.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  /// Overall platform status (HEALTHY, DEGRADED, UNAVAILABLE).
  SubsystemHealthStatus get overallPlatformStatus {
    if (healthNodes.any((n) => n.status == SubsystemHealthStatus.unavailable)) {
      return SubsystemHealthStatus.unavailable;
    }
    if (healthNodes.any((n) => n.status == SubsystemHealthStatus.degraded)) {
      return SubsystemHealthStatus.degraded;
    }
    return SubsystemHealthStatus.healthy;
  }

  PlatformLoaded copyWith({
    List<SystemHealthNode>? healthNodes,
    List<PlatformTenantItem>? tenants,
    List<PaymentProviderConfig>? providers,
    List<SecurityAuditEvent>? securityEvents,
    PlatformCircuitBreakerState? circuitBreaker,
    PlatformTenantItem? Function()? selectedTenant,
    SecurityAuditEvent? Function()? selectedSecurityEvent,
    int? activeTab,
    String? searchQuery,
    String? statusFilter,
    bool? isExecutingAction,
    String? Function()? actionFeedback,
    bool? isActionSuccess,
  }) {
    return PlatformLoaded(
      healthNodes: healthNodes ?? this.healthNodes,
      tenants: tenants ?? this.tenants,
      providers: providers ?? this.providers,
      securityEvents: securityEvents ?? this.securityEvents,
      circuitBreaker: circuitBreaker ?? this.circuitBreaker,
      selectedTenant: selectedTenant != null ? selectedTenant() : this.selectedTenant,
      selectedSecurityEvent: selectedSecurityEvent != null ? selectedSecurityEvent() : this.selectedSecurityEvent,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      isExecutingAction: isExecutingAction ?? this.isExecutingAction,
      actionFeedback: actionFeedback != null ? actionFeedback() : this.actionFeedback,
      isActionSuccess: isActionSuccess ?? this.isActionSuccess,
    );
  }
}

/// Error state if cluster telemetry cannot be retrieved.
class PlatformError extends PlatformState {
  final String errorMessage;
  final String correlationId;

  const PlatformError({
    required this.errorMessage,
    required this.correlationId,
  });
}
