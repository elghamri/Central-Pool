/**
 * Central Pool Domain Entity & State Validation
 * Enforces domain boundaries, tenant isolation, currency standards, and delegates math to the Step 1 kernel.
 */

import {
  ParticipationRequestState,
  AllocationUnitState,
  LEGAL_PARTICIPATION_REQUEST_TRANSITIONS,
  LEGAL_ALLOCATION_UNIT_TRANSITIONS,
} from './domain_states';
import {
  MissingTenantIdError,
  MissingMemberUidError,
  InvalidCurrencyError,
  InvalidAllocationRuleError,
  InvalidStateTransitionError,
  EntityValidationError,
} from './domain_errors';
import { ParticipationRequest } from './participation_request';
import { AllocationUnit } from './allocation_unit';
import { AllocationPosition } from './allocation_position';
import { AllocationCandidate } from './allocation_candidate';
import { ConfirmedAllocation } from './confirmed_allocation';
import {
  validateMemberCount,
  validatePeriodicContribution,
  validatePositionNumber,
  validatePeriodNumber,
} from '../math/math_validation';
import { calculateTotalEntitlement, calculateTotalPot } from '../math/allocation_math';

const ISO_4217_REGEX = /^[A-Z]{3}$/;

/**
 * Validates that tenantId is present, non-empty, and of string type.
 */
export function validateTenantId(tenantId: string, entityName = 'Entity'): void {
  if (!tenantId || typeof tenantId !== 'string' || tenantId.trim() === '') {
    throw new MissingTenantIdError(entityName);
  }
}

/**
 * Validates that memberUid is present, non-empty, and of string type.
 */
export function validateMemberUid(memberUid: string, entityName = 'Entity'): void {
  if (!memberUid || typeof memberUid !== 'string' || memberUid.trim() === '') {
    throw new MissingMemberUidError(entityName);
  }
}

/**
 * Validates ISO 4217 Currency Code (e.g. 'USD', 'EGP', 'EUR').
 */
export function validateCurrency(currency: string): void {
  if (!currency || typeof currency !== 'string' || !ISO_4217_REGEX.test(currency)) {
    throw new InvalidCurrencyError(currency || '');
  }
}

/**
 * Validates approved mathematical allocation rule identifier.
 */
export function validateAllocationRule(rule: string): asserts rule is 'SYMMETRICAL_V1' {
  if (rule !== 'SYMMETRICAL_V1') {
    throw new InvalidAllocationRuleError(rule || '');
  }
}

/**
 * Guards state transitions for Participation Requests.
 */
export function validateParticipationRequestStateTransition(
  fromState: ParticipationRequestState,
  toState: ParticipationRequestState
): void {
  const allowedNextStates = LEGAL_PARTICIPATION_REQUEST_TRANSITIONS[fromState];
  if (!allowedNextStates || !allowedNextStates.has(toState)) {
    throw new InvalidStateTransitionError(fromState, toState, 'ParticipationRequest');
  }
}

/**
 * Guards state transitions for Allocation Units.
 */
export function validateAllocationUnitStateTransition(
  fromState: AllocationUnitState,
  toState: AllocationUnitState
): void {
  const allowedNextStates = LEGAL_ALLOCATION_UNIT_TRANSITIONS[fromState];
  if (!allowedNextStates || !allowedNextStates.has(toState)) {
    throw new InvalidStateTransitionError(fromState, toState, 'AllocationUnit');
  }
}

/**
 * Validates a ParticipationRequest domain entity.
 */
export function validateParticipationRequest(req: Partial<ParticipationRequest>): void {
  if (!req.requestId || typeof req.requestId !== 'string' || req.requestId.trim() === '') {
    throw new EntityValidationError('ParticipationRequest must carry a non-empty requestId');
  }
  validateTenantId(req.tenantId || '', 'ParticipationRequest');
  validateMemberUid(req.memberUid || '', 'ParticipationRequest');
  validateCurrency(req.currency || '');

  const N = req.durationPeriods ?? 0;
  validateMemberCount(N, true); // Strict Central Pool [2..12] bound

  const C = req.contributionMinor ?? 0;
  validatePeriodicContribution(C, N);

  if (req.preferredPayoutPeriod !== undefined) {
    validatePeriodNumber(req.preferredPayoutPeriod, N);
  }

  if (!req.status || typeof req.status !== 'string') {
    throw new EntityValidationError('ParticipationRequest must carry a valid status');
  }
}

/**
 * Validates an AllocationUnit domain entity.
 */
export function validateAllocationUnit(unit: Partial<AllocationUnit>): void {
  if (!unit.unitId || typeof unit.unitId !== 'string' || unit.unitId.trim() === '') {
    throw new EntityValidationError('AllocationUnit must carry a non-empty unitId');
  }
  validateTenantId(unit.tenantId || '', 'AllocationUnit');
  validateCurrency(unit.currency || '');
  validateAllocationRule(unit.allocationRule || '');

  const N = unit.memberCount ?? 0;
  validateMemberCount(N, true);

  if (unit.durationPeriods !== N) {
    throw new EntityValidationError(`AllocationUnit durationPeriods (${unit.durationPeriods}) must equal memberCount (${N})`);
  }

  const C = unit.contributionMinor ?? 0;
  validatePeriodicContribution(C, N);

  const occupied = unit.occupiedCount ?? -1;
  if (!Number.isSafeInteger(occupied) || occupied < 0 || occupied > N) {
    throw new EntityValidationError(
      `AllocationUnit occupiedCount must be an integer between 0 and memberCount (${N}), got ${occupied}`
    );
  }

  // Formation status invariant:
  if (unit.status === 'COMMITTED_FULL' && occupied !== N) {
    throw new EntityValidationError(
      `AllocationUnit status cannot be COMMITTED_FULL when occupiedCount (${occupied}) < memberCount (${N})`
    );
  }
}

