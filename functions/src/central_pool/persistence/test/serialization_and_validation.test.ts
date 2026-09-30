/**
 * Central Pool Step 3: Serialization & DTO Converters Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';

import {
  ParticipationRequest,
  AllocationUnit,
  AllocationPosition,
  AllocationCandidate,
  ConfirmedAllocation,
  IdempotencyRecord,
} from '../../domain';
import {
  participationRequestToDoc,
  docToParticipationRequest,
  allocationUnitToDoc,
  docToAllocationUnit,
  allocationPositionToDoc,
  docToAllocationPosition,
  allocationCandidateToDoc,
  docToAllocationCandidate,
  confirmedAllocationToDoc,
  docToConfirmedAllocation,
  idempotencyRecordToDoc,
  docToIdempotencyRecord,
  timestampToIsoString,
  isoStringToTimestamp,
} from '../dto/dto_converters';
import { InvalidPersistenceStateError } from '../persistence_errors';
import { EntityValidationError } from '../../domain/domain_errors';

describe('CENTRAL POOL — Step 3: DTO Serialization & Converter Boundaries', () => {
  describe('1. Timestamp Conversion Utilities', () => {
    it('converts Timestamp to ISO 8601 string and back', () => {
      const iso = '2026-09-08T12:00:00.000Z';
      const ts = isoStringToTimestamp(iso, 'testField');
      assert.ok(ts instanceof Timestamp);
      const convertedBack = timestampToIsoString(ts, 'testField');
      assert.equal(convertedBack, iso);
    });

    it('rejects invalid date strings in isoStringToTimestamp', () => {
      assert.throws(
        () => isoStringToTimestamp('not-a-date', 'badField'),
        (err: any) => err instanceof InvalidPersistenceStateError
      );
      assert.throws(
        () => isoStringToTimestamp('', 'emptyField'),
        (err: any) => err instanceof InvalidPersistenceStateError
      );
    });
  });

  describe('2. ParticipationRequest Serialization & State Filtering', () => {
    const validDomainRequest: ParticipationRequest = {
      requestId: 'req_test_001',
      tenantId: 'tenant_alpha',
      memberUid: 'usr_alice',
      contributionMinor: 50000,
      currency: 'USD',
      durationPeriods: 10,
      preferredPayoutPeriod: 4,
      status: 'SUBMITTED',
      clientSubmissionId: 'sub_123',
      createdAt: '2026-09-08T12:00:00.000Z',
      updatedAt: '2026-09-08T12:00:00.000Z',
      requestExpiresAt: '2026-09-15T12:00:00.000Z',
      version: 1,
    };

    it('serializes a valid SUBMITTED domain request to Firestore DTO', () => {
      const doc = participationRequestToDoc(validDomainRequest);
      assert.equal(doc.requestId, 'req_test_001');
      assert.equal(doc.tenantId, 'tenant_alpha');
      assert.equal(doc.status, 'SUBMITTED');
      assert.ok(doc.createdAt instanceof Timestamp);
    });

    it('rejects DRAFT state from Firestore persistence', () => {
      const draftReq: ParticipationRequest = {
        ...validDomainRequest,
        status: 'DRAFT' as any,
      };
      assert.throws(
        () => participationRequestToDoc(draftReq),
        (err: any) => err instanceof InvalidPersistenceStateError
      );
    });

    it('rejects ANALYZING (transient) and MATCHED (alias) from Firestore persistence', () => {
      assert.throws(
        () => participationRequestToDoc({ ...validDomainRequest, status: 'ANALYZING' as any }),
        (err: any) => err instanceof InvalidPersistenceStateError
      );
      assert.throws(
        () => participationRequestToDoc({ ...validDomainRequest, status: 'MATCHED' as any }),
        (err: any) => err instanceof InvalidPersistenceStateError
      );
    });

    it('round-trips domain -> DTO -> domain with exact equality', () => {
      const doc = participationRequestToDoc(validDomainRequest);
      const restored = docToParticipationRequest(doc as any);
      assert.deepEqual(restored, validDomainRequest);
    });
  });

  describe('3. AllocationUnit Serialization', () => {
    const validUnit: AllocationUnit = {
      unitId: 'unit_test_001',
      tenantId: 'tenant_alpha',
      compatibilityKey: 'cp_key_123',
      memberCount: 6,
      occupiedCount: 2,
      status: 'FORMING',
      contributionMinor: 25000,
      currency: 'USD',
      durationPeriods: 6,
      allocationRule: 'SYMMETRICAL_V1',
      createdAt: '2026-09-08T12:00:00.000Z',
      updatedAt: '2026-09-08T12:00:00.000Z',
      version: 1,
    };

    it('round-trips AllocationUnit successfully', () => {
      const doc = allocationUnitToDoc(validUnit);
      const restored = docToAllocationUnit(doc as any);
      assert.deepEqual(restored, validUnit);
    });

    it('rejects invalid allocation rule during serialization', () => {
      assert.throws(
        () => allocationUnitToDoc({ ...validUnit, allocationRule: 'RANDOM' as any }),
        (err: any) => err.code === 'INVALID_ALLOCATION_RULE'
      );
    });
  });

  describe('4. AllocationPosition Serialization (Occupancy Truth)', () => {
    const validPos: AllocationPosition = {
      unitId: 'unit_test_001',
      positionNumber: 3,
      tenantId: 'tenant_alpha',
      memberUid: 'usr_alice',
      requestId: 'req_test_001',
      payoutPeriod: 3,
      occupiedAt: '2026-09-08T12:00:00.000Z',
      version: 1,
    };

    it('round-trips AllocationPosition successfully', () => {
      const doc = allocationPositionToDoc(validPos, 6);
      const restored = docToAllocationPosition(doc as any, 6);
      assert.deepEqual(restored, validPos);
    });

    it('rejects position number exceeding unit capacity', () => {
      assert.throws(
        () => allocationPositionToDoc({ ...validPos, positionNumber: 7 }, 6),
        (err: any) => err.name === 'InvalidPositionNumberError' || err.message.includes('position number must be between')
      );
    });
  });

  describe('5. AllocationCandidate & ConfirmedAllocation Serialization', () => {
    const validCandidate: AllocationCandidate = {
      candidateId: 'cand_test_001',
      requestId: 'req_test_001',
      tenantId: 'tenant_alpha',
      memberUid: 'usr_alice',
      allocationUnitId: 'unit_test_001',
      allocatedPosition: 3,
      payoutPeriod: 3,
      contributionMinor: 50000,
      durationPeriods: 10,
      totalEntitlementMinor: 500000,
      totalPotMinor: 5000000,
      currency: 'USD',
      allocationRule: 'SYMMETRICAL_V1',
      issuedAt: '2026-09-08T12:00:00.000Z',
      expiresAt: '2026-09-08T12:05:00.000Z',
      isProvisional: true,
    };

    const validConfirmed: ConfirmedAllocation = {
      allocationId: 'alloc_test_001',
      requestId: 'req_test_001',
      tenantId: 'tenant_alpha',
      memberUid: 'usr_alice',
      allocationUnitId: 'unit_test_001',
      allocatedPosition: 3,
      payoutPeriod: 3,
      contributionMinor: 50000,
      durationPeriods: 10,
      totalEntitlementMinor: 500000,
      totalPotMinor: 5000000,
      currency: 'USD',
      allocationRule: 'SYMMETRICAL_V1',
      confirmedAt: '2026-09-08T12:01:00.000Z',
      isProjection: true,
      classification: 'DERIVED_PROJECTION',
      version: 1,
    };

    it('round-trips AllocationCandidate with provisional flag', () => {
      const doc = allocationCandidateToDoc(validCandidate);
      const restored = docToAllocationCandidate(doc as any);
      assert.deepEqual(restored, validCandidate);
    });

    it('round-trips ConfirmedAllocation with projection classification', () => {
      const doc = confirmedAllocationToDoc(validConfirmed);
      const restored = docToConfirmedAllocation(doc as any);
      assert.deepEqual(restored, validConfirmed);
    });
  });

  describe('6. IdempotencyRecord Serialization', () => {
    const validRecord: IdempotencyRecord = {
      idempotencyId: 'idemp_sha256_hash',
      tenantId: 'tenant_alpha',
      memberUid: 'usr_alice',
      clientKey: 'uuid_client_key_123',
      operation: 'SUBMIT_PARTICIPATION_REQUEST',
      status: 'COMPLETED',
      responsePayload: { requestId: 'req_test_001' },
      createdAt: '2026-09-08T12:00:00.000Z',
      expiresAt: '2026-09-09T12:00:00.000Z',
      version: 1,
    };

    it('round-trips IdempotencyRecord successfully', () => {
      const doc = idempotencyRecordToDoc(validRecord);
      const restored = docToIdempotencyRecord(doc as any);
      assert.deepEqual(restored, validRecord);
    });

    it('rejects idempotency record with missing required fields', () => {
      assert.throws(
        () => idempotencyRecordToDoc({ ...validRecord, tenantId: '' }),
        (err: any) => err instanceof InvalidPersistenceStateError
      );
    });
  });
});
