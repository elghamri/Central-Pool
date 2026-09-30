/**
 * Central Pool Step 4: Pure Eligibility Evaluator Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';

import { ParticipationRequest, AllocationUnit } from '../../domain';
import { evaluateUnitEligibility } from '../eligibility_evaluator';

describe('CENTRAL POOL — Step 4: Pure Eligibility Evaluator', () => {
  const validRequest: ParticipationRequest = {
    requestId: 'req_001',
    tenantId: 'tenant_prod_01',
    memberUid: 'usr_alice',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 10,
    preferredPayoutPeriod: 5,
    status: 'SUBMITTED',
    clientSubmissionId: 'sub_123',
    createdAt: '2026-09-08T12:00:00.000Z',
    updatedAt: '2026-09-08T12:00:00.000Z',
    requestExpiresAt: '2026-09-15T12:00:00.000Z',
    version: 1,
  };

  const validUnit: AllocationUnit = {
    unitId: 'unit_001',
    tenantId: 'tenant_prod_01',
    compatibilityKey: 'cp_test_key',
    memberCount: 10,
    occupiedCount: 3,
    status: 'FORMING',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 10,
    allocationRule: 'SYMMETRICAL_V1',
    createdAt: '2026-09-08T12:00:00.000Z',
    updatedAt: '2026-09-08T12:00:00.000Z',
    version: 1,
  };

  it('accepts perfectly matched request and unit context', () => {
    const res = evaluateUnitEligibility(validRequest, validUnit);
    assert.equal(res.isEligible, true);
    assert.equal(res.rejectionReasons.length, 0);
  });

  it('strictly rejects cross-tenant matching', () => {
    const res = evaluateUnitEligibility(validRequest, { ...validUnit, tenantId: 'tenant_other' });
    assert.equal(res.isEligible, false);
    assert.ok(res.rejectionReasons.some((r) => r.includes('Tenant mismatch')));
  });

  it('rejects units in COMMITTED_FULL and DEFECT_QUARANTINE status', () => {
    const resFull = evaluateUnitEligibility(validRequest, { ...validUnit, status: 'COMMITTED_FULL', occupiedCount: 10 });
    assert.equal(resFull.isEligible, false);
    assert.ok(resFull.rejectionReasons.some((r) => r.includes('ineligible status')));

    const resQuarantine = evaluateUnitEligibility(validRequest, { ...validUnit, status: 'DEFECT_QUARANTINE' });
    assert.equal(resQuarantine.isEligible, false);
  });

  it('rejects units with zero remaining capacity', () => {
    const res = evaluateUnitEligibility(validRequest, { ...validUnit, occupiedCount: 10 });
    assert.equal(res.isEligible, false);
    assert.ok(res.rejectionReasons.some((r) => r.includes('no available capacity')));
  });

  it('rejects mismatched contribution amount or currency', () => {
    const resAmount = evaluateUnitEligibility(validRequest, { ...validUnit, contributionMinor: 25000 });
    assert.equal(resAmount.isEligible, false);
    assert.ok(resAmount.rejectionReasons.some((r) => r.includes('Contribution mismatch')));

    const resCurr = evaluateUnitEligibility(validRequest, { ...validUnit, currency: 'EGP' });
    assert.equal(resCurr.isEligible, false);
    assert.ok(resCurr.rejectionReasons.some((r) => r.includes('Currency mismatch')));
  });

  it('rejects duration mismatch and out-of-bounds duration', () => {
    const resDuration = evaluateUnitEligibility(validRequest, { ...validUnit, memberCount: 6, durationPeriods: 6 });
    assert.equal(resDuration.isEligible, false);
    assert.ok(resDuration.rejectionReasons.some((r) => r.includes('Duration mismatch')));

    const resOutOfBounds = evaluateUnitEligibility(
      { ...validRequest, durationPeriods: 1 },
      { ...validUnit, memberCount: 1, durationPeriods: 1 }
    );
    assert.equal(resOutOfBounds.isEligible, false);
  });

  it('enforces Central Pool Odd-Entitlement Guardrail (e.g. N=3, C=1 is rejected)', () => {
    const oddRequest: ParticipationRequest = {
      ...validRequest,
      durationPeriods: 3,
      contributionMinor: 1,
    };
    const oddUnit: AllocationUnit = {
      ...validUnit,
      memberCount: 3,
      occupiedCount: 1,
      durationPeriods: 3,
      contributionMinor: 1,
    };

    const res = evaluateUnitEligibility(oddRequest, oddUnit);
    assert.equal(res.isEligible, false);
    assert.ok(res.rejectionReasons.some((r) => r.includes('Odd entitlement rejection')));
  });

  it('accepts valid even entitlement with odd member count (e.g. N=3, C=2 -> E=6)', () => {
    const evenRequest: ParticipationRequest = {
      ...validRequest,
      durationPeriods: 3,
      contributionMinor: 2,
    };
    const evenUnit: AllocationUnit = {
      ...validUnit,
      memberCount: 3,
      occupiedCount: 1,
      durationPeriods: 3,
      contributionMinor: 2,
    };

    const res = evaluateUnitEligibility(evenRequest, evenUnit);
    assert.equal(res.isEligible, true);
  });
});
