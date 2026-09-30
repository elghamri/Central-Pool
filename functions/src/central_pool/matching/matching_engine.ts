/**
 * Central Pool Step 4: Pure Matching Engine
 * Pure pipeline orchestrating Eligibility -> Capacity -> Payout -> Generation -> Ranking.
 *
 * CRITICAL ARCHITECTURAL BOUNDARY:
 * Matching is purely advisory and produces provisional AllocationCandidate tokens.
 * It NEVER creates positions, reserves slots, increments occupancy, or confirms allocations.
 */

import { validateParticipationRequest } from '../domain';
import { MatchingInput, CandidateUnitContext, MatchingOptions, MatchingResult } from './matching_types';
import { evaluateUnitEligibility } from './eligibility_evaluator';
import { evaluateVacantPositions } from './payout_evaluator';
import { generateCandidate } from './candidate_generator';
import { rankCandidates } from './candidate_ranker';
import { AllocationCandidate } from '../domain';

export class MatchingEngine {
  /**
   * Evaluates a Participation Request against a collection of Allocation Unit contexts
   * and returns ranked provisional candidate options.
   */
  evaluateRequest(
    input: MatchingInput,
    unitContexts: CandidateUnitContext[],
    options?: MatchingOptions
  ): MatchingResult {
    // 1. Validate Input Request
    validateParticipationRequest(input.request);

    const rejections: Array<{ unitId: string; reasons: string[] }> = [];
    const allGeneratedCandidates: AllocationCandidate[] = [];
    let eligibleUnitsCount = 0;

    // 2. Evaluate Each Candidate Unit Context
    for (const ctx of unitContexts) {
      const eligibility = evaluateUnitEligibility(input.request, ctx.unit);
      if (!eligibility.isEligible) {
        rejections.push({
          unitId: ctx.unit.unitId,
          reasons: eligibility.rejectionReasons,
        });
        continue;
      }

      eligibleUnitsCount++;

      // 3. Evaluate Vacant Positions
      const vacantPositions = evaluateVacantPositions(
        ctx.unit,
        ctx.occupiedPositions,
        input.request.preferredPayoutPeriod
      );

      // 4. Generate Candidate for Each Vacant Position Slot
      for (const vacantPos of vacantPositions) {
        const candidate = generateCandidate(input.request, ctx.unit, vacantPos, options);
        allGeneratedCandidates.push(candidate);
      }
    }

    // 5. Deterministic Ranking
    const rankedCandidates = rankCandidates(
      allGeneratedCandidates,
      input.request.preferredPayoutPeriod
    );

    // 6. Limit Output to Configured Max Candidates (default: 10)
    const maxCandidates = options?.maxCandidates ?? 10;
    const finalCandidates = rankedCandidates.slice(0, maxCandidates);

    return {
      requestId: input.request.requestId,
      tenantId: input.request.tenantId,
      evaluatedUnitsCount: unitContexts.length,
      eligibleUnitsCount,
      candidates: finalCandidates,
      rejections,
    };
  }
}
