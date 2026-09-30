/**
 * Concrete Firestore Adapter: FirestoreAllocationCandidateRepository
 * Ephemeral/provisional candidate authorization token persistence.
 * Note: Candidates are ephemeral and NEVER establish occupancy or financial truth.
 */

import { Firestore } from 'firebase-admin/firestore';
import { AllocationCandidate } from '../../domain';
import { AllocationCandidateRepository } from '../ports/allocation_candidate_repository';
import { allocationCandidateToDoc, docToAllocationCandidate } from '../dto/dto_converters';
import { TenantIsolationViolationError } from '../persistence_errors';

const CANDIDATES_COLLECTION = 'allocation_candidates';

export class FirestoreAllocationCandidateRepository implements AllocationCandidateRepository {
  constructor(private readonly db: Firestore) {}

  async saveCandidate(tenantId: string, candidate: AllocationCandidate): Promise<void> {
    if (!tenantId || candidate.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, candidate.tenantId, 'AllocationCandidate');
    }

    const docRef = this.db.collection(CANDIDATES_COLLECTION).doc(candidate.candidateId);
    const docData = allocationCandidateToDoc(candidate, true);
    await docRef.set(docData);
  }

  async getCandidate(tenantId: string, candidateId: string): Promise<AllocationCandidate | null> {
    const docRef = this.db.collection(CANDIDATES_COLLECTION).doc(candidateId);
    const snap = await docRef.get();

    if (!snap.exists) {
      return null;
    }

    const cand = docToAllocationCandidate(snap.data()!);
    if (cand.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, cand.tenantId, 'AllocationCandidate');
    }

    return cand;
  }

  async deleteCandidate(tenantId: string, candidateId: string): Promise<void> {
    const docRef = this.db.collection(CANDIDATES_COLLECTION).doc(candidateId);
    const snap = await docRef.get();

    if (snap.exists) {
      const cand = docToAllocationCandidate(snap.data()!);
      if (cand.tenantId !== tenantId) {
        throw new TenantIsolationViolationError(tenantId, cand.tenantId, 'AllocationCandidate');
      }
      await docRef.delete();
    }
  }
}
