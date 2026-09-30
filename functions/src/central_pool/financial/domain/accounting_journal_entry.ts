/**
 * Central Pool Domain Entity: AccountingJournalEntry
 *
 * QUARANTINE STATUS (F6-BLOCKER-01):
 * - The General Ledger double-entry posting model (including account codes 1000, 1100, 2100, 2200
 *   and entry types OBLIGATION_RECOGNITION, CONTRIBUTION_RECORDED, ENTITLEMENT_RECOGNITION)
 *   is NOT explicitly ratified as authoritative accounting truth in existing project contracts.
 * - It is classified as UNRESOLVED_ACCOUNTING_DECISION and quarantined from authoritative execution.
 * - It remains preserved purely as an internal proposed simulation representation.
 * - Invariant: sum(debitMinor) === sum(creditMinor) > 0.
 * - Stored at: /accounting_journal_entries/{journalEntryId} (Quarantined/Non-Authoritative)
 */

import { JournalEntryType, JournalLine, JournalReferenceType } from './financial_types';

export const ACCOUNT_CODES = {
  SIMULATED_POOL_LIQUIDITY: '1000-SIMULATED-POOL-LIQUIDITY',
  MEMBER_RECEIVABLE: '1100-MEMBER-RECEIVABLE',
  POOL_OBLIGATION_RESERVE: '2100-POOL-OBLIGATION-RESERVE',
  PAYOUT_ENTITLEMENT_PAYABLE: '2200-PAYOUT-ENTITLEMENT-PAYABLE',
} as const;


export interface AccountingJournalEntry {
  /** Deterministic journal entry ID: 'je_' + SHA256(tenantId + ':' + entryType + ':' + referenceId) */
  journalEntryId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Type of accounting event */
  entryType: JournalEntryType;

  /** Entity reference type linking this entry */
  referenceType: JournalReferenceType;

  /** ID of the triggering entity (allocationId, contributionEventId, etc.) */
  referenceId: string;

  /** Immutable double-entry balanced lines */
  lines: JournalLine[];

  /** Total debit in integer minor units (must equal totalCreditMinor) */
  totalDebitMinor: number;

  /** Total credit in integer minor units (must equal totalDebitMinor) */
  totalCreditMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Posting timestamp (RFC 3339 UTC) */
  postedAt: string;

  /** Deterministic idempotency tracking key */
  idempotencyId: string;
}
