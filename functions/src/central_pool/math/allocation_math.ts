/**
 * Central Pool TypeScript Mathematical Kernel
 * Pure, deterministic mathematical implementation of the Central Pool Symmetrical Allocation Engine.
 * Reference: services/cooperative-service/allocation_mathematical_kernel.go
 */

import {
  BASIS_POINTS_100_PERCENT,
  BASIS_POINTS_50_PERCENT,
  BASIS_POINTS_ZERO,
  AllocationMode,
  CycleScheduleMatrix,
  PeriodAllocationSummary,
  ScheduledDisbursementSlot,
} from './math_types';
import {
  UnsupportedAllocationModeError,
  EntitlementMismatchError,
  MirrorInvolutionError,
  NegativeAllocationAmountError,
  DuplicatePositionAssignmentError,
  IncompleteRosterError,
} from './math_errors';
import {
  validateMemberCount,
  validatePeriodicContribution,
  validatePositionNumber,
  validatePeriodNumber,
  validateSafeMultiplication,
  validateSymmetricalEvenEntitlement,
} from './math_validation';

/**
 * Computes the symmetrical mirror period for any period P in [1..N].
 * Formula: Mirror(P) = N + 1 - P.
 * Invariant: Mirror(Mirror(P)) = N + 1 - (N + 1 - P) = P.
 */
export function calculateMirrorPeriod(memberCount: number, primaryPeriod: number): number {
  validateMemberCount(memberCount);
  validatePeriodNumber(primaryPeriod, memberCount);
  return memberCount + 1 - primaryPeriod;
}

/**
 * Computes a member's total contractual entitlement: E = C * N.
 */
export function calculateTotalEntitlement(periodicContributionMinor: number, cyclePeriods: number): number {
  validateMemberCount(cyclePeriods);
  validatePeriodicContribution(periodicContributionMinor);
  validateSafeMultiplication(cyclePeriods, periodicContributionMinor);

  const entitlement = cyclePeriods * periodicContributionMinor;
  if (!Number.isSafeInteger(entitlement)) {
    throw new Error('allocation error: total entitlement calculation produced an unsafe integer');
  }
  return entitlement;
}

/**
 * Computes the total cycle contribution volume across all N members: TotalPot = N * (C * N) = N^2 * C.
 */
export function calculateTotalPot(periodicContributionMinor: number, memberCount: number): number {
  validateMemberCount(memberCount);
  validatePeriodicContribution(periodicContributionMinor, memberCount);

  const memberEntitlement = calculateTotalEntitlement(periodicContributionMinor, memberCount);
  validateSafeMultiplication(memberCount, memberEntitlement);

  const totalPot = memberCount * memberEntitlement;
  if (!Number.isSafeInteger(totalPot)) {
    throw new Error('allocation error: total pot calculation produced an unsafe integer');
  }
  return totalPot;
}

/**
 * Maps a member's position [1..N] to their primary scheduled payout period P1.
 * For Even N = 2K:
 *   Pair k = floor((pos + 1) / 2) in [1..K]. Primary period P1 = k.
 * For Odd N = 2K + 1:
 *   Center position M = (N + 1) / 2 -> isCenter = true, P1 = M.
 *   Positions < M: j = pos     -> k = floor((j + 1) / 2) in [1..K]. P1 = k.
 *   Positions > M: j = pos - 1 -> k = floor((j + 1) / 2) in [1..K]. P1 = k.
 */
export function calculateMemberPrimaryPeriod(
  memberCount: number,
  position: number
): { primaryPeriod: number; isCenter: boolean } {
  validateMemberCount(memberCount);
  validatePositionNumber(position, memberCount);

  const isOdd = memberCount % 2 !== 0;
  if (isOdd) {
    const centerM = (memberCount + 1) / 2;
    if (position === centerM) {
      return { primaryPeriod: centerM, isCenter: true };
    }
    let j: number;
    if (position < centerM) {
      j = position;
    } else {
      j = position - 1;
    }
    const k = Math.floor((j + 1) / 2);
    return { primaryPeriod: k, isCenter: false };
  }

  // Even N
  const k = Math.floor((position + 1) / 2);
  return { primaryPeriod: k, isCenter: false };
}

/**
 * Computes the primary and mirror payout amounts and basis points.
 * For STANDARD_SPLIT:
 *   Primary = floor(Total / 2)
 *   Mirror  = Total - Primary (Canonical Remainder Rule guarantees 100% conservation)
 * For DEFERRED_FULL_ALLOCATION:
 *   Primary = 0
 *   Mirror  = Total
 *
 * When strictEvenSplit is true (Central Pool guardrail), requires Total % 2 === 0.
 */
