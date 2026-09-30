/**
 * Central Pool Domain Entity: ContributionSchedule
 * Represents the sequence of scheduled contribution periods for a Financial Obligation.
 * Stored at: /contribution_schedules/{scheduleId}
 */

import { ScheduledPeriodStatus } from './financial_types';

export interface ScheduledContributionPeriod {
  /** Period number in [1..N] */
  periodNumber: number;

  /** Expected contribution amount in integer minor units */
  scheduledAmountMinor: number;

  /** Period status: SCHEDULED | RECORDED | OVERDUE */
  status: ScheduledPeriodStatus;

  /** Timestamp when contribution event was recorded for this period (if any) */
  recordedAt?: string;

  /** Contribution Event ID linked to this period (if any) */
  contributionEventId?: string;
}

export interface ContributionSchedule {
  /** Deterministic schedule ID: 'cs_' + SHA256(tenantId + ':' + obligationId) */
  scheduleId: string;

  /** Financial Obligation ID bound to this schedule */
  obligationId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member user ID */
  memberUid: string;

  /** Allocation Unit ID */
  allocationUnitId: string;

  /** Total periods N */
  totalPeriods: number;

  /** Scheduled contribution periods [1..N] */
  periods: ScheduledContributionPeriod[];

  /** Creation timestamp (RFC 3339 UTC) */
  createdAt: string;

  /** Last update timestamp (RFC 3339 UTC) */
  updatedAt: string;

  /** Optimistic concurrency version */
  version: number;
}
