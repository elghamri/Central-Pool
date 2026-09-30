/**
 * Central Pool Domain: Pure Financial Period Engine
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT (Step 7)
 *
 * PROVENANCE & SEMANTIC BOUNDARY:
 * - 100% pure, deterministic derivation of period-level structures from confirmed allocations.
 * - Delegates all mathematical formulas directly to Step 1 Math Kernel & Step 6 Financial Validation.
 * - Zero settlement, zero banking, zero payment processing, zero activation policy.
 */

import {
  CyclePeriodProjection,
  CyclePeriodSummary,
  MemberPeriodProjection,
  MemberPeriodDetail,
  PeriodPayoutSlot,
  PeriodReadiness,
} from './period_types';
import { PeriodMathConservationError } from './period_errors';
import {
  validatePeriodNumberInRange,
  validatePeriodProjectionContext,
  validatePeriodCurrency,
  validateMemberCount,
  validatePeriodicContribution,
  validateSafeMinorAmount,
  validateSymmetricalEvenEntitlement,
} from './period_validation';
import {
  calculateFinancialTotalEntitlement,
  calculateFinancialTotalPoolPot,
  calculateSymmetricalDisbursementSplits,
} from '../../financial/domain/financial_validation';
import { calculateMirrorPeriod } from '../../math/allocation_math';
import { validatePositionNumber } from '../../math/math_validation';
import { computeCyclePeriodProjectionId, computeMemberPeriodProjectionId } from './period_identities';
import { ContributionSchedule } from '../../financial/domain/contribution_schedule';

export interface DeriveCyclePeriodInput {
  tenantId: string;
  allocationUnitId: string;
  memberCount: number;
  periodicContributionMinor: number;
  currency: string;
  positionMembers?: Record<number, string>;
  nowIso?: string;
}

export interface DeriveMemberPeriodInput {
  tenantId: string;
  memberUid: string;
  allocationId: string;
  allocationUnitId: string;
  positionNumber: number;
  totalPeriods: number;
  periodicContributionMinor: number;
  currency: string;
  contributionSchedule?: ContributionSchedule;
  nowIso?: string;
}

/**
 * Derives the complete cycle-level period timeline projection from confirmed allocation parameters.
 */
export function deriveCyclePeriodStructure(input: DeriveCyclePeriodInput): CyclePeriodProjection {
  const {
    tenantId,
    allocationUnitId,
    memberCount,
    periodicContributionMinor,
    currency,
    positionMembers,
    nowIso,
  } = input;

  // 1. Invariant & Boundary Validations
  validateMemberCount(memberCount);
  validatePeriodicContribution(periodicContributionMinor, memberCount);
  validateSafeMinorAmount(periodicContributionMinor, 'periodicContributionMinor');
  validatePeriodCurrency(currency);

  // 2. Math Kernel Delegation
  const totalEntitlementMinor = calculateFinancialTotalEntitlement(memberCount, periodicContributionMinor);
  const totalPotMinor = calculateFinancialTotalPoolPot(memberCount, periodicContributionMinor);
  const expectedMonthlyPoolMinor = totalEntitlementMinor; // N * C

  // 3. Initialize Period Summaries 1..N
  const periodSummaries: CyclePeriodSummary[] = [];
  for (let p = 1; p <= memberCount; p++) {
    periodSummaries.push({
      periodNumber: p,
      expectedContributionPoolMinor: expectedMonthlyPoolMinor,
      expectedDisbursementPoolMinor: 0,
      payoutSlots: [],
      isBalanced: false,
    });
  }

  // 4. Map Payout Slots for each position [1..N]
  for (let pos = 1; pos <= memberCount; pos++) {
    const splits = calculateSymmetricalDisbursementSplits(pos, memberCount, totalEntitlementMinor);
    const memberUid = positionMembers?.[pos];

    for (const slot of splits) {
      validatePeriodNumberInRange(slot.periodNumber, memberCount);
      const periodSummary = periodSummaries[slot.periodNumber - 1];

      const payoutSlot: PeriodPayoutSlot = {
        positionNumber: pos,
        memberUid,
        amountMinor: slot.amountMinor,
        basisPoints: slot.basisPoints,
        isCenter: slot.isCenter,
        mirrorPosition: slot.isCenter ? undefined : memberCount + 1 - pos,
      };

      periodSummary.payoutSlots.push(payoutSlot);
      periodSummary.expectedDisbursementPoolMinor += slot.amountMinor;
    }
  }

  // 5. Verify Period Balance & Sort Slots
  for (const summary of periodSummaries) {
    // Deterministic position sorting within each period
    summary.payoutSlots.sort((a, b) => a.positionNumber - b.positionNumber);

    if (summary.expectedDisbursementPoolMinor !== summary.expectedContributionPoolMinor) {
      throw new PeriodMathConservationError(
        `period ${summary.periodNumber} disbursement pool (${summary.expectedDisbursementPoolMinor}) != contribution pool (${summary.expectedContributionPoolMinor})`
      );
    }
    summary.isBalanced = true;
  }

  // 6. Compile Final CyclePeriodProjection
  const authorizedMemberUids = positionMembers
    ? Array.from(new Set(Object.values(positionMembers).filter((uid) => Boolean(uid && uid.trim())))).sort()
    : undefined;

  const projection: CyclePeriodProjection = {
    projectionId: computeCyclePeriodProjectionId(tenantId, allocationUnitId),
    tenantId: tenantId.trim(),
    allocationUnitId: allocationUnitId.trim(),
    memberCount,
    periodicContributionMinor,
    totalEntitlementMinor,
    totalPotMinor,
    currency,
    periods: periodSummaries,
    authorizedMemberUids,
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
    generatedAt: nowIso || new Date().toISOString(),
  };

  // 7. Mathematical Conservation Audit
  verifyPeriodConservationInvariants(projection);

  return projection;
}

