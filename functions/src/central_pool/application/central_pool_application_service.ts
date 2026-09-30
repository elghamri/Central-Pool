/**
 * Central Pool Step 8: Central Pool Application Orchestration Service
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT (Step 8)
 *
 * PROVENANCE & SEMANTIC BOUNDARY:
 * - Server-authoritative application boundary over approved domain services.
 * - Enforces tenant isolation, trusted auth extraction, and member ownership.
 * - Zero real-money movement, zero payment processing, zero settlement.
 */

import { Firestore } from 'firebase-admin/firestore';
import {
  ParticipationRequest,
  getFinancialObligationPath,
  getContributionSchedulePath,
  getPayoutEntitlementPath,
  CONTRIBUTION_EVENTS_COLLECTION,
} from '../domain';
import {
  UnauthenticatedError,
  UnauthorizedAccessError,
} from './api_errors';
import {
  ParticipationRequestRepository,
  AllocationUnitRepository,
  AllocationPositionRepository,
  AllocationCandidateRepository,
  FirestoreParticipationRequestRepository,
  FirestoreAllocationUnitRepository,
  FirestoreAllocationPositionRepository,
  FirestoreAllocationCandidateRepository,
  TenantIsolationViolationError,
  EntityNotFoundError,
} from '../persistence';
import {
  validateMemberCount,
  validatePeriodicContribution,
  validatePeriodNumber,
} from '../math/math_validation';
import { validatePeriodCurrency } from '../period/domain/period_validation';
import { sha256Hex, computeCompatibilityKey } from '../matching/compatibility_key';
import { MatchingService } from '../matching/matching_service';
import { AllocationConfirmationService } from '../confirmation/confirmation_service';
import { ObligationGenerationService } from '../financial/services/obligation_generation_service';
import { PeriodProjectionService } from '../period/services/period_projection_service';
import {
  docToFinancialObligation,
  docToContributionSchedule,
  docToPayoutEntitlement,
  docToContributionEvent,
} from '../financial/dto';
import { computeObligationId, computeContributionScheduleId, computePayoutEntitlementId } from '../financial/identities';
import {
  TrustedAuthContext,
  SubmitParticipationRequestInput,
  SubmitParticipationRequestResult,
  GetMatchingCandidatesInput,
  GetMatchingCandidatesResult,
  SelectCandidateAndConfirmInput,
  SelectCandidateAndConfirmResult,
  GetFinancialObligationInput,
  GetFinancialObligationResult,
  GetContributionScheduleInput,
  GetContributionScheduleResult,
  GetContributionEventsInput,
  GetContributionEventsResult,
  GetPayoutEntitlementInput,
  GetPayoutEntitlementResult,
  GetCyclePeriodProjectionInput,
  GetCyclePeriodProjectionResult,
  GetMemberPeriodTimelineInput,
  GetMemberPeriodTimelineResult,
} from './application_types';

export function computeParticipationRequestId(
  tenantId: string,
  memberUid: string,
  clientSubmissionId: string
): string {
  return `req_${sha256Hex(`${tenantId}:${memberUid}:${clientSubmissionId}`)}`;
}

export class CentralPoolApplicationService {
  private readonly requestRepo: ParticipationRequestRepository;
  private readonly unitRepo: AllocationUnitRepository;
  private readonly positionRepo: AllocationPositionRepository;
  private readonly candidateRepo: AllocationCandidateRepository;
  private readonly matchingService: MatchingService;
  private readonly confirmationService: AllocationConfirmationService;
  private readonly obligationService: ObligationGenerationService;
  private readonly periodProjectionService: PeriodProjectionService;

  constructor(
    private readonly db: Firestore,
    dependencies?: {
      requestRepo?: ParticipationRequestRepository;
      unitRepo?: AllocationUnitRepository;
      positionRepo?: AllocationPositionRepository;
      candidateRepo?: AllocationCandidateRepository;
      matchingService?: MatchingService;
      confirmationService?: AllocationConfirmationService;
      obligationService?: ObligationGenerationService;
      periodProjectionService?: PeriodProjectionService;
    }
  ) {
    this.requestRepo = dependencies?.requestRepo ?? new FirestoreParticipationRequestRepository(db);
    this.unitRepo = dependencies?.unitRepo ?? new FirestoreAllocationUnitRepository(db);
    this.positionRepo = dependencies?.positionRepo ?? new FirestoreAllocationPositionRepository(db);
    this.candidateRepo = dependencies?.candidateRepo ?? new FirestoreAllocationCandidateRepository(db);
    this.matchingService = dependencies?.matchingService ?? new MatchingService(this.unitRepo, this.positionRepo, this.candidateRepo);
    this.confirmationService = dependencies?.confirmationService ?? new AllocationConfirmationService(db);
    this.obligationService = dependencies?.obligationService ?? new ObligationGenerationService(db);
    this.periodProjectionService = dependencies?.periodProjectionService ?? new PeriodProjectionService(db);
  }