export function calculateDisbursementSplit(
  totalEntitlementMinor: number,
  mode: AllocationMode = 'STANDARD_SPLIT',
  strictEvenSplit = false
): {
  primaryAmount: number;
  mirrorAmount: number;
  primaryBps: number;
  mirrorBps: number;
} {
  if (mode !== 'STANDARD_SPLIT' && mode !== 'DEFERRED_FULL_ALLOCATION') {
    throw new UnsupportedAllocationModeError(
      `allocation error: unsupported allocation mode; only STANDARD_SPLIT and DEFERRED_FULL_ALLOCATION are permitted, got ${mode}`
    );
  }
  if (!Number.isSafeInteger(totalEntitlementMinor) || totalEntitlementMinor <= 0) {
    throw new Error('allocation error: total entitlement must be a positive safe integer');
  }

  let primaryAmount: number;
  let mirrorAmount: number;
  let primaryBps: number;
  let mirrorBps: number;

  switch (mode) {
    case 'STANDARD_SPLIT': {
      if (strictEvenSplit) {
        validateSymmetricalEvenEntitlement(totalEntitlementMinor);
      }
      // Canonical Remainder Rule:
      primaryAmount = Math.floor(totalEntitlementMinor / 2);
      mirrorAmount = totalEntitlementMinor - primaryAmount;
      primaryBps = BASIS_POINTS_50_PERCENT;
      mirrorBps = BASIS_POINTS_50_PERCENT;
      break;
    }
    case 'DEFERRED_FULL_ALLOCATION': {
      primaryAmount = 0;
      mirrorAmount = totalEntitlementMinor;
      primaryBps = BASIS_POINTS_ZERO;
      mirrorBps = BASIS_POINTS_100_PERCENT;
      break;
    }
  }

  // Conservation Invariant: Primary + Mirror === Total
  if (primaryAmount + mirrorAmount !== totalEntitlementMinor) {
    throw new EntitlementMismatchError('allocation invariant violation: primary + mirror != total');
  }

  return { primaryAmount, mirrorAmount, primaryBps, mirrorBps };
}

/**
 * Compiles the complete deterministic allocation matrix for a cycle.
 */
export function generateCycleScheduleMatrix(
  cycleId: string,
  tenantId: string,
  memberCount: number,
  periodicContributionMinor: number,
  memberPositions: Record<string, number>,
  memberModes?: Record<string, AllocationMode>,
  strictEvenSplit = false
): CycleScheduleMatrix {
  validateMemberCount(memberCount);
  validatePeriodicContribution(periodicContributionMinor, memberCount);

  const memberEntries = Object.entries(memberPositions);
  if (memberEntries.length !== memberCount) {
    throw new IncompleteRosterError(
      `allocation error: expected ${memberCount} members, got ${memberEntries.length}`
    );
  }

  // Verify position uniqueness across [1..N]
  const positionToMember: Record<number, string> = {};
  for (const [memberId, pos] of memberEntries) {
    validatePositionNumber(pos, memberCount);
    if (positionToMember[pos]) {
      throw new DuplicatePositionAssignmentError(
        `allocation invariant violation: duplicate position assignment detected in cycle roster: position ${pos} claimed by ${positionToMember[pos]} and ${memberId}`
      );
    }
    positionToMember[pos] = memberId;
  }

  const totalPotMinor = calculateTotalPot(periodicContributionMinor, memberCount);
  const expectedMonthlyPoolMinor = calculateTotalEntitlement(periodicContributionMinor, memberCount);

  // Initialize periods 1..N
  const periods: PeriodAllocationSummary[] = [];
  for (let i = 0; i < memberCount; i++) {
    periods.push({
      periodIndex: i + 1,
      expectedPoolMinor: expectedMonthlyPoolMinor,
      scheduledMinor: 0,
      totalPercentageBps: 0,
      slots: [],
    });
  }

  const entitlements: Record<string, number> = {};

  // Populate slots for each member position
  for (let pos = 1; pos <= memberCount; pos++) {
    const memberId = positionToMember[pos];
    const mode = memberModes?.[memberId] || 'STANDARD_SPLIT';

    const memberEntitlement = calculateTotalEntitlement(periodicContributionMinor, memberCount);
    entitlements[memberId] = memberEntitlement;

    const { primaryPeriod: p1, isCenter } = calculateMemberPrimaryPeriod(memberCount, pos);
    const p2 = calculateMirrorPeriod(memberCount, p1);

    const { primaryAmount, mirrorAmount, primaryBps, mirrorBps } = calculateDisbursementSplit(
      memberEntitlement,
      mode,
      strictEvenSplit
    );

    // Handle Special Odd-Count Center Position Aggregation (P1 == P2)
    if (isCenter && p1 === p2) {
      const centerSlot: ScheduledDisbursementSlot = {
        slotId: `slot-${memberId}-p${p1}-center`,
        memberId,
        positionNumber: pos,
        periodIndex: p1,
        payoutSequence: 1,
        percentageBps: BASIS_POINTS_100_PERCENT,
        amountMinor: memberEntitlement,
        mode,
        isAggregatedCenter: true,
      };
      periods[p1 - 1].slots.push(centerSlot);
      periods[p1 - 1].scheduledMinor += memberEntitlement;
      periods[p1 - 1].totalPercentageBps += BASIS_POINTS_100_PERCENT;
    } else {
      // Standard Symmetrical Two-Slot Disbursement
      const slot1: ScheduledDisbursementSlot = {
        slotId: `slot-${memberId}-p${p1}-seq1`,
        memberId,
        positionNumber: pos,
        periodIndex: p1,
        payoutSequence: 1,
        percentageBps: primaryBps,
        amountMinor: primaryAmount,
        mode,
        isAggregatedCenter: false,
      };
      periods[p1 - 1].slots.push(slot1);
      periods[p1 - 1].scheduledMinor += primaryAmount;
      periods[p1 - 1].totalPercentageBps += primaryBps;

      const slot2: ScheduledDisbursementSlot = {
        slotId: `slot-${memberId}-p${p2}-seq2`,
        memberId,
        positionNumber: pos,
        periodIndex: p2,
        payoutSequence: 2,
        percentageBps: mirrorBps,
        amountMinor: mirrorAmount,
        mode,
        isAggregatedCenter: false,
      };
      periods[p2 - 1].slots.push(slot2);
      periods[p2 - 1].scheduledMinor += mirrorAmount;
      periods[p2 - 1].totalPercentageBps += mirrorBps;
    }
  }

  const matrix: CycleScheduleMatrix = {
    cycleId,
    tenantId,
    memberCount,
    periodicContributionMinor,
    totalPotMinor,
    periods,
    memberEntitlements: entitlements,
    invariantsVerified: false,
  };

  // Validate Invariants
  validateAllocationInvariants(matrix);
  matrix.invariantsVerified = true;

  return matrix;
}

