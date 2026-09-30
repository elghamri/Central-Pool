/**
 * Central Pool Step 5: Idempotency & Retry Test Suite
 * Proves that duplicated confirmation requests (e.g. from network retries, Cloud Function re-execution)
 * return identical cached results without creating duplicate positions or double-incrementing occupancy.
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
  docToAllocationUnit,
} from '../../persistence/dto/dto_converters';
import {
  AllocationConfirmationService,
  computeConfirmationIdempotencyId,
} from '../confirmation_service';
import { AllocationConfirmationInput } from '../confirmation_types';
import { MockFirestore } from './mock_firestore';

describe('CENTRAL POOL — Step 5: Idempotency & Retry Safety', () => {
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
    idempotencyKey: 'idemp_key_retry_test',
    evaluationTimestamp: currentTime,
  };

  beforeEach(() => {
    mockDb = new MockFirestore();
    service = new AllocationConfirmationService(mockDb as any);

    mockDb.doc(getParticipationRequestPath(requestId)).set(participationRequestToDoc(sampleRequest, true));
    mockDb.doc(getAllocationUnitPath(unitId)).set(allocationUnitToDoc(sampleUnit, true));
    mockDb.doc(`allocation_candidates/${candidateId}`).set(allocationCandidateToDoc(sampleCandidate, true));
  });

  it('handles repeated retries idempotently without duplicate position documents or double occupancy', async () => {
    // 1. Initial Confirmation Attempt
    const firstResult = await service.confirmAllocation(sampleInput);
    assert.equal(firstResult.success, true);
    assert.equal(firstResult.isIdempotentReplay, false);

    // Initial occupancy should be 3
    const unitAfterFirst = docToAllocationUnit((await mockDb.doc(getAllocationUnitPath(unitId)).get()).data()!);
    assert.equal(unitAfterFirst.occupiedCount, 3);

    // 2. Retry Attempt with the exact same idempotencyKey
    const retryResult = await service.confirmAllocation(sampleInput);
    assert.equal(retryResult.success, true);
    assert.equal(retryResult.isIdempotentReplay, true);
    assert.equal(retryResult.allocationId, firstResult.allocationId);
    assert.equal(retryResult.allocatedPosition, firstResult.allocatedPosition);
    assert.equal(retryResult.payoutPeriod, firstResult.payoutPeriod);

    // Occupancy MUST remain exactly 3 (no double increment)
    const unitAfterRetry = docToAllocationUnit((await mockDb.doc(getAllocationUnitPath(unitId)).get()).data()!);
    assert.equal(unitAfterRetry.occupiedCount, 3);

    // Exactly one position document exists for position 3
    const posSnap = await mockDb.doc(getPositionPath(unitId, 3)).get();
    assert.equal(posSnap.exists, true);
  });

  it('guarantees strict cross-tenant idempotency isolation for identical client keys', async () => {
    const rawKey = 'shared_client_idempotency_key_xyz';
    const idempTenantA = computeConfirmationIdempotencyId('tenant_A', 'usr_001', rawKey);
    const idempTenantB = computeConfirmationIdempotencyId('tenant_B', 'usr_001', rawKey);

    assert.notEqual(idempTenantA, idempTenantB);
    assert.ok(idempTenantA.startsWith('idemp_'));
    assert.ok(idempTenantB.startsWith('idemp_'));
  });

  it('guarantees strict cross-member idempotency isolation within same tenant for identical client keys', async () => {
    const rawKey = 'shared_client_idempotency_key_xyz';
    const idempMemberA = computeConfirmationIdempotencyId('tenant_A', 'usr_alice', rawKey);
    const idempMemberB = computeConfirmationIdempotencyId('tenant_A', 'usr_bob', rawKey);

    assert.notEqual(idempMemberA, idempMemberB);
  });
});
