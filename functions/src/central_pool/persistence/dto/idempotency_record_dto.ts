/**
 * Firestore DTO: IdempotencyRecordDoc
 * Represents the document stored at /idempotency_records/{idempotencyId}
 */

import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { IdempotencyStatus } from '../../domain/idempotency_record';

export interface IdempotencyRecordDoc {
  idempotencyId: string;
  tenantId: string;
  memberUid: string;
  clientKey: string;
  operation: string;
  status: IdempotencyStatus;
  responsePayload?: Record<string, unknown>;
  errorDetail?: string;
  createdAt: Timestamp | FieldValue;
  expiresAt: Timestamp;
  version: number;
}
