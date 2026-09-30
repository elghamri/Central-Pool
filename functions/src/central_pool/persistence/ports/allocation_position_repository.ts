/**
 * Repository Interface: AllocationPositionRepository
 * Manages the authoritative occupied position records under /allocation_units/{unitId}/positions/{positionNumber}.
 * This is the SINGLE AUTHORITATIVE SOURCE of position occupancy truth.
 */

import { AllocationPosition } from '../../domain';

export interface AllocationPositionRepository {
  /**
   * Persists an authoritative occupied position slot.
   * Enforces parent tenant matching, position range [1..N], and uniqueness.
   */
  createPosition(tenantId: string, position: AllocationPosition, unitMemberCount: number): Promise<void>;

  /**
   * Retrieves an authoritative position slot.
   */
  getPosition(tenantId: string, unitId: string, positionNumber: number, unitMemberCount: number): Promise<AllocationPosition | null>;

  /**
   * Lists all occupied position records inside an Allocation Unit.
   */
  listPositionsForUnit(tenantId: string, unitId: string, unitMemberCount: number): Promise<AllocationPosition[]>;
}
