// Central Pool Riverpod Providers (Step 13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - State management providers adhering strictly to Riverpod architecture.
// - Provides reactive state for financial read models, period projections, matching flow, and system lockdown.
// - Invariant: Zero financial or allocation logic on client. All mathematical and financial truth is server-authoritative.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/central_pool_repository.dart';
import '../models/participation_request_model.dart';
import '../models/candidate_allocation_model.dart';
import '../models/financial_obligation_model.dart';
import '../models/contribution_schedule_model.dart';
import '../models/contribution_event_model.dart';
import '../models/payout_entitlement_model.dart';
import '../models/period_projection_models.dart';
import '../models/system_lockdown_model.dart';
import '../services/idempotency_service.dart';

// =============================================================================
// 1. REPOSITORY & SERVICE PROVIDERS
// =============================================================================

/// Canonical Production Cloud Functions Base URL for central-pool-production.
const String kCanonicalProductionBaseUrl =
    'https://us-central1-central-pool-production.cloudfunctions.net';

/// Canonical Local Development Base URL.
const String kCanonicalDevelopmentBaseUrl = 'http://localhost:8080';

/// Authoritative Base URL resolution logic.
/// INVARIANT: If isRelease is true (kReleaseMode), kCanonicalProductionBaseUrl is ALWAYS returned.
/// No --dart-define=CENTRAL_POOL_API_URL value may override a Release build.
String resolveCentralPoolBaseUrl({
  bool isRelease = kReleaseMode,
  String envUrl = const String.fromEnvironment('CENTRAL_POOL_API_URL', defaultValue: ''),
}) {
  if (isRelease) {
    return kCanonicalProductionBaseUrl;
  }
  if (envUrl.isNotEmpty) {
    return envUrl;
  }
  return kCanonicalDevelopmentBaseUrl;
}

/// Configurable Base URL for Central Pool API endpoints.
final centralPoolBaseUrlProvider = Provider<String>((ref) {
  return resolveCentralPoolBaseUrl();
});

/// Central Pool Client Repository Provider.
final centralPoolRepositoryProvider = Provider<CentralPoolRepository>((ref) {
  final baseUrl = ref.watch(centralPoolBaseUrlProvider);
  return CentralPoolRepository(baseUrl: baseUrl);
});

/// Client Idempotency Service Provider.
final idempotencyServiceProvider = Provider<IdempotencyService>((ref) {
  return IdempotencyService();
});

// =============================================================================
// 2. TENANT & MEMBER CONTEXT PROVIDERS
// =============================================================================

class CentralPoolMemberContext {
  final String tenantId;
  final String memberId;