/**
 * Executes formal mathematical assertions across the generated matrix.
 */
export function validateAllocationInvariants(matrix: CycleScheduleMatrix): void {
  const N = matrix.memberCount;
  validateMemberCount(N);

  // 1. Validate Mirror Involution for every period: Mirror(Mirror(P)) === P
  for (let p = 1; p <= N; p++) {
    const m = calculateMirrorPeriod(N, p);
    if (m < 1 || m > N) {
      throw new Error(`allocation error: mirror ${m} out of bounds [1..${N}]`);
    }
    const remirror = calculateMirrorPeriod(N, m);
    if (remirror !== p) {
      throw new MirrorInvolutionError();
    }
  }

  // 2. Validate Total Member Entitlement Conservation: Sum of member slots === C * N
  const memberSlotSums: Record<string, number> = {};
  for (const period of matrix.periods) {
    for (const slot of period.slots) {
      if (slot.amountMinor < 0) {
        throw new NegativeAllocationAmountError();
      }
      memberSlotSums[slot.memberId] = (memberSlotSums[slot.memberId] || 0) + slot.amountMinor;
    }
  }

  for (const [memberId, expectedEntitlement] of Object.entries(matrix.memberEntitlements)) {
    const actualSum = memberSlotSums[memberId] || 0;
    if (actualSum !== expectedEntitlement) {
      throw new EntitlementMismatchError(
        `allocation invariant violation: member ${memberId} expected ${expectedEntitlement}, got ${actualSum}`
      );
    }
  }

  // 3. Validate Total Cumulative Distributed Amount equals Total Pot (N * (N * C))
  let totalDistributedMinor = 0;
  for (const period of matrix.periods) {
    totalDistributedMinor += period.scheduledMinor;
  }
  if (totalDistributedMinor !== matrix.totalPotMinor) {
    throw new EntitlementMismatchError(
      `allocation invariant violation: total distributed ${totalDistributedMinor} != total pot ${matrix.totalPotMinor}`
    );
  }

  // 4. Validate Period Balance: Each period receives exactly 100% of periodic pool (N * C)
  for (const period of matrix.periods) {
    if (period.scheduledMinor !== period.expectedPoolMinor) {
      throw new EntitlementMismatchError(
        `allocation invariant violation: period ${period.periodIndex} scheduled ${period.scheduledMinor} != expected ${period.expectedPoolMinor}`
      );
    }
    if (period.totalPercentageBps !== BASIS_POINTS_100_PERCENT) {
      throw new EntitlementMismatchError(
        `allocation invariant violation: period ${period.periodIndex} total percentage ${period.totalPercentageBps} bps != 10000 bps`
      );
    }
  }
}