/**
 * Derives a member-specific period timeline projection combining contribution schedule and payout entitlement.
 */
export function deriveMemberPeriodProjection(input: DeriveMemberPeriodInput): MemberPeriodProjection {
  const {
    tenantId,
    memberUid,
    allocationId,
    allocationUnitId,
    positionNumber,
    totalPeriods,
    periodicContributionMinor,
    currency,
    contributionSchedule,
    nowIso,
  } = input;

  // 1. Invariant & Boundary Validations
  validatePeriodProjectionContext(tenantId, memberUid, allocationId);
  validateMemberCount(totalPeriods);
  validatePositionNumber(positionNumber, totalPeriods);
  validatePeriodicContribution(periodicContributionMinor, totalPeriods);
  validateSafeMinorAmount(periodicContributionMinor, 'periodicContributionMinor');
  validatePeriodCurrency(currency);

  // 2. Math Kernel Delegation
  const totalEntitlementMinor = calculateFinancialTotalEntitlement(totalPeriods, periodicContributionMinor);
  const totalObligationMinor = totalEntitlementMinor; // In homogeneous model: N * C
  const splits = calculateSymmetricalDisbursementSplits(positionNumber, totalPeriods, totalEntitlementMinor);

  // 3. Index splits by period number
  const splitsByPeriod = new Map<number, (typeof splits)[0]>();
  for (const split of splits) {
    splitsByPeriod.set(split.periodNumber, split);
  }

  // 4. Index existing contribution schedule if provided
  const scheduleByPeriod = new Map<number, NonNullable<typeof contributionSchedule>['periods'][0]>();
  if (contributionSchedule) {
    for (const period of contributionSchedule.periods) {
      scheduleByPeriod.set(period.periodNumber, period);
    }
  }

  // 5. Populate Member Period Details 1..N
  const memberPeriods: MemberPeriodDetail[] = [];
  let totalContributionSum = 0;
  let totalPayoutSum = 0;

  for (let p = 1; p <= totalPeriods; p++) {
    const scheduleItem = scheduleByPeriod.get(p);
    const splitItem = splitsByPeriod.get(p);

    const contributionDetail = {
      periodNumber: p,
      dueAmountMinor: periodicContributionMinor,
      status: scheduleItem?.status || 'SCHEDULED',
      recordedAt: scheduleItem?.recordedAt,
      contributionEventId: scheduleItem?.contributionEventId,
    };
    totalContributionSum += contributionDetail.dueAmountMinor;

    const payoutDetail = splitItem
      ? {
          entitledAmountMinor: splitItem.amountMinor,
          basisPoints: splitItem.basisPoints,
          isPayoutPeriod: true,
          isCenter: splitItem.isCenter,
          mirrorPeriod: splitItem.isCenter ? undefined : calculateMirrorPeriod(totalPeriods, p),
        }
      : {
          entitledAmountMinor: 0,
          basisPoints: 0,
          isPayoutPeriod: false,
          isCenter: false,
          mirrorPeriod: undefined,
        };
    totalPayoutSum += payoutDetail.entitledAmountMinor;

    const netEntitlementDeltaMinor = payoutDetail.entitledAmountMinor - contributionDetail.dueAmountMinor;

    memberPeriods.push({
      periodNumber: p,
      contribution: contributionDetail,
      payout: payoutDetail,
      netEntitlementDeltaMinor,
    });
  }

  // 6. Member-Level Conservation Assertions
  if (totalContributionSum !== totalObligationMinor) {
    throw new PeriodMathConservationError(
      `member contribution sum (${totalContributionSum}) != obligation (${totalObligationMinor})`
    );
  }
  if (totalPayoutSum !== totalEntitlementMinor) {
    throw new PeriodMathConservationError(
      `member payout sum (${totalPayoutSum}) != entitlement (${totalEntitlementMinor})`
    );
  }

  // 7. Compile Final MemberPeriodProjection
  return {
    projectionId: computeMemberPeriodProjectionId(tenantId, allocationId),
    tenantId: tenantId.trim(),
    memberUid: memberUid.trim(),
    allocationId: allocationId.trim(),
    allocationUnitId: allocationUnitId.trim(),
    positionNumber,
    totalPeriods,
    periodicContributionMinor,
    totalObligationMinor,
    totalEntitlementMinor,
    currency,
    periods: memberPeriods,
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
    generatedAt: nowIso || new Date().toISOString(),
  };
}

