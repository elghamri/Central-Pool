/**
 * Repository Interface: AllocationUnitRepository
 * Manages persistence for internal computational/accounting units under /allocation_units.
 */

import { AllocationUnit, AllocationUnitState } from '../../domain';

export interface AllocationUnitRepository {
  /**
   * Persists a new FORMING Allocation Unit.
   * Enforces status === 'FORMING' and occupiedCount === 0 (or initial member count).
   */
  createFormingUnit(tenantId: string, unit: AllocationUnit): Promise<void>;

  /**
   * Retrieves an Allocation Unit by ID within a tenant.
   */
  getAllocationUnit(tenantId: string, unitId: string): Promise<AllocationUnit | null>;

  /**
   * Transitions an Allocation Unit state (e.g. FORMING -> COMMITTED_FULL or DEFECT_QUARANTINE).
   * Enforces valid formation transitions and guards immutable fields.
   */
  updateUnitState(
    tenantId: string,
    unitId: string,
    expectedCurrentState: AllocationUnitState,
    targetState: AllocationUnitState,
    occupiedCount?: number
  ): Promise<void>;

  /**
   * Finds forming allocation units matching a compatibility key.
   */
  findFormingUnitsByCompatibilityKey(tenantId: string, compatibilityKey: string): Promise<AllocationUnit[]>;
}
