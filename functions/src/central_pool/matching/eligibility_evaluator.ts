/**
 * Central Pool Step 4: Pure Eligibility Evaluator
 * Validates whether an Allocation Unit is structurally and contextually eligible for a Participation Request.
 */

import { ParticipationRequest, AllocationUnit } from '../domain';
import { EligibilityResult } from './matching_types';
import { validateMemberCount, validatePeriodicContribution } from '../math/math_validation';

export function evaluateUnitEligibility(
  request: ParticipationRequest,
  unit: AllocationUnit
): EligibilityResult {
  const rejectionReasons: string[] = [];

  // 1. Tenant Boundary Check (Zero Cross-Tenant Matching)
  if (!request.tenantId || !unit.tenantId || request.tenantId !== unit.tenantId) {
    rejectionReasons.push(`Tenant mismatch: request tenant '${request.tenantId}' != unit tenant '${unit.tenantId}'`);
  }

  // 2. Lifecycle Status (Only FORMING units can accept candidates)
  if (unit.status !== 'FORMING') {
    rejectionReasons.push(`Allocation unit '${unit.unitId}' is in ineligible status '${unit.status}' (only FORMING accepted)`);
  }

  // 3. Capacity Check (Currently appears available; not a reservation)
  if (unit.occupiedCount >= unit.memberCount) {
    rejectionReasons.push(`Allocation unit '${unit.unitId}' has no available capacity (${unit.occupiedCount}/${unit.memberCount})`);
  }

  // 4. Currency Compatibility
  if (!request.currency || !unit.currency || request.currency.toUpperCase() !== unit.currency.toUpperCase()) {
    rejectionReasons.push(`Currency mismatch: request '${request.currency}' != unit '${unit.currency}'`);
  }

  // 5. Contribution Amount Compatibility (Exact homogeneous match)
  if (request.contributionMinor !== unit.contributionMinor) {
    rejectionReasons.push(
      `Contribution mismatch: request ${request.contributionMinor} != unit ${unit.contributionMinor}`
    );
  }

  // 6. Duration / Member Count Compatibility
  if (request.durationPeriods !== unit.memberCount || request.durationPeriods !== unit.durationPeriods) {
    rejectionReasons.push(
      `Duration mismatch: request duration ${request.durationPeriods} != unit capacity ${unit.memberCount}`
    );
  }

  // 7. Duration Bounds Check [2..12]
  try {
    validateMemberCount(request.durationPeriods, true);
  } catch (err: any) {
    rejectionReasons.push(err.message || 'Invalid duration periods');
  }

  // 8. Periodic Contribution Safety & Bounds Check
  try {
    validatePeriodicContribution(request.contributionMinor, request.durationPeriods);
  } catch (err: any) {
    rejectionReasons.push(err.message || 'Invalid contribution minor');
  }

  // 9. Allocation Rule Compatibility
  if (unit.allocationRule !== 'SYMMETRICAL_V1') {
    rejectionReasons.push(`Unsupported allocation rule: '${unit.allocationRule}' (only 'SYMMETRICAL_V1' supported)`);
  }

  // 10. Central Pool Odd-Entitlement Guardrail (Symmetrical 50/50 requires even entitlement)
  const totalEntitlement = request.durationPeriods * request.contributionMinor;
  if (totalEntitlement % 2 !== 0) {
    rejectionReasons.push(
      `Odd entitlement rejection: E = N * C = ${totalEntitlement} is odd; symmetrical split requires an even integer`
    );
  }

  return {
    isEligible: rejectionReasons.length === 0,
    rejectionReasons,
  };
}
