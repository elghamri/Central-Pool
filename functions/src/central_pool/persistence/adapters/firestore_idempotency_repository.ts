/**
 * Concrete Firestore Adapter: FirestoreIdempotencyRepository
 * Manages deterministic idempotency records at /idempotency_records/{idempotencyId}.
 */

import { Firestore } from 'firebase-admin/firestore';
import { IdempotencyRecord, getIdempotencyRecordPath } from '../../domain';
import { IdempotencyRepository } from '../ports/idempotency_repository';
import { idempotencyRecordToDoc, docToIdempotencyRecord } from '../dto/dto_converters';
import { TenantIsolationViolationError } from '../persistence_errors';

export class FirestoreIdempotencyRepository implements IdempotencyRepository {
  constructor(private readonly db: Firestore) {}

  async saveIdempotencyRecord(tenantId: string, record: IdempotencyRecord): Promise<void> {
    if (!tenantId || record.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, record.tenantId, 'IdempotencyRecord');
    }

    const path = getIdempotencyRecordPath(record.idempotencyId);
    const docRef = this.db.doc(path);
    const docData = idempotencyRecordToDoc(record, true);

    await docRef.set(docData);
  }

  async getIdempotencyRecord(tenantId: string, idempotencyId: string): Promise<IdempotencyRecord | null> {
    const path = getIdempotencyRecordPath(idempotencyId);
    const docRef = this.db.doc(path);
    const snap = await docRef.get();

    if (!snap.exists) {
      return null;
    }

    const record = docToIdempotencyRecord(snap.data()!);
    if (record.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, record.tenantId, 'IdempotencyRecord');
    }

    return record;
  }
}
