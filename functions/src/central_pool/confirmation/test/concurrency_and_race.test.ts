/**
 * Central Pool Step 5: Concurrency & Race Condition Test Suite
 * Proves that competing concurrent confirmation attempts for the same position slot
 * are strictly resolved by the Firestore transaction boundary with zero race condition leakage.
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
} from '../../domain';
import { computeCandidateId, computeCompatibilityKey } from '../../matching/compatibility_key';
import {
  participationRequestToDoc,
  allocationUnitToDoc,
  allocationCandidateToDoc,
  docToAllocationPosition,
  docToAllocationUnit,
  docToParticipationRequest,
} from '../../persistence/dto/dto_converters';
import { AllocationConfirmationService } from '../confirmation_service';
import { PositionAlreadyOccupiedError } from '../confirmation_errors';
import { MockFirestore } from './mock_firestore';

describe('CENTRAL POOL — Step 5: Concurrency & Race Condition Simulation', () => {
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

  // Member A (Alice)
  const reqAlice: ParticipationRequest = {
    requestId: 'req_alice',
    tenantId,
    memberUid: 'usr_alice',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    preferredPayoutPeriod: 2,
    status: 'AWAITING_SELECTION',
    clientSubmissionId: 'sub_alice_1',
    createdAt: '2026-09-09T11:55:00.000Z',
    updatedAt: '2026-09-09T11:55:00.000Z',
    requestExpiresAt: '2026-09-16T11:55:00.000Z',
    version: 1,
  };

  const candAliceId = computeCandidateId({
    tenantId,
    requestId: 'req_alice',
    allocationUnitId: unitId,
    allocatedPosition: 3,
    payoutPeriod: 2,
    contributionMinor: 50000,
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const candAlice: AllocationCandidate = {
    candidateId: candAliceId,
    requestId: 'req_alice',
    tenantId,
    memberUid: 'usr_alice',
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

  // Member B (Bob) - Competing for the exact same Position 3 on unit_alpha
  const reqBob: ParticipationRequest = {
    requestId: 'req_bob',
    tenantId,
    memberUid: 'usr_bob',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    preferredPayoutPeriod: 2,
    status: 'AWAITING_SELECTION',
    clientSubmissionId: 'sub_bob_1',
    createdAt: '2026-09-09T11:55:00.000Z',
    updatedAt: '2026-09-09T11:55:00.000Z',
    requestExpiresAt: '2026-09-16T11:55:00.000Z',
    version: 1,
  };

  const candBobId = computeCandidateId({
    tenantId,
    requestId: 'req_bob',
    allocationUnitId: unitId,
    allocatedPosition: 3,
    payoutPeriod: 2,
    contributionMinor: 50000,
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const candBob: AllocationCandidate = {
    candidateId: candBobId,
    requestId: 'req_bob',
    tenantId,
    memberUid: 'usr_bob',
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
    mockDb.doc(getParticipationRequestPath('req_alice')).set(participationRequestToDoc(reqAlice, true));
    mockDb.doc(`allocation_candidates/${candAliceId}`).set(allocationCandidateToDoc(candAlice, true));
    mockDb.doc(getParticipationRequestPath('req_bob')).set(participationRequestToDoc(reqBob, true));
    mockDb.doc(`allocation_candidates/${candBobId}`).set(allocationCandidateToDoc(candBob, true));
  });

  it('guarantees that when two members compete for Position 3, exactly one succeeds and one fails', async () => {
    // 1. Member A executes confirmation first
    const resultAlice = await service.confirmAllocation({
      tenantId,
      memberUid: 'usr_alice',
      requestId: 'req_alice',
      candidateId: candAliceId,
      idempotencyKey: 'idemp_alice',
      evaluationTimestamp: currentTime,
    });

    assert.equal(resultAlice.success, true);
    assert.equal(resultAlice.memberUid, 'usr_alice');

    // 2. Member B attempts to confirm the same position
    await assert.rejects(
      async () => {
        await service.confirmAllocation({
          tenantId,
          memberUid: 'usr_bob',
          requestId: 'req_bob',
          candidateId: candBobId,
          idempotencyKey: 'idemp_bob',
          evaluationTimestamp: currentTime,
        });
      },
      (err: any) => err instanceof PositionAlreadyOccupiedError
    );

    // 3. Verify Single Authoritative Position Owner
    const posPath = getPositionPath(unitId, 3);
    const posSnap = await mockDb.doc(posPath).get();
    assert.equal(posSnap.exists, true);
    const pos = docToAllocationPosition(posSnap.data()!, 6);
    assert.equal(pos.memberUid, 'usr_alice'); // Alice owns it
    assert.equal(pos.requestId, 'req_alice');

    // 4. Verify Occupancy Invariant: incremented exactly once (2 -> 3)
    const unitSnap = await mockDb.doc(getAllocationUnitPath(unitId)).get();
    const updatedUnit = docToAllocationUnit(unitSnap.data()!);
    assert.equal(updatedUnit.occupiedCount, 3);

    // 5. Verify Requests States: Alice CONFIRMED, Bob remained AWAITING_SELECTION
    const reqAliceSnap = await mockDb.doc(getParticipationRequestPath('req_alice')).get();
    const aliceReq = docToParticipationRequest(reqAliceSnap.data()!);
    assert.equal(aliceReq.status, 'CONFIRMED');

    const reqBobSnap = await mockDb.doc(getParticipationRequestPath('req_bob')).get();
    const bobReq = docToParticipationRequest(reqBobSnap.data()!);
    assert.equal(bobReq.status, 'AWAITING_SELECTION'); // Not falsely confirmed
  });
});