/**
 * Validates mathematical conservation invariants across a CyclePeriodProjection.
 */
export function verifyPeriodConservationInvariants(projection: CyclePeriodProjection): boolean {
  const N = projection.memberCount;
  const C = projection.periodicContributionMinor;
  const E = projection.totalEntitlementMinor;
  const totalPot = projection.totalPotMinor;

  // 1. E = N * C
  if (E !== N * C) {
    throw new PeriodMathConservationError(`totalEntitlementMinor (${E}) != N * C (${N * C})`);
  }

  // 2. TotalPot = N^2 * C
  if (totalPot !== N * N * C) {
    throw new PeriodMathConservationError(`totalPotMinor (${totalPot}) != N^2 * C (${N * N * C})`);
  }

  // 3. Sum of periodic disbursements === TotalPot
  let totalDisbursed = 0;
  for (const period of projection.periods) {
    if (period.expectedDisbursementPoolMinor !== period.expectedContributionPoolMinor) {
      throw new PeriodMathConservationError(
        `period ${period.periodNumber} disbursement (${period.expectedDisbursementPoolMinor}) != contribution (${period.expectedContributionPoolMinor})`
      );
    }
    totalDisbursed += period.expectedDisbursementPoolMinor;
  }

  if (totalDisbursed !== totalPot) {
    throw new PeriodMathConservationError(`sum of disbursements (${totalDisbursed}) != total pot (${totalPot})`);
  }

  return true;
}

/**
 * Computes readiness indicators for a specific cycle period.
 */
export function computePeriodReadiness(
  summary: CyclePeriodSummary,
  recordedContributionsMinor: number
): PeriodReadiness {
  validateSafeMinorAmount(recordedContributionsMinor, 'recordedContributionsMinor', true);

  return {
    periodNumber: summary.periodNumber,
    totalScheduledContributionMinor: summary.expectedContributionPoolMinor,
    totalRecordedContributionMinor: recordedContributionsMinor,
    totalScheduledPayoutMinor: summary.expectedDisbursementPoolMinor,
    allContributionsRecorded: recordedContributionsMinor >= summary.expectedContributionPoolMinor,
    isPoolBalanced: summary.isBalanced,
  };
}
