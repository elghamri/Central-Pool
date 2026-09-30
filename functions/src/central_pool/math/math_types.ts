/**
 * Central Pool TypeScript Mathematical Kernel - Type Definitions
 * Reference: services/cooperative-service/allocation_mathematical_kernel.go
 */

export const BASIS_POINTS_100_PERCENT = 10000;
export const BASIS_POINTS_50_PERCENT = 5000;
export const BASIS_POINTS_ZERO = 0;

export const MIN_DURATION_PERIODS = 2;
export const MAX_DURATION_PERIODS = 12;

// Maximum safe contribution for N_max = 12 such that N^2 * C <= Number.MAX_SAFE_INTEGER
// Math.floor(9007199254740991 / 144) = 62549994824590 minor units
export const MAX_SAFE_CONTRIBUTION_MINOR = 62_549_994_824_590;

export type AllocationMode = 'STANDARD_SPLIT' | 'DEFERRED_FULL_ALLOCATION';

export interface ScheduledDisbursementSlot {
  slotId: string;
  memberId: string;
  positionNumber: number;
  periodIndex: number;
  payoutSequence: number; // 1 = Primary, 2 = Mirror
  percentageBps: number;
  amountMinor: number;
  mode: AllocationMode;
  isAggregatedCenter: boolean;
}

export interface PeriodAllocationSummary {
  periodIndex: number;
  expectedPoolMinor: number;
  scheduledMinor: number;
  totalPercentageBps: number;
  slots: ScheduledDisbursementSlot[];
}

export interface CycleScheduleMatrix {
  cycleId: string;
  tenantId: string;
  memberCount: number;
  periodicContributionMinor: number;
  totalPotMinor: number;
  periods: PeriodAllocationSummary[];
  memberEntitlements: Record<string, number>;
  invariantsVerified: boolean;
}

export type VectorProvenance = 'FROZEN_GO' | 'CONTRACT_DERIVED';

export interface GoldenVectorStandard {
  id: string;
  N: number;
  C: number;
  E: number;
  totalPot: number;
  centerPeriod: number | null;
  centerPayout: number | null;
  splitPayout: number;
  pairs: [number, number][];
  source: VectorProvenance;
  sourceFile?: string;
  sourceFunction?: string;
}

export interface GoldenVectorEdge {
  id: string;
  description: string;
  N: number;
  C: number;
  E: number;
  totalPot: number;
  centerPeriod: number | null;
  splitPayout: number;
  source: VectorProvenance;
  sourceFile?: string;
}

export interface GoldenVectorInvalid {
  id: string;
  description: string;
  N: number;
  C: number;
  goNativeError?: string;
  goNativeBehavior?: string;
  contractError: string;
  source: VectorProvenance;
  sourceFile?: string;
}