  private validateAuthContext(auth: TrustedAuthContext): void {
    if (!auth || !auth.uid || typeof auth.uid !== 'string' || !auth.uid.trim()) {
      throw new UnauthenticatedError('User authentication UID is required');
    }
    if (!auth.tenantId || typeof auth.tenantId !== 'string' || !auth.tenantId.trim()) {
      throw new UnauthenticatedError('User tenant ID claim is required');
    }
  }

  // ===========================================================================
  // USE CASE A: SUBMIT PARTICIPATION REQUEST
  // ===========================================================================

  async submitParticipationRequest(
    auth: TrustedAuthContext,
    input: SubmitParticipationRequestInput
  ): Promise<SubmitParticipationRequestResult> {
    this.validateAuthContext(auth);
    const tenantId = auth.tenantId.trim();
    const memberUid = auth.uid.trim();

    // 1. Input & Mathematical Validations
    validateMemberCount(input.durationPeriods, true);
    validatePeriodicContribution(input.contributionMinor, input.durationPeriods);
    validatePeriodCurrency(input.currency);

    if (input.payoutPreference !== undefined) {
      validatePeriodNumber(input.payoutPreference, input.durationPeriods);
    }

    const nowIso = new Date().toISOString();
    const clientSubmissionId = input.clientRequestId?.trim() || `sub_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
    const requestId = computeParticipationRequestId(tenantId, memberUid, clientSubmissionId);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

    // 2. Build Authoritative ParticipationRequest Entity in SUBMITTED State
    const request: ParticipationRequest = {
      requestId,
      tenantId,
      memberUid,
      contributionMinor: input.contributionMinor,
      currency: input.currency.toUpperCase(),
      durationPeriods: input.durationPeriods,
      preferredPayoutPeriod: input.payoutPreference,
      status: 'SUBMITTED',
      clientSubmissionId,
      createdAt: nowIso,
      updatedAt: nowIso,
      requestExpiresAt: expiresAt,
      version: 1,
    };

    // 3. Persist Authoritative Request Entity
    await this.requestRepo.createSubmittedRequest(tenantId, request);

    return {
      success: true,
      request,
    };
  }

  // ===========================================================================
  // USE CASE B: GET MATCHING CANDIDATES (PROVISIONAL DISCOVERY)
  // ===========================================================================

  async getMatchingCandidates(
    auth: TrustedAuthContext,
    input: GetMatchingCandidatesInput
  ): Promise<GetMatchingCandidatesResult> {
    this.validateAuthContext(auth);
    const tenantId = auth.tenantId.trim();
    const requestId = input.requestId?.trim();

    if (!requestId) {
      throw new EntityNotFoundError('ParticipationRequest', 'missing requestId');
    }

    // 1. Load Request
    const request = await this.requestRepo.getRequest(tenantId, requestId);
    if (!request) {
      throw new EntityNotFoundError('ParticipationRequest', requestId);
    }

    // 2. Member Ownership Verification
    if (auth.role === 'MEMBER' && request.memberUid !== auth.uid) {
      throw new UnauthorizedAccessError(`member ${auth.uid} does not own request ${requestId}`);
    }

    // 3. Delegate Discovery to Step 4 Matching Service
    const matchingResult = await this.matchingService.findCandidatesForRequest(tenantId, request, {
      maxCandidates: input.maxCandidates,
    });

    if (matchingResult.candidates.length > 0 && request.status === 'SUBMITTED') {
      await this.requestRepo.updateRequestState(tenantId, request.requestId, 'SUBMITTED', 'AWAITING_SELECTION');
    }

    const compatibilityKey = computeCompatibilityKey({
      tenantId: request.tenantId,
      currency: request.currency,
      contributionMinor: request.contributionMinor,
      durationPeriods: request.durationPeriods,
      allocationRule: 'SYMMETRICAL_V1',
    });

    return {
      requestId: request.requestId,
      tenantId: request.tenantId,
      memberUid: request.memberUid,
      compatibilityKey,
      candidates: matchingResult.candidates,
      totalCandidates: matchingResult.candidates.length,
    };
  }

  // ===========================================================================
  // USE CASE C: SELECT CANDIDATE AND CONFIRM (ATOMIC TRANSACTION)
  // ===========================================================================

  async selectCandidateAndConfirm(
    auth: TrustedAuthContext,
    input: SelectCandidateAndConfirmInput
  ): Promise<SelectCandidateAndConfirmResult> {
    this.validateAuthContext(auth);
    const tenantId = auth.tenantId.trim();
    const memberUid = auth.uid.trim();

    if (!input.requestId || !input.requestId.trim()) {
      throw new EntityNotFoundError('ParticipationRequest', 'missing requestId');
    }
    if (!input.candidateId || !input.candidateId.trim()) {
      throw new EntityNotFoundError('AllocationCandidate', 'missing candidateId');
    }
    if (!input.idempotencyKey || !input.idempotencyKey.trim()) {
      throw new Error('idempotencyKey is required for confirmation');
    }

    // 1. Execute Step 5 Authoritative Confirmation Transaction
    const confirmationResult = await this.confirmationService.confirmAllocation({
      tenantId,
      memberUid,
      requestId: input.requestId.trim(),
      candidateId: input.candidateId.trim(),
      idempotencyKey: input.idempotencyKey.trim(),
      evaluationTimestamp: input.evaluationTimestamp,
    });

    // 2. Derive Step 6 Financial Records (Obligation, Schedule, Entitlement)
    const obligationResult = await this.obligationService.generateObligation({
      tenantId,
      memberUid,
      allocationId: confirmationResult.allocationId,
      allocationUnitId: confirmationResult.allocationUnitId,
      positionNumber: confirmationResult.allocatedPosition,
      contributionMinor: confirmationResult.contributionMinor,
      totalPeriods: confirmationResult.durationPeriods,
      currency: confirmationResult.currency,
      idempotencyKey: input.idempotencyKey.trim(),
      nowIso: confirmationResult.confirmedAt,
    });

    return {
      ...confirmationResult,
      obligationId: obligationResult.obligation.obligationId,
      scheduleId: obligationResult.contributionSchedule.scheduleId,
      entitlementId: obligationResult.payoutEntitlement.payoutEntitlementId,
    };
  }

  // ===========================================================================
  // USE CASE D: FINANCIAL FOUNDATION READS
  // ===========================================================================

  async getFinancialObligation(
    auth: TrustedAuthContext,
    input: GetFinancialObligationInput
  ): Promise<GetFinancialObligationResult> {
    this.validateAuthContext(auth);
    const tenantId = auth.tenantId.trim();

    let obligationId = input.obligationId?.trim();
    if (!obligationId && input.allocationId) {
      obligationId = computeObligationId(tenantId, input.allocationId.trim());
    }

    if (!obligationId) {
      throw new EntityNotFoundError('FinancialObligation', 'missing obligationId or allocationId');
    }

    const docRef = this.db.doc(getFinancialObligationPath(obligationId));
    const docSnap = await docRef.get();
    if (!docSnap.exists) {
      throw new EntityNotFoundError('FinancialObligation', obligationId);
    }

    const obligation = docToFinancialObligation(docSnap.data());
    if (obligation.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, obligation.tenantId, 'FinancialObligation');
    }
    if (auth.role === 'MEMBER' && obligation.memberUid !== auth.uid) {
      throw new UnauthorizedAccessError(`member ${auth.uid} does not own obligation ${obligationId}`);
    }

    return { obligation };
  }

  async getContributionSchedule(
    auth: TrustedAuthContext,
    input: GetContributionScheduleInput
  ): Promise<GetContributionScheduleResult> {
    this.validateAuthContext(auth);
    const tenantId = auth.tenantId.trim();

    let scheduleId = input.scheduleId?.trim();
    if (!scheduleId && input.obligationId) {
      scheduleId = computeContributionScheduleId(tenantId, input.obligationId.trim());
    }

    if (!scheduleId) {
      throw new EntityNotFoundError('ContributionSchedule', 'missing scheduleId or obligationId');
    }

    const docRef = this.db.doc(getContributionSchedulePath(scheduleId));
    const docSnap = await docRef.get();
    if (!docSnap.exists) {
      throw new EntityNotFoundError('ContributionSchedule', scheduleId);
    }

    const schedule = docToContributionSchedule(docSnap.data());
    if (schedule.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, schedule.tenantId, 'ContributionSchedule');
    }
    if (auth.role === 'MEMBER' && schedule.memberUid !== auth.uid) {
      throw new UnauthorizedAccessError(`member ${auth.uid} does not own schedule ${scheduleId}`);
    }

    return { schedule };
  }

  async getContributionEvents(
    auth: TrustedAuthContext,
    input: GetContributionEventsInput
  ): Promise<GetContributionEventsResult> {
    this.validateAuthContext(auth);
    const tenantId = auth.tenantId.trim();
    const obligationId = input.obligationId?.trim();

    if (!obligationId) {
      throw new EntityNotFoundError('ContributionEvent', 'missing obligationId');
    }

    // Verify parent obligation ownership first
    await this.getFinancialObligation(auth, { obligationId });

    const querySnap = await this.db
      .collection(CONTRIBUTION_EVENTS_COLLECTION)
      .where('tenantId', '==', tenantId)
      .where('obligationId', '==', obligationId)
      .get();

    const events = querySnap.docs.map((doc) => docToContributionEvent(doc.data()));
    return {
      obligationId,
      events,
      totalEvents: events.length,
    };
  }

  async getPayoutEntitlement(
    auth: TrustedAuthContext,
    input: GetPayoutEntitlementInput
  ): Promise<GetPayoutEntitlementResult> {
    this.validateAuthContext(auth);
    const tenantId = auth.tenantId.trim();

    let entitlementId = input.entitlementId?.trim();
    if (!entitlementId && input.allocationId) {
      entitlementId = computePayoutEntitlementId(tenantId, input.allocationId.trim());
    }

    if (!entitlementId) {
      throw new EntityNotFoundError('PayoutEntitlement', 'missing entitlementId or allocationId');
    }

    const docRef = this.db.doc(getPayoutEntitlementPath(entitlementId));
    const docSnap = await docRef.get();
    if (!docSnap.exists) {
      throw new EntityNotFoundError('PayoutEntitlement', entitlementId);
    }

    const entitlement = docToPayoutEntitlement(docSnap.data());
    if (entitlement.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, entitlement.tenantId, 'PayoutEntitlement');
    }
    if (auth.role === 'MEMBER' && entitlement.memberUid !== auth.uid) {
      throw new UnauthorizedAccessError(`member ${auth.uid} does not own entitlement ${entitlementId}`);
    }

    return { entitlement };
  }

  // ===========================================================================
  // USE CASE E: PERIOD PROJECTION READS
  // ===========================================================================

  async getCyclePeriodProjection(
    auth: TrustedAuthContext,
    input: GetCyclePeriodProjectionInput
  ): Promise<GetCyclePeriodProjectionResult> {
    this.validateAuthContext(auth);
    const tenantId = auth.tenantId.trim();
    const unitId = input.unitId?.trim();

    if (!unitId) {
      throw new EntityNotFoundError('AllocationUnit', 'missing unitId');
    }

    const projection = await this.periodProjectionService.getCyclePeriodProjection(tenantId, unitId, true);

    // Enforce member authorization: Member must be an authorized member in this unit
    if (auth.role === 'MEMBER') {
      if (!projection.authorizedMemberUids || !projection.authorizedMemberUids.includes(auth.uid)) {
        throw new UnauthorizedAccessError(`member ${auth.uid} is not authorized to read period projection for unit ${unitId}`);
      }
    }

    return { projection };
  }

  async getMemberPeriodTimeline(
    auth: TrustedAuthContext,
    input: GetMemberPeriodTimelineInput
  ): Promise<GetMemberPeriodTimelineResult> {
    this.validateAuthContext(auth);
    const tenantId = auth.tenantId.trim();
    const allocationId = input.allocationId?.trim();

    if (!allocationId) {
      throw new EntityNotFoundError('ConfirmedAllocation', 'missing allocationId');
    }

    const projection = await this.periodProjectionService.getMemberPeriodProjection(tenantId, auth.uid, allocationId, true);

    let specificPeriod = undefined;
    if (input.periodNumber !== undefined) {
      specificPeriod = await this.periodProjectionService.queryPeriodTimeline(tenantId, auth.uid, allocationId, input.periodNumber);
    }

    return {
      projection,
      specificPeriod,
    };
  }
}
