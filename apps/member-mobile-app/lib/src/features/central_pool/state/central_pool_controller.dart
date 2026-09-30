// Central Pool State Controller (Step 8/13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Manages client presentation state for matching, financial reads, and projections.
// - Invariant: Zero financial or allocation logic on client.
// - Adapts server-authoritative responses and provides reactive lockdown handling.

import 'package:flutter/foundation.dart';
import '../data/central_pool_repository.dart';
import '../models/contribution_tier_model.dart';
import '../models/fee_model.dart';
import '../models/participation_request_model.dart';
import '../models/candidate_allocation_model.dart';
import '../models/financial_obligation_model.dart';
import '../models/contribution_schedule_model.dart';
import '../models/contribution_event_model.dart';
import '../models/payout_entitlement_model.dart';
import '../models/period_projection_models.dart';
import '../models/system_lockdown_model.dart';
import '../services/idempotency_service.dart';

enum CentralPoolFlowStep {
  form,
  matching,
  candidateList,
  confirmed,
  error,
}

class CentralPoolController extends ChangeNotifier {
  final CentralPoolRepository repository;
  final IdempotencyService idempotencyService;
  final String tenantId;
  final String memberId;

  // Matching Flow State
  CentralPoolFlowStep step = CentralPoolFlowStep.form;
  bool isLoading = false;
  String? errorMessage;

  ParticipationRequestModel? currentRequest;
  List<CandidateAllocationModel> candidates = [];
  CandidateAllocationModel? selectedCandidate;
  ConfirmationResultModel? confirmationResult;

  // Fee & Tier State
  FeeConfigModel? feeConfig = FeeConfigModel.standardDefault();
  ContributionTierModel? selectedTier;

  // Financial Read Models State
  FinancialObligationModel? financialObligation;
  ContributionScheduleModel? contributionSchedule;
  List<ContributionEventModel> contributionEvents = [];
  PayoutEntitlementModel? payoutEntitlement;

  // Period Projections State
  CyclePeriodProjectionModel? cycleProjection;
  MemberPeriodProjectionModel? memberTimeline;

  // System Lockdown State
  SystemLockdownModel? lockdown;
  bool isSystemLocked = false;

  CentralPoolController({
    required this.repository,
    IdempotencyService? idempotencyService,
    required this.tenantId,
    required this.memberId,
    this.feeConfig,
  }) : idempotencyService = idempotencyService ?? IdempotencyService();

  // ===========================================================================
  // 1. SYSTEM LOCKDOWN LISTENER / REFRESH
  // ===========================================================================
  Future<void> checkSystemLockdown() async {
    try {
      final res = await repository.getSystemLockdown(tenantId: tenantId, memberId: memberId);
      lockdown = res;
      isSystemLocked = res?.isLocked ?? false;
      notifyListeners();
    } catch (_) {
      // Non-blocking for offline / test mocks
    }
  }

  void setSystemLockdown(bool locked, {String? reason}) {
    isSystemLocked = locked;
    if (locked) {
      lockdown = SystemLockdownModel(
        lockdownId: 'lock_manual',
        tenantId: tenantId,
        isLocked: true,
        reason: reason ?? 'System operations are temporarily paused by administration.',
        initiatedAt: DateTime.now(),
      );
    } else {
      lockdown = null;
    }
    notifyListeners();
  }

  // ===========================================================================
  // 2. SUBMIT PARTICIPATION REQUEST (Canonical Callable #1)
  // ===========================================================================
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
    if (isSystemLocked) {
      errorMessage = 'Cannot submit request: System lockdown is currently active.';
      step = CentralPoolFlowStep.error;
      notifyListeners();
      return;
    }

