/**
 * Central Pool Domain Entity: ContributionEvent
 * Represents an internal accounting event indicating a periodic contribution has been recorded.
 * Note: contribution_event != payment_transaction.
 * Stored at: /contribution_events/{contributionEventId}
 */

export interface ContributionEvent {
  /** Deterministic event ID: 'ce_' + SHA256(tenantId + ':' + obligationId + ':' + periodNumber) */
  contributionEventId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member user ID */
  memberUid: string;

  /** Financial Obligation ID */
  obligationId: string;

  /** Allocation Unit ID */
  allocationUnitId: string;

  /** Period number in [1..N] */
  periodNumber: number;

  /** Contribution amount in integer minor units */
  amountMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Timestamp when event was recorded (RFC 3339 UTC) */
  recordedAt: string;

  /** Optional linked balanced General Ledger Journal Entry ID (quarantined simulation concept) */
  journalEntryId?: string;

  /** Deterministic idempotency tracking key */
  idempotencyId: string;
}

