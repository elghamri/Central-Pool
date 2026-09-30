/**
 * Central Pool Domain Types: Period Model & Projections
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT (Step 7)
 *
 * PROVENANCE & SEMANTIC BOUNDARY:
 * - Operates strictly on confirmed allocations and existing financial entities.
 * - All projections are read-models explicitly classified as DERIVED_PROJECTION.
 * - Does NOT implement settlement, banking, escrow, custody, or activation policy.
 */

import { ScheduledPeriodStatus } from '../../financial/domain/financial_types';

export type PeriodClassification = 'DERIVED_PROJECTION';

/**
 * Details of a contribution obligation in a specific period.
 */
export interface PeriodContributionDetail {
  /** Period number in [1..N] */
  periodNumber: number;

  /** Expected contribution amount in integer minor units (C) */
  dueAmountMinor: number;

  /** Status: SCHEDULED | RECORDED */
  status: ScheduledPeriodStatus;

  /** Timestamp when contribution was recorded (if any) */
  recordedAt?: string;

  /** Contribution Event ID linked to this period (if any) */
  contributionEventId?: string;
}

/**
 * Details of a single position's payout entitlement occurring in a period.
 */
export interface PeriodPayoutSlot {
  /** Numerical position index in [1..N] receiving this disbursement */
  positionNumber: number;

  /** Optional member UID if authorized */
  memberUid?: string;

  /** Entitlement disbursement amount in integer minor units */
  amountMinor: number;

  /** Proportion in basis points (5000 = 50%, 10000 = 100%) */
  basisPoints: number;

  /** True if this is an odd-cycle center position (100% single payout) */
  isCenter: boolean;

  /** Paired reciprocal mirror position: N + 1 - positionNumber (if not center) */
  mirrorPosition?: number;
}

/**
 * Cycle-level summary of a specific period p in [1..N].
 */
export interface CyclePeriodSummary {
  /** Period number in [1..N] */
  periodNumber: number;

  /** Total expected contribution collected across all N members in this period (N * C) */
  expectedContributionPoolMinor: number;

  /** Total expected payout disbursed across eligible positions in this period (N * C) */
  expectedDisbursementPoolMinor: number;

  /** Array of payout slots scheduled in this period */
  payoutSlots: PeriodPayoutSlot[];

  /** True when expectedContributionPoolMinor === expectedDisbursementPoolMinor */
  isBalanced: boolean;
}

/**
 * Complete cycle-level timeline projection from a confirmed Allocation Unit.
 */
export interface CyclePeriodProjection {
  /** Deterministic projection ID: 'cpp_' + SHA256(tenantId + ':' + allocationUnitId) */
  projectionId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Parent Allocation Unit ID */
  allocationUnitId: string;

  /** Total members / duration periods N in [2..12] */
  memberCount: number;

  /** Periodic contribution amount C in integer minor units */
  periodicContributionMinor: number;

  /** Single member contractual entitlement E = N * C */
  totalEntitlementMinor: number;

  /** Aggregate cycle volume TotalPot = N^2 * C */
  totalPotMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Array of period summaries for p in [1..N] */
  periods: CyclePeriodSummary[];

  /** Authoritative member UIDs occupying positions in this allocation unit (copied projection authorization attribute) */
  authorizedMemberUids?: string[];

  /** Explicit derived read-model marker */
  isProjection: true;

  /** Explicit classification */
  classification: PeriodClassification;

  /** Timestamp when projection was generated (RFC 3339 UTC) */
  generatedAt: string;
}

/**
 * Member-specific single period projection (combining contribution obligation and payout entitlement).
 */
export interface MemberPeriodDetail {
  /** Period number in [1..N] */
  periodNumber: number;

  /** Member's contribution due in this period */
  contribution: PeriodContributionDetail;

  /** Member's payout entitlement in this period */
  payout: {
    /** Entitlement amount in integer minor units (0 if no payout in this period) */
    entitledAmountMinor: number;

    /** Proportion in basis points (0, 5000, or 10000) */
    basisPoints: number;

    /** True if member receives a payout disbursement in this period */
    isPayoutPeriod: boolean;

    /** True if this is an odd-cycle center position (100% single payout) */
    isCenter: boolean;

    /** Symmetrical reciprocal mirror period in [1..N] (if applicable) */
    mirrorPeriod?: number;
  };

  /**
   * Derived simulation net entitlement delta in integer minor units:
   * payout.entitledAmountMinor - contribution.dueAmountMinor
   * NOTE: This is a pure mathematical/simulation projection value and does NOT represent actual cash flow, cash availability, settlement, or banking liquidity.
   */
  netEntitlementDeltaMinor: number;
}

/**
 * Complete member-specific timeline projection for a confirmed allocation.
 */
export interface MemberPeriodProjection {
  /** Deterministic member projection ID: 'mpp_' + SHA256(tenantId + ':' + allocationId) */
  projectionId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member User ID */
  memberUid: string;

  /** Confirmed Allocation Receipt ID */
  allocationId: string;

  /** Allocation Unit ID */
  allocationUnitId: string;

  /** Numerical position index in [1..N] */
  positionNumber: number;

  /** Total periods N in [2..12] */
  totalPeriods: number;

  /** Periodic contribution amount C in integer minor units */
  periodicContributionMinor: number;

  /** Total member contribution obligation E = N * C */
  totalObligationMinor: number;

  /** Total member contractual entitlement E = N * C */
  totalEntitlementMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Array of member period details for p in [1..N] */
  periods: MemberPeriodDetail[];

  /** Explicit derived read-model marker */
  isProjection: true;

  /** Explicit classification */
  classification: PeriodClassification;

  /** Timestamp when projection was generated (RFC 3339 UTC) */
  generatedAt: string;
}

/**
 * Period-level readiness summary.
 */
export interface PeriodReadiness {
  /** Period number in [1..N] */
  periodNumber: number;

  /** Total scheduled contribution in minor units */
  totalScheduledContributionMinor: number;

  /** Total recorded contribution in minor units */
  totalRecordedContributionMinor: number;

  /** Total scheduled payout entitlement in minor units */
  totalScheduledPayoutMinor: number;

  /** Whether all contributions for this period have been recorded */
  allContributionsRecorded: boolean;

  /** Whether mathematical pool balance is satisfied */
  isPoolBalanced: boolean;
}