  const CentralPoolMemberContext({
    required this.tenantId,
    required this.memberId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CentralPoolMemberContext &&
          runtimeType == other.runtimeType &&
          tenantId == other.tenantId &&
          memberId == other.memberId;

  @override
  int get hashCode => tenantId.hashCode ^ memberId.hashCode;
}

class CentralPoolContextNotifier extends Notifier<CentralPoolMemberContext> {
  @override
  CentralPoolMemberContext build() {
    return const CentralPoolMemberContext(tenantId: 'tenant_default', memberId: 'mem_default');
  }

  void updateContext({required String tenantId, required String memberId}) {
    state = CentralPoolMemberContext(tenantId: tenantId, memberId: memberId);
  }
}

final centralPoolContextProvider = NotifierProvider<CentralPoolContextNotifier, CentralPoolMemberContext>(
  CentralPoolContextNotifier.new,
);

// =============================================================================
// 3. SYSTEM LOCKDOWN STATE & LISTENER PROVIDER
// =============================================================================

class SystemLockdownNotifier extends Notifier<SystemLockdownModel?> {
  @override
  SystemLockdownModel? build() {
    return null;
  }

  Future<void> refresh() async {
    final repo = ref.read(centralPoolRepositoryProvider);
    final ctx = ref.read(centralPoolContextProvider);
    try {
      final res = await repo.getSystemLockdown(
        tenantId: ctx.tenantId,
        memberId: ctx.memberId,
      );
      state = res;
    } catch (_) {
      // Non-blocking for offline / test mocks
    }
  }

  void setLockdown(bool isLocked, {String? reason}) {
    final ctx = ref.read(centralPoolContextProvider);
    if (isLocked) {
      state = SystemLockdownModel(
        lockdownId: 'lock_manual',
        tenantId: ctx.tenantId,
        isLocked: true,
        reason: reason ?? 'System operations are temporarily paused by administration.',
        initiatedAt: DateTime.now(),
      );
    } else {
      state = null;
    }
  }
}

final systemLockdownProvider = NotifierProvider<SystemLockdownNotifier, SystemLockdownModel?>(
  SystemLockdownNotifier.new,
);

final isSystemLockedProvider = Provider<bool>((ref) {
  final lockdown = ref.watch(systemLockdownProvider);
  return lockdown?.isLocked ?? false;
});

// =============================================================================
// 4. FINANCIAL FOUNDATION READ MODEL PROVIDERS (Canonical Callables #4 - #7)
// =============================================================================

/// Financial Obligation Query Parameter Record
class ObligationQueryParams {
  final String? obligationId;
  final String? allocationId;

  const ObligationQueryParams({this.obligationId, this.allocationId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObligationQueryParams &&
          obligationId == other.obligationId &&
          allocationId == other.allocationId;

  @override
  int get hashCode => (obligationId?.hashCode ?? 0) ^ (allocationId?.hashCode ?? 0);
}

/// Financial Obligation Provider (Canonical Callable #4)
final financialObligationFamily = FutureProvider.family<FinancialObligationModel, ObligationQueryParams>((ref, params) async {
  final repo = ref.watch(centralPoolRepositoryProvider);
  final ctx = ref.watch(centralPoolContextProvider);

  return await repo.getFinancialObligation(
    tenantId: ctx.tenantId,
    memberId: ctx.memberId,
    obligationId: params.obligationId,
    allocationId: params.allocationId,
  );
});

/// Contribution Schedule Query Parameter Record
class ScheduleQueryParams {
  final String? scheduleId;
  final String? obligationId;

  const ScheduleQueryParams({this.scheduleId, this.obligationId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleQueryParams &&
          scheduleId == other.scheduleId &&
          obligationId == other.obligationId;

  @override
  int get hashCode => (scheduleId?.hashCode ?? 0) ^ (obligationId?.hashCode ?? 0);
}

/// Contribution Schedule Provider (Canonical Callable #5)
final contributionScheduleFamily = FutureProvider.family<ContributionScheduleModel, ScheduleQueryParams>((ref, params) async {
  final repo = ref.watch(centralPoolRepositoryProvider);
  final ctx = ref.watch(centralPoolContextProvider);

  return await repo.getContributionSchedule(
    tenantId: ctx.tenantId,
    memberId: ctx.memberId,
    scheduleId: params.scheduleId,
    obligationId: params.obligationId,
  );
});

/// Contribution Events Provider (Canonical Callable #6)
final contributionEventsFamily = FutureProvider.family<List<ContributionEventModel>, String>((ref, obligationId) async {
  final repo = ref.watch(centralPoolRepositoryProvider);
  final ctx = ref.watch(centralPoolContextProvider);

  return await repo.getContributionEvents(
    tenantId: ctx.tenantId,
    memberId: ctx.memberId,
    obligationId: obligationId,
  );
});

/// Payout Entitlement Query Parameter Record
class EntitlementQueryParams {
  final String? entitlementId;
  final String? allocationId;

  const EntitlementQueryParams({this.entitlementId, this.allocationId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntitlementQueryParams &&
          entitlementId == other.entitlementId &&
          allocationId == other.allocationId;

  @override
  int get hashCode => (entitlementId?.hashCode ?? 0) ^ (allocationId?.hashCode ?? 0);
}

/// Payout Entitlement Provider (Canonical Callable #7)
final payoutEntitlementFamily = FutureProvider.family<PayoutEntitlementModel, EntitlementQueryParams>((ref, params) async {
  final repo = ref.watch(centralPoolRepositoryProvider);
  final ctx = ref.watch(centralPoolContextProvider);

  return await repo.getPayoutEntitlement(
    tenantId: ctx.tenantId,
    memberId: ctx.memberId,
    entitlementId: params.entitlementId,
    allocationId: params.allocationId,
  );
});

// =============================================================================
// 5. PERIOD PROJECTION READ MODEL PROVIDERS (Canonical Callables #8 & #9)
// =============================================================================

/// Cycle Period Projection Provider (Canonical Callable #8)
final cyclePeriodProjectionFamily = FutureProvider.family<CyclePeriodProjectionModel, String>((ref, unitId) async {
  final repo = ref.watch(centralPoolRepositoryProvider);
  final ctx = ref.watch(centralPoolContextProvider);

  return await repo.getCyclePeriodProjection(
    tenantId: ctx.tenantId,
    memberId: ctx.memberId,
    unitId: unitId,
  );
});

/// Member Period Timeline Query Parameter Record
class MemberTimelineQueryParams {
  final String allocationId;
  final int? periodNumber;

  const MemberTimelineQueryParams({required this.allocationId, this.periodNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberTimelineQueryParams &&
          allocationId == other.allocationId &&
          periodNumber == other.periodNumber;

  @override
  int get hashCode => allocationId.hashCode ^ (periodNumber?.hashCode ?? 0);
}

/// Member Period Timeline Provider (Canonical Callable #9)
final memberPeriodTimelineFamily = FutureProvider.family<MemberPeriodProjectionModel, MemberTimelineQueryParams>((ref, params) async {
  final repo = ref.watch(centralPoolRepositoryProvider);
  final ctx = ref.watch(centralPoolContextProvider);

  return await repo.getMemberPeriodTimeline(
    tenantId: ctx.tenantId,
    memberId: ctx.memberId,
    allocationId: params.allocationId,
    periodNumber: params.periodNumber,
  );
});

// =============================================================================
// 6. MATCHING & CONFIRMATION FLOW STATE & NOTIFIER (Canonical Callables #1 - #3)
// =============================================================================

enum MatchingFlowStep {
  form,
  matching,
  candidateList,
  confirmed,
  error,
}

class CentralPoolFlowState {
  final MatchingFlowStep step;
  final bool isLoading;
  final String? errorMessage;
  final ParticipationRequestModel? currentRequest;
  final List<CandidateAllocationModel> candidates;
  final CandidateAllocationModel? selectedCandidate;
  final ConfirmationResultModel? confirmationResult;

  const CentralPoolFlowState({
    this.step = MatchingFlowStep.form,
    this.isLoading = false,
    this.errorMessage,
    this.currentRequest,
    this.candidates = const [],
    this.selectedCandidate,
    this.confirmationResult,
  });

  CentralPoolFlowState copyWith({
    MatchingFlowStep? step,
    bool? isLoading,
    String? errorMessage,
    ParticipationRequestModel? currentRequest,
    List<CandidateAllocationModel>? candidates,
    CandidateAllocationModel? selectedCandidate,
    ConfirmationResultModel? confirmationResult,
    bool clearError = false,
  }) {
    return CentralPoolFlowState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentRequest: currentRequest ?? this.currentRequest,
      candidates: candidates ?? this.candidates,
      selectedCandidate: selectedCandidate ?? this.selectedCandidate,
      confirmationResult: confirmationResult ?? this.confirmationResult,
    );
  }
}

class CentralPoolFlowNotifier extends Notifier<CentralPoolFlowState> {
  @override
  CentralPoolFlowState build() {
    return const CentralPoolFlowState();
  }

  Future<void> submitParticipationRequest({
    required int monthlyContributionMinor,
    required int durationPeriods,
    required int preferredPayoutPeriod,
    required int payoutFlexibilityWindow,
    required String currency,
    String? idempotencyKey,
    String? clientRequestId,
    String? tierId,
    String? tierDisplayName,
  }) async {
    final isLocked = ref.read(isSystemLockedProvider);
    if (isLocked) {
      state = state.copyWith(
        step: MatchingFlowStep.error,
        errorMessage: 'Cannot submit request: System lockdown is currently active.',
      );
      return;
    }

    if (durationPeriods < 2 || durationPeriods > 12) {
      state = state.copyWith(
        step: MatchingFlowStep.error,
        errorMessage: 'Invalid duration: must be between 2 and 12 periods.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(centralPoolRepositoryProvider);
    final idempotencyService = ref.read(idempotencyServiceProvider);
    final ctx = ref.read(centralPoolContextProvider);
    final actualIdempotencyKey = idempotencyKey ?? idempotencyService.generateKey(prefix: 'idem_sub');
    final actualClientReqId = clientRequestId ?? idempotencyService.generateClientRequestId(ctx.memberId);

    try {
      final req = await repo.submitRequest(
        tenantId: ctx.tenantId,
        memberId: ctx.memberId,
        monthlyContributionMinor: monthlyContributionMinor,
        durationPeriods: durationPeriods,
        preferredPayoutPeriod: preferredPayoutPeriod,
        payoutFlexibilityWindow: payoutFlexibilityWindow,
        currency: currency,
        idempotencyKey: actualIdempotencyKey,
        clientRequestId: actualClientReqId,
        tierId: tierId,
        tierDisplayName: tierDisplayName,
      );
      state = state.copyWith(
        isLoading: false,
        step: MatchingFlowStep.matching,
        currentRequest: req,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        step: MatchingFlowStep.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadCandidates() async {
    if (state.currentRequest == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(centralPoolRepositoryProvider);
    final ctx = ref.read(centralPoolContextProvider);

    try {
      final candidates = await repo.getCandidates(
        tenantId: ctx.tenantId,
        memberId: ctx.memberId,
        requestId: state.currentRequest!.requestId,
      );
      state = state.copyWith(
        isLoading: false,
        step: MatchingFlowStep.candidateList,
        candidates: candidates,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        step: MatchingFlowStep.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> confirmSelection({
    required CandidateAllocationModel candidate,
    String? idempotencyKey,
  }) async {
    final isLocked = ref.read(isSystemLockedProvider);
    if (isLocked) {
      state = state.copyWith(
        step: MatchingFlowStep.error,
        errorMessage: 'Cannot confirm allocation: System lockdown is currently active.',
      );
      return;
    }

    if (state.currentRequest == null) return;
    state = state.copyWith(
      isLoading: true,
      selectedCandidate: candidate,
      clearError: true,
    );
    final repo = ref.read(centralPoolRepositoryProvider);
    final idempotencyService = ref.read(idempotencyServiceProvider);
    final ctx = ref.read(centralPoolContextProvider);
    final actualIdempotencyKey = idempotencyKey ?? idempotencyService.generateKey(prefix: 'idem_sel');

    try {
      final result = await repo.selectCandidate(
        tenantId: ctx.tenantId,
        memberId: ctx.memberId,
        requestId: state.currentRequest!.requestId,
        candidate: candidate,
        idempotencyKey: actualIdempotencyKey,
      );
      state = state.copyWith(
        isLoading: false,
        step: MatchingFlowStep.confirmed,
        confirmationResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        step: MatchingFlowStep.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const CentralPoolFlowState();
  }
}

final centralPoolFlowProvider = NotifierProvider<CentralPoolFlowNotifier, CentralPoolFlowState>(
  CentralPoolFlowNotifier.new,
);
