/**
 * Concrete Firestore Adapter: FirestoreAllocationPositionRepository
 * Authoritative occupant position persistence at /allocation_units/{unitId}/positions/{positionNumber}.
 * SINGLE SOURCE OF TRUTH for position occupancy.
 */

import { Firestore } from 'firebase-admin/firestore';
import {
  AllocationPosition,
  getPositionPath,
  getAllocationUnitPath,
  ALLOCATION_POSITIONS_SUBCOLLECTION,
} from '../../domain';
import { AllocationPositionRepository } from '../ports/allocation_position_repository';
import { allocationPositionToDoc, docToAllocationPosition, docToAllocationUnit } from '../dto/dto_converters';
import {
  TenantIsolationViolationError,
  EntityNotFoundError,
  DuplicateEntityError,
} from '../persistence_errors';

export class FirestoreAllocationPositionRepository implements AllocationPositionRepository {
  constructor(private readonly db: Firestore) {}

  async createPosition(tenantId: string, position: AllocationPosition, unitMemberCount: number): Promise<void> {
    if (!tenantId || position.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, position.tenantId, 'AllocationPosition');
    }

    // Verify parent Allocation Unit exists and belongs to the same tenant
    const unitRef = this.db.doc(getAllocationUnitPath(position.unitId));
    const unitSnap = await unitRef.get();
    if (!unitSnap.exists) {
      throw new EntityNotFoundError('AllocationUnit', position.unitId);
    }
    const unitData = docToAllocationUnit(unitSnap.data()!);
    if (unitData.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, unitData.tenantId, 'Parent AllocationUnit');
    }

    const posPath = getPositionPath(position.unitId, position.positionNumber);
    const posRef = this.db.doc(posPath);

    const posSnap = await posRef.get();
    if (posSnap.exists) {
      throw new DuplicateEntityError('AllocationPosition', `${position.unitId}#${position.positionNumber}`);
    }

    const docData = allocationPositionToDoc(position, unitMemberCount, true);
    await posRef.set(docData);
  }

  async getPosition(
    tenantId: string,
    unitId: string,
    positionNumber: number,
    unitMemberCount: number
  ): Promise<AllocationPosition | null> {
    const posPath = getPositionPath(unitId, positionNumber);
    const posSnap = await this.db.doc(posPath).get();

    if (!posSnap.exists) {
      return null;
    }

    const pos = docToAllocationPosition(posSnap.data()!, unitMemberCount);
    if (pos.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, pos.tenantId, 'AllocationPosition');
    }

    return pos;
  }

  async listPositionsForUnit(tenantId: string, unitId: string, unitMemberCount: number): Promise<AllocationPosition[]> {
    // Verify parent unit tenant
    const unitRef = this.db.doc(getAllocationUnitPath(unitId));
    const unitSnap = await unitRef.get();
    if (!unitSnap.exists) {
      throw new EntityNotFoundError('AllocationUnit', unitId);
    }
    const unitData = docToAllocationUnit(unitSnap.data()!);
    if (unitData.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, unitData.tenantId, 'Parent AllocationUnit');
    }

    const querySnap = await unitRef.collection(ALLOCATION_POSITIONS_SUBCOLLECTION).get();
    return querySnap.docs.map((doc) => docToAllocationPosition(doc.data(), unitMemberCount));
  }
}
