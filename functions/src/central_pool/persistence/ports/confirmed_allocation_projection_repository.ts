/**
 * Repository Interface: ConfirmedAllocationProjectionRepository
 * Manages the member-facing receipt read-model projections under /users/{userId}/allocations/{allocationId}.
 * CLASSIFICATION: DERIVED_PROJECTION (Receipt only; CANNOT establish occupancy or financial truth).
 */

import { ConfirmedAllocation } from '../../domain';

export interface ConfirmedAllocationProjectionRepository {
  /**
   * Writes a member-facing confirmed allocation projection receipt.
   * Enforces classification === 'DERIVED_PROJECTION' and isProjection === true.
   */
  saveMemberProjection(tenantId: string, memberUid: string, allocation: ConfirmedAllocation): Promise<void>;

  /**
   * Retrieves a member-facing confirmed allocation projection receipt.
   */
  getMemberProjection(tenantId: string, memberUid: string, allocationId: string): Promise<ConfirmedAllocation | null>;

  /**
   * Lists all allocation receipts for a member within a tenant.
   */
  listMemberProjections(tenantId: string, memberUid: string): Promise<ConfirmedAllocation[]>;
}
