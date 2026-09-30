/**
 * Central Pool Domain Entity: IdempotencyRecord
 * Represents a deterministic record guaranteeing that client operations are executed exactly once.
 * Stored at: /idempotency_records/{idempotencyId}
 * Deterministic Key: 'idemp_' + SHA256(tenantId + ':' + memberUid + ':' + clientKey)
 */

export type IdempotencyStatus = 'PENDING' | 'COMPLETED' | 'FAILED';

export interface IdempotencyRecord {
  /** Deterministic idempotency record ID */
  idempotencyId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member user ID initiating the operation */
  memberUid: string;

  /** Client-provided idempotency key */
  clientKey: string;

  /** Operation name (e.g. 'SUBMIT_PARTICIPATION_REQUEST', 'CANCEL_PARTICIPATION_REQUEST') */
  operation: string;

  /** Lifecycle state of the idempotent execution */
  status: IdempotencyStatus;

  /** Canonical response payload or resource reference ID */
  responsePayload?: Record<string, unknown>;

  /** Error message or code if status is FAILED */
  errorDetail?: string;

  /** Record creation timestamp (RFC 3339 UTC) */
  createdAt: string;

  /** Expiration timestamp after which the idempotency record can be cleaned up */
  expiresAt: string;

  /** Optimistic concurrency version */
  version: number;
}
