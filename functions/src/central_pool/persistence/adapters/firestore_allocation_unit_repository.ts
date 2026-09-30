/**
 * Concrete Firestore Adapter: FirestoreAllocationUnitRepository
 * Implements AllocationUnitRepository with tenant isolation and formation state machine guards.
 */

import { Firestore, FieldValue } from 'firebase-admin/firestore';
import {
  AllocationUnit,
  AllocationUnitState,
  getAllocationUnitPath,
  validateAllocationUnitStateTransition,
  ALLOCATION_UNITS_COLLECTION,
} from '../../domain';
import { AllocationUnitRepository } from '../ports/allocation_unit_repository';
import { allocationUnitToDoc, docToAllocationUnit } from '../dto/dto_converters';
import {
  TenantIsolationViolationError,
  EntityNotFoundError,
  DuplicateEntityError,
  InvalidPersistenceStateError,
} from '../persistence_errors';

export class FirestoreAllocationUnitRepository implements AllocationUnitRepository {
  constructor(private readonly db: Firestore) {}

  async createFormingUnit(tenantId: string, unit: AllocationUnit): Promise<void> {
    if (!tenantId || unit.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, unit.tenantId, 'AllocationUnit');
    }

    if (unit.status !== 'FORMING') {
      throw new InvalidPersistenceStateError(
        `New allocation unit must be initialized in 'FORMING' status, got '${unit.status}'`
      );
    }

    const path = getAllocationUnitPath(unit.unitId);
    const docRef = this.db.doc(path);

    const snap = await docRef.get();
    if (snap.exists) {
      throw new DuplicateEntityError('AllocationUnit', unit.unitId);
    }

    const docData = allocationUnitToDoc(unit, true);
    await docRef.set(docData);
  }

  async getAllocationUnit(tenantId: string, unitId: string): Promise<AllocationUnit | null> {
    const path = getAllocationUnitPath(unitId);
    const docSnapshot = await this.db.doc(path).get();

    if (!docSnapshot.exists) {
      return null;
    }

    const data = docSnapshot.data();
    if (!data) return null;

    const unit = docToAllocationUnit(data);
    if (unit.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, unit.tenantId, 'AllocationUnit');
    }

    return unit;
  }

  async updateUnitState(
    tenantId: string,
    unitId: string,
    expectedCurrentState: AllocationUnitState,
    targetState: AllocationUnitState,
    occupiedCount?: number
  ): Promise<void> {
    const path = getAllocationUnitPath(unitId);
    const docRef = this.db.doc(path);

    await this.db.runTransaction(async (tx) => {
      const snap = await tx.get(docRef);
      if (!snap.exists) {
        throw new EntityNotFoundError('AllocationUnit', unitId);
      }

      const current = docToAllocationUnit(snap.data()!);
      if (current.tenantId !== tenantId) {
        throw new TenantIsolationViolationError(tenantId, current.tenantId, 'AllocationUnit');
      }

      if (current.status !== expectedCurrentState) {
        throw new InvalidPersistenceStateError(
          `AllocationUnit '${unitId}' is in status '${current.status}', expected '${expectedCurrentState}'`
        );
      }

      // Guard formation transition
      validateAllocationUnitStateTransition(current.status, targetState);

      const nextOccupied = occupiedCount !== undefined ? occupiedCount : current.occupiedCount;
      if (targetState === 'COMMITTED_FULL' && nextOccupied !== current.memberCount) {
        throw new InvalidPersistenceStateError(
          `Cannot transition AllocationUnit to COMMITTED_FULL: occupiedCount (${nextOccupied}) != memberCount (${current.memberCount})`
        );
      }

      const updates: Record<string, any> = {
        status: targetState,
        occupiedCount: nextOccupied,
        version: current.version + 1,
        updatedAt: FieldValue.serverTimestamp(),
      };

      tx.update(docRef, updates);
    });
  }

  async findFormingUnitsByCompatibilityKey(tenantId: string, compatibilityKey: string): Promise<AllocationUnit[]> {
    if (!tenantId) {
      throw new TenantIsolationViolationError('non-empty tenantId', '', 'AllocationUnit');
    }

    const querySnap = await this.db
      .collection(ALLOCATION_UNITS_COLLECTION)
      .where('tenantId', '==', tenantId)
      .where('compatibilityKey', '==', compatibilityKey)
      .where('status', '==', 'FORMING')
      .get();

    return querySnap.docs.map((doc) => docToAllocationUnit(doc.data()));
  }
}
