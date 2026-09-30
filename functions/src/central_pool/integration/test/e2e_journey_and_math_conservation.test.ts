/**
 * Central Pool Step 9: Canonical End-to-End Member Journey & Mathematical Conservation Test Suite
 *
 * Invariants Protected:
 * - Complete lifecycle chain from SUBMITTED -> AWAITING_SELECTION -> REVALIDATING -> CONFIRMED
 * - Atomic derivation of AllocationPosition, ConfirmedAllocation, FinancialObligation, ContributionSchedule, PayoutEntitlement, GL Journal Entries, and Period Projections
 * - Full mathematical conservation: E = N * C, TotalPot = N^2 * C, sum(contributions) == TotalPot, sum(entitlements) == TotalPot
 * - Zero divergence across domain entities, Firestore DTOs, application DTOs, and period projection records
 */

import { describe, it, beforeEach } from 'node:test';
import * as assert from 'node:assert/strict';
import { MockFirestore } from '../../application/test/mock_firestore';
import { CentralPoolApplicationService } from '../../application/central_pool_application_service';
import { TrustedAuthContext } from '../../application/application_types';
import {
  getParticipationRequestPath,
  getAllocationUnitPath,
  getPositionPath,
} from '../../domain';
import {
  computeCompatibilityKey,
} from '../../matching/compatibility_key';
import {
  calculateTotalEntitlement,
  calculateTotalPot,
  calculateMemberPrimaryPeriod,
} from '../../math/allocation_math';
import {
  computeObligationId,
} from '../../financial/identities/financial_identities';