    if (durationPeriods < 2 || durationPeriods > 12) {
      errorMessage = 'Invalid duration: must be between 2 and 12 periods.';
      step = CentralPoolFlowStep.error;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final actualIdempotencyKey = idempotencyKey ?? idempotencyService.generateKey(prefix: 'idem_sub');
    final actualClientReqId = clientRequestId ?? idempotencyService.generateClientRequestId(memberId);

    try {
      currentRequest = await repository.submitRequest(
        tenantId: tenantId,
        memberId: memberId,
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
      step = CentralPoolFlowStep.matching;
    } catch (e) {
      errorMessage = e.toString();
      step = CentralPoolFlowStep.error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 3. LOAD CANDIDATES (Canonical Callable #2)
  // ===========================================================================
  Future<void> loadCandidates() async {
    if (currentRequest == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      candidates = await repository.getCandidates(
        tenantId: tenantId,
        memberId: memberId,
        requestId: currentRequest!.requestId,
      );
      step = CentralPoolFlowStep.candidateList;
    } catch (e) {
      errorMessage = e.toString();
      step = CentralPoolFlowStep.error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 4. SELECT CANDIDATE & CONFIRM (Canonical Callable #3)
  // ===========================================================================
  Future<void> confirmSelection({
    required CandidateAllocationModel candidate,
    String? idempotencyKey,
  }) async {
    if (isSystemLocked) {
      errorMessage = 'Cannot confirm allocation: System lockdown is currently active.';
      step = CentralPoolFlowStep.error;
      notifyListeners();
      return;
    }

    if (currentRequest == null) return;
    isLoading = true;
    errorMessage = null;
    selectedCandidate = candidate;
    notifyListeners();

    final actualIdempotencyKey = idempotencyKey ?? idempotencyService.generateKey(prefix: 'idem_sel');

    try {
      confirmationResult = await repository.selectCandidate(
        tenantId: tenantId,
        memberId: memberId,
        requestId: currentRequest!.requestId,
        candidate: candidate,
        idempotencyKey: actualIdempotencyKey,
      );
      step = CentralPoolFlowStep.confirmed;
    } catch (e) {
      errorMessage = e.toString();
      step = CentralPoolFlowStep.error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 5. LOAD FINANCIAL OBLIGATION (Canonical Callable #4)
  // ===========================================================================
  Future<void> loadFinancialObligation({String? obligationId, String? allocationId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      financialObligation = await repository.getFinancialObligation(
        tenantId: tenantId,
        memberId: memberId,
        obligationId: obligationId,
        allocationId: allocationId,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 6. LOAD CONTRIBUTION SCHEDULE (Canonical Callable #5)
  // ===========================================================================
  Future<void> loadContributionSchedule({String? scheduleId, String? obligationId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      contributionSchedule = await repository.getContributionSchedule(
        tenantId: tenantId,
        memberId: memberId,
        scheduleId: scheduleId,
        obligationId: obligationId,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 7. LOAD CONTRIBUTION EVENTS (Canonical Callable #6)
  // ===========================================================================
  Future<void> loadContributionEvents({required String obligationId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      contributionEvents = await repository.getContributionEvents(
        tenantId: tenantId,
        memberId: memberId,
        obligationId: obligationId,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 8. LOAD PAYOUT ENTITLEMENT (Canonical Callable #7)
  // ===========================================================================
  Future<void> loadPayoutEntitlement({String? entitlementId, String? allocationId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      payoutEntitlement = await repository.getPayoutEntitlement(
        tenantId: tenantId,
        memberId: memberId,
        entitlementId: entitlementId,
        allocationId: allocationId,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 9. LOAD CYCLE PERIOD PROJECTION (Canonical Callable #8)
  // ===========================================================================
  Future<void> loadCyclePeriodProjection({required String unitId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      cycleProjection = await repository.getCyclePeriodProjection(
        tenantId: tenantId,
        memberId: memberId,
        unitId: unitId,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 10. LOAD MEMBER PERIOD TIMELINE (Canonical Callable #9)
  // ===========================================================================
  Future<void> loadMemberPeriodTimeline({required String allocationId, int? periodNumber}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      memberTimeline = await repository.getMemberPeriodTimeline(
        tenantId: tenantId,
        memberId: memberId,
        allocationId: allocationId,
        periodNumber: periodNumber,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Reset Flow
  void reset() {
    step = CentralPoolFlowStep.form;
    isLoading = false;
    errorMessage = null;
    currentRequest = null;
    candidates = [];
    selectedCandidate = null;
    confirmationResult = null;
    selectedTier = null;
    notifyListeners();
  }
}
