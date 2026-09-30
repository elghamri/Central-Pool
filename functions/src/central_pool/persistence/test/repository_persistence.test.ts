/**
 * Central Pool Step 3: Repository Persistence & Tenant/Member Isolation Test Suite
 * Tests concrete Firestore repository adapters against in-memory Firestore document storage.
 */

import { describe, it, beforeEach } from 'node:test';
import * as assert from 'node:assert/strict';
import { Timestamp, FieldValue } from 'firebase-admin/firestore';

import {
  ParticipationRequest,
  AllocationUnit,
  AllocationPosition,
  AllocationCandidate,
  ConfirmedAllocation,
  IdempotencyRecord,
} from '../../domain';
import {
  FirestoreParticipationRequestRepository,
  FirestoreAllocationUnitRepository,
  FirestoreAllocationPositionRepository,
  FirestoreAllocationCandidateRepository,
  FirestoreConfirmedAllocationProjectionRepository,
  FirestoreIdempotencyRepository,
  TenantIsolationViolationError,
  MemberOwnershipViolationError,
  EntityNotFoundError,
  DuplicateEntityError,
  InvalidPersistenceStateError,
} from '../index';
import { InvalidStateTransitionError } from '../../domain/domain_errors';

/**
 * Deterministic in-memory mock Firestore implementation for unit testing adapters.
 */
class InMemoryFirestore {
  private docs: Map<string, Record<string, any>> = new Map();

  doc(path: string) {
    const self = this;
    return {
      path,
      async get() {
        const data = self.docs.get(path);
        return {
          exists: data !== undefined,
          data: () => (data ? JSON.parse(JSON.stringify(data), self.dateReviver) : undefined),
        };
      },
      async set(data: Record<string, any>) {
        const processed = self.processTimestamps(data);
        self.docs.set(path, processed);
      },
      async update(updates: Record<string, any>) {
        const existing = self.docs.get(path);
        if (!existing) throw new Error(`Doc at ${path} not found for update`);
        const processed = self.processTimestamps(updates);
        self.docs.set(path, { ...existing, ...processed });
      },
      async delete() {
        self.docs.delete(path);
      },
      collection(subPath: string) {
        return self.collection(`${path}/${subPath}`);
      },
    };
  }

  collection(collPath: string) {
    const self = this;
    return {
      doc(id?: string) {
        const docId = id || `auto_${Math.random().toString(36).substring(2, 9)}`;
        return self.doc(`${collPath}/${docId}`);
      },
      where(field: string, op: string, val: any) {
        return this.createFilteredQuery([[field, op, val]]);
      },
      async get() {
        return this.createFilteredQuery([]).get();
      },
      createFilteredQuery(filters: [string, string, any][]) {
        return {
          where(field: string, op: string, val: any) {
            return self.collection(collPath).createFilteredQuery([...filters, [field, op, val]]);
          },
          async get() {
            const results: { data: () => Record<string, any> }[] = [];
            for (const [p, docData] of self.docs.entries()) {
              if (p.startsWith(`${collPath}/`) && p.substring(collPath.length + 1).indexOf('/') === -1) {
                let matches = true;
                for (const [field, op, val] of filters) {
                  if (op === '==' && docData[field] !== val) {
                    matches = false;
                    break;
                  }
                }
                if (matches) {
                  results.push({
                    data: () => JSON.parse(JSON.stringify(docData), self.dateReviver),
                  });
                }
              }
            }
            return { docs: results };
          },
        };
      },
    };
  }

  async runTransaction<T>(fn: (tx: any) => Promise<T>): Promise<T> {
    const self = this;
    const tx = {
      async get(ref: any) {
        return ref.get();
      },
      set(ref: any, data: any) {
        ref.set(data);
      },
      update(ref: any, updates: any) {
        ref.update(updates);
      },
      delete(ref: any) {
        ref.delete();
      },
    };
    return fn(tx);
  }

