/**
 * Central Pool Step 4: Matching Engine Type Definitions
 * Pure types for matching inputs, unit contexts, evaluation reports, and ranking options.
 */

import {
  ParticipationRequest,
  AllocationUnit,
  AllocationPosition,
  AllocationCandidate,
} from '../domain';

export interface MatchingInput {
  request: ParticipationRequest;
}

export interface CandidateUnitContext {
  unit: AllocationUnit;
  occupiedPositions?: AllocationPosition[];
}

export interface EligibilityResult {
  isEligible: boolean;
  rejectionReasons: string[];
}

export interface VacantPositionEvaluation {
  positionNumber: number;
  primaryPayoutPeriod: number;
  isCenter: boolean;
  isExactPayoutPreferenceMatch: boolean;
}

export interface MatchingOptions {
  /** Candidate token TTL in seconds (default: 300 seconds) */
  candidateTtlSeconds?: number;

  /** Maximum candidate count to generate per matching evaluation (default: 10) */
  maxCandidates?: number;

  /** Stamped timestamp for deterministic test execution */
  evaluationTimestamp?: string;
}

export interface MatchingResult {
  requestId: string;
  tenantId: string;
  evaluatedUnitsCount: number;
  eligibleUnitsCount: number;
  candidates: AllocationCandidate[];
  rejections: Array<{ unitId: string; reasons: string[] }>;
}
