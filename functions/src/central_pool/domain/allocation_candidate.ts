/**
 * Central Pool Domain Entity: AllocationCandidate
 * Represents a provisional, ephemeral authorization artifact produced by matching evaluation.
 * Note: A candidate is NOT financial truth, creates NO positions, and creates NO obligations.
 */

export interface AllocationCandidate {
  /** Deterministic candidate ID: 'cand_' + SHA256(JCS(Payload)) */
  candidateId: string;

  /** Participation request ID bound to this candidate */
  requestId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member user ID receiving this candidate */
  memberUid: string;

  /** Proposed target Allocation Unit ID */
  allocationUnitId: string;

  /** Proposed position index in [1..N] */
  allocatedPosition: number;

  /** Proposed scheduled primary payout period in [1..N] */
  payoutPeriod: number;

  /** Periodic contribution amount in integer minor units */
  contributionMinor: number;

  /** Duration periods N in [2..12] */
  durationPeriods: number;

  /** Total member entitlement: E = N * C (calculated via calculateTotalEntitlement) */
  totalEntitlementMinor: number;

  /** Total lifecycle pot: TotalPot = N^2 * C (calculated via calculateTotalPot) */
  totalPotMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Frozen allocation rule */
  allocationRule: 'SYMMETRICAL_V1';

  /** Candidate issuance timestamp (RFC 3339 UTC) */
  issuedAt: string;

  /** Candidate authorization expiration timestamp (RFC 3339 UTC, default 300s TTL) */
  expiresAt: string;

  /** HMAC-SHA256 signature guaranteeing token authenticity */
  signature?: string;

  /** Explicit domain tag confirming this is a provisional artifact */
  isProvisional: true;
}
