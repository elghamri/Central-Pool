/**
 * Central Pool Financial Foundation Types
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT v1.8 (Step 6)
 *
 * PROVENANCE & SEMANTIC BOUNDARY:
 * - FinancialObligation represents an internal simulation/accounting expected contribution obligation (Meaning A).
 * - It does NOT establish legal liability, custody, external debt, or real-money settlement (FM-02 unresolved).
 */

export type FinancialObligationStatus = 'ACTIVE' | 'FULFILLED';

export type ScheduledPeriodStatus = 'SCHEDULED' | 'RECORDED';

export type PayoutEntitlementStatus = 'SCHEDULED';

export type JournalEntryType =
  | 'OBLIGATION_RECOGNITION'
  | 'CONTRIBUTION_RECORDED'
  | 'ENTITLEMENT_RECOGNITION';

export type JournalReferenceType =
  | 'CONFIRMED_ALLOCATION'
  | 'CONTRIBUTION_EVENT'
  | 'PAYOUT_ENTITLEMENT';

export interface JournalLine {
  /** Standard General Ledger Account Code */
  accountCode: string;

  /** Human-readable Account Name */
  accountName: string;

  /** Debit amount in positive integer minor units */
  debitMinor: number;

  /** Credit amount in positive integer minor units */
  creditMinor: number;
}
