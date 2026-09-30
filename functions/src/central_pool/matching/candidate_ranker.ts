/**
 * Central Pool Step 4: Pure Deterministic Candidate Ranker
 * Ranks provisional candidates deterministically without randomness, timestamp drift, or user discrimination.
 *
 * RANKING GOVERNANCE:
 * 1. Approved Business Rule:
 *    - Preferred Payout Period Exact Match & Proximity (|payoutPeriod - preferredPayoutPeriod|).
 * 2. Deterministic Technical Tie-Breakers:
 *    - a. allocationUnitId (ascending lexicographical)
 *    - b. allocatedPosition (ascending numerical in [1..N])
 *    - c. candidateId (ascending lexicographical)
 */

import { AllocationCandidate } from '../domain';

export function rankCandidates(
  candidates: AllocationCandidate[],
  preferredPayoutPeriod?: number
): AllocationCandidate[] {
  return [...candidates].sort((a, b) => {
    // 1. Approved Business Rule: Payout Preference Match / Proximity
    if (preferredPayoutPeriod !== undefined && Number.isSafeInteger(preferredPayoutPeriod)) {
      const aExact = a.payoutPeriod === preferredPayoutPeriod;
      const bExact = b.payoutPeriod === preferredPayoutPeriod;

      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      // Payout distance comparison (smaller distance ranks earlier)
      const aDist = Math.abs(a.payoutPeriod - preferredPayoutPeriod);
      const bDist = Math.abs(b.payoutPeriod - preferredPayoutPeriod);
      if (aDist !== bDist) {
        return aDist - bDist;
      }
    }

    // 2. Deterministic Technical Tie-Breakers (No unapproved business/liquidity preferences):
    // a. Stable Allocation Unit ID lexicographical sort
    if (a.allocationUnitId !== b.allocationUnitId) {
      return a.allocationUnitId.localeCompare(b.allocationUnitId);
    }

    // b. Position index ascending sort in [1..N]
    if (a.allocatedPosition !== b.allocatedPosition) {
      return a.allocatedPosition - b.allocatedPosition;
    }

    // c. Candidate ID lexicographical sort
    return a.candidateId.localeCompare(b.candidateId);
  });
}
