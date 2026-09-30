/**
 * Central Pool Step 8: Application Orchestration & Firebase API Boundary Types
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT (Step 8)
 *
 * PROVENANCE & SEMANTIC BOUNDARY:
 * - DTOs for server-authoritative application use cases.
 * - Enforces trusted authentication context extraction.
 * - Zero real-money movement, zero payment processing, zero settlement.
 */

import {
  ParticipationRequest,
  AllocationCandidate,
  ConfirmedAllocation,
  IdempotencyRecord,
} from '../domain';
import { MatchingResult } from '../matching/matching_types';
import { AllocationConfirmationResult } from '../confirmation/confirmation_types';
import {
  FinancialObligation,
  ContributionSchedule,
  ContributionEvent,
  PayoutEntitlement,
} from '../financial';
import {
  CyclePeriodProjection,
  MemberPeriodProjection,
  MemberPeriodDetail,
} from '../period/domain/period_types';

export type UserRole = 'MEMBER' | 'ADMIN' | 'FINOPS' | 'COMPLIANCE' | 'SECURITY' | 'AUDITOR';

/**
 * Authoritative authentication and tenant context extracted exclusively from verified Firebase Auth token.
 * Never trusted when supplied in raw request payload.
 */
export interface TrustedAuthContext {
  /** Authenticated user UID */
  uid: string;

  /** Authoritative tenant ID resolved from auth claims */
  tenantId: string;

  /** Role assigned in auth token claims */
  role: UserRole;

  /** Optional email if available */
  email?: string;
}

// =============================================================================
// USE CASE A: SUBMIT PARTICIPATION REQUEST
// =============================================================================

export interface SubmitParticipationRequestInput {
  /** Monthly / periodic contribution in integer minor units (e.g. cents) */
  contributionMinor: number;

  /** Cycle duration in months / periods N in [2..12] */
  durationPeriods: number;

  /** ISO 4217 Currency Code (e.g. 'USD', 'EGP') */
  currency: string;

  /** Optional target payout preference period in [1..durationPeriods] */
  payoutPreference?: number;

  /** Optional client request identifier (validated or generated) */
  clientRequestId?: string;

  /** Optional non-authoritative client metadata */
  metadata?: Record<string, unknown>;
}

export interface SubmitParticipationRequestResult {
  success: true;
  request: ParticipationRequest;
}

// =============================================================================
// USE CASE B: GET MATCHING CANDIDATES (ADVISORY DISCOVERY)
// =============================================================================

export interface GetMatchingCandidatesInput {
  /** Authoritative Participation Request ID owned by caller */
  requestId: string;

  /** Optional maximum candidates to return */
  maxCandidates?: number;
}

export interface GetMatchingCandidatesResult {
  requestId: string;
  tenantId: string;
  memberUid: string;
  compatibilityKey: string;
  candidates: AllocationCandidate[];
  totalCandidates: number;
}

// =============================================================================
// USE CASE C: SELECT CANDIDATE AND CONFIRM (ATOMIC TRANSACTION)
// =============================================================================

export interface SelectCandidateAndConfirmInput {
  /** Participation Request ID */
  requestId: string;

  /** Candidate ID selected by the member */
  candidateId: string;

  /** Client idempotency key */
  idempotencyKey: string;

  /** Optional evaluation timestamp override (for testing) */
  evaluationTimestamp?: string;
}

export interface SelectCandidateAndConfirmResult extends AllocationConfirmationResult {
  /** Associated financial obligation created upon confirmation */
  obligationId?: string;

  /** Associated contribution schedule ID */
  scheduleId?: string;

  /** Associated payout entitlement ID */
  entitlementId?: string;
}

// =============================================================================
// USE CASE D: FINANCIAL FOUNDATION READS
// =============================================================================

export interface GetFinancialObligationInput {
  /** Obligation ID or Allocation ID */
  obligationId?: string;
  allocationId?: string;
}

export interface GetFinancialObligationResult {
  obligation: FinancialObligation;
}

export interface GetContributionScheduleInput {
  /** Contribution Schedule ID or Obligation ID */
  scheduleId?: string;
  obligationId?: string;
}

export interface GetContributionScheduleResult {
  schedule: ContributionSchedule;
}

export interface GetContributionEventsInput {
  /** Authoritative Financial Obligation ID */
  obligationId: string;
}

export interface GetContributionEventsResult {
  obligationId: string;
  events: ContributionEvent[];
  totalEvents: number;
}

export interface GetPayoutEntitlementInput {
  /** Payout Entitlement ID or Allocation ID */
  entitlementId?: string;
  allocationId?: string;
}

export interface GetPayoutEntitlementResult {
  entitlement: PayoutEntitlement;
}

// =============================================================================
// USE CASE E: PERIOD PROJECTION READS
// =============================================================================

export interface GetCyclePeriodProjectionInput {
  /** Allocation Unit ID */
  unitId: string;
}

export interface GetCyclePeriodProjectionResult {
  projection: CyclePeriodProjection;
}

export interface GetMemberPeriodTimelineInput {
  /** Confirmed Allocation Receipt ID */
  allocationId: string;

  /** Optional specific period number query in [1..N] */
  periodNumber?: number;
}

export interface GetMemberPeriodTimelineResult {
  projection: MemberPeriodProjection;
  specificPeriod?: MemberPeriodDetail;
}
