/**
 * Central Pool Step 6: Financial DTO Converters
 * Type-safe bidirectional conversions between Domain Entities and Firestore Document Schemas.
 */

import { Timestamp } from 'firebase-admin/firestore';
import {
  FinancialObligation,
  ContributionSchedule,
  ScheduledContributionPeriod,
  ContributionEvent,
  PayoutEntitlement,
  FinancialDisbursementSlot,
  AccountingJournalEntry,
  validateFinancialObligation,
  validateContributionSchedule,
  validateContributionEvent,
  validatePayoutEntitlement,
  validateAccountingJournalEntry,
} from '../domain';
import {
  FinancialObligationDoc,
  ContributionScheduleDoc,
  ScheduledContributionPeriodDoc,
  ContributionEventDoc,
  PayoutEntitlementDoc,
  FinancialDisbursementSlotDoc,
  AccountingJournalEntryDoc,
  MemberObligationProjectionDoc,
  MemberPayoutEntitlementProjectionDoc,
} from './financial_dtos';
import { timestampToIsoString } from '../../persistence/dto/dto_converters';
import { InvalidPersistenceStateError } from '../../persistence/persistence_errors';

export function financialObligationToDoc(entity: FinancialObligation): FinancialObligationDoc {
  validateFinancialObligation(entity);
  return {
    obligationId: entity.obligationId,
    tenantId: entity.tenantId,
    memberUid: entity.memberUid,
    allocationUnitId: entity.allocationUnitId,
    allocationId: entity.allocationId,
    positionNumber: entity.positionNumber,
    totalObligationMinor: entity.totalObligationMinor,
    contributionMinor: entity.contributionMinor,
    totalPeriods: entity.totalPeriods,
    fulfilledAmountMinor: entity.fulfilledAmountMinor,
    currency: entity.currency,
    status: entity.status,
    createdAt: Timestamp.fromDate(new Date(entity.createdAt)),
    updatedAt: Timestamp.fromDate(new Date(entity.updatedAt)),
    version: entity.version,
  };
}

export function docToFinancialObligation(data: unknown): FinancialObligation {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('Expected object data for FinancialObligationDoc');
  }
  const d = data as Record<string, any>;
  const entity: FinancialObligation = {
    obligationId: d.obligationId,
    tenantId: d.tenantId,
    memberUid: d.memberUid,
    allocationUnitId: d.allocationUnitId,
    allocationId: d.allocationId,
    positionNumber: d.positionNumber,
    totalObligationMinor: d.totalObligationMinor,
    contributionMinor: d.contributionMinor,
    totalPeriods: d.totalPeriods,
    fulfilledAmountMinor: d.fulfilledAmountMinor,
    currency: d.currency,
    status: d.status,
    createdAt: timestampToIsoString(d.createdAt, 'createdAt'),
    updatedAt: timestampToIsoString(d.updatedAt, 'updatedAt'),
    version: d.version,
  };
  validateFinancialObligation(entity);
  return entity;
}

export function contributionScheduleToDoc(entity: ContributionSchedule): ContributionScheduleDoc {
  validateContributionSchedule(entity);
  return {
    scheduleId: entity.scheduleId,
    obligationId: entity.obligationId,
    tenantId: entity.tenantId,
    memberUid: entity.memberUid,
    allocationUnitId: entity.allocationUnitId,
    totalPeriods: entity.totalPeriods,
    periods: entity.periods.map((p) => {
      const pDoc: ScheduledContributionPeriodDoc = {
        periodNumber: p.periodNumber,
        scheduledAmountMinor: p.scheduledAmountMinor,
        status: p.status,
      };
      if (p.recordedAt) {
        pDoc.recordedAt = Timestamp.fromDate(new Date(p.recordedAt));
      }
      if (p.contributionEventId) {
        pDoc.contributionEventId = p.contributionEventId;
      }
      return pDoc;
    }),
    createdAt: Timestamp.fromDate(new Date(entity.createdAt)),
    updatedAt: Timestamp.fromDate(new Date(entity.updatedAt)),
    version: entity.version,
  };
}

export function docToContributionSchedule(data: unknown): ContributionSchedule {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('Expected object data for ContributionScheduleDoc');
  }
  const d = data as Record<string, any>;
  if (!Array.isArray(d.periods)) {
    throw new InvalidPersistenceStateError('ContributionScheduleDoc periods must be an array');
  }

  const periods: ScheduledContributionPeriod[] = d.periods.map((p: any, idx: number) => {
    const period: ScheduledContributionPeriod = {
      periodNumber: p.periodNumber,
      scheduledAmountMinor: p.scheduledAmountMinor,
      status: p.status,
    };
    if (p.recordedAt) {
      period.recordedAt = timestampToIsoString(p.recordedAt, `periods[${idx}].recordedAt`);
    }
    if (p.contributionEventId) {
      period.contributionEventId = p.contributionEventId;
    }
    return period;
  });

  const entity: ContributionSchedule = {
    scheduleId: d.scheduleId,
    obligationId: d.obligationId,
    tenantId: d.tenantId,
    memberUid: d.memberUid,
    allocationUnitId: d.allocationUnitId,
    totalPeriods: d.totalPeriods,
    periods,
    createdAt: timestampToIsoString(d.createdAt, 'createdAt'),
    updatedAt: timestampToIsoString(d.updatedAt, 'updatedAt'),
    version: d.version,
  };
  validateContributionSchedule(entity);
  return entity;
}

