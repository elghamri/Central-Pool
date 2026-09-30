/**
 * Central Pool Step 4: Matching Service (Repository Adapter Boundary)
 * Connects repository discovery queries to the pure MatchingEngine.
 *
 * CRITICAL ARCHITECTURAL BOUNDARY:
 * This service performs read-only candidate discovery and advisory matching.
 * It NEVER acquires positions, increments occupancy, confirms allocations, or writes ledger entries.
 */

import { ParticipationRequest } from '../domain';
import {
  AllocationUnitRepository,
  AllocationPositionRepository,
  AllocationCandidateRepository,
  TenantIsolationViolationError,
} from '../persistence';
import { MatchingEngine } from './matching_engine';
import { MatchingOptions, MatchingResult, CandidateUnitContext } from './matching_types';
import { computeCompatibilityKey } from './compatibility_key';

export class MatchingService {
  private readonly engine: MatchingEngine;

  constructor(
    private readonly unitRepo: AllocationUnitRepository,
    private readonly positionRepo: AllocationPositionRepository,
    private readonly candidateRepo?: AllocationCandidateRepository,
    engine?: MatchingEngine
  ) {
    this.engine = engine ?? new MatchingEngine();
  }

  /**
   * Discovers compatible candidate Allocation Units for a Participation Request,
   * evaluates vacant slots, and returns ranked provisional candidates.
   */
  async findCandidatesForRequest(
    tenantId: string,
    request: ParticipationRequest,
    options?: MatchingOptions
  ): Promise<MatchingResult> {
    if (!tenantId || request.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, request.tenantId, 'ParticipationRequest');
    }

    // 1. Compute Deterministic Compatibility Key
    const compatibilityKey = computeCompatibilityKey({
      tenantId: request.tenantId,
      currency: request.currency,
      contributionMinor: request.contributionMinor,
      durationPeriods: request.durationPeriods,
      allocationRule: 'SYMMETRICAL_V1',
    });

    // 2. Discover FORMING Allocation Units Matching Compatibility Key
    const formingUnits = await this.unitRepo.findFormingUnitsByCompatibilityKey(tenantId, compatibilityKey);

    // 3. Assemble Unit Contexts with Occupied Position Data
    const unitContexts: CandidateUnitContext[] = [];
    for (const unit of formingUnits) {
      const occupiedPositions = await this.positionRepo.listPositionsForUnit(tenantId, unit.unitId, unit.memberCount);
      unitContexts.push({
        unit,
        occupiedPositions,
      });
    }

    // 4. Run Pure Deterministic Matching Engine
    const result = this.engine.evaluateRequest({ request }, unitContexts, options);

    // 5. Optionally Persist Provisional Candidates to Ephemeral Candidate Repository
    if (this.candidateRepo && result.candidates.length > 0) {
      for (const candidate of result.candidates) {
        await this.candidateRepo.saveCandidate(tenantId, candidate);
      }
    }

    return result;
  }
}
