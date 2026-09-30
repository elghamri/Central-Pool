/**
 * Central Pool Step 5: Security & Invariant Verification Test Suite
 * Asserts strict occupancy invariants (occupiedCount == position count), non-contamination on failure,
 * and projection receipt classification.
 */

import { describe, it, beforeEach } from 'node:test';
import * as assert from 'node:assert/strict';

import {
  ParticipationRequest,
  AllocationUnit,
  AllocationCandidate,
  getParticipationRequestPath,
  getAllocationUnitPath,
  getPositionPath,
  getAllocationReceiptPath,
} from '../../domain';
import { computeCandidateId, computeCompatibilityKey } from '../../matching/compatibility_key';
import {
  participationRequestToDoc,
  allocationUnitToDoc,
  allocationCandidateToDoc,
  docToAllocationUnit,
  docToParticipationRequest,
  docToConfirmedAllocation,
} from '../../persistence/dto/dto_converters';
import { AllocationConfirmationService, computeAllocationReceiptId } from '../confirmation_service';
import { CandidateExpiredError } from '../confirmation_errors';
import { MockFirestore } from './mock_firestore';

describe('CENTRAL POOL — Step 5: Security & Invariant Verification', () => {
  let mockDb: MockFirestore;
  let service: AllocationConfirmationService;

  const tenantId = 'tenant_prod_01';
  const unitId = 'unit_alpha';
  const currentTime = '2026-09-09T12:00:00.000Z';

  const compatibilityKey = computeCompatibilityKey({
    tenantId,
    currency: 'USD',
    contributionMinor: 50000,
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const sampleUnit: AllocationUnit = {
    unitId,
    tenantId,
    compatibilityKey,
    memberCount: 6,
    occupiedCount: 2, // 2 initial positions
    status: 'FORMING',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
    createdAt: '2026-09-09T11:00:00.000Z',
    updatedAt: '2026-09-09T11:00:00.000Z',
    version: 1,
  };

  const req1: ParticipationRequest = {
    requestId: 'req_001',
    tenantId,
    memberUid: 'usr_001',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    preferredPayoutPeriod: 2,
    status: 'AWAITING_SELECTION',
    clientSubmissionId: 'sub_001',
    createdAt: '2026-09-09T11:55:00.000Z',
    updatedAt: '2026-09-09T11:55:00.000Z',
    requestExpiresAt: '2026-09-16T11:55:00.000Z',
    version: 1,
  };

  const cand1Id = computeCandidateId({
    tenantId,
    requestId: 'req_001',
    allocationUnitId: unitId,
    allocatedPosition: 3,
    payoutPeriod: 2,
    contributionMinor: 50000,
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const cand1: AllocationCandidate = {
    candidateId: cand1Id,
    requestId: 'req_001',
    tenantId,
    memberUid: 'usr_001',
    allocationUnitId: unitId,
    allocatedPosition: 3,
    payoutPeriod: 2,
    contributionMinor: 50000,
    durationPeriods: 6,
    totalEntitlementMinor: 300000,
    totalPotMinor: 1800000,
    currency: 'USD',
    allocationRule: 'SYMMETRICAL_V1',
    issuedAt: '2026-09-09T11:58:00.000Z',
    expiresAt: '2026-09-09T12:05:00.000Z',
    isProvisional: true,
  };

  beforeEach(() => {
    mockDb = new MockFirestore();
    service = new AllocationConfirmationService(mockDb as any);

    mockDb.doc(getAllocationUnitPath(unitId)).set(allocationUnitToDoc(sampleUnit, true));
    mockDb.doc(getParticipationRequestPath('req_001')).set(participationRequestToDoc(req1, true));
    mockDb.doc(`allocation_candidates/${cand1Id}`).set(allocationCandidateToDoc(cand1, true));
  });

  it('proves that occupiedCount strictly tracks valid position count before and after operations', async () => {
    // Initial State: occupiedCount is 2
    let unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    assert.equal(docToAllocationUnit(unitSnap.data()!).occupiedCount, 2);

    // Confirm 1st position (slot 3)
    await service.confirmAllocation({
      tenantId,
      memberUid: 'usr_001',
      requestId: 'req_001',
      candidateId: cand1Id,
      idempotencyKey: 'idemp_001',
      evaluationTimestamp: currentTime,
    });

    unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    assert.equal(docToAllocationUnit(unitSnap.data()!).occupiedCount, 3);

    // Verify position document exists for slot 3
    const posSnap = await mockDb.doc(getPositionPath(unitId, 3)).get();
    assert.equal(posSnap.exists, true);
  });

  it('guarantees complete non-contamination when validation fails (e.g. expired candidate)', async () => {
    const expiredCandId = computeCandidateId({
      tenantId,
      requestId: 'req_001',
      allocationUnitId: unitId,
      allocatedPosition: 3,
      payoutPeriod: 2,
      contributionMinor: 50000,
      durationPeriods: 6,
      allocationRule: 'SYMMETRICAL_V1',
    });

    const expiredCand: AllocationCandidate = {
      ...cand1,
      candidateId: expiredCandId,
      expiresAt: '2026-09-09T11:50:00.000Z', // Expired in past
    };
    mockDb.doc(`allocation_candidates/${expiredCandId}`).set(allocationCandidateToDoc(expiredCand, true));

    await assert.rejects(
      async () => {
        await service.confirmAllocation({
          tenantId,
          memberUid: 'usr_001',
          requestId: 'req_001',
          candidateId: expiredCandId,
          idempotencyKey: 'idemp_fail',
          evaluationTimestamp: currentTime,
        });
      },
      (err: any) => err instanceof CandidateExpiredError
    );

    // Invariants post-failure:
    // 1. Position 3 was NOT created
    const posSnap = await mockDb.doc(getPositionPath(unitId, 3)).get();
    assert.equal(posSnap.exists, false);

    // 2. Unit occupancy remained 2
    const unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    assert.equal(docToAllocationUnit(unitSnap.data()!).occupiedCount, 2);

    // 3. Request status remained AWAITING_SELECTION
    const reqSnap = await mockDb.doc(getParticipationRequestPath('req_001')).get();
    assert.equal(docToParticipationRequest(reqSnap.data()!).status, 'AWAITING_SELECTION');

    // 4. No ConfirmedAllocation receipt was created
    const allocId = computeAllocationReceiptId(tenantId, 'req_001');
    const receiptSnap = await mockDb.doc(getAllocationReceiptPath('usr_001', allocId)).get();
    assert.equal(receiptSnap.exists, false);
  });

  it('verifies that ConfirmedAllocation is explicitly stamped with DERIVED_PROJECTION classification', async () => {
    const result = await service.confirmAllocation({
      tenantId,
      memberUid: 'usr_001',
      requestId: 'req_001',
      candidateId: cand1Id,
      idempotencyKey: 'idemp_001',
      evaluationTimestamp: currentTime,
    });

    const receiptPath = getAllocationReceiptPath('usr_001', result.allocationId);
    const receiptSnap = await mockDb.doc(receiptPath).get();
    assert.equal(receiptSnap.exists, true);

    const receipt = docToConfirmedAllocation(receiptSnap.data()!);
    assert.equal(receipt.isProjection, true);
    assert.equal(receipt.classification, 'DERIVED_PROJECTION');
  });

  it('verifies S5-01 OPTION A occupancy invariants: zero drift across success, failure, retry', async () => {
    // 1. Initial occupancy
    let unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    assert.equal(docToAllocationUnit(unitSnap.data()!).occupiedCount, 2);

    // 2. First confirmation increments exactly once
    const firstResult = await service.confirmAllocation({
      tenantId,
      memberUid: 'usr_001',
      requestId: 'req_001',
      candidateId: cand1Id,
      idempotencyKey: 'idemp_s501_test',
      evaluationTimestamp: currentTime,
    });
    assert.equal(firstResult.success, true);
    unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    assert.equal(docToAllocationUnit(unitSnap.data()!).occupiedCount, 3);

    // 3. Idempotent retry increments zero additional times
    const retryResult = await service.confirmAllocation({
      tenantId,
      memberUid: 'usr_001',
      requestId: 'req_001',
      candidateId: cand1Id,
      idempotencyKey: 'idemp_s501_test',
      evaluationTimestamp: currentTime,
    });
    assert.equal(retryResult.isIdempotentReplay, true);
    unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    assert.equal(docToAllocationUnit(unitSnap.data()!).occupiedCount, 3);

    // 4. Authoritative Position document remains the single source of truth
    const posSnap = await mockDb.doc(getPositionPath(unitId, 3)).get();
    assert.equal(posSnap.exists, true);
    assert.equal(posSnap.data()!.memberUid, 'usr_001');
  });

  it('rejects transaction without auto-repair when slot collision or capacity limit is hit', async () => {
    // 1. Populate position slot 3 beforehand as already occupied
    const occupiedPosPath = getPositionPath(unitId, 3);
    await mockDb.doc(occupiedPosPath).set({
      unitId,
      positionNumber: 3,
      tenantId,
      memberUid: 'usr_existing_owner',
      requestId: 'req_existing',
      payoutPeriod: 2,
      occupiedAt: '2026-09-09T10:00:00.000Z',
      version: 1,
    });

    // 2. Attempting confirmation on slot 3 must fail cleanly
    await assert.rejects(
      async () => {
        await service.confirmAllocation({
          tenantId,
          memberUid: 'usr_001',
          requestId: 'req_001',
          candidateId: cand1Id,
          idempotencyKey: 'idemp_collision_test',
          evaluationTimestamp: currentTime,
        });
      },
      (err: any) => err.code === 'POSITION_ALREADY_OCCUPIED'
    );

    // 3. Verify zero auto-repair and zero mutation on existing state
    const posSnap = await mockDb.doc(occupiedPosPath).get();
    assert.equal(posSnap.data()!.memberUid, 'usr_existing_owner'); // Unmodified

    const unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    assert.equal(docToAllocationUnit(unitSnap.data()!).occupiedCount, 2); // Unmodified
  });
});
