/**
 * Central Pool Step 4: Candidate Generation & Ranking Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';

import { ParticipationRequest, AllocationUnit, AllocationCandidate } from '../../domain';
import { generateCandidate } from '../candidate_generator';
import { rankCandidates } from '../candidate_ranker';
import { VacantPositionEvaluation } from '../matching_types';
import { calculateTotalEntitlement, calculateTotalPot } from '../../math/allocation_math';

describe('CENTRAL POOL — Step 4: Candidate Generation & Ranking', () => {
  const sampleRequest: ParticipationRequest = {
    requestId: 'req_001',
    tenantId: 'tenant_prod_01',
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

  const sampleUnit: AllocationUnit = {
    unitId: 'unit_001',
    tenantId: 'tenant_prod_01',
    compatibilityKey: 'cp_test_key',
    memberCount: 10,
    occupiedCount: 4,
    status: 'FORMING',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 10,
    allocationRule: 'SYMMETRICAL_V1',
    createdAt: '2026-09-08T12:00:00.000Z',
    updatedAt: '2026-09-08T12:00:00.000Z',
    version: 1,
  };

  describe('1. Candidate Generation & Math Kernel Delegation', () => {
    it('generates a valid provisional candidate delegating E and TotalPot to math kernel', () => {
      const vacantPos: VacantPositionEvaluation = {
        positionNumber: 3,
        primaryPayoutPeriod: 3,
        isCenter: false,
        isExactPayoutPreferenceMatch: false,
      };

      const candidate = generateCandidate(sampleRequest, sampleUnit, vacantPos, {
        evaluationTimestamp: '2026-09-08T12:00:00.000Z',
        candidateTtlSeconds: 300,
      });

      assert.equal(candidate.requestId, 'req_001');
      assert.equal(candidate.tenantId, 'tenant_prod_01');
      assert.equal(candidate.memberUid, 'usr_alice');
      assert.equal(candidate.allocationUnitId, 'unit_001');
      assert.equal(candidate.allocatedPosition, 3);
      assert.equal(candidate.payoutPeriod, 3);
      assert.equal(candidate.isProvisional, true);

      // Verify delegation to math kernel
      const expectedE = calculateTotalEntitlement(50000, 10);
      const expectedPot = calculateTotalPot(50000, 10);
      assert.equal(candidate.totalEntitlementMinor, expectedE);
      assert.equal(candidate.totalPotMinor, expectedPot);
      assert.equal(candidate.totalEntitlementMinor, 500000);
      assert.equal(candidate.totalPotMinor, 5000000);

      // Verify candidate TTL is exactly 300s (independent of request TTL)
      assert.equal(candidate.issuedAt, '2026-09-08T12:00:00.000Z');
      assert.equal(candidate.expiresAt, '2026-09-08T12:05:00.000Z');
      assert.ok(candidate.candidateId.startsWith('cand_'));
    });
  });

  describe('2. S4-03 / S4-06: Deterministic Candidate Ranking Governance', () => {
    const candidateAtPeriod4: AllocationCandidate = {
      candidateId: 'cand_p4',
      requestId: 'req_001',
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_alice',
      allocationUnitId: 'unit_alpha',
      allocatedPosition: 4,
      payoutPeriod: 4,
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

    const candidateAtPeriod3: AllocationCandidate = {
      ...candidateAtPeriod4,
      candidateId: 'cand_p3',
      allocatedPosition: 3,
      payoutPeriod: 3,
    };

    const candidateAtPeriod8: AllocationCandidate = {
      ...candidateAtPeriod4,
      candidateId: 'cand_p8',
      allocatedPosition: 8,
      payoutPeriod: 8,
    };

    it('1. APPROVED BUSINESS RULE: ranks exact preferred payout period match first', () => {
      const candidates = [candidateAtPeriod8, candidateAtPeriod3, candidateAtPeriod4];
      const ranked = rankCandidates(candidates, 4);

      assert.equal(ranked[0].payoutPeriod, 4);
      assert.equal(ranked[0].candidateId, 'cand_p4');
    });

    it('2. APPROVED BUSINESS RULE: ranks candidates by payout proximity when exact match is absent', () => {
      const candidates = [candidateAtPeriod8, candidateAtPeriod3];
      // Preference is 4. Distance to 3 is |3-4|=1; distance to 8 is |8-4|=4.
      const ranked = rankCandidates(candidates, 4);

      assert.equal(ranked[0].payoutPeriod, 3);
      assert.equal(ranked[1].payoutPeriod, 8);
    });

    it('3. TECHNICAL TIE-BREAKER: uses deterministic unitId sort when payout distance is equal', () => {
      const unitBetaCandidate: AllocationCandidate = {
        ...candidateAtPeriod4,
        candidateId: 'cand_beta_p4',
        allocationUnitId: 'unit_beta',
        allocatedPosition: 4,
      };

      const unitAlphaCandidate: AllocationCandidate = {
        ...candidateAtPeriod4,
        candidateId: 'cand_alpha_p4',
        allocationUnitId: 'unit_alpha',
        allocatedPosition: 4,
      };

      const ranked = rankCandidates([unitBetaCandidate, unitAlphaCandidate], 4);

      // 'unit_alpha' precedes 'unit_beta' lexicographically
      assert.equal(ranked[0].allocationUnitId, 'unit_alpha');
      assert.equal(ranked[1].allocationUnitId, 'unit_beta');
    });

    it('4. TECHNICAL TIE-BREAKER: uses position index ascending sort within same unit', () => {
      const candPos1: AllocationCandidate = {
        ...candidateAtPeriod4,
        candidateId: 'cand_pos1',
        allocationUnitId: 'unit_a',
        allocatedPosition: 1,
        payoutPeriod: 1,
      };
      const candPos2: AllocationCandidate = {
        ...candidateAtPeriod4,
        candidateId: 'cand_pos2',
        allocationUnitId: 'unit_a',
        allocatedPosition: 2,
        payoutPeriod: 1, // Same payout period for tie-break
      };

      const ranked = rankCandidates([candPos2, candPos1], 1);

      assert.equal(ranked[0].allocatedPosition, 1);
      assert.equal(ranked[1].allocatedPosition, 2);
    });

    it('5. PERMUTATION INVARIANCE: any input permutation produces identical final order', () => {
      const c1: AllocationCandidate = { ...candidateAtPeriod4, candidateId: 'c1', allocationUnitId: 'u1', allocatedPosition: 1, payoutPeriod: 1 };
      const c2: AllocationCandidate = { ...candidateAtPeriod4, candidateId: 'c2', allocationUnitId: 'u1', allocatedPosition: 2, payoutPeriod: 2 };
      const c3: AllocationCandidate = { ...candidateAtPeriod4, candidateId: 'c3', allocationUnitId: 'u2', allocatedPosition: 1, payoutPeriod: 4 }; // exact match
      const c4: AllocationCandidate = { ...candidateAtPeriod4, candidateId: 'c4', allocationUnitId: 'u3', allocatedPosition: 5, payoutPeriod: 5 }; // dist 1

      const list1 = [c1, c2, c3, c4];
      const list2 = [c4, c2, c1, c3];
      const list3 = [c3, c4, c2, c1];

      const ranked1 = rankCandidates(list1, 4);
      const ranked2 = rankCandidates(list2, 4);
      const ranked3 = rankCandidates(list3, 4);

      assert.deepEqual(ranked1.map((c) => c.candidateId), ['c3', 'c4', 'c2', 'c1']);
      assert.deepEqual(ranked2.map((c) => c.candidateId), ['c3', 'c4', 'c2', 'c1']);
      assert.deepEqual(ranked3.map((c) => c.candidateId), ['c3', 'c4', 'c2', 'c1']);
    });
  });
});
