import '../models/member_dashboard_models.dart';

/// Base sealed state for Member Dashboard.
abstract class DashboardState {
  const DashboardState();
}

/// Initial or active loading state with skeleton placeholders.
class DashboardLoading extends DashboardState {
  final String message;

  const DashboardLoading({this.message = 'Loading live pool data...'});
}

/// Empty state when member is not currently assigned to any active cycle.
class DashboardEmpty extends DashboardState {
  final String title;
  final String message;

  const DashboardEmpty({
    this.title = 'No Active Cooperative Cycle',
    this.message = 'You are not currently enrolled in an active rotating pool cycle. Explore available cooperative cycles or contact your organization administrator to be assigned a rotation slot.',
  });
}

/// Fully populated loaded state.
class DashboardLoaded extends DashboardState {
  final MemberSummary summary;
  final LiveCyclePoolState poolState;
  final MemberFinancialSummary financialSummary;
  final List<DashboardAlert> alerts;
  final bool isRefreshing;
  final DateTime lastUpdated;

  const DashboardLoaded({
    required this.summary,
    required this.poolState,
    required this.financialSummary,
    this.alerts = const [],
    this.isRefreshing = false,
    required this.lastUpdated,
  });

  DashboardLoaded copyWith({
    MemberSummary? summary,
    LiveCyclePoolState? poolState,
    MemberFinancialSummary? financialSummary,
    List<DashboardAlert>? alerts,
    bool? isRefreshing,
    DateTime? lastUpdated,
  }) {
    return DashboardLoaded(
      summary: summary ?? this.summary,
      poolState: poolState ?? this.poolState,
      financialSummary: financialSummary ?? this.financialSummary,
      alerts: alerts ?? this.alerts,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Error state when network or invariant failures occur.
class DashboardError extends DashboardState {
  final String errorMessage;
  final String? correlationId;
  final bool isRetryable;

  const DashboardError({
    required this.errorMessage,
    this.correlationId,
    this.isRetryable = true,
  });
}