/**
 * Validates an AllocationPosition domain entity.
 */
export function validateAllocationPosition(pos: Partial<AllocationPosition>, memberCount: number): void {
  if (!pos.unitId || typeof pos.unitId !== 'string' || pos.unitId.trim() === '') {
    throw new EntityValidationError('AllocationPosition must carry a non-empty unitId');
  }
  validateTenantId(pos.tenantId || '', 'AllocationPosition');
  validateMemberUid(pos.memberUid || '', 'AllocationPosition');

  if (!pos.requestId || typeof pos.requestId !== 'string' || pos.requestId.trim() === '') {
    throw new EntityValidationError('AllocationPosition must carry a bound requestId');
  }

  const posNum = pos.positionNumber ?? 0;
  validatePositionNumber(posNum, memberCount);

  const payoutPeriod = pos.payoutPeriod ?? 0;
  validatePeriodNumber(payoutPeriod, memberCount);
}

/**
 * Validates an AllocationCandidate domain entity.
 */
export function validateAllocationCandidate(cand: Partial<AllocationCandidate>): void {
  if (!cand.candidateId || typeof cand.candidateId !== 'string' || cand.candidateId.trim() === '') {
    throw new EntityValidationError('AllocationCandidate must carry a non-empty candidateId');
  }
  if (!cand.requestId || typeof cand.requestId !== 'string' || cand.requestId.trim() === '') {
    throw new EntityValidationError('AllocationCandidate must carry a bound requestId');
  }
  validateTenantId(cand.tenantId || '', 'AllocationCandidate');
  validateMemberUid(cand.memberUid || '', 'AllocationCandidate');
  validateCurrency(cand.currency || '');
  validateAllocationRule(cand.allocationRule || '');

  const N = cand.durationPeriods ?? 0;
  validateMemberCount(N, true);

  const C = cand.contributionMinor ?? 0;
  validatePeriodicContribution(C, N);

  const posNum = cand.allocatedPosition ?? 0;
  validatePositionNumber(posNum, N);

  const payoutPeriod = cand.payoutPeriod ?? 0;
  validatePeriodNumber(payoutPeriod, N);

  const expectedEntitlement = calculateTotalEntitlement(C, N);
  if (cand.totalEntitlementMinor !== expectedEntitlement) {
    throw new EntityValidationError(
      `AllocationCandidate totalEntitlementMinor (${cand.totalEntitlementMinor}) must equal N * C (${expectedEntitlement})`
    );
  }

  const expectedPot = calculateTotalPot(C, N);
  if (cand.totalPotMinor !== expectedPot) {
    throw new EntityValidationError(
      `AllocationCandidate totalPotMinor (${cand.totalPotMinor}) must equal N^2 * C (${expectedPot})`
    );
  }

  if (cand.isProvisional !== true) {
    throw new EntityValidationError('AllocationCandidate must carry isProvisional: true');
  }
}

/**
 * Validates a ConfirmedAllocation domain entity.
 */
export function validateConfirmedAllocation(alloc: Partial<ConfirmedAllocation>): void {
  if (!alloc.allocationId || typeof alloc.allocationId !== 'string' || alloc.allocationId.trim() === '') {
    throw new EntityValidationError('ConfirmedAllocation must carry a non-empty allocationId');
  }
  if (!alloc.requestId || typeof alloc.requestId !== 'string' || alloc.requestId.trim() === '') {
    throw new EntityValidationError('ConfirmedAllocation must carry a bound requestId');
  }
  validateTenantId(alloc.tenantId || '', 'ConfirmedAllocation');
  validateMemberUid(alloc.memberUid || '', 'ConfirmedAllocation');
  validateCurrency(alloc.currency || '');
  validateAllocationRule(alloc.allocationRule || '');

  const N = alloc.durationPeriods ?? 0;
  validateMemberCount(N, true);

  const C = alloc.contributionMinor ?? 0;
  validatePeriodicContribution(C, N);

  const posNum = alloc.allocatedPosition ?? 0;
  validatePositionNumber(posNum, N);

  const payoutPeriod = alloc.payoutPeriod ?? 0;
  validatePeriodNumber(payoutPeriod, N);

  const expectedEntitlement = calculateTotalEntitlement(C, N);
  if (alloc.totalEntitlementMinor !== expectedEntitlement) {
    throw new EntityValidationError(
      `ConfirmedAllocation totalEntitlementMinor (${alloc.totalEntitlementMinor}) must equal N * C (${expectedEntitlement})`
    );
  }

  const expectedPot = calculateTotalPot(C, N);
  if (alloc.totalPotMinor !== expectedPot) {
    throw new EntityValidationError(
      `ConfirmedAllocation totalPotMinor (${alloc.totalPotMinor}) must equal N^2 * C (${expectedPot})`
    );
  }

  if (alloc.isProjection !== true) {
    throw new EntityValidationError('ConfirmedAllocation must carry isProjection: true');
  }

  if (alloc.classification !== 'DERIVED_PROJECTION') {
    throw new EntityValidationError("ConfirmedAllocation must carry classification: 'DERIVED_PROJECTION'");
  }
}
