/**
 * Repository Interface: AllocationCandidateRepository
 * Manages provisional candidate authorization tokens.
 * Candidates are ephemeral/provisional artifacts and NEVER establish occupancy or financial truth.
 */

import { AllocationCandidate } from '../../domain';

export interface AllocationCandidateRepository {
  /**
   * Persists an ephemeral candidate token.
   */
  saveCandidate(tenantId: string, candidate: AllocationCandidate): Promise<void>;

  /**
   * Retrieves an ephemeral candidate token.
   */
  getCandidate(tenantId: string, candidateId: string): Promise<AllocationCandidate | null>;

  /**
   * Deletes or invalidates an expired candidate token.
   */
  deleteCandidate(tenantId: string, candidateId: string): Promise<void>;
}
