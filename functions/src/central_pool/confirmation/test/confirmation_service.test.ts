/**
 * Central Pool Step 5: Authoritative Confirmation Service Test Suite
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
  docToAllocationPosition,
  docToAllocationUnit,
  docToParticipationRequest,
  docToConfirmedAllocation,
} from '../../persistence/dto/dto_converters';
import { EntityNotFoundError } from '../../persistence/persistence_errors';
import { AllocationConfirmationService, computeAllocationReceiptId } from '../confirmation_service';
import { AllocationConfirmationInput } from '../confirmation_types';
import { ParticipationRequestNotConfirmableError } from '../confirmation_errors';
import { createMockFirestore, MockFirestore } from './mock_firestore';

describe('CENTRAL POOL — Step 5: Authoritative Allocation Confirmation Service', () => {
  let mockDb: MockFirestore;
  let service: AllocationConfirmationService;

  const tenantId = 'tenant_prod_01';
  const memberUid = 'usr_alice';
  const requestId = 'req_001';
  const unitId = 'unit_alpha';
  const currentTime = '2026-09-09T12:00:00.000Z';

  const compatibilityKey = computeCompatibilityKey({
    tenantId,
    currency: 'USD',
    contributionMinor: 50000,
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const sampleRequest: ParticipationRequest = {
    requestId,
    tenantId,
    memberUid,
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    preferredPayoutPeriod: 2,
    status: 'AWAITING_SELECTION',
    clientSubmissionId: 'sub_123',
    createdAt: '2026-09-09T11:55:00.000Z',
    updatedAt: '2026-09-09T11:55:00.000Z',
    requestExpiresAt: '2026-09-16T11:55:00.000Z',
    version: 1,
  };

  const sampleUnit: AllocationUnit = {
    unitId,
    tenantId,
    compatibilityKey,
    memberCount: 6,
    occupiedCount: 2,
    status: 'FORMING',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
    createdAt: '2026-09-09T11:00:00.000Z',
    updatedAt: '2026-09-09T11:00:00.000Z',
    version: 1,
  };

  const candidateId = computeCandidateId({
    tenantId,
    requestId,
    allocationUnitId: unitId,
    allocatedPosition: 3,
    payoutPeriod: 2,
    contributionMinor: 50000,
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const sampleCandidate: AllocationCandidate = {
    candidateId,
    requestId,
    tenantId,
    memberUid,
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

  const sampleInput: AllocationConfirmationInput = {
    tenantId,
    memberUid,
    requestId,
    candidateId,
    idempotencyKey: 'idemp_key_123',
    evaluationTimestamp: currentTime,
  };

  beforeEach(() => {
    mockDb = new MockFirestore();
    service = new AllocationConfirmationService(mockDb as any);

    // Populate initial state
    mockDb.doc(getParticipationRequestPath(requestId)).set(participationRequestToDoc(sampleRequest, true));
    mockDb.doc(getAllocationUnitPath(unitId)).set(allocationUnitToDoc(sampleUnit, true));
    mockDb.doc(`allocation_candidates/${candidateId}`).set(allocationCandidateToDoc(sampleCandidate, true));
  });

  it('atomically executes authoritative confirmation and updates all consistency boundaries', async () => {
    const result = await service.confirmAllocation(sampleInput);

    // 1. Validate result structure
    assert.equal(result.success, true);
    assert.equal(result.tenantId, tenantId);
    assert.equal(result.memberUid, memberUid);
    assert.equal(result.requestId, requestId);
    assert.equal(result.allocationUnitId, unitId);
    assert.equal(result.allocatedPosition, 3);
    assert.equal(result.payoutPeriod, 2);
    assert.equal(result.totalEntitlementMinor, 300000);
    assert.equal(result.totalPotMinor, 1800000);
    assert.equal(result.isIdempotentReplay, false);
    assert.equal(result.unitTransitionedToCommittedFull, false);

    // 2. Authoritative Position Document Created
    const posPath = getPositionPath(unitId, 3);
    const posSnap = await mockDb.doc(posPath).get();
    assert.equal(posSnap.exists, true);
    const pos = docToAllocationPosition(posSnap.data()!, 6);
    assert.equal(pos.unitId, unitId);
    assert.equal(pos.positionNumber, 3);
    assert.equal(pos.memberUid, memberUid);
    assert.equal(pos.requestId, requestId);
    assert.equal(pos.payoutPeriod, 2);

    // 3. Unit Occupancy Updated
    const unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    const updatedUnit = docToAllocationUnit(unitSnap.data()!);
    assert.equal(updatedUnit.occupiedCount, 3); // 2 -> 3
    assert.equal(updatedUnit.status, 'FORMING');

    // 4. Participation Request Transitioned to CONFIRMED
    const reqSnap = await mockDb.doc(getParticipationRequestPath(requestId)).get();
    const updatedReq = docToParticipationRequest(reqSnap.data()!);
    assert.equal(updatedReq.status, 'CONFIRMED');
    assert.equal(updatedReq.allocationUnitId, unitId);
    assert.equal(updatedReq.allocatedPosition, 3);
    assert.equal(updatedReq.payoutPeriod, 2);

    // 5. Derived Projection Receipt Created
    const expectedAllocId = computeAllocationReceiptId(tenantId, requestId);
    const receiptPath = getAllocationReceiptPath(memberUid, expectedAllocId);
    const receiptSnap = await mockDb.doc(receiptPath).get();
    assert.equal(receiptSnap.exists, true);
    const receipt = docToConfirmedAllocation(receiptSnap.data()!);
    assert.equal(receipt.allocationId, expectedAllocId);
    assert.equal(receipt.isProjection, true);
    assert.equal(receipt.classification, 'DERIVED_PROJECTION');
  });

  it('atomically transitions unit to COMMITTED_FULL when final capacity slot is acquired', async () => {
    // Set unit occupiedCount to 5 (out of 6 capacity)
    const almostFullUnit: AllocationUnit = {
      ...sampleUnit,
      occupiedCount: 5,
    };
    mockDb.doc(getAllocationUnitPath(unitId)).set(allocationUnitToDoc(almostFullUnit, true));

    // Position 6 maps to primary payout period 3
    const candId6 = computeCandidateId({
      tenantId,
      requestId,
      allocationUnitId: unitId,
      allocatedPosition: 6,
      payoutPeriod: 3,
      contributionMinor: 50000,
      durationPeriods: 6,
      allocationRule: 'SYMMETRICAL_V1',
    });

    const cand6: AllocationCandidate = {
      ...sampleCandidate,
      candidateId: candId6,
      allocatedPosition: 6,
      payoutPeriod: 3,
    };
    mockDb.doc(`allocation_candidates/${candId6}`).set(allocationCandidateToDoc(cand6, true));

    const result = await service.confirmAllocation({
      ...sampleInput,
      candidateId: candId6,
    });

    assert.equal(result.success, true);
    assert.equal(result.unitTransitionedToCommittedFull, true);

    const unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    const updatedUnit = docToAllocationUnit(unitSnap.data()!);
    assert.equal(updatedUnit.occupiedCount, 6);
    assert.equal(updatedUnit.status, 'COMMITTED_FULL');
  });

  it('successfully confirms when request is already in REVALIDATING state', async () => {
    const revalReq: ParticipationRequest = {
      ...sampleRequest,
      status: 'REVALIDATING',
    };
    mockDb.doc(getParticipationRequestPath(requestId)).set(participationRequestToDoc(revalReq, true));

    const result = await service.confirmAllocation(sampleInput);
    assert.equal(result.success, true);

    const reqSnap = await mockDb.doc(getParticipationRequestPath(requestId)).get();
    assert.equal(docToParticipationRequest(reqSnap.data()!).status, 'CONFIRMED');
  });

  it('rejects confirmation when request is in SUBMITTED state (must be matched & in selection)', async () => {
    const subReq: ParticipationRequest = {
      ...sampleRequest,
      status: 'SUBMITTED',
    };
    mockDb.doc(getParticipationRequestPath(requestId)).set(participationRequestToDoc(subReq, true));

    await assert.rejects(
      async () => {
        await service.confirmAllocation(sampleInput);
      },
      (err: any) => err instanceof ParticipationRequestNotConfirmableError
    );
  });

  it('throws EntityNotFoundError when request or unit does not exist', async () => {
    await assert.rejects(
      async () => {
        await service.confirmAllocation({
          ...sampleInput,
          requestId: 'req_non_existent',
        });
      },
      (err: any) => err instanceof EntityNotFoundError
    );
  });
});