  private processTimestamps(obj: Record<string, any>): Record<string, any> {
    const res: Record<string, any> = {};
    for (const [k, v] of Object.entries(obj)) {
      if (v instanceof FieldValue || (v && v.constructor && v.constructor.name === 'FieldValue')) {
        res[k] = Timestamp.fromDate(new Date());
      } else if (v instanceof Timestamp) {
        res[k] = v;
      } else {
        res[k] = v;
      }
    }
    return res;
  }

  private dateReviver(key: string, value: any) {
    if (value && typeof value === 'object' && value._seconds !== undefined) {
      return new Timestamp(value._seconds, value._nanoseconds);
    }
    return value;
  }
}

describe('CENTRAL POOL — Step 3: Repository Persistence & Isolation Tests', () => {
  let db: any;
  let requestRepo: FirestoreParticipationRequestRepository;
  let unitRepo: FirestoreAllocationUnitRepository;
  let positionRepo: FirestoreAllocationPositionRepository;
  let candidateRepo: FirestoreAllocationCandidateRepository;
  let projectionRepo: FirestoreConfirmedAllocationProjectionRepository;
  let idempotencyRepo: FirestoreIdempotencyRepository;

  beforeEach(() => {
    db = new InMemoryFirestore();
    requestRepo = new FirestoreParticipationRequestRepository(db);
    unitRepo = new FirestoreAllocationUnitRepository(db);
    positionRepo = new FirestoreAllocationPositionRepository(db);
    candidateRepo = new FirestoreAllocationCandidateRepository(db);
    projectionRepo = new FirestoreConfirmedAllocationProjectionRepository(db);
    idempotencyRepo = new FirestoreIdempotencyRepository(db);
  });

  describe('1. ParticipationRequestRepository', () => {
    const sampleReq: ParticipationRequest = {
      requestId: 'req_001',
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_alice',
      contributionMinor: 50000,
      currency: 'USD',
      durationPeriods: 10,
      preferredPayoutPeriod: 3,
      status: 'SUBMITTED',
      clientSubmissionId: 'sub_uuid_1',
      createdAt: '2026-09-08T12:00:00.000Z',
      updatedAt: '2026-09-08T12:00:00.000Z',
      requestExpiresAt: '2026-09-15T12:00:00.000Z',
      version: 1,
    };

    it('persists a new SUBMITTED request successfully', async () => {
      await requestRepo.createSubmittedRequest('tenant_prod_01', sampleReq);
      const fetched = await requestRepo.getRequest('tenant_prod_01', 'req_001');
      assert.ok(fetched);
      assert.equal(fetched.requestId, 'req_001');
      assert.equal(fetched.status, 'SUBMITTED');
    });

    it('rejects creation if tenantId does not match caller tenant', async () => {
      await assert.rejects(
        () => requestRepo.createSubmittedRequest('tenant_wrong', sampleReq),
        (err: any) => err instanceof TenantIsolationViolationError
      );
    });

    it('rejects creation if request is already persisted (duplicate ID)', async () => {
      await requestRepo.createSubmittedRequest('tenant_prod_01', sampleReq);
      await assert.rejects(
        () => requestRepo.createSubmittedRequest('tenant_prod_01', sampleReq),
        (err: any) => err instanceof DuplicateEntityError
      );
    });

    it('enforces tenant isolation on getRequest', async () => {
      await requestRepo.createSubmittedRequest('tenant_prod_01', sampleReq);
      await assert.rejects(
        () => requestRepo.getRequest('tenant_other', 'req_001'),
        (err: any) => err instanceof TenantIsolationViolationError
      );
    });

    it('updates request lifecycle state on legal forward transition', async () => {
      await requestRepo.createSubmittedRequest('tenant_prod_01', sampleReq);
      await requestRepo.updateRequestState(
        'tenant_prod_01',
        'req_001',
        'SUBMITTED',
        'AWAITING_SELECTION'
      );
      const updated = await requestRepo.getRequest('tenant_prod_01', 'req_001');
      assert.equal(updated?.status, 'AWAITING_SELECTION');
      assert.equal(updated?.version, 2);
    });

    it('rejects state update if expected current state does not match', async () => {
      await requestRepo.createSubmittedRequest('tenant_prod_01', sampleReq);
      await assert.rejects(
        () => requestRepo.updateRequestState('tenant_prod_01', 'req_001', 'AWAITING_SELECTION', 'REVALIDATING'),
        (err: any) => err instanceof InvalidPersistenceStateError
      );
    });

    it('rejects state update on prohibited transition (e.g. SUBMITTED -> CONFIRMED)', async () => {
      await requestRepo.createSubmittedRequest('tenant_prod_01', sampleReq);
      await assert.rejects(
        () => requestRepo.updateRequestState('tenant_prod_01', 'req_001', 'SUBMITTED', 'CONFIRMED'),
        (err: any) => err instanceof InvalidStateTransitionError
      );
    });

    it('lists member requests filtered strictly by tenant', async () => {
      await requestRepo.createSubmittedRequest('tenant_prod_01', sampleReq);
      const list = await requestRepo.listMemberRequests('tenant_prod_01', 'usr_alice');
      assert.equal(list.length, 1);
      assert.equal(list[0].requestId, 'req_001');

      const wrongTenantList = await requestRepo.listMemberRequests('tenant_other', 'usr_alice');
      assert.equal(wrongTenantList.length, 0);
    });
  });

  describe('2. AllocationUnitRepository', () => {
    const sampleUnit: AllocationUnit = {
      unitId: 'unit_001',
      tenantId: 'tenant_prod_01',
      compatibilityKey: 'cp_tuple_hash',
      memberCount: 6,
      occupiedCount: 0,
      status: 'FORMING',
      contributionMinor: 25000,
      currency: 'USD',
      durationPeriods: 6,
      allocationRule: 'SYMMETRICAL_V1',
      createdAt: '2026-09-08T12:00:00.000Z',
      updatedAt: '2026-09-08T12:00:00.000Z',
      version: 1,
    };

    it('creates a FORMING allocation unit', async () => {
      await unitRepo.createFormingUnit('tenant_prod_01', sampleUnit);
      const fetched = await unitRepo.getAllocationUnit('tenant_prod_01', 'unit_001');
      assert.ok(fetched);
      assert.equal(fetched.status, 'FORMING');
    });

    it('rejects non-FORMING initial status', async () => {
      await assert.rejects(
        () => unitRepo.createFormingUnit('tenant_prod_01', { ...sampleUnit, status: 'COMMITTED_FULL' }),
        (err: any) => err instanceof InvalidPersistenceStateError
      );
    });

    it('rejects tenant mismatch on create and read', async () => {
      await assert.rejects(
        () => unitRepo.createFormingUnit('tenant_wrong', sampleUnit),
        (err: any) => err instanceof TenantIsolationViolationError
      );

      await unitRepo.createFormingUnit('tenant_prod_01', sampleUnit);
      await assert.rejects(
        () => unitRepo.getAllocationUnit('tenant_wrong', 'unit_001'),
        (err: any) => err instanceof TenantIsolationViolationError
      );
    });

    it('allows FORMING -> COMMITTED_FULL transition only when occupiedCount === memberCount', async () => {
      await unitRepo.createFormingUnit('tenant_prod_01', sampleUnit);

      // Attempt COMMITTED_FULL with occupiedCount = 5 < 6
      await assert.rejects(
        () => unitRepo.updateUnitState('tenant_prod_01', 'unit_001', 'FORMING', 'COMMITTED_FULL', 5),
        (err: any) => err instanceof InvalidPersistenceStateError
      );

      // Transition with occupiedCount = 6
      await unitRepo.updateUnitState('tenant_prod_01', 'unit_001', 'FORMING', 'COMMITTED_FULL', 6);
      const fullUnit = await unitRepo.getAllocationUnit('tenant_prod_01', 'unit_001');
      assert.equal(fullUnit?.status, 'COMMITTED_FULL');
      assert.equal(fullUnit?.occupiedCount, 6);
    });
  });

  describe('3. AllocationPositionRepository (Authoritative Occupancy Truth)', () => {
    const parentUnit: AllocationUnit = {
      unitId: 'unit_parent_01',
      tenantId: 'tenant_prod_01',
      compatibilityKey: 'cp_key_1',
      memberCount: 6,
      occupiedCount: 1,
      status: 'FORMING',
      contributionMinor: 50000,
      currency: 'USD',
      durationPeriods: 6,
      allocationRule: 'SYMMETRICAL_V1',
      createdAt: '2026-09-08T12:00:00.000Z',
      updatedAt: '2026-09-08T12:00:00.000Z',
      version: 1,
    };

    const samplePos: AllocationPosition = {
      unitId: 'unit_parent_01',
      positionNumber: 2,
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_alice',
      requestId: 'req_001',
      payoutPeriod: 2,
      occupiedAt: '2026-09-08T12:05:00.000Z',
      version: 1,
    };

    it('creates authoritative position slot under parent Allocation Unit', async () => {
      await unitRepo.createFormingUnit('tenant_prod_01', parentUnit);
      await positionRepo.createPosition('tenant_prod_01', samplePos, 6);

      const fetched = await positionRepo.getPosition('tenant_prod_01', 'unit_parent_01', 2, 6);
      assert.ok(fetched);
      assert.equal(fetched.positionNumber, 2);
      assert.equal(fetched.memberUid, 'usr_alice');
    });

    it('rejects position creation if parent unit does not exist', async () => {
      await assert.rejects(
        () => positionRepo.createPosition('tenant_prod_01', samplePos, 6),
        (err: any) => err instanceof EntityNotFoundError
      );
    });

    it('rejects position creation if parent unit tenant differs from position tenant', async () => {
      await unitRepo.createFormingUnit('tenant_prod_01', parentUnit);
      await assert.rejects(
        () => positionRepo.createPosition('tenant_wrong', { ...samplePos, tenantId: 'tenant_wrong' }, 6),
        (err: any) => err instanceof TenantIsolationViolationError
      );
    });

    it('rejects duplicate position slot creation within same unit', async () => {
      await unitRepo.createFormingUnit('tenant_prod_01', parentUnit);
      await positionRepo.createPosition('tenant_prod_01', samplePos, 6);

      await assert.rejects(
        () => positionRepo.createPosition('tenant_prod_01', samplePos, 6),
        (err: any) => err instanceof DuplicateEntityError
      );
    });

    it('lists all occupied positions for a unit', async () => {
      await unitRepo.createFormingUnit('tenant_prod_01', parentUnit);
      await positionRepo.createPosition('tenant_prod_01', samplePos, 6);
      await positionRepo.createPosition(
        'tenant_prod_01',
        { ...samplePos, positionNumber: 4, memberUid: 'usr_bob', payoutPeriod: 4 },
        6
      );

      const positions = await positionRepo.listPositionsForUnit('tenant_prod_01', 'unit_parent_01', 6);
      assert.equal(positions.length, 2);
    });
  });

  describe('4. ConfirmedAllocationProjectionRepository (Derived Read-Model)', () => {
    const sampleConfirmed: ConfirmedAllocation = {
      allocationId: 'alloc_req_001',
      requestId: 'req_001',
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_alice',
      allocationUnitId: 'unit_parent_01',
      allocatedPosition: 2,
      payoutPeriod: 2,
      contributionMinor: 50000,
      durationPeriods: 6,
      totalEntitlementMinor: 300000,
      totalPotMinor: 1800000,
      currency: 'USD',
      allocationRule: 'SYMMETRICAL_V1',
      confirmedAt: '2026-09-08T12:05:00.000Z',
      isProjection: true,
      classification: 'DERIVED_PROJECTION',
      version: 1,
    };

    it('saves and retrieves a member-facing confirmed allocation projection receipt', async () => {
      await projectionRepo.saveMemberProjection('tenant_prod_01', 'usr_alice', sampleConfirmed);
      const fetched = await projectionRepo.getMemberProjection('tenant_prod_01', 'usr_alice', 'alloc_req_001');

      assert.ok(fetched);
      assert.equal(fetched.allocationId, 'alloc_req_001');
      assert.equal(fetched.isProjection, true);
      assert.equal(fetched.classification, 'DERIVED_PROJECTION');
    });

    it('rejects save if tenant or memberUid mismatch caller context', async () => {
      await assert.rejects(
        () => projectionRepo.saveMemberProjection('tenant_wrong', 'usr_alice', sampleConfirmed),
        (err: any) => err instanceof TenantIsolationViolationError
      );
      await assert.rejects(
        () => projectionRepo.saveMemberProjection('tenant_prod_01', 'usr_bob', sampleConfirmed),
        (err: any) => err instanceof MemberOwnershipViolationError
      );
    });

    it('enforces member ownership isolation on getMemberProjection and saveMemberProjection', async () => {
      await projectionRepo.saveMemberProjection('tenant_prod_01', 'usr_alice', sampleConfirmed);

      // Querying for non-existent doc returns null
      const nonExistent = await projectionRepo.getMemberProjection('tenant_prod_01', 'usr_bob', 'alloc_req_001');
      assert.equal(nonExistent, null);

      // Attempting to save with mismatched memberUid throws MemberOwnershipViolationError
      await assert.rejects(
        () => projectionRepo.saveMemberProjection('tenant_prod_01', 'usr_bob', sampleConfirmed),
        (err: any) => err instanceof MemberOwnershipViolationError
      );

      // Attempting to read a doc whose payload memberUid does not match caller memberUid throws MemberOwnershipViolationError
      await db.doc('users/usr_bob/allocations/alloc_corrupted').set({
        ...sampleConfirmed,
        allocationId: 'alloc_corrupted',
        memberUid: 'usr_alice', // Payload belongs to alice, stored under bob
      });

      await assert.rejects(
        () => projectionRepo.getMemberProjection('tenant_prod_01', 'usr_bob', 'alloc_corrupted'),
        (err: any) => err instanceof MemberOwnershipViolationError
      );
    });
  });

  describe('5. IdempotencyRepository', () => {
    const sampleIdemp: IdempotencyRecord = {
      idempotencyId: 'idemp_hash_123',
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_alice',
      clientKey: 'client_uuid_abc',
      operation: 'SUBMIT_PARTICIPATION_REQUEST',
      status: 'PENDING',
      createdAt: '2026-09-08T12:00:00.000Z',
      expiresAt: '2026-09-09T12:00:00.000Z',
      version: 1,
    };

    it('saves and retrieves an idempotency record', async () => {
      await idempotencyRepo.saveIdempotencyRecord('tenant_prod_01', sampleIdemp);
      const fetched = await idempotencyRepo.getIdempotencyRecord('tenant_prod_01', 'idemp_hash_123');

      assert.ok(fetched);
      assert.equal(fetched.idempotencyId, 'idemp_hash_123');
      assert.equal(fetched.status, 'PENDING');
    });

    it('enforces tenant isolation on idempotency access', async () => {
      await idempotencyRepo.saveIdempotencyRecord('tenant_prod_01', sampleIdemp);
      await assert.rejects(
        () => idempotencyRepo.getIdempotencyRecord('tenant_wrong', 'idemp_hash_123'),
        (err: any) => err instanceof TenantIsolationViolationError
      );
    });
  });
});
