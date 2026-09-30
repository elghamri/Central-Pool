/**
 * Central Pool Domain Entity: ConfirmedAllocation (Allocation Receipt)
 * Represents a member-facing DERIVED READ MODEL / PROJECTION.
 * Stored at: /users/{userId}/allocations/{allocationId}
 *
 * CRITICAL ARCHITECTURAL BOUNDARY:
 * This document is a derived presentation projection and CANNOT independently establish:
 * - Position occupancy or ownership (Authoritative record: /allocation_units/{unitId}/positions/{positionNumber})
 * - Financial obligations or payout entitlements (Authoritative record: Allocation Unit & Financial Core)
 * - General Ledger truth
 */

export interface ConfirmedAllocation {
  /** Deterministic allocation receipt ID: 'alloc_' + requestId */
  allocationId: string;

  /** Participation request ID bound to this allocation */
  requestId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member user ID owning this allocation receipt */
  memberUid: string;

  /** Allocation Unit ID containing the confirmed position */
  allocationUnitId: string;

  /** Confirmed position index in [1..N] */
  allocatedPosition: number;

  /** Confirmed primary payout period in [1..N] */
  payoutPeriod: number;

  /** Contribution amount in integer minor units */
  contributionMinor: number;

  /** Duration periods N in [2..12] */
  durationPeriods: number;

  /** Total member payout entitlement: E = N * C (calculated via calculateTotalEntitlement) */
  totalEntitlementMinor: number;

  /** Total lifecycle pot: TotalPot = N^2 * C (calculated via calculateTotalPot) */
  totalPotMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Frozen allocation rule */
  allocationRule: 'SYMMETRICAL_V1';

  /** Timestamp of authoritative confirmation */
  confirmedAt: string;

  /** Explicit domain tag confirming this is a derived projection */
  isProjection: true;

  /** Domain classification tag */
  classification: 'DERIVED_PROJECTION';

  /** Optimistic concurrency version */
  version: number;
}
