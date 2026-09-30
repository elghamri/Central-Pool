/**
 * Central Pool Step 5: Pure Authoritative Confirmation Validator
 * Revalidates all tenant boundaries, candidate integrity, request lifecycle,
 * unit formation capacity, position indexing, and mathematical invariants.
 */

import {
  ParticipationRequest,
  AllocationUnit,
  AllocationCandidate,
  CandidateExpiredError,
} from '../domain';
import {
  calculateMemberPrimaryPeriod,
  calculateTotalEntitlement,
  calculateTotalPot,
} from '../math/allocation_math';
import {
  validateMemberCount,
  validatePeriodicContribution,
  validatePositionNumber,
  validateSymmetricalEvenEntitlement,
} from '../math/math_validation';
import { computeCandidateId, computeCompatibilityKey } from '../matching/compatibility_key';
import { AllocationConfirmationInput } from './confirmation_types';
import {
  CandidateInvalidError,
  AllocationUnitNotFormingError,
  AllocationUnitCapacityExceededError,
  ParticipationRequestNotConfirmableError,
  TenantIsolationConfirmationError,
  MemberOwnershipConfirmationError,
} from './confirmation_errors';

export function validateConfirmationInvariants(
  input: AllocationConfirmationInput,
  request: ParticipationRequest,
  candidate: AllocationCandidate,
  unit: AllocationUnit,
  currentTimeMs: number = Date.now()
): void {
  // 1. Caller & Tenant Boundary Checks
  if (input.tenantId !== request.tenantId) {
    throw new TenantIsolationConfirmationError(input.tenantId, request.tenantId, 'ParticipationRequest');
  }
  if (input.tenantId !== candidate.tenantId) {
    throw new TenantIsolationConfirmationError(input.tenantId, candidate.tenantId, 'AllocationCandidate');
  }
  if (input.tenantId !== unit.tenantId) {
    throw new TenantIsolationConfirmationError(input.tenantId, unit.tenantId, 'AllocationUnit');
  }

  // 2. Caller Member Ownership Checks
  if (input.memberUid !== request.memberUid) {
    throw new MemberOwnershipConfirmationError(input.memberUid, request.memberUid, 'ParticipationRequest');
  }
  if (input.memberUid !== candidate.memberUid) {
    throw new MemberOwnershipConfirmationError(input.memberUid, candidate.memberUid, 'AllocationCandidate');
  }

  // 3. Candidate Context & Binding Checks
  if (candidate.requestId !== request.requestId) {
    throw new CandidateInvalidError(
      `Candidate bound to requestId '${candidate.requestId}' does not match request '${request.requestId}'`
    );
  }
  if (candidate.allocationUnitId !== unit.unitId) {
    throw new CandidateInvalidError(
      `Candidate bound to unitId '${candidate.allocationUnitId}' does not match unit '${unit.unitId}'`
    );
  }

  // 4. Cryptographic Candidate Identity Check
  const expectedCandidateId = computeCandidateId({
    tenantId: candidate.tenantId,
    requestId: candidate.requestId,
    allocationUnitId: candidate.allocationUnitId,
    allocatedPosition: candidate.allocatedPosition,
    payoutPeriod: candidate.payoutPeriod,
    contributionMinor: candidate.contributionMinor,
    durationPeriods: candidate.durationPeriods,
    allocationRule: 'SYMMETRICAL_V1',
  });
  if (candidate.candidateId !== expectedCandidateId) {
    throw new CandidateInvalidError(
      `Candidate ID '${candidate.candidateId}' does not match computed deterministic digest '${expectedCandidateId}'`
    );
  }

  // 5. Candidate Expiration Check
  const candidateExpiryMs = new Date(candidate.expiresAt).getTime();
  if (Number.isNaN(candidateExpiryMs) || candidateExpiryMs <= currentTimeMs) {
    throw new CandidateExpiredError(candidate.candidateId, candidate.expiresAt);
  }

  // 6. Request State Machine & Expiration Check
  if (
    request.status !== 'AWAITING_SELECTION' &&
    request.status !== 'REVALIDATING'
  ) {
    throw new ParticipationRequestNotConfirmableError(request.requestId, request.status);
  }
  const requestExpiryMs = new Date(request.requestExpiresAt).getTime();
  if (Number.isNaN(requestExpiryMs) || requestExpiryMs <= currentTimeMs) {
    throw new ParticipationRequestNotConfirmableError(request.requestId, 'EXPIRED');
  }

  // 7. Allocation Unit Formation State & Capacity
  if (unit.status !== 'FORMING') {
    throw new AllocationUnitNotFormingError(unit.unitId, unit.status);
  }
  if (unit.occupiedCount >= unit.memberCount) {
    throw new AllocationUnitCapacityExceededError(unit.unitId, unit.occupiedCount, unit.memberCount);
  }

  // 8. Financial & Structural Dimension Compatibility
  const N = request.durationPeriods;
  const C = request.contributionMinor;

  validateMemberCount(N, true);
  validatePeriodicContribution(C, N);

  if (unit.memberCount !== N || unit.durationPeriods !== N) {
    throw new CandidateInvalidError(
      `Unit duration/capacity (${unit.memberCount}) does not match request duration (${N})`
    );
  }
  if (unit.contributionMinor !== C) {
    throw new CandidateInvalidError(
      `Unit contribution (${unit.contributionMinor}) does not match request contribution (${C})`
    );
  }
  if (unit.currency.toUpperCase() !== request.currency.toUpperCase()) {
    throw new CandidateInvalidError(
      `Unit currency '${unit.currency}' does not match request currency '${request.currency}'`
    );
  }
  if (unit.allocationRule !== 'SYMMETRICAL_V1') {
    throw new CandidateInvalidError(`Unsupported unit allocation rule: '${unit.allocationRule}'`);
  }

  // Compatibility Key Check
  const expectedKey = computeCompatibilityKey({
    tenantId: unit.tenantId,
    currency: unit.currency,
    contributionMinor: unit.contributionMinor,
    durationPeriods: unit.durationPeriods,
    allocationRule: 'SYMMETRICAL_V1',
  });
  if (unit.compatibilityKey !== expectedKey) {
    throw new CandidateInvalidError(
      `Unit compatibilityKey '${unit.compatibilityKey}' does not match computed key '${expectedKey}'`
    );
  }

  // 9. Mathematical Kernel Entitlement & Odd Entitlement Guardrail
  const totalEntitlement = calculateTotalEntitlement(C, N);
  validateSymmetricalEvenEntitlement(totalEntitlement);

  const totalPot = calculateTotalPot(C, N);
  if (candidate.totalEntitlementMinor !== totalEntitlement) {
    throw new CandidateInvalidError(
      `Candidate totalEntitlementMinor (${candidate.totalEntitlementMinor}) != computed (${totalEntitlement})`
    );
  }
  if (candidate.totalPotMinor !== totalPot) {
    throw new CandidateInvalidError(
      `Candidate totalPotMinor (${candidate.totalPotMinor}) != computed (${totalPot})`
    );
  }

  // 10. Position Indexing & Primary Payout Mapping Check
  validatePositionNumber(candidate.allocatedPosition, N);
  const { primaryPeriod } = calculateMemberPrimaryPeriod(N, candidate.allocatedPosition);
  if (candidate.payoutPeriod !== primaryPeriod) {
    throw new CandidateInvalidError(
      `Candidate payoutPeriod (${candidate.payoutPeriod}) does not match math kernel primaryPeriod (${primaryPeriod}) for pos ${candidate.allocatedPosition}`
    );
  }
}
