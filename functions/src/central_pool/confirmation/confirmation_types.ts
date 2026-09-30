/**
 * Central Pool Step 5: Allocation Confirmation Type Definitions
 * Pure types for confirmation input parameters, results, and transactional payloads.
 */

export interface AllocationConfirmationInput {
  /** Mandatory tenant identifier */
  tenantId: string;

  /** Member user identifier requesting confirmation */
  memberUid: string;

  /** Authoritative Participation Request identifier */
  requestId: string;

  /** Provisional Allocation Candidate identifier */
  candidateId: string;

  /** Client-provided idempotency key for safely retryable confirmation */
  idempotencyKey: string;

  /** Optional evaluation timestamp for deterministic testing (defaults to server timestamp) */
  evaluationTimestamp?: string;
}

export interface AllocationConfirmationResult {
  /** Boolean indicating authoritative confirmation success */
  success: boolean;

  /** Derived confirmed allocation receipt identifier: 'alloc_' + SHA256(...) */
  allocationId: string;

  /** Bound Participation Request identifier */
  requestId: string;

  /** Tenant boundary */
  tenantId: string;

  /** Member user ID */
  memberUid: string;

  /** Authoritative Allocation Unit identifier */
  allocationUnitId: string;

  /** Authoritative occupied position slot in [1..N] */
  allocatedPosition: number;

  /** Primary payout period in [1..N] */
  payoutPeriod: number;

  /** Minor unit periodic contribution */
  contributionMinor: number;

  /** Cycle duration in periods */
  durationPeriods: number;

  /** Total entitlement minor units (E = N * C) */
  totalEntitlementMinor: number;

  /** Total pot minor units (TotalPot = N^2 * C) */
  totalPotMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Symmetrical allocation rule version */
  allocationRule: 'SYMMETRICAL_V1';

  /** Timestamp when authoritative confirmation was stamped */
  confirmedAt: string;

  /** Flag indicating if this was returned from a cached idempotent replay */
  isIdempotentReplay: boolean;

  /** Flag indicating if this confirmation completed unit capacity and transitioned it to COMMITTED_FULL */
  unitTransitionedToCommittedFull: boolean;
}
