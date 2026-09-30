/**
 * Central Pool Step 4: Pure Provisional Candidate Generator
 * Constructs strongly typed AllocationCandidate objects with mathematical kernel delegation
 * and deterministic cryptographic identity.
 */

import { ParticipationRequest, AllocationUnit, AllocationCandidate, validateAllocationCandidate } from '../domain';
import { calculateTotalEntitlement, calculateTotalPot } from '../math/allocation_math';
import { VacantPositionEvaluation, MatchingOptions } from './matching_types';
import { computeCandidateId } from './compatibility_key';

export function generateCandidate(
  request: ParticipationRequest,
  unit: AllocationUnit,
  vacantPos: VacantPositionEvaluation,
  options?: MatchingOptions
): AllocationCandidate {
  const N = request.durationPeriods;
  const C = request.contributionMinor;

  // Delegate financial calculations strictly to Step 1 Math Kernel
  const totalEntitlementMinor = calculateTotalEntitlement(C, N);
  const totalPotMinor = calculateTotalPot(C, N);

  const issuedAt = options?.evaluationTimestamp || new Date().toISOString();
  const ttlSeconds = options?.candidateTtlSeconds ?? 300;
  const expiresAt = new Date(new Date(issuedAt).getTime() + ttlSeconds * 1000).toISOString();

  const candidateId = computeCandidateId({
    tenantId: request.tenantId,
    requestId: request.requestId,
    allocationUnitId: unit.unitId,
    allocatedPosition: vacantPos.positionNumber,
    payoutPeriod: vacantPos.primaryPayoutPeriod,
    contributionMinor: C,
    durationPeriods: N,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const candidate: AllocationCandidate = {
    candidateId,
    requestId: request.requestId,
    tenantId: request.tenantId,
    memberUid: request.memberUid,
    allocationUnitId: unit.unitId,
    allocatedPosition: vacantPos.positionNumber,
    payoutPeriod: vacantPos.primaryPayoutPeriod,
    contributionMinor: C,
    durationPeriods: N,
    totalEntitlementMinor,
    totalPotMinor,
    currency: request.currency.toUpperCase(),
    allocationRule: 'SYMMETRICAL_V1',
    issuedAt,
    expiresAt,
    isProvisional: true,
  };

  // Domain validation before returning
  validateAllocationCandidate(candidate);
  return candidate;
}
