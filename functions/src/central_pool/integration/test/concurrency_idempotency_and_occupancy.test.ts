/**
 * Central Pool Step 9: Concurrency, Idempotency & Occupancy Authority Test Suite
 *
 * Invariants Protected:
 * - AllocationPosition = authoritative occupancy truth (/allocation_units/{unitId}/positions/{pos})
 * - occupiedCount is a denormalized operational counter, not independent source of financial truth
 * - Candidate matching is strictly advisory; authoritative conditions are revalidated inside atomic OCC transaction
 * - Concurrency race between 2, 3, or more members on the same position resolves with exactly 1 winner and 0 corrupted state
 * - Idempotency is strictly scoped by (tenantId, memberUid, clientKey), preventing duplicate positions, allocations, or financial obligations
 */

import { describe, it, beforeEach } from 'node:test';
import * as assert from 'node:assert/strict';
import { MockFirestore } from '../../application/test/mock_firestore';
import { CentralPoolApplicationService } from '../../application/central_pool_application_service';
import { TrustedAuthContext } from '../../application/application_types';
import {
  getAllocationUnitPath,
  getPositionPath,
  getParticipationRequestPath,
  CandidateExpiredError,
} from '../../domain';
import {
  computeCompatibilityKey,
  computeCandidateId,
} from '../../matching/compatibility_key';
import {
  PositionAlreadyOccupiedError,
} from '../../confirmation/confirmation_errors';

