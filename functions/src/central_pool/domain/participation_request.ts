/**
 * Central Pool Domain Entity: ParticipationRequest
 * Represents a member's authoritative participation intent in the Central Pool.
 */

import { ParticipationRequestState } from './domain_states';

export interface ParticipationRequest {
  /** Authoritative document ID: 'req_' + SHA256(tenantId + ':' + uid + ':' + clientSubmissionId) */
  requestId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member user ID owning this request */
  memberUid: string;

  /** Periodic contribution in safe integer minor units */
  contributionMinor: number;

  /** ISO 4217 Currency Code (e.g. 'USD', 'EGP') */
  currency: string;

  /** Cycle duration / member count N in [2..12] */
  durationPeriods: number;

  /** Optional preferred payout period in [1..N] */
  preferredPayoutPeriod?: number;

  /** Authoritative lifecycle state */
  status: ParticipationRequestState;

  /** Client deduplication ID */
  clientSubmissionId: string;

  /** Creation timestamp (ISO 8601 string or Date) */
  createdAt: string;

  /** Last update timestamp */
  updatedAt: string;

  /** Business-level request expiration (default 7 days from creation) */
  requestExpiresAt: string;

  /** Optimistic concurrency version */
  version: number;

  // Stamped upon confirmation:
  allocationUnitId?: string;
  allocatedPosition?: number;
  payoutPeriod?: number;
  confirmedAt?: string;
  revalidationFailureReason?: string;
}
