/**
 * Central Pool Domain Entity: AllocationPosition
 * Represents an authoritative occupied allocation slot inside an Allocation Unit.
 * Stored at: /allocation_units/{unitId}/positions/{positionNumber}
 */

export interface AllocationPosition {
  /** Allocation Unit ID owning this position */
  unitId: string;

  /** Numerical position index in [1..N] */
  positionNumber: number;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member user ID occupying this position */
  memberUid: string;

  /** Participation request ID bound to this position */
  requestId: string;

  /** Scheduled primary payout period in [1..N] */
  payoutPeriod: number;

  /** Timestamp when the position was confirmed and occupied */
  occupiedAt: string;

  /** Optimistic concurrency version */
  version: number;
}
