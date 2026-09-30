/**
 * Central Pool Step 6: General Ledger & Journal Entry Balance Conservation Test Suite
 *
 * QUARANTINE CLARIFICATION (F6-BLOCKER-01):
 * - Tests internal simulation double-entry mathematical conservation invariants.
 * - This ledger posting model is quarantined from authoritative execution and classified
 *   as UNRESOLVED_ACCOUNTING_DECISION until explicit accounting chart/events are ratified.
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import {
  AccountingJournalEntry,
  ACCOUNT_CODES,
  validateAccountingJournalEntry,
  JournalEntryUnbalancedError,
} from '../index';

describe('CENTRAL POOL — Step 6: Quarantined GL Double-Entry Mathematical Conservation (Simulation Only)', () => {

  const tenantId = 'tenant_prod_01';
  const nowIso = '2026-09-09T12:00:00.000Z';

  it('conserves balance for Obligation Recognition journal entry', () => {
    const entry: AccountingJournalEntry = {
      journalEntryId: 'je_ob_rec_01',
      tenantId,
      entryType: 'OBLIGATION_RECOGNITION',
      referenceType: 'CONFIRMED_ALLOCATION',
      referenceId: 'alloc_001',
      lines: [
        {
          accountCode: ACCOUNT_CODES.MEMBER_RECEIVABLE,
          accountName: 'Member Obligation Receivable',
          debitMinor: 600000,
          creditMinor: 0,
        },
        {
          accountCode: ACCOUNT_CODES.POOL_OBLIGATION_RESERVE,
          accountName: 'Central Pool Obligation Reserve',
          debitMinor: 0,
          creditMinor: 600000,
        },
      ],
      totalDebitMinor: 600000,
      totalCreditMinor: 600000,
      currency: 'USD',
      postedAt: nowIso,
      idempotencyId: 'idemp_001',
    };

    assert.doesNotThrow(() => validateAccountingJournalEntry(entry));
    assert.equal(entry.totalDebitMinor, entry.totalCreditMinor);
  });

  it('conserves balance for Contribution Recorded journal entry', () => {
    const entry: AccountingJournalEntry = {
      journalEntryId: 'je_cont_01',
      tenantId,
      entryType: 'CONTRIBUTION_RECORDED',
      referenceType: 'CONTRIBUTION_EVENT',
      referenceId: 'ce_001',
      lines: [
        {
          accountCode: ACCOUNT_CODES.SIMULATED_POOL_LIQUIDITY,
          accountName: 'Simulated Pool Liquidity',
          debitMinor: 100000,
          creditMinor: 0,
        },
        {
          accountCode: ACCOUNT_CODES.MEMBER_RECEIVABLE,
          accountName: 'Member Obligation Receivable',
          debitMinor: 0,
          creditMinor: 100000,
        },
      ],
      totalDebitMinor: 100000,
      totalCreditMinor: 100000,
      currency: 'USD',
      postedAt: nowIso,
      idempotencyId: 'idemp_002',
    };

    assert.doesNotThrow(() => validateAccountingJournalEntry(entry));
    assert.equal(entry.totalDebitMinor, entry.totalCreditMinor);
  });

  it('conserves balance for Entitlement Recognition journal entry', () => {
    const entry: AccountingJournalEntry = {
      journalEntryId: 'je_ent_rec_01',
      tenantId,
      entryType: 'ENTITLEMENT_RECOGNITION',
      referenceType: 'PAYOUT_ENTITLEMENT',
      referenceId: 'pe_001',
      lines: [
        {
          accountCode: ACCOUNT_CODES.POOL_OBLIGATION_RESERVE,
          accountName: 'Central Pool Obligation Reserve',
          debitMinor: 600000,
          creditMinor: 0,
        },
        {
          accountCode: ACCOUNT_CODES.PAYOUT_ENTITLEMENT_PAYABLE,
          accountName: 'Member Payout Entitlement Payable',
          debitMinor: 0,
          creditMinor: 600000,
        },
      ],
      totalDebitMinor: 600000,
      totalCreditMinor: 600000,
      currency: 'USD',
      postedAt: nowIso,
      idempotencyId: 'idemp_003',
    };

    assert.doesNotThrow(() => validateAccountingJournalEntry(entry));
    assert.equal(entry.totalDebitMinor, entry.totalCreditMinor);
  });

  it('strictly rejects any single-penny / single-minor imbalance', () => {
    const imbalancedEntry: AccountingJournalEntry = {
      journalEntryId: 'je_bad_01',
      tenantId,
      entryType: 'CONTRIBUTION_RECORDED',
      referenceType: 'CONTRIBUTION_EVENT',
      referenceId: 'ce_001',
      lines: [
        {
          accountCode: ACCOUNT_CODES.SIMULATED_POOL_LIQUIDITY,
          accountName: 'Simulated Pool Liquidity',
          debitMinor: 100001, // 1 cent difference
          creditMinor: 0,
        },
        {
          accountCode: ACCOUNT_CODES.MEMBER_RECEIVABLE,
          accountName: 'Member Obligation Receivable',
          debitMinor: 0,
          creditMinor: 100000,
        },
      ],
      totalDebitMinor: 100001,
      totalCreditMinor: 100000,
      currency: 'USD',
      postedAt: nowIso,
      idempotencyId: 'idemp_004',
    };

    assert.throws(() => validateAccountingJournalEntry(imbalancedEntry), JournalEntryUnbalancedError);
  });
});