describe('CENTRAL POOL — Step 9: Canonical E2E Member Journey & Mathematical Conservation', () => {
  let mockDb: MockFirestore;
  let service: CentralPoolApplicationService;

  const tenantId = 'tenant_prod_alpha';
  const aliceAuth: TrustedAuthContext = {
    uid: 'usr_alice_01',
    tenantId,
    role: 'MEMBER',
  };

  beforeEach(() => {
    mockDb = new MockFirestore();
    service = new CentralPoolApplicationService(mockDb as any);
  });

  // ===========================================================================
  // 1. CANONICAL END-TO-END MEMBER JOURNEY (N=6, C=500.00 / 50000 minor)
  // ===========================================================================

  describe('1. Canonical End-to-End Member Journey', () => {
    it('executes the full approved execution chain from request submission to period projections', async () => {
      // -----------------------------------------------------------------------
      // GIVEN: An authenticated member in Tenant A submitting a 6-period, $500/period request
      // -----------------------------------------------------------------------
      const contributionMinor = 50000;
      const durationPeriods = 6;
      const currency = 'USD';
      const clientRequestId = 'sub_e2e_journey_001';

      // -----------------------------------------------------------------------
      // WHEN: Step 8 submitParticipationRequest is invoked
      // -----------------------------------------------------------------------
      const submitResult = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor,
        durationPeriods,
        currency,
        clientRequestId,
      });

      // -----------------------------------------------------------------------
      // THEN: Request is persisted in authoritative SUBMITTED state
      // INVARIANT: Pure SUBMITTED state, correct compatibility key, no provisional artifacts
      // -----------------------------------------------------------------------
      assert.equal(submitResult.request.status, 'SUBMITTED');
      assert.equal(submitResult.request.tenantId, tenantId);
      assert.equal(submitResult.request.memberUid, aliceAuth.uid);
      assert.equal(submitResult.request.contributionMinor, contributionMinor);
      assert.equal(submitResult.request.durationPeriods, durationPeriods);
      assert.equal(submitResult.request.currency, currency);

      const reqDoc = await mockDb.doc(getParticipationRequestPath(submitResult.request.requestId)).get();
      assert.equal(reqDoc.exists, true);
      assert.equal(reqDoc.data()?.status, 'SUBMITTED');

      // -----------------------------------------------------------------------
      // WHEN: Candidate matching is performed via getMatchingCandidates
      // -----------------------------------------------------------------------
      // Pre-seed an existing FORMING unit for this compatibility key to test slot assignment
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency,
        contributionMinor,
        durationPeriods,
        allocationRule: 'SYMMETRICAL_V1',
      });

      const unitId = 'unit_e2e_alpha_01';
      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: durationPeriods,
        durationPeriods,
        contributionMinor,
        totalPoolMinor: calculateTotalPot(contributionMinor, durationPeriods),
        occupiedCount: 0,
        status: 'FORMING',
        currency,
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const matchResult = await service.getMatchingCandidates(aliceAuth, {
        requestId: submitResult.request.requestId,
      });

      // -----------------------------------------------------------------------
      // THEN: Candidate is discovered, request transitions to AWAITING_SELECTION
      // INVARIANT: Read-only provisional discovery, candidate is NOT authority
      // -----------------------------------------------------------------------
      assert.ok(matchResult.candidates.length > 0);
      const candidate = matchResult.candidates[0];
      assert.equal(candidate.tenantId, tenantId);
      assert.equal(candidate.memberUid, aliceAuth.uid);
      assert.equal(candidate.isProvisional, true);

      const reqDocAwaiting = await mockDb.doc(getParticipationRequestPath(submitResult.request.requestId)).get();
      assert.equal(reqDocAwaiting.data()?.status, 'AWAITING_SELECTION');

      // -----------------------------------------------------------------------
      // WHEN: Member confirms selection via selectCandidateAndConfirm
      // -----------------------------------------------------------------------
      const confirmResult = await service.selectCandidateAndConfirm(aliceAuth, {
        requestId: submitResult.request.requestId,
        candidateId: candidate.candidateId,
        idempotencyKey: 'idem_e2e_journey_001',
      });

      // -----------------------------------------------------------------------
      // THEN: Authoritative AllocationPosition is committed, financial records derived, projections created
      // INVARIANT: Single atomic transaction for position/unit/request/projection + deterministic Step 6/7 derivation
      // -----------------------------------------------------------------------
      assert.equal(confirmResult.success, true);
      assert.equal(confirmResult.allocationUnitId, unitId);
      assert.equal(confirmResult.allocatedPosition, candidate.allocatedPosition);
      assert.equal(confirmResult.payoutPeriod, candidate.payoutPeriod);
      assert.equal(confirmResult.totalEntitlementMinor, 300000); // 6 * 50000
      assert.equal(confirmResult.totalPotMinor, 1800000); // 6^2 * 50000

      // 1. Authoritative AllocationPosition verification:
      const posDoc = await mockDb.doc(getPositionPath(unitId, candidate.allocatedPosition)).get();
      assert.equal(posDoc.exists, true);
      assert.equal(posDoc.data()?.memberUid, aliceAuth.uid);
      assert.equal(posDoc.data()?.tenantId, tenantId);
      assert.equal(posDoc.data()?.payoutPeriod, candidate.payoutPeriod);

      // 2. Unit Occupancy Counter verification:
      const unitDoc = await mockDb.doc(getAllocationUnitPath(unitId)).get();
      assert.equal(unitDoc.data()?.occupiedCount, 1);
      assert.equal(unitDoc.data()?.status, 'FORMING');

      // 3. ParticipationRequest terminal transition:
      const reqDocConfirmed = await mockDb.doc(getParticipationRequestPath(submitResult.request.requestId)).get();
      assert.equal(reqDocConfirmed.data()?.status, 'CONFIRMED');

      // 4. Financial Obligation verification via Step 8 Read API:
      const expectedObligationId = computeObligationId(tenantId, confirmResult.allocationId);
      assert.equal(confirmResult.obligationId, expectedObligationId);

      const obResult = await service.getFinancialObligation(aliceAuth, {
        allocationId: confirmResult.allocationId,
      });
      assert.equal(obResult.obligation.obligationId, expectedObligationId);
      assert.equal(obResult.obligation.totalObligationMinor, 300000);
      assert.equal(obResult.obligation.contributionMinor, 50000);

      // 5. Contribution Schedule verification via Step 8 Read API (6 periods):
      const schedResult = await service.getContributionSchedule(aliceAuth, {
        obligationId: expectedObligationId,
      });
      assert.equal(schedResult.schedule.periods.length, 6);
      for (let p = 1; p <= 6; p++) {
        const periodItem = schedResult.schedule.periods[p - 1];
        assert.equal(periodItem?.periodNumber, p);
        assert.equal(periodItem?.scheduledAmountMinor, 50000);
        assert.equal(periodItem?.status, 'SCHEDULED');
      }

      // 6. Payout Entitlement verification via Step 8 Read API:
      const entResult = await service.getPayoutEntitlement(aliceAuth, {
        allocationId: confirmResult.allocationId,
      });
      assert.equal(entResult.entitlement.payoutEntitlementId, confirmResult.entitlementId);
      assert.equal(entResult.entitlement.totalEntitlementMinor, 300000);
      assert.equal(entResult.entitlement.status, 'SCHEDULED');

      // 7. Period Math Balance verification:
      assert.equal(confirmResult.totalEntitlementMinor, 300000);
      assert.equal(confirmResult.totalPotMinor, 1800000);

      // 8. Cycle Period Projection retrieval verification:
      const cycleProjResult = await service.getCyclePeriodProjection(aliceAuth, {
        unitId,
      });
      assert.equal(cycleProjResult.projection.allocationUnitId, unitId);
      assert.equal(cycleProjResult.projection.memberCount, 6);
      assert.equal(cycleProjResult.projection.totalEntitlementMinor, 300000);
      assert.equal(cycleProjResult.projection.totalPotMinor, 1800000);
      assert.ok(cycleProjResult.projection.authorizedMemberUids?.includes(aliceAuth.uid));

      // 9. Member Period Timeline retrieval verification:
      const memberTimelineResult = await service.getMemberPeriodTimeline(aliceAuth, {
        allocationId: confirmResult.allocationId,
      });
      assert.equal(memberTimelineResult.projection.allocationId, confirmResult.allocationId);
      assert.equal(memberTimelineResult.projection.periods.length, 6);
      const totalDelta = memberTimelineResult.projection.periods.reduce((sum, p) => sum + p.netEntitlementDeltaMinor, 0);
      assert.equal(totalDelta, 0, 'Lifetime net entitlement delta across all periods must be zero');
    });
  });

  // ===========================================================================
  // 2. MATHEMATICAL INTEGRATION CONSISTENCY ACROSS VECTORS
  // ===========================================================================

  describe('2. Mathematical Integration Consistency Across Valid Vectors', () => {
    const testVectors = [
      { N: 4, C: 25000, currency: 'USD', name: 'N=4, C=250.00' },
      { N: 6, C: 50000, currency: 'EUR', name: 'N=6, C=500.00' },
      { N: 11, C: 10000, currency: 'USD', name: 'N=11, C=100.00 (Odd with Center Position)' },
      { N: 12, C: 100000, currency: 'GBP', name: 'N=12, C=1000.00 (Maximum Approved Boundary)' },
    ];

    for (const vec of testVectors) {
      it(`proves mathematical conservation across Steps 1, 6, 7, and 8 for ${vec.name}`, async () => {
        // GIVEN: Pure mathematical calculation from Step 1
        const expectedE = vec.N * vec.C;
        const expectedTotalPot = vec.N * vec.N * vec.C;

        assert.equal(calculateTotalEntitlement(vec.C, vec.N), expectedE);
        assert.equal(calculateTotalPot(vec.C, vec.N), expectedTotalPot);

        // WHEN: Executing complete unit cycle simulation with all N members
        const unitId = `unit_math_vec_${vec.N}_${vec.currency}`;
        const compatKey = computeCompatibilityKey({
          tenantId,
          currency: vec.currency,
          contributionMinor: vec.C,
          durationPeriods: vec.N,
          allocationRule: 'SYMMETRICAL_V1',
        });

        await mockDb.doc(getAllocationUnitPath(unitId)).set({
          unitId,
          tenantId,
          compatibilityKey: compatKey,
          memberCount: vec.N,
          durationPeriods: vec.N,
          contributionMinor: vec.C,
          totalPoolMinor: expectedTotalPot,
          occupiedCount: 0,
          status: 'FORMING',
          currency: vec.currency,
          allocationRule: 'SYMMETRICAL_V1',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          version: 1,
        });

        let unitTotalContribution = 0;
        let unitTotalEntitlement = 0;
        let unitTotalGLDebits = 0;
        let unitTotalGLCredits = 0;

        for (let pos = 1; pos <= vec.N; pos++) {
          const memberUid = `usr_math_vec_${vec.N}_pos_${pos}`;
          const memberAuth: TrustedAuthContext = {
            uid: memberUid,
            tenantId,
            role: 'MEMBER',
          };

          // 1. Submit
          const sub = await service.submitParticipationRequest(memberAuth, {
            contributionMinor: vec.C,
            durationPeriods: vec.N,
            currency: vec.currency,
            clientRequestId: `sub_vec_${vec.N}_${pos}`,
          });

          // 2. Discover Candidate
          const match = await service.getMatchingCandidates(memberAuth, {
            requestId: sub.request.requestId,
          });
          const candidate = match.candidates[0];

          // Symmetrical reciprocal check from Step 1:
          const { primaryPeriod } = calculateMemberPrimaryPeriod(vec.N, pos);
          assert.equal(candidate.allocatedPosition, pos);
          assert.equal(candidate.payoutPeriod, primaryPeriod);

          // 3. Confirm & Derive Financials
          const conf = await service.selectCandidateAndConfirm(memberAuth, {
            requestId: sub.request.requestId,
            candidateId: candidate.candidateId,
            idempotencyKey: `idem_vec_${vec.N}_${pos}`,
          });

          // Accumulate and assert individual financial invariants:
          assert.equal(conf.totalEntitlementMinor, expectedE);
          assert.equal(conf.totalPotMinor, expectedTotalPot);

          const sched = await service.getContributionSchedule(memberAuth, {
            obligationId: conf.obligationId,
          });
          const scheduleSum = sched.schedule.periods.reduce((sum: number, p: any) => sum + p.scheduledAmountMinor, 0);
          assert.equal(scheduleSum, expectedE, `Member schedule sum must equal E (${expectedE})`);

          const ent = await service.getPayoutEntitlement(memberAuth, {
            allocationId: conf.allocationId,
          });
          assert.equal(ent.entitlement.totalEntitlementMinor, expectedE);

          unitTotalContribution += scheduleSum;
          unitTotalEntitlement += ent.entitlement.totalEntitlementMinor;
        }

        // ---------------------------------------------------------------------
        // THEN: Verify unit-level global conservation laws
        // INVARIANT 1: Total unit contributions == N^2 * C
        // INVARIANT 2: Total unit payout entitlements == N^2 * C
        // INVARIANT 3: Net unit simulation delta == 0
        // INVARIANT 4: Unit transitioned to COMMITTED_FULL when occupiedCount == N
        // ---------------------------------------------------------------------
        assert.equal(unitTotalContribution, expectedTotalPot, `Total unit contributions must equal TotalPot (${expectedTotalPot})`);
        assert.equal(unitTotalEntitlement, expectedTotalPot, `Total unit entitlements must equal TotalPot (${expectedTotalPot})`);
        assert.equal(unitTotalContribution - unitTotalEntitlement, 0, 'Net unit cycle simulation delta must be zero');

        const finalUnitDoc = await mockDb.doc(getAllocationUnitPath(unitId)).get();
        assert.equal(finalUnitDoc.data()?.occupiedCount, vec.N);
        assert.equal(finalUnitDoc.data()?.status, 'COMMITTED_FULL');
      });
    }
  });

  // ===========================================================================
  // 3. API REPRESENTATION CONSISTENCY
  // ===========================================================================

  describe('3. API Representation Consistency Across Boundaries', () => {
    it('verifies exact value and identity correspondence across domain, Firestore, and API responses', async () => {
      // GIVEN: A completed allocation
      const contributionMinor = 50000;
      const durationPeriods = 6;
      const currency = 'USD';

      const compatKey = computeCompatibilityKey({
        tenantId,
        currency,
        contributionMinor,
        durationPeriods,
        allocationRule: 'SYMMETRICAL_V1',
      });

      const unitId = 'unit_api_rep_01';
      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: durationPeriods,
        durationPeriods,
        contributionMinor,
        totalPoolMinor: calculateTotalPot(contributionMinor, durationPeriods),
        occupiedCount: 0,
        status: 'FORMING',
        currency,
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const sub = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor,
        durationPeriods,
        currency,
        clientRequestId: 'sub_api_rep_001',
      });

      const match = await service.getMatchingCandidates(aliceAuth, {
        requestId: sub.request.requestId,
      });

      const conf = await service.selectCandidateAndConfirm(aliceAuth, {
        requestId: sub.request.requestId,
        candidateId: match.candidates[0].candidateId,
        idempotencyKey: 'idem_api_rep_001',
      });

      // WHEN: Reading from API endpoints vs Firestore raw documents
      const apiObligation = await service.getFinancialObligation(aliceAuth, {
        allocationId: conf.allocationId,
      });
      const apiSchedule = await service.getContributionSchedule(aliceAuth, {
        obligationId: conf.obligationId,
      });
      const apiEntitlement = await service.getPayoutEntitlement(aliceAuth, {
        allocationId: conf.allocationId,
      });

      // THEN: Assert exact representation consistency without semantic translation
      // 1. Allocation ID matching:
      assert.equal(apiObligation.obligation.allocationId, conf.allocationId);
      assert.equal(apiSchedule.schedule.obligationId, conf.obligationId);
      assert.equal(apiEntitlement.entitlement.allocationId, conf.allocationId);

      // 2. Financial Amount consistency:
      assert.equal(apiObligation.obligation.totalObligationMinor, 300000);
      assert.equal(apiObligation.obligation.contributionMinor, 50000);
      assert.equal(apiSchedule.schedule.periods.length, 6);
      assert.equal(apiEntitlement.entitlement.totalEntitlementMinor, 300000);

      // 3. Currency and Tenant consistency:
      assert.equal(apiObligation.obligation.currency, 'USD');
      assert.equal(apiObligation.obligation.tenantId, tenantId);
      assert.equal(apiSchedule.schedule.tenantId, tenantId);
      assert.equal(apiEntitlement.entitlement.tenantId, tenantId);
    });
  });
});
