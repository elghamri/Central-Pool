/**
 * Central Pool Step 6: Financial Document Types (Firestore Schemas)
 * Stored at:
 *  - /financial_obligations/{obligationId}
 *  - /contribution_schedules/{scheduleId}
 *  - /contribution_events/{contributionEventId}
 *  - /payout_entitlements/{payoutEntitlementId}
 *  - /accounting_journal_entries/{journalEntryId}
 *  - /users/{userId}/financial_obligations/{obligationId}
 *  - /users/{userId}/payout_entitlements/{payoutEntitlementId}
 */

import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import {
  FinancialObligationStatus,
  ScheduledPeriodStatus,
  PayoutEntitlementStatus,
  JournalEntryType,
  JournalReferenceType,
  JournalLine,
} from '../domain/financial_types';

export interface FinancialObligationDoc {
  obligationId: string;
  tenantId: string;
  memberUid: string;
  allocationUnitId: string;
  allocationId: string;
  positionNumber: number;
  totalObligationMinor: number;
  contributionMinor: number;
  totalPeriods: number;
  fulfilledAmountMinor: number;
  currency: string;
  status: FinancialObligationStatus;
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
  version: number;
}

export interface ScheduledContributionPeriodDoc {
  periodNumber: number;
  scheduledAmountMinor: number;
  status: ScheduledPeriodStatus;
  recordedAt?: Timestamp | FieldValue;
  contributionEventId?: string;
}

export interface ContributionScheduleDoc {
  scheduleId: string;
  obligationId: string;
  tenantId: string;
  memberUid: string;
  allocationUnitId: string;
  totalPeriods: number;
  periods: ScheduledContributionPeriodDoc[];
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
  version: number;
}

export interface ContributionEventDoc {
  contributionEventId: string;
  tenantId: string;
  memberUid: string;
  obligationId: string;
  allocationUnitId: string;
  periodNumber: number;
  amountMinor: number;
  currency: string;
  recordedAt: Timestamp | FieldValue;
  journalEntryId?: string;
  idempotencyId: string;
}


export interface FinancialDisbursementSlotDoc {
  periodNumber: number;
  amountMinor: number;
  basisPoints: number;
  isCenter: boolean;
}

export interface PayoutEntitlementDoc {
  payoutEntitlementId: string;
  tenantId: string;
  memberUid: string;
  allocationUnitId: string;
  allocationId: string;
  positionNumber: number;
  totalEntitlementMinor: number;
  currency: string;
  splits: FinancialDisbursementSlotDoc[];
  status: PayoutEntitlementStatus;
  calculatedAt: Timestamp | FieldValue;
  version: number;
}

export interface AccountingJournalEntryDoc {
  journalEntryId: string;
  tenantId: string;
  entryType: JournalEntryType;
  referenceType: JournalReferenceType;
  referenceId: string;
  lines: JournalLine[];
  totalDebitMinor: number;
  totalCreditMinor: number;
  currency: string;
  postedAt: Timestamp | FieldValue;
  idempotencyId: string;
}

export interface MemberObligationProjectionDoc extends FinancialObligationDoc {
  isProjection: true;
  classification: 'DERIVED_PROJECTION';
}

export interface MemberPayoutEntitlementProjectionDoc extends PayoutEntitlementDoc {
  isProjection: true;
  classification: 'DERIVED_PROJECTION';
}