describe('CENTRAL POOL — Step 9: Concurrency, Idempotency & Occupancy Authority', () => {
  let mockDb: MockFirestore;
  let service: CentralPoolApplicationService;

  const tenantId = 'tenant_prod_alpha';
  const memberUid1 = 'usr_alice_01';
  const memberUid2 = 'usr_bob_02';
  const memberUid3 = 'usr_carol_03';

  const aliceAuth: TrustedAuthContext = { uid: memberUid1, tenantId, role: 'MEMBER' };
  const bobAuth: TrustedAuthContext = { uid: memberUid2, tenantId, role: 'MEMBER' };
  const carolAuth: TrustedAuthContext = { uid: memberUid3, tenantId, role: 'MEMBER' };

  beforeEach(() => {
    mockDb = new MockFirestore();
    service = new CentralPoolApplicationService(mockDb as any);
  });

  // ===========================================================================
  // 1. OCCUPANCY AUTHORITY & DENORMALIZED COUNTER INVARIANT
  // ===========================================================================

  describe('1. Occupancy Authority Invariant', () => {
    it('proves AllocationPosition is the sole occupancy authority and occupiedCount does not dictate truth', async () => {
      // -----------------------------------------------------------------------
      // GIVEN: A unit where occupiedCount is artificially modified / drifted
      // -----------------------------------------------------------------------
      const unitId = 'unit_occupancy_truth_01';
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 5, // Artificially inflated counter
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      // No actual Position documents exist yet in position slot 1
      const pos1DocBefore = await mockDb.doc(getPositionPath(unitId, 1)).get();
      assert.equal(pos1DocBefore.exists, false);

      // -----------------------------------------------------------------------
      // WHEN: Alice submits a request and discovers slot 1
      // -----------------------------------------------------------------------
      const sub = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_occ_001',
      });

      // Seed valid candidate targeting position 1 (payoutPeriod = 1)
      const candidateId = computeCandidateId({
        tenantId,
        requestId: sub.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(`allocation_candidates/${candidateId}`).set({
        candidateId,
        tenantId,
        memberUid: memberUid1,
        requestId: sub.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        totalEntitlementMinor: 300000,
        totalPotMinor: 1800000,
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        issuedAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 3600000).toISOString(),
        isProvisional: true,
      });

      // Update request to AWAITING_SELECTION
      await mockDb.doc(getParticipationRequestPath(sub.request.requestId)).update({
        status: 'AWAITING_SELECTION',
      });

      // Confirm candidate
      const conf = await service.selectCandidateAndConfirm(aliceAuth, {
        requestId: sub.request.requestId,
        candidateId,
        idempotencyKey: 'idem_occ_001',
      });

      // -----------------------------------------------------------------------
      // THEN: Authoritative AllocationPosition is created in slot 1
      // INVARIANT: Occupancy truth is solely in the Position document
      // -----------------------------------------------------------------------
      assert.equal(conf.success, true);
      assert.equal(conf.allocatedPosition, 1);

      const pos1DocAfter = await mockDb.doc(getPositionPath(unitId, 1)).get();
      assert.equal(pos1DocAfter.exists, true);
      assert.equal(pos1DocAfter.data()?.memberUid, memberUid1);
    });
  });

  // ===========================================================================
  // 2. MATCHING -> CONFIRMATION REVALIDATION SCENARIOS
  // ===========================================================================

  describe('2. Matching -> Confirmation Revalidation Scenarios', () => {
    const unitId = 'unit_revalidation_01';
    const compatKey = computeCompatibilityKey({
      tenantId,
      currency: 'USD',
      contributionMinor: 50000,
      durationPeriods: 6,
      allocationRule: 'SYMMETRICAL_V1',
    });

    beforeEach(async () => {
      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });
    });

    it('Scenario A: Candidate remains valid -> confirmation succeeds', async () => {
      const sub = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_scen_a',
      });

      const match = await service.getMatchingCandidates(aliceAuth, {
        requestId: sub.request.requestId,
      });

      const conf = await service.selectCandidateAndConfirm(aliceAuth, {
        requestId: sub.request.requestId,
        candidateId: match.candidates[0].candidateId,
        idempotencyKey: 'idem_scen_a',
      });

      assert.equal(conf.success, true);
      assert.equal(conf.allocatedPosition, 1);
    });

    it('Scenario B: Candidate becomes invalid/expired -> confirmation fails safely', async () => {
      const sub = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_scen_b',
      });

      const candidateId = computeCandidateId({
        tenantId,
        requestId: sub.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      // Seed an expired candidate (expired 1 hour ago)
      await mockDb.doc(`allocation_candidates/${candidateId}`).set({
        candidateId,
        tenantId,
        memberUid: memberUid1,
        requestId: sub.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        totalEntitlementMinor: 300000,
        totalPotMinor: 1800000,
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        issuedAt: new Date(Date.now() - 7200000).toISOString(),
        expiresAt: new Date(Date.now() - 3600000).toISOString(),
        isProvisional: true,
      });

      await mockDb.doc(getParticipationRequestPath(sub.request.requestId)).update({
        status: 'AWAITING_SELECTION',
      });

      await assert.rejects(
        () => service.selectCandidateAndConfirm(aliceAuth, {
          requestId: sub.request.requestId,
          candidateId,
          idempotencyKey: 'idem_scen_b',
        }),
        (err: any) => err instanceof CandidateExpiredError || err.code === 'failed-precondition'
      );
    });

    it('Scenario C: Position already occupied -> confirmation fails safely with PositionAlreadyOccupiedError', async () => {
      // 1. Bob occupies position 1
      await mockDb.doc(getPositionPath(unitId, 1)).set({
        unitId,
        positionNumber: 1,
        tenantId,
        memberUid: memberUid2,
        requestId: 'req_bob_preoccupied',
        payoutPeriod: 1,
        occupiedAt: new Date().toISOString(),
        version: 1,
      });

      // 2. Alice tries to confirm candidate targeting position 1
      const sub = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_scen_c',
      });

      const candidateId = computeCandidateId({
        tenantId,
        requestId: sub.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(`allocation_candidates/${candidateId}`).set({
        candidateId,
        tenantId,
        memberUid: memberUid1,
        requestId: sub.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        totalEntitlementMinor: 300000,
        totalPotMinor: 1800000,
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        issuedAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 3600000).toISOString(),
        isProvisional: true,
      });

      await mockDb.doc(getParticipationRequestPath(sub.request.requestId)).update({
        status: 'AWAITING_SELECTION',
      });

      await assert.rejects(
        () => service.selectCandidateAndConfirm(aliceAuth, {
          requestId: sub.request.requestId,
          candidateId,
          idempotencyKey: 'idem_scen_c',
        }),
        (err: any) => err instanceof PositionAlreadyOccupiedError || err.code === 'already-exists'
      );
    });
  });

  // ===========================================================================
  // 3. CONCURRENCY / RACE HARNESS (2 & 3+ CONCURRENT CONFIRMATIONS)
  // ===========================================================================

  describe('3. Concurrency & Race Validation', () => {
    it('executes 2 concurrent confirmations on the same candidate/position: exactly 1 wins, 0 state corruption', async () => {
      // -----------------------------------------------------------------------
      // GIVEN: Unit with slot 1 open, Alice and Bob each holding a provisional candidate for slot 1
      // -----------------------------------------------------------------------
      const unitId = 'unit_race_2_members';
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const subAlice = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_race_alice',
      });

      const subBob = await service.submitParticipationRequest(bobAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_race_bob',
      });

      // Both target position 1 with valid computed IDs
      const candAliceId = computeCandidateId({
        tenantId,
        requestId: subAlice.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      const candBobId = computeCandidateId({
        tenantId,
        requestId: subBob.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(`allocation_candidates/${candAliceId}`).set({
        candidateId: candAliceId,
        tenantId,
        memberUid: memberUid1,
        requestId: subAlice.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        totalEntitlementMinor: 300000,
        totalPotMinor: 1800000,
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        issuedAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 3600000).toISOString(),
        isProvisional: true,
      });

      await mockDb.doc(`allocation_candidates/${candBobId}`).set({
        candidateId: candBobId,
        tenantId,
        memberUid: memberUid2,
        requestId: subBob.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        totalEntitlementMinor: 300000,
        totalPotMinor: 1800000,
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        issuedAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 3600000).toISOString(),
        isProvisional: true,
      });

      await mockDb.doc(getParticipationRequestPath(subAlice.request.requestId)).update({
        status: 'AWAITING_SELECTION',
      });
      await mockDb.doc(getParticipationRequestPath(subBob.request.requestId)).update({
        status: 'AWAITING_SELECTION',
      });

      // -----------------------------------------------------------------------
      // WHEN: Both attempt selectCandidateAndConfirm concurrently
      // -----------------------------------------------------------------------
      const results = await Promise.allSettled([
        service.selectCandidateAndConfirm(aliceAuth, {
          requestId: subAlice.request.requestId,
          candidateId: candAliceId,
          idempotencyKey: 'idem_race_alice',
        }),
        service.selectCandidateAndConfirm(bobAuth, {
          requestId: subBob.request.requestId,
          candidateId: candBobId,
          idempotencyKey: 'idem_race_bob',
        }),
      ]);

      // -----------------------------------------------------------------------
      // THEN: Exactly 1 succeeds, 1 fails
      // INVARIANT: Exactly one authoritative AllocationPosition, occupiedCount incremented by exactly 1
      // -----------------------------------------------------------------------
      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      assert.equal(fulfilled.length, 1, 'Exactly one concurrent confirmation must succeed');
      assert.equal(rejected.length, 1, 'Losing concurrent confirmation must fail');

      const pos1Doc = await mockDb.doc(getPositionPath(unitId, 1)).get();
      assert.equal(pos1Doc.exists, true);

      const unitDoc = await mockDb.doc(getAllocationUnitPath(unitId)).get();
      assert.equal(unitDoc.data()?.occupiedCount, 1, 'Occupied count must be incremented by exactly 1');
    });

    it('executes 3 concurrent confirmations on a single open position: exactly 1 wins, 2 fail cleanly', async () => {
      const unitId = 'unit_race_3_members';
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const sub1 = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_3race_1',
      });
      const sub2 = await service.submitParticipationRequest(bobAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_3race_2',
      });
      const sub3 = await service.submitParticipationRequest(carolAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_3race_3',
      });

      const cId1 = computeCandidateId({
        tenantId,
        requestId: sub1.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });
      const cId2 = computeCandidateId({
        tenantId,
        requestId: sub2.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });
      const cId3 = computeCandidateId({
        tenantId,
        requestId: sub3.request.requestId,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      for (const [sub, uid, cId] of [
        [sub1, memberUid1, cId1],
        [sub2, memberUid2, cId2],
        [sub3, memberUid3, cId3],
      ] as const) {
        await mockDb.doc(`allocation_candidates/${cId}`).set({
          candidateId: cId,
          tenantId,
          memberUid: uid,
          requestId: sub.request.requestId,
          allocationUnitId: unitId,
          allocatedPosition: 1,
          payoutPeriod: 1,
          contributionMinor: 50000,
          durationPeriods: 6,
          totalEntitlementMinor: 300000,
          totalPotMinor: 1800000,
          currency: 'USD',
          allocationRule: 'SYMMETRICAL_V1',
          issuedAt: new Date().toISOString(),
          expiresAt: new Date(Date.now() + 3600000).toISOString(),
          isProvisional: true,
        });
        await mockDb.doc(getParticipationRequestPath(sub.request.requestId)).update({
          status: 'AWAITING_SELECTION',
        });
      }

      const results = await Promise.allSettled([
        service.selectCandidateAndConfirm(aliceAuth, {
          requestId: sub1.request.requestId,
          candidateId: cId1,
          idempotencyKey: 'idem_3_1',
        }),
        service.selectCandidateAndConfirm(bobAuth, {
          requestId: sub2.request.requestId,
          candidateId: cId2,
          idempotencyKey: 'idem_3_2',
        }),
        service.selectCandidateAndConfirm(carolAuth, {
          requestId: sub3.request.requestId,
          candidateId: cId3,
          idempotencyKey: 'idem_3_3',
        }),
      ]);

      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      assert.equal(fulfilled.length, 1, 'Exactly one of 3 concurrent requests must succeed');
      assert.equal(rejected.length, 2, 'Two of 3 concurrent requests must fail');

      const unitDoc = await mockDb.doc(getAllocationUnitPath(unitId)).get();
      assert.equal(unitDoc.data()?.occupiedCount, 1);
    });
  });

  // ===========================================================================
  // 4. IDEMPOTENCY SCOPING & REPLAY INVARIANTS
  // ===========================================================================

  describe('4. Idempotency End-to-End & Scope Isolation', () => {
    it('proves exact replay returns cached result with isIdempotentReplay: true and 0 duplicate records', async () => {
      const unitId = 'unit_idemp_replay_01';
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const sub = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_idemp_001',
      });

      const match = await service.getMatchingCandidates(aliceAuth, {
        requestId: sub.request.requestId,
      });

      const clientKey = 'client_idem_key_abc_123';

      // First invocation:
      const conf1 = await service.selectCandidateAndConfirm(aliceAuth, {
        requestId: sub.request.requestId,
        candidateId: match.candidates[0].candidateId,
        idempotencyKey: clientKey,
      });

      assert.equal(conf1.isIdempotentReplay, false);

      // Replay with identical key:
      const conf2 = await service.selectCandidateAndConfirm(aliceAuth, {
        requestId: sub.request.requestId,
        candidateId: match.candidates[0].candidateId,
        idempotencyKey: clientKey,
      });

      assert.equal(conf2.isIdempotentReplay, true);
      assert.equal(conf1.allocationId, conf2.allocationId);
      assert.equal(conf1.obligationId, conf2.obligationId);

      // Verify occupiedCount did not inflate:
      const unitDoc = await mockDb.doc(getAllocationUnitPath(unitId)).get();
      assert.equal(unitDoc.data()?.occupiedCount, 1);
    });

    it('proves same clientKey with different memberUid executes independently without collision', async () => {
      const unitId = 'unit_idemp_diff_member';
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const sharedClientKey = 'shared_client_key_999';

      // 1. Alice matches and confirms position 1
      const subAlice = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_diff_alice',
      });
      const matchAlice = await service.getMatchingCandidates(aliceAuth, {
        requestId: subAlice.request.requestId,
      });
      const confAlice = await service.selectCandidateAndConfirm(aliceAuth, {
        requestId: subAlice.request.requestId,
        candidateId: matchAlice.candidates[0].candidateId,
        idempotencyKey: sharedClientKey,
      });

      // 2. Bob matches (slot 1 is now occupied, discovers slot 2) and confirms with same shared client key
      const subBob = await service.submitParticipationRequest(bobAuth, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_diff_bob',
      });
      const matchBob = await service.getMatchingCandidates(bobAuth, {
        requestId: subBob.request.requestId,
      });
      const confBob = await service.selectCandidateAndConfirm(bobAuth, {
        requestId: subBob.request.requestId,
        candidateId: matchBob.candidates[0].candidateId,
        idempotencyKey: sharedClientKey,
      });

      // Both should succeed independently with different allocation IDs and positions:
      assert.notEqual(confAlice.allocationId, confBob.allocationId);
      assert.equal(confAlice.allocatedPosition, 1);
      assert.equal(confBob.allocatedPosition, 2);

      const unitDoc = await mockDb.doc(getAllocationUnitPath(unitId)).get();
      assert.equal(unitDoc.data()?.occupiedCount, 2);
    });
  });
});
