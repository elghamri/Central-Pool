/**
 * Central Pool Domain Entity: AllocationUnit
 * Represents an internal computational and accounting vessel aggregating matching participant positions.
 * Note: An AllocationUnit is NOT a user-created group, organizer circle, or social club.
 */

import { AllocationUnitState } from './domain_states';

export interface AllocationUnit {
  /** Authoritative document ID: 'unit_' + UUID */
  unitId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Compatibility key: 'cp_' + SHA256(JCS(Tuple)) */
  compatibilityKey: string;

  /** Total member capacity N in [2..12] */
  memberCount: number;

  /** Current occupied slot count in [0..memberCount] */
  occupiedCount: number;

  /** Formation lifecycle state: FORMING | COMMITTED_FULL | DEFECT_QUARANTINE */
  status: AllocationUnitState;

  /** Periodic contribution in integer minor units */
  contributionMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Total duration periods N */
  durationPeriods: number;

  /** Frozen mathematical allocation rule */
  allocationRule: 'SYMMETRICAL_V1';

  /** Creation timestamp */
  createdAt: string;

  /** Last update timestamp */
  updatedAt: string;

  /** Optimistic concurrency version */
  version: number;
}
