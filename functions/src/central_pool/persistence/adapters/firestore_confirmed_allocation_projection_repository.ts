/**
 * Concrete Firestore Adapter: FirestoreConfirmedAllocationProjectionRepository
 * Member-facing presentation read-model projection at /users/{userId}/allocations/{allocationId}.
 * CLASSIFICATION: DERIVED_PROJECTION (Receipt only; CANNOT establish occupancy or financial truth).
 */

import { Firestore } from 'firebase-admin/firestore';
import {
  ConfirmedAllocation,
  getAllocationReceiptPath,
  USERS_COLLECTION,
  ALLOCATIONS_SUBCOLLECTION,
} from '../../domain';
import { ConfirmedAllocationProjectionRepository } from '../ports/confirmed_allocation_projection_repository';
import { confirmedAllocationToDoc, docToConfirmedAllocation } from '../dto/dto_converters';
import {
  TenantIsolationViolationError,
  MemberOwnershipViolationError,
} from '../persistence_errors';

export class FirestoreConfirmedAllocationProjectionRepository implements ConfirmedAllocationProjectionRepository {
  constructor(private readonly db: Firestore) {}

  async saveMemberProjection(tenantId: string, memberUid: string, allocation: ConfirmedAllocation): Promise<void> {
    if (!tenantId || allocation.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, allocation.tenantId, 'ConfirmedAllocation Projection');
    }

    if (!memberUid || allocation.memberUid !== memberUid) {
      throw new MemberOwnershipViolationError(memberUid, allocation.memberUid, 'ConfirmedAllocation Projection');
    }

    const path = getAllocationReceiptPath(memberUid, allocation.allocationId);
    const docRef = this.db.doc(path);
    const docData = confirmedAllocationToDoc(allocation, true);

    await docRef.set(docData);
  }

  async getMemberProjection(
    tenantId: string,
    memberUid: string,
    allocationId: string
  ): Promise<ConfirmedAllocation | null> {
    const path = getAllocationReceiptPath(memberUid, allocationId);
    const docRef = this.db.doc(path);
    const snap = await docRef.get();

    if (!snap.exists) {
      return null;
    }

    const alloc = docToConfirmedAllocation(snap.data()!);
    if (alloc.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, alloc.tenantId, 'ConfirmedAllocation Projection');
    }
    if (alloc.memberUid !== memberUid) {
      throw new MemberOwnershipViolationError(memberUid, alloc.memberUid, 'ConfirmedAllocation Projection');
    }

    return alloc;
  }

  async listMemberProjections(tenantId: string, memberUid: string): Promise<ConfirmedAllocation[]> {
    if (!tenantId) {
      throw new TenantIsolationViolationError('non-empty tenantId', '', 'ConfirmedAllocation Projection');
    }
    if (!memberUid) {
      throw new MemberOwnershipViolationError('non-empty memberUid', '', 'ConfirmedAllocation Projection');
    }

    const collectionRef = this.db
      .collection(USERS_COLLECTION)
      .doc(memberUid)
      .collection(ALLOCATIONS_SUBCOLLECTION);

    const snap = await collectionRef.where('tenantId', '==', tenantId).get();
    return snap.docs.map((doc) => docToConfirmedAllocation(doc.data()));
  }
}
