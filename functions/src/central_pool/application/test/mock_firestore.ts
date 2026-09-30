/**
 * Central Pool Step 8: Transactional In-Memory Mock Firestore
 * Supports doc(), collection(), where() query filtering, FieldValues, and atomic runTransaction().
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
  delete: () => Promise<void>;
  collection: (subPath: string) => MockCollectionReference;
}

export interface MockQuerySnapshot {
  docs: Array<{ id: string; exists: boolean; data: () => Record<string, any> }>;
  empty: boolean;
  size: number;
}

export interface MockCollectionReference {
  doc: (id?: string) => MockDocumentReference;
  where: (field: string, op: string, val: any) => MockQuery;
  get: () => Promise<MockQuerySnapshot>;
}

export interface MockQuery {
  where: (field: string, op: string, val: any) => MockQuery;
  get: () => Promise<MockQuerySnapshot>;
}

function resolveFieldValues(data: Record<string, any>, existingData?: Record<string, any>): Record<string, any> {
  const result: Record<string, any> = {};
  for (const [key, value] of Object.entries(data)) {
    if (value && typeof value === 'object') {
      if ((value as any)._methodName === 'serverTimestamp' || (value as any).constructor?.name === 'ServerTimestampTransform') {
        result[key] = Timestamp.fromDate(new Date());
        continue;
      }
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
    const self = this;
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
      delete: async () => {
        this.docs.delete(path);
      },
      collection: (subPath: string) => self.collection(`${path}/${subPath}`),
    };
  }

  collection(collPath: string): MockCollectionReference {
    const self = this;
    return {
      doc(id?: string): MockDocumentReference {
        const docId = id || `auto_${Math.random().toString(36).substring(2, 9)}`;
        return self.doc(`${collPath}/${docId}`);
      },
      where(field: string, op: string, val: any): MockQuery {
        return self.createQuery(collPath, [[field, op, val]]);
      },
      get: async (): Promise<MockQuerySnapshot> => {
        return self.createQuery(collPath, []).get();
      },
    };
  }

  private createQuery(collPath: string, filters: [string, string, any][]): MockQuery {
    const self = this;
    return {
      where(field: string, op: string, val: any): MockQuery {
        return self.createQuery(collPath, [...filters, [field, op, val]]);
      },
      get: async (): Promise<MockQuerySnapshot> => {
        const matchingDocs: Array<{ id: string; exists: boolean; data: () => Record<string, any> }> = [];
        for (const [p, entry] of self.docs.entries()) {
          if (p.startsWith(`${collPath}/`) && p.substring(collPath.length + 1).indexOf('/') === -1) {
            let matches = true;
            for (const [field, op, val] of filters) {
              if (op === '==' && entry.data[field] !== val) {
                matches = false;
                break;
              }
            }
            if (matches) {
              matchingDocs.push({
                id: p.split('/').pop() || '',
                exists: true,
                data: () => ({ ...entry.data }),
              });
            }
          }
        }
        return {
          docs: matchingDocs,
          empty: matchingDocs.length === 0,
          size: matchingDocs.length,
        };
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
      { type: 'SET' | 'UPDATE' | 'DELETE'; data?: Record<string, any> }
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
      delete: (ref: MockDocumentReference) => {
        pendingWrites.set(ref.path, { type: 'DELETE' });
      },
    };

    const result = await updateFunction(tx);

    // Concurrency verification
    for (const [path, expectedVersion] of readVersions.entries()) {
      const currentEntry = this.docs.get(path);
      const currentVersion = currentEntry ? currentEntry.version : 0;
      if (currentVersion !== expectedVersion) {
        throw new Error(`Transaction contention: document at '${path}' was modified concurrently.`);
      }
    }

    // Apply writes
    for (const [path, write] of pendingWrites.entries()) {
      const current = this.docs.get(path);
      const nextVersion = current ? current.version + 1 : 1;
      if (write.type === 'SET') {
        const resolved = resolveFieldValues(write.data || {}, current?.data);
        this.docs.set(path, { data: resolved, version: nextVersion });
      } else if (write.type === 'UPDATE') {
        if (!current) {
          throw new Error(`Cannot update non-existent document at '${path}'`);
        }
        const resolved = resolveFieldValues(write.data || {}, current.data);
        this.docs.set(path, {
          data: { ...current.data, ...resolved },
          version: nextVersion,
        });
      } else if (write.type === 'DELETE') {
        this.docs.delete(path);
      }
    }

    return result;
  }
}

export function createMockFirestore(): Firestore {
  return new MockFirestore() as unknown as Firestore;
}