export function contributionEventToDoc(entity: ContributionEvent): ContributionEventDoc {
  validateContributionEvent(entity);
  const doc: ContributionEventDoc = {
    contributionEventId: entity.contributionEventId,
    tenantId: entity.tenantId,
    memberUid: entity.memberUid,
    obligationId: entity.obligationId,
    allocationUnitId: entity.allocationUnitId,
    periodNumber: entity.periodNumber,
    amountMinor: entity.amountMinor,
    currency: entity.currency,
    recordedAt: Timestamp.fromDate(new Date(entity.recordedAt)),
    idempotencyId: entity.idempotencyId,
  };
  if (entity.journalEntryId) {
    doc.journalEntryId = entity.journalEntryId;
  }
  return doc;
}

export function docToContributionEvent(data: unknown): ContributionEvent {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('Expected object data for ContributionEventDoc');
  }
  const d = data as Record<string, any>;
  const entity: ContributionEvent = {
    contributionEventId: d.contributionEventId,
    tenantId: d.tenantId,
    memberUid: d.memberUid,
    obligationId: d.obligationId,
    allocationUnitId: d.allocationUnitId,
    periodNumber: d.periodNumber,
    amountMinor: d.amountMinor,
    currency: d.currency,
    recordedAt: timestampToIsoString(d.recordedAt, 'recordedAt'),
    idempotencyId: d.idempotencyId,
  };
  if (d.journalEntryId) {
    entity.journalEntryId = d.journalEntryId;
  }
  validateContributionEvent(entity);
  return entity;
}


export function payoutEntitlementToDoc(entity: PayoutEntitlement): PayoutEntitlementDoc {
  validatePayoutEntitlement(entity);
  return {
    payoutEntitlementId: entity.payoutEntitlementId,
    tenantId: entity.tenantId,
    memberUid: entity.memberUid,
    allocationUnitId: entity.allocationUnitId,
    allocationId: entity.allocationId,
    positionNumber: entity.positionNumber,
    totalEntitlementMinor: entity.totalEntitlementMinor,
    currency: entity.currency,
    splits: entity.splits.map((s): FinancialDisbursementSlotDoc => ({
      periodNumber: s.periodNumber,
      amountMinor: s.amountMinor,
      basisPoints: s.basisPoints,
      isCenter: s.isCenter,
    })),
    status: entity.status,
    calculatedAt: Timestamp.fromDate(new Date(entity.calculatedAt)),
    version: entity.version,
  };
}

export function docToPayoutEntitlement(data: unknown): PayoutEntitlement {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('Expected object data for PayoutEntitlementDoc');
  }
  const d = data as Record<string, any>;
  if (!Array.isArray(d.splits)) {
    throw new InvalidPersistenceStateError('PayoutEntitlementDoc splits must be an array');
  }

  const splits: FinancialDisbursementSlot[] = d.splits.map((s: any) => ({
    periodNumber: s.periodNumber,
    amountMinor: s.amountMinor,
    basisPoints: s.basisPoints,
    isCenter: Boolean(s.isCenter),
  }));

  const entity: PayoutEntitlement = {
    payoutEntitlementId: d.payoutEntitlementId,
    tenantId: d.tenantId,
    memberUid: d.memberUid,
    allocationUnitId: d.allocationUnitId,
    allocationId: d.allocationId,
    positionNumber: d.positionNumber,
    totalEntitlementMinor: d.totalEntitlementMinor,
    currency: d.currency,
    splits,
    status: d.status,
    calculatedAt: timestampToIsoString(d.calculatedAt, 'calculatedAt'),
    version: d.version,
  };
  validatePayoutEntitlement(entity);
  return entity;
}

export function accountingJournalEntryToDoc(entity: AccountingJournalEntry): AccountingJournalEntryDoc {
  validateAccountingJournalEntry(entity);
  return {
    journalEntryId: entity.journalEntryId,
    tenantId: entity.tenantId,
    entryType: entity.entryType,
    referenceType: entity.referenceType,
    referenceId: entity.referenceId,
    lines: entity.lines.map((l) => ({
      accountCode: l.accountCode,
      accountName: l.accountName,
      debitMinor: l.debitMinor,
      creditMinor: l.creditMinor,
    })),
    totalDebitMinor: entity.totalDebitMinor,
    totalCreditMinor: entity.totalCreditMinor,
    currency: entity.currency,
    postedAt: Timestamp.fromDate(new Date(entity.postedAt)),
    idempotencyId: entity.idempotencyId,
  };
}

export function docToAccountingJournalEntry(data: unknown): AccountingJournalEntry {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('Expected object data for AccountingJournalEntryDoc');
  }
  const d = data as Record<string, any>;
  if (!Array.isArray(d.lines)) {
    throw new InvalidPersistenceStateError('AccountingJournalEntryDoc lines must be an array');
  }

  const entity: AccountingJournalEntry = {
    journalEntryId: d.journalEntryId,
    tenantId: d.tenantId,
    entryType: d.entryType,
    referenceType: d.referenceType,
    referenceId: d.referenceId,
    lines: d.lines.map((l: any) => ({
      accountCode: l.accountCode,
      accountName: l.accountName,
      debitMinor: l.debitMinor,
      creditMinor: l.creditMinor,
    })),
    totalDebitMinor: d.totalDebitMinor,
    totalCreditMinor: d.totalCreditMinor,
    currency: d.currency,
    postedAt: timestampToIsoString(d.postedAt, 'postedAt'),
    idempotencyId: d.idempotencyId,
  };
  validateAccountingJournalEntry(entity);
  return entity;
}

export function financialObligationToProjectionDoc(entity: FinancialObligation): MemberObligationProjectionDoc {
  const base = financialObligationToDoc(entity);
  return {
    ...base,
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
  };
}

export function payoutEntitlementToProjectionDoc(entity: PayoutEntitlement): MemberPayoutEntitlementProjectionDoc {
  const base = payoutEntitlementToDoc(entity);
  return {
    ...base,
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
  };
}
