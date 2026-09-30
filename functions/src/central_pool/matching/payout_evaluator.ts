/**
 * Central Pool Step 4: Pure Payout & Vacant Position Evaluator
 * Identifies vacant position slots in an Allocation Unit and maps them to primary payout periods
 * using the Step 1 mathematical kernel.
 */

import { AllocationUnit, AllocationPosition, ParticipationRequest } from '../domain';
import { calculateMemberPrimaryPeriod } from '../math/allocation_math';
import { VacantPositionEvaluation } from './matching_types';

/**
 * Evaluates vacant position slots for an Allocation Unit against a member's payout preference.
 */
export function evaluateVacantPositions(
  unit: AllocationUnit,
  occupiedPositions: AllocationPosition[] = [],
  preferredPayoutPeriod?: number
): VacantPositionEvaluation[] {
  const N = unit.memberCount;
  const occupiedSet = new Set<number>(occupiedPositions.map((p) => p.positionNumber));

  const vacantPositions: VacantPositionEvaluation[] = [];

  for (let pos = 1; pos <= N; pos++) {
    if (!occupiedSet.has(pos)) {
      const { primaryPeriod, isCenter } = calculateMemberPrimaryPeriod(N, pos);
      const isExactMatch =
        preferredPayoutPeriod !== undefined && Number.isSafeInteger(preferredPayoutPeriod)
          ? primaryPeriod === preferredPayoutPeriod
          : false;

      vacantPositions.push({
        positionNumber: pos,
        primaryPayoutPeriod: primaryPeriod,
        isCenter,
        isExactPayoutPreferenceMatch: isExactMatch,
      });
    }
  }

  return vacantPositions;
}
