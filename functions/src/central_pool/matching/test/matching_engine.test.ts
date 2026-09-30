/**
 * Central Pool Step 4: Pure Matching Engine Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';

import { ParticipationRequest, AllocationUnit, AllocationPosition } from '../../domain';
import { MatchingEngine } from '../matching_engine';
import { CandidateUnitContext } from '../matching_types';

describe('CENTRAL POOL — Step 4: Pure Matching Engine', () => {
  const engine = new MatchingEngine();

  const validRequest: ParticipationRequest = {
    requestId: 'req_001',
    tenantId: 'tenant_prod_01',
    memberUid: 'usr_alice',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 4,
    preferredPayoutPeriod: 2,
    status: 'SUBMITTED',
    clientSubmissionId: 'sub_123',
    createdAt: '2026-09-08T12:00:00.000Z',
    updatedAt: '2026-09-08T12:00:00.000Z',
    requestExpiresAt: '2026-09-15T12:00:00.000Z',
    version: 1,
  };

  const unitAlpha: AllocationUnit = {
    unitId: 'unit_alpha',
    tenantId: 'tenant_prod_01',
    compatibilityKey: 'cp_test_key_4',
    memberCount: 4,
    occupiedCount: 2,
    status: 'FORMING',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 4,
    allocationRule: 'SYMMETRICAL_V1',
    createdAt: '2026-09-08T12:00:00.000Z',
    updatedAt: '2026-09-08T12:00:00.000Z',
    version: 1,
  };

  const unitAlphaPositions: AllocationPosition[] = [
    {
      unitId: 'unit_alpha',
      positionNumber: 1,
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_bob',
      requestId: 'req_bob',
      payoutPeriod: 1,
      occupiedAt: '2026-09-08T12:00:00.000Z',
      version: 1,
    },
    {
      unitId: 'unit_alpha',
      positionNumber: 2,
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_charlie',
      requestId: 'req_charlie',
      payoutPeriod: 2,
      occupiedAt: '2026-09-08T12:00:00.000Z',
      version: 1,
    },
  ];

  it('evaluates vacant positions accurately excluding occupied positions', () => {
    const contexts: CandidateUnitContext[] = [
      {
        unit: unitAlpha,
        occupiedPositions: unitAlphaPositions, // positions 1 and 2 occupied; 3 and 4 vacant
      },
    ];

    const result = engine.evaluateRequest(
      { request: validRequest },
      contexts,
      { evaluationTimestamp: '2026-09-08T12:00:00.000Z' }
    );

    assert.equal(result.requestId, 'req_001');
    assert.equal(result.tenantId, 'tenant_prod_01');
    assert.equal(result.evaluatedUnitsCount, 1);
    assert.equal(result.eligibleUnitsCount, 1);
    assert.equal(result.candidates.length, 2);

    // Vacant positions are 3 and 4
    const candidatePositions = result.candidates.map((c) => c.allocatedPosition).sort();
    assert.deepEqual(candidatePositions, [3, 4]);

    // All candidates must be provisional
    for (const cand of result.candidates) {
      assert.equal(cand.isProvisional, true);
      assert.equal(cand.allocationUnitId, 'unit_alpha');
    }
  });

  it('applies non-contamination: inputs remain 100% immutable and unmutated', () => {
    const initialUnitJson = JSON.stringify(unitAlpha);
    const initialPositionsJson = JSON.stringify(unitAlphaPositions);
    const initialRequestJson = JSON.stringify(validRequest);

    engine.evaluateRequest(
      { request: validRequest },
      [{ unit: unitAlpha, occupiedPositions: unitAlphaPositions }],
      { evaluationTimestamp: '2026-09-08T12:00:00.000Z' }
    );

    assert.equal(JSON.stringify(unitAlpha), initialUnitJson);
    assert.equal(JSON.stringify(unitAlphaPositions), initialPositionsJson);
    assert.equal(JSON.stringify(validRequest), initialRequestJson);
  });

  it('respects maxCandidates limit option', () => {
    const unitBeta: AllocationUnit = {
      ...unitAlpha,
      unitId: 'unit_beta',
      occupiedCount: 0,
    };

    const contexts: CandidateUnitContext[] = [
      { unit: unitAlpha, occupiedPositions: [] }, // 4 vacant slots
      { unit: unitBeta, occupiedPositions: [] },  // 4 vacant slots
    ];

    const result = engine.evaluateRequest(
      { request: validRequest },
      contexts,
      { maxCandidates: 3, evaluationTimestamp: '2026-09-08T12:00:00.000Z' }
    );

    assert.equal(result.evaluatedUnitsCount, 2);
    assert.equal(result.eligibleUnitsCount, 2);
    assert.equal(result.candidates.length, 3);
  });

  it('collects rejections with clear diagnostics for ineligible units', () => {
    const unitIneligible: AllocationUnit = {
      ...unitAlpha,
      unitId: 'unit_diff_curr',
      currency: 'EUR',
    };

    const contexts: CandidateUnitContext[] = [
      { unit: unitAlpha, occupiedPositions: unitAlphaPositions },
      { unit: unitIneligible },
    ];

    const result = engine.evaluateRequest(
      { request: validRequest },
      contexts,
      { evaluationTimestamp: '2026-09-08T12:00:00.000Z' }
    );

    assert.equal(result.evaluatedUnitsCount, 2);
    assert.equal(result.eligibleUnitsCount, 1);
    assert.equal(result.rejections.length, 1);
    assert.equal(result.rejections[0].unitId, 'unit_diff_curr');
    assert.ok(result.rejections[0].reasons.some((r) => r.includes('Currency mismatch')));
  });
});
