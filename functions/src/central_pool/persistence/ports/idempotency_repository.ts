/**
 * Repository Interface: IdempotencyRepository
 * Manages deterministic idempotency records under /idempotency_records/{idempotencyId}.
 */

import { IdempotencyRecord } from '../../domain';

export interface IdempotencyRepository {
  /**
   * Saves or updates an idempotency record.
   */
  saveIdempotencyRecord(tenantId: string, record: IdempotencyRecord): Promise<void>;

  /**
   * Retrieves an idempotency record by its deterministic ID.
   */
  getIdempotencyRecord(tenantId: string, idempotencyId: string): Promise<IdempotencyRecord | null>;
}
