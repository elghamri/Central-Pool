/**
 * Central Pool Step 5: High-Fidelity Transactional In-Memory Firestore Mock
 * Supports doc(), get(), set(), update(), and atomic runTransaction() with optimistic concurrency control.
 */

import { Firestore, Timestamp } from 'firebase-admin/firestore';

export interface MockDocSnapshot {
  id: string;
  exists: boolean;
  data: () => Record<string, any> | undefined;
}

export interface MockDocumentReference {
  path: string;
  id: string;
  get: () => Promise<MockDocSnapshot>;
  set: (data: Record<string, any>) => Promise<void>;
  update: (data: Record<string, any>) => Promise<void>;
}

function resolveFieldValues(data: Record<string, any>, existingData?: Record<string, any>): Record<string, any> {
  const result: Record<string, any> = {};
  for (const [key, value] of Object.entries(data)) {
    if (value && typeof value === 'object') {
      // Check for FieldValue serverTimestamp sentinel
      if ((value as any)._methodName === 'serverTimestamp' || (value as any).constructor?.name === 'ServerTimestampTransform') {
        result[key] = Timestamp.fromDate(new Date());
        continue;
      }
      // Check for FieldValue numeric increment sentinel
      if ((value as any)._methodName === 'numericIncrement' || (value as any)._operand !== undefined) {
        const prev = (existingData && typeof existingData[key] === 'number') ? existingData[key] : 0;
        const operand = typeof (value as any)._operand === 'number' ? (value as any)._operand : 1;
        result[key] = prev + operand;
        continue;
      }
    }
    result[key] = value;
  }
  return result;
}

export class MockFirestore {
  public docs = new Map<string, { data: Record<string, any>; version: number }>();

  doc(path: string): MockDocumentReference {
    return {
      path,
      id: path.split('/').pop() || '',
      get: async () => this.getDocSnapshot(path),
      set: async (data: Record<string, any>) => {
        const existing = this.docs.get(path);
        const resolved = resolveFieldValues(data, existing?.data);
        const version = existing ? existing.version + 1 : 1;
        this.docs.set(path, { data: resolved, version });
      },
      update: async (data: Record<string, any>) => {
        const existing = this.docs.get(path);
        if (!existing) {
          throw new Error(`Document does not exist at path: ${path}`);
        }
        const resolved = resolveFieldValues(data, existing.data);
        this.docs.set(path, {
          data: { ...existing.data, ...resolved },
          version: existing.version + 1,
        });
      },
    };
  }

  private getDocSnapshot(path: string): MockDocSnapshot {
    const entry = this.docs.get(path);
    if (!entry) {
      return {
        id: path.split('/').pop() || '',
        exists: false,
        data: () => undefined,
      };
    }
    return {
      id: path.split('/').pop() || '',
      exists: true,
      data: () => ({ ...entry.data }),
    };
  }

  async runTransaction<T>(updateFunction: (tx: any) => Promise<T>): Promise<T> {
    const readVersions = new Map<string, number>();
    const pendingWrites = new Map<
      string,
      { type: 'SET' | 'UPDATE'; data: Record<string, any> }
    >();

    const tx = {
      get: async (ref: MockDocumentReference) => {
        const entry = this.docs.get(ref.path);
        const version = entry ? entry.version : 0;
        readVersions.set(ref.path, version);
        return this.getDocSnapshot(ref.path);
      },
      set: (ref: MockDocumentReference, data: Record<string, any>) => {
        pendingWrites.set(ref.path, { type: 'SET', data: { ...data } });
      },
      update: (ref: MockDocumentReference, data: Record<string, any>) => {
        pendingWrites.set(ref.path, { type: 'UPDATE', data: { ...data } });
      },
    };

    const result = await updateFunction(tx);

    // Commit Transaction: Verify optimistic concurrency on all read documents
    for (const [path, expectedVersion] of readVersions.entries()) {
      const currentEntry = this.docs.get(path);
      const currentVersion = currentEntry ? currentEntry.version : 0;
      if (currentVersion !== expectedVersion) {
        throw new Error(`Transaction contention: document at '${path}' was modified concurrently.`);
      }
    }

    // Apply all atomic writes
    for (const [path, write] of pendingWrites.entries()) {
      const current = this.docs.get(path);
      const nextVersion = current ? current.version + 1 : 1;
      if (write.type === 'SET') {
        const resolved = resolveFieldValues(write.data, current?.data);
        this.docs.set(path, { data: resolved, version: nextVersion });
      } else {
        if (!current) {
          throw new Error(`Cannot update non-existent document at '${path}'`);
        }
        const resolved = resolveFieldValues(write.data, current.data);
        this.docs.set(path, {
          data: { ...current.data, ...resolved },
          version: nextVersion,
        });
      }
    }

    return result;
  }
}

export function createMockFirestore(): Firestore {
  return new MockFirestore() as unknown as Firestore;
}
