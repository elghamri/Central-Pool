/**
 * Central Pool Step 6: Financial DTO Serialization & Conversion Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';
import {
  FinancialObligation,
  ContributionSchedule,
  ContributionEvent,
  PayoutEntitlement,
  AccountingJournalEntry,
  ACCOUNT_CODES,
  financialObligationToDoc,
  docToFinancialObligation,
  contributionScheduleToDoc,
  docToContributionSchedule,
  contributionEventToDoc,
  docToContributionEvent,
  payoutEntitlementToDoc,
  docToPayoutEntitlement,
  accountingJournalEntryToDoc,
  docToAccountingJournalEntry,
  financialObligationToProjectionDoc,
  payoutEntitlementToProjectionDoc,
} from '../index';
import { InvalidPersistenceStateError } from '../../persistence/persistence_errors';

describe('CENTRAL POOL — Step 6: Financial DTO Converters', () => {
  const tenantId = 'tenant_prod_01';
  const memberUid = 'usr_alice';
  const nowIso = '2026-09-09T12:00:00.000Z';

  it('converts FinancialObligation to and from Firestore Doc accurately', () => {
    const obligation: FinancialObligation = {
      obligationId: 'ob_001',
      tenantId,
      memberUid,
      allocationUnitId: 'unit_001',
      allocationId: 'alloc_001',
      positionNumber: 1,
      totalObligationMinor: 300000,
      contributionMinor: 50000,
      totalPeriods: 6,
      fulfilledAmountMinor: 50000,
      currency: 'USD',
      status: 'ACTIVE',
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 2,
    };

    const doc = financialObligationToDoc(obligation);
    assert.equal(doc.obligationId, obligation.obligationId);
    assert.ok(doc.createdAt instanceof Timestamp);

    const reconstructed = docToFinancialObligation(doc);
    assert.deepEqual(reconstructed, obligation);
  });

  it('converts ContributionSchedule to and from Firestore Doc accurately', () => {
    const schedule: ContributionSchedule = {
      scheduleId: 'cs_001',
      obligationId: 'ob_001',
      tenantId,
      memberUid,
      allocationUnitId: 'unit_001',
      totalPeriods: 2,
      periods: [
        {
          periodNumber: 1,
          scheduledAmountMinor: 50000,
          status: 'RECORDED',
          recordedAt: nowIso,
          contributionEventId: 'ce_001',
        },
        {
          periodNumber: 2,
          scheduledAmountMinor: 50000,
          status: 'SCHEDULED',
        },
      ],
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 1,
    };

    const doc = contributionScheduleToDoc(schedule);
    const reconstructed = docToContributionSchedule(doc);
    assert.deepEqual(reconstructed, schedule);
  });

  it('converts ContributionEvent to and from Firestore Doc accurately', () => {
    const event: ContributionEvent = {
      contributionEventId: 'ce_001',
      tenantId,
      memberUid,
      obligationId: 'ob_001',
      allocationUnitId: 'unit_001',
      periodNumber: 1,
      amountMinor: 50000,
      currency: 'USD',
      recordedAt: nowIso,
      journalEntryId: 'je_001',
      idempotencyId: 'idemp_001',
    };

    const doc = contributionEventToDoc(event);
    const reconstructed = docToContributionEvent(doc);
    assert.deepEqual(reconstructed, event);
  });

  it('converts PayoutEntitlement to and from Firestore Doc accurately', () => {
    const entitlement: PayoutEntitlement = {
      payoutEntitlementId: 'pe_001',
      tenantId,
      memberUid,
      allocationUnitId: 'unit_001',
      allocationId: 'alloc_001',
      positionNumber: 1,
      totalEntitlementMinor: 300000,
      currency: 'USD',
      splits: [
        { periodNumber: 1, amountMinor: 150000, basisPoints: 5000, isCenter: false },
        { periodNumber: 6, amountMinor: 150000, basisPoints: 5000, isCenter: false },
      ],
      status: 'SCHEDULED',
      calculatedAt: nowIso,
      version: 1,
    };

    const doc = payoutEntitlementToDoc(entitlement);
    const reconstructed = docToPayoutEntitlement(doc);
    assert.deepEqual(reconstructed, entitlement);
  });

  it('converts AccountingJournalEntry to and from Firestore Doc accurately', () => {
    const entry: AccountingJournalEntry = {
      journalEntryId: 'je_001',
      tenantId,
      entryType: 'OBLIGATION_RECOGNITION',
      referenceType: 'CONFIRMED_ALLOCATION',
      referenceId: 'alloc_001',
      lines: [
        {
          accountCode: ACCOUNT_CODES.MEMBER_RECEIVABLE,
          accountName: 'Member Obligation Receivable',
          debitMinor: 300000,
          creditMinor: 0,
        },
        {
          accountCode: ACCOUNT_CODES.POOL_OBLIGATION_RESERVE,
          accountName: 'Central Pool Obligation Reserve',
          debitMinor: 0,
          creditMinor: 300000,
        },
      ],
      totalDebitMinor: 300000,
      totalCreditMinor: 300000,
      currency: 'USD',
      postedAt: nowIso,
      idempotencyId: 'idemp_001',
    };

    const doc = accountingJournalEntryToDoc(entry);
    const reconstructed = docToAccountingJournalEntry(doc);
    assert.deepEqual(reconstructed, entry);
  });

  it('stamps member presentation projections with DERIVED_PROJECTION metadata', () => {
    const obligation: FinancialObligation = {
      obligationId: 'ob_001',
      tenantId,
      memberUid,
      allocationUnitId: 'unit_001',
      allocationId: 'alloc_001',
      positionNumber: 1,
      totalObligationMinor: 300000,
      contributionMinor: 50000,
      totalPeriods: 6,
      fulfilledAmountMinor: 0,
      currency: 'USD',
      status: 'ACTIVE',
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 1,
    };
    const proj = financialObligationToProjectionDoc(obligation);
    assert.equal(proj.isProjection, true);
    assert.equal(proj.classification, 'DERIVED_PROJECTION');

    const entitlement: PayoutEntitlement = {
      payoutEntitlementId: 'pe_001',
      tenantId,
      memberUid,
      allocationUnitId: 'unit_001',
      allocationId: 'alloc_001',
      positionNumber: 1,
      totalEntitlementMinor: 300000,
      currency: 'USD',
      splits: [{ periodNumber: 1, amountMinor: 300000, basisPoints: 10000, isCenter: true }],
      status: 'SCHEDULED',
      calculatedAt: nowIso,
      version: 1,
    };
    const entProj = payoutEntitlementToProjectionDoc(entitlement);
    assert.equal(entProj.isProjection, true);
    assert.equal(entProj.classification, 'DERIVED_PROJECTION');
  });

  it('throws InvalidPersistenceStateError on malformed documents', () => {
    assert.throws(() => docToFinancialObligation(null), InvalidPersistenceStateError);
    assert.throws(() => docToContributionSchedule({}), InvalidPersistenceStateError);
    assert.throws(() => docToAccountingJournalEntry({ lines: 'not-an-array' }), InvalidPersistenceStateError);
  });
});
